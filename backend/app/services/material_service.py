import uuid
from decimal import Decimal
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from app.core.exceptions import (
    NotFoundException,
    BadRequestException,
    ForbiddenException,
    StateConflictException,
)
from app.db.models.user import User
from app.db.models.gig import Gig
from app.db.models.payment import MaterialReceipt
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    UserRole,
    GigStatus,
    MaterialProcurementMode,
    WorkerParticipationStatus,
)
from app.schemas.material import (
    MaterialReceiptResponse,
    MaterialReceiptListResponse,
)


class MaterialService:
    """Service managing itemized material expense receipts, privacy boundaries, and totals."""

    @classmethod
    def upload_material_receipt(
        cls,
        user: User,
        gig_id: uuid.UUID,
        amount: Decimal,
        receipt_url: str,
        description: Optional[str],
        db: Session,
    ) -> MaterialReceiptResponse:
        """Upload and record a material receipt with strict authorization and state checks."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        # 1. Role Check: Only workers can upload material receipts
        if user.role != UserRole.WORKER:
            raise ForbiddenException("Only workers can upload material receipts", code="FORBIDDEN")

        # 2. Procurement Mode Check
        if gig.material_procurement_mode != MaterialProcurementMode.WORKER_PURCHASES:
            raise BadRequestException(
                "Material receipts can only be uploaded when gig procurement mode is WORKER_PURCHASES",
                code="MATERIAL_PROCUREMENT_NOT_WORKER",
            )

        # 3. Lifecycle State Check
        allowed_upload_states = {
            GigStatus.WORKER_SELECTED,
            GigStatus.SCHEDULED,
            GigStatus.IN_PROGRESS,
            GigStatus.COMPLETION_SUBMITTED,
        }
        if gig.status not in allowed_upload_states:
            raise StateConflictException(
                f"Material receipts cannot be uploaded when gig is in {gig.status.value} state",
                code="INVALID_GIG_STATE",
            )

        # 4. Worker Participation Authorization Check
        is_primary_worker = (gig.selected_worker_id is not None) and (gig.selected_worker_id == user.id)
        collaborator = (
            db.query(WorkerParticipation)
            .filter(
                WorkerParticipation.gig_id == gig.id,
                WorkerParticipation.additional_worker_id == user.id,
            )
            .first()
        )
        is_accepted_collaborator = (
            collaborator is not None and collaborator.status == WorkerParticipationStatus.ACCEPTED
        )

        if collaborator is not None and collaborator.status != WorkerParticipationStatus.ACCEPTED:
            raise ForbiddenException(
                f"Collaborating worker participation is {collaborator.status.value}, not ACCEPTED",
                code="COLLABORATOR_NOT_ACCEPTED",
            )

        if not is_primary_worker and not is_accepted_collaborator:
            raise ForbiddenException(
                "You are not an authorized worker participant on this gig",
                code="FORBIDDEN",
            )

        # 5. Validation: Amount & URL
        try:
            amount_dec = Decimal(str(amount))
        except Exception:
            raise BadRequestException("Invalid receipt amount", code="INVALID_AMOUNT")

        if amount_dec <= Decimal("0.00"):
            raise BadRequestException("Receipt amount must be strictly greater than zero", code="INVALID_AMOUNT")

        if not receipt_url or not receipt_url.strip():
            raise BadRequestException("Receipt URL or storage reference is required", code="RECEIPT_PROOF_REQUIRED")

        clean_url = receipt_url.strip()
        clean_desc = description.strip() if description else None

        # 6. Create MaterialReceipt Record
        receipt = MaterialReceipt(
            gig_id=gig.id,
            worker_id=user.id,
            amount=float(amount_dec),
            receipt_url=clean_url,
            description=clean_desc,
        )
        db.add(receipt)
        db.flush()

        # 7. Audit Event Log
        event = GigEvent(
            gig_id=gig.id,
            actor_id=user.id,
            event_type="MATERIAL_RECEIPT_UPLOADED",
            metadata_json={
                "receipt_id": str(receipt.id),
                "worker_id": str(user.id),
                "amount": f"{amount_dec:.2f}",
                "description": clean_desc,
            },
        )
        db.add(event)

        # 8. Notification to Customer
        notif = Notification(
            recipient_id=gig.customer_id,
            gig_id=gig.id,
            type="MATERIAL_RECEIPT_UPLOADED",
            title="Material Receipt Uploaded",
            body=f"A material receipt for ₹{amount_dec:.2f} has been uploaded for your gig.",
        )
        db.add(notif)

        db.commit()
        db.refresh(receipt)

        return MaterialReceiptResponse(
            id=receipt.id,
            gig_id=receipt.gig_id,
            worker_id=receipt.worker_id,
            worker_name=user.full_name,
            amount=amount_dec,
            receipt_url=receipt.receipt_url,
            description=receipt.description,
            created_at=receipt.created_at,
            updated_at=receipt.updated_at,
        )

    @classmethod
    def get_material_receipts(
        cls,
        user: User,
        gig_id: uuid.UUID,
        db: Session,
    ) -> MaterialReceiptListResponse:
        """Fetch itemized receipts and authoritative total with privacy & role enforcement."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        # Authorization: Customer, Primary Worker, or Accepted Collaborator
        is_customer = (gig.customer_id == user.id)
        is_primary_worker = (gig.selected_worker_id is not None) and (gig.selected_worker_id == user.id)
        is_accepted_collab = (
            db.query(WorkerParticipation)
            .filter(
                WorkerParticipation.gig_id == gig.id,
                WorkerParticipation.additional_worker_id == user.id,
                WorkerParticipation.status == WorkerParticipationStatus.ACCEPTED,
            )
            .first()
            is not None
        )

        if not (is_customer or is_primary_worker or is_accepted_collab):
            raise ForbiddenException(
                "You are not authorized to view material receipts for this gig",
                code="FORBIDDEN",
            )

        receipts = (
            db.query(MaterialReceipt)
            .filter(MaterialReceipt.gig_id == gig.id)
            .order_by(MaterialReceipt.created_at.asc())
            .all()
        )

        items: List[MaterialReceiptResponse] = []
        total_dec = Decimal("0.00")

        for r in receipts:
            r_amount = Decimal(str(r.amount))
            total_dec += r_amount
            items.append(
                MaterialReceiptResponse(
                    id=r.id,
                    gig_id=r.gig_id,
                    worker_id=r.worker_id,
                    worker_name=r.worker.full_name if r.worker else None,
                    amount=r_amount,
                    receipt_url=r.receipt_url,
                    description=r.description,
                    created_at=r.created_at,
                    updated_at=r.updated_at,
                )
            )

        return MaterialReceiptListResponse(
            gig_id=gig.id,
            material_procurement_mode=gig.material_procurement_mode,
            total_material_cost=total_dec,
            receipt_count=len(items),
            receipts=items,
        )

    @classmethod
    def delete_material_receipt(
        cls,
        user: User,
        gig_id: uuid.UUID,
        receipt_id: uuid.UUID,
        db: Session,
    ) -> Dict[str, Any]:
        """Delete an uploaded receipt before work confirmation locking."""
        gig = db.query(Gig).filter(Gig.id == gig_id).first()
        if not gig:
            raise NotFoundException(f"Gig {gig_id} not found", code="GIG_NOT_FOUND")

        receipt = (
            db.query(MaterialReceipt)
            .filter(
                MaterialReceipt.id == receipt_id,
                MaterialReceipt.gig_id == gig.id,
            )
            .first()
        )
        if not receipt:
            raise NotFoundException(
                f"Material receipt {receipt_id} not found on this gig",
                code="RECEIPT_NOT_FOUND",
            )

        # 1. Ownership: Only the specific uploader can delete
        if receipt.worker_id != user.id:
            raise ForbiddenException(
                "You can only delete your own uploaded material receipts",
                code="FORBIDDEN",
            )

        # 2. Lifecycle Locking: Can only delete during active pre-completion states
        allowed_delete_states = {
            GigStatus.WORKER_SELECTED,
            GigStatus.SCHEDULED,
            GigStatus.IN_PROGRESS,
        }
        if gig.status not in allowed_delete_states:
            raise StateConflictException(
                f"Material receipts are locked and cannot be deleted when gig is in {gig.status.value} state",
                code="MATERIAL_RECEIPTS_LOCKED",
            )

        deleted_amount = Decimal(str(receipt.amount))
        db.delete(receipt)

        # 3. Audit Event
        event = GigEvent(
            gig_id=gig.id,
            actor_id=user.id,
            event_type="MATERIAL_RECEIPT_DELETED",
            metadata_json={
                "receipt_id": str(receipt_id),
                "amount": f"{deleted_amount:.2f}",
                "deleted_by": str(user.id),
            },
        )
        db.add(event)

        # 4. Notification to Customer
        notif = Notification(
            recipient_id=gig.customer_id,
            gig_id=gig.id,
            type="MATERIAL_RECEIPT_DELETED",
            title="Material Receipt Removed",
            body=f"Worker has removed a material receipt of ₹{deleted_amount:.2f}.",
        )
        db.add(notif)

        db.commit()

        return {
            "message": "Material receipt deleted successfully",
            "receipt_id": str(receipt_id),
        }
