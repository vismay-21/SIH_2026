import uuid
from decimal import Decimal
from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, Request, status, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.db.models.user import User
from app.core.security import get_current_active_user
from app.core.exceptions import BadRequestException
from app.schemas.common import ResponseEnvelope
from app.schemas.material import (
    MaterialReceiptCreateRequest,
    MaterialReceiptResponse,
    MaterialReceiptListResponse,
)
from app.services.material_service import MaterialService

router = APIRouter()

ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "application/pdf"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


@router.post(
    "/gigs/{gig_id}/material-receipts",
    response_model=ResponseEnvelope[MaterialReceiptResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Upload material expense receipt",
)
async def upload_material_receipt(
    gig_id: uuid.UUID,
    request: Request,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[MaterialReceiptResponse]:
    """Upload itemized material receipt proof conforming to 05_API_DESIGN.md Section 23.

    Supports both formats:
    1. multipart/form-data:
       - amount: Decimal string (required)
       - receipt_file: Binary image/pdf file (optional if receipt_url is given)
       - receipt_url: Pre-uploaded storage reference (optional if receipt_file is given)
       - description: Optional text note
    2. application/json:
       - { "amount": 450.00, "receipt_url": "https://...", "description": "..." }
    """
    content_type = request.headers.get("content-type", "").lower()

    if "multipart/form-data" in content_type or "application/x-www-form-urlencoded" in content_type:
        form = await request.form()
        amount_raw = form.get("amount")
        if not amount_raw:
            raise BadRequestException("Field 'amount' is required", code="INVALID_AMOUNT")
        try:
            amount_val = Decimal(str(amount_raw))
        except Exception:
            raise BadRequestException("Field 'amount' must be a valid decimal number", code="INVALID_AMOUNT")

        if amount_val <= Decimal("0.00"):
            raise BadRequestException("Receipt amount must be strictly greater than zero", code="INVALID_AMOUNT")

        description_val = form.get("description")
        if description_val and isinstance(description_val, str):
            description_val = description_val.strip()
        else:
            description_val = None

        receipt_url_val = form.get("receipt_url")
        receipt_file_val = form.get("receipt_file")

        # Determine receipt URL from binary upload or pre-uploaded reference
        if receipt_file_val and hasattr(receipt_file_val, "filename") and receipt_file_val.filename:
            file_mime = receipt_file_val.content_type or "image/jpeg"
            if file_mime not in ALLOWED_MIME_TYPES:
                raise BadRequestException(
                    f"Receipt file MIME type '{file_mime}' is not permitted. Allowed: {sorted(list(ALLOWED_MIME_TYPES))}",
                    code="INVALID_FILE_TYPE",
                )
            content = await receipt_file_val.read()
            if len(content) > MAX_FILE_SIZE:
                raise BadRequestException("Receipt file size cannot exceed 10MB", code="FILE_TOO_LARGE")
            if len(content) == 0:
                raise BadRequestException("Uploaded receipt file cannot be empty", code="EMPTY_FILE")

            clean_filename = receipt_file_val.filename.replace(" ", "_")
            receipt_url_val = f"https://storage.sahakaar.org/material-receipts/{gig_id}/{uuid.uuid4()}_{clean_filename}"
        elif receipt_url_val and isinstance(receipt_url_val, str) and receipt_url_val.strip():
            receipt_url_val = receipt_url_val.strip()
        else:
            raise BadRequestException(
                "Either 'receipt_file' or 'receipt_url' must be provided",
                code="RECEIPT_PROOF_REQUIRED",
            )

        result = MaterialService.upload_material_receipt(
            user=current_user,
            gig_id=gig_id,
            amount=amount_val,
            receipt_url=receipt_url_val,
            description=description_val,
            db=db,
        )
    else:
        # JSON workflow
        try:
            body = await request.json()
        except Exception:
            raise BadRequestException("Malformed or missing JSON payload", code="INVALID_PAYLOAD")

        try:
            payload = MaterialReceiptCreateRequest(**body)
        except Exception as e:
            raise BadRequestException(f"Invalid payload: {e}", code="INVALID_PAYLOAD")

        result = MaterialService.upload_material_receipt(
            user=current_user,
            gig_id=gig_id,
            amount=payload.amount,
            receipt_url=payload.receipt_url,
            description=payload.description,
            db=db,
        )

    return ResponseEnvelope(data=result)


@router.get(
    "/gigs/{gig_id}/material-receipts",
    response_model=ResponseEnvelope[MaterialReceiptListResponse],
    summary="Get itemized material receipts for a gig",
)
async def get_material_receipts(
    gig_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[MaterialReceiptListResponse]:
    """Retrieve all material receipts and authoritative total cost with privacy gating."""
    result = MaterialService.get_material_receipts(
        user=current_user,
        gig_id=gig_id,
        db=db,
    )
    return ResponseEnvelope(data=result)


@router.delete(
    "/gigs/{gig_id}/material-receipts/{receipt_id}",
    response_model=ResponseEnvelope[Dict[str, Any]],
    summary="Delete an uploaded material receipt",
)
async def delete_material_receipt(
    gig_id: uuid.UUID,
    receipt_id: uuid.UUID,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db),
) -> ResponseEnvelope[Dict[str, Any]]:
    """Delete a previously uploaded receipt before completion confirmation locking."""
    result = MaterialService.delete_material_receipt(
        user=current_user,
        gig_id=gig_id,
        receipt_id=receipt_id,
        db=db,
    )
    return ResponseEnvelope(data=result)
