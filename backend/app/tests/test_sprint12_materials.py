import uuid
import io
from decimal import Decimal
from typing import Tuple
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.db.models.user import User
from app.db.models.service import ServiceCategory, ServiceTask
from app.db.models.gig import Gig
from app.db.models.payment import MaterialReceipt
from app.db.models.multi_worker import WorkerParticipation
from app.db.models.communication import GigEvent, Notification
from app.db.models.enums import (
    GigStatus,
    MaterialProcurementMode,
    WorkerParticipationStatus,
    WorkerParticipationClassification,
)
from app.services.catalogue_service import CatalogueService


@pytest.fixture(autouse=True)
def seed_catalog_fixture(db_session: Session):
    """Ensure service catalogue is populated."""
    CatalogueService.seed_catalogue_if_empty(db_session)


def create_test_customer(
    client: TestClient, db_session: Session, email_prefix: str = "cust12"
) -> Tuple[str, dict]:
    """Helper to initialize a customer and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "CUSTOMER", "full_name": f"Customer {sub[:6]}"},
    )
    assert res.status_code == 201
    return token, res.json()["data"]


def create_test_worker(
    client: TestClient,
    db_session: Session,
    category_id: uuid.UUID,
    email_prefix: str = "w12",
) -> Tuple[str, dict]:
    """Helper to initialize a worker with category and return (jwt_token, user_dict)."""
    sub = str(uuid.uuid4())
    token = create_access_token(
        {"sub": sub, "email": f"{email_prefix}_{sub[:8]}@sahakaar.org"}
    )
    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": f"Worker {sub[:6]}"},
    )
    assert res.status_code == 201
    worker_data = res.json()["data"]

    res_cat = client.put(
        "/api/v1/worker/categories",
        headers={"Authorization": f"Bearer {token}"},
        json={"category_ids": [str(category_id)]},
    )
    assert res_cat.status_code == 200

    return token, worker_data


def setup_assigned_materials_gig(
    client: TestClient,
    db_session: Session,
    procurement_mode: str = "WORKER_PURCHASES",
    prefix: str = "m12",
) -> Tuple[str, dict, str, dict, str, ServiceCategory]:
    """Helper to set up a gig assigned to primary worker in WORKER_SELECTED status."""
    token_cust, cust = create_test_customer(
        client, db_session, email_prefix=f"c_{prefix}"
    )
    plumbing = (
        db_session.query(ServiceCategory)
        .filter(ServiceCategory.name == "Plumbing")
        .first()
    )
    task = (
        db_session.query(ServiceTask)
        .filter(ServiceTask.category_id == plumbing.id)
        .first()
    )

    token_w1, w1 = create_test_worker(
        client, db_session, plumbing.id, email_prefix=f"w1_{prefix}"
    )

    # 1. Customer creates gig
    res_create = client.post(
        "/api/v1/gigs",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={
            "category_id": str(plumbing.id),
            "task_ids": [str(task.id)],
            "instructions": "Need pipes replaced and materials procured",
            "material_procurement_mode": procurement_mode,
        },
    )
    assert res_create.status_code == 201
    gig_id = res_create.json()["data"]["id"]

    # 2. Customer posts gig
    res_post = client.post(
        f"/api/v1/gigs/{gig_id}/post",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_post.status_code == 200

    # 3. Worker accepts opportunity
    res_opps = client.get(
        "/api/v1/worker/opportunities",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_opps.status_code == 200
    opp = next(o for o in res_opps.json()["data"] if o["gig_id"] == gig_id)

    res_accept = client.post(
        f"/api/v1/worker/opportunities/{opp['id']}/accept",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_accept.status_code == 200

    # 4. Customer selects worker
    res_select = client.post(
        f"/api/v1/gigs/{gig_id}/select-worker",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"worker_id": w1["id"]},
    )
    assert res_select.status_code == 200

    return token_cust, cust, token_w1, w1, gig_id, plumbing


# ==============================================================================
# 1. PROCUREMENT MODE RULES
# ==============================================================================

def test_material_receipt_upload_blocked_when_customer_purchases(
    client: TestClient, db_session: Session
):
    """Uploading receipts is forbidden when gig procurement mode is CUSTOMER_PURCHASES."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="CUSTOMER_PURCHASES", prefix="cp"
    )

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "amount": 250.00,
            "receipt_url": "https://storage.sahakaar.org/receipts/bill1.jpg",
            "description": "Pipe sealants",
        },
    )
    assert res.status_code == 400
    assert "MATERIAL_PROCUREMENT_NOT_WORKER" in res.json()["error"]["code"]


def test_material_receipt_upload_allowed_when_worker_purchases_json(
    client: TestClient, db_session: Session
):
    """Worker can upload itemized receipt via JSON workflow when mode is WORKER_PURCHASES."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="wp"
    )

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "amount": 350.50,
            "receipt_url": "https://storage.sahakaar.org/material-receipts/r1.jpg",
            "description": "Copper elbow joints and Teflon tape",
        },
    )
    assert res.status_code == 201
    data = res.json()["data"]
    assert data["gig_id"] == gig_id
    assert data["worker_id"] == w1["id"]
    assert float(data["amount"]) == 350.50
    assert data["receipt_url"] == "https://storage.sahakaar.org/material-receipts/r1.jpg"
    assert data["description"] == "Copper elbow joints and Teflon tape"
    assert data["worker_name"] == w1["full_name"]


# ==============================================================================
# 2. DUAL UPLOAD FORMAT SUPPORT (MULTIPART VS JSON)
# ==============================================================================

def test_multipart_binary_receipt_file_upload(
    client: TestClient, db_session: Session
):
    """Multipart upload with binary image file succeeds and generates canonical storage URL."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="mp_bin"
    )

    fake_image = io.BytesIO(b"\xff\xd8\xff\xe0\x00\x10JFIFfake_receipt_data")
    files = {"receipt_file": ("hardware_bill.jpg", fake_image, "image/jpeg")}
    form_data = {
        "amount": "520.00",
        "description": "Brass valve replacement from Metro Hardware",
    }

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        data=form_data,
        files=files,
    )
    assert res.status_code == 201
    data = res.json()["data"]
    assert float(data["amount"]) == 520.00
    assert "https://storage.sahakaar.org/material-receipts/" in data["receipt_url"]
    assert "hardware_bill.jpg" in data["receipt_url"]
    assert data["description"] == "Brass valve replacement from Metro Hardware"


def test_multipart_preuploaded_receipt_url(
    client: TestClient, db_session: Session
):
    """Multipart upload with pre-uploaded storage receipt_url succeeds."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="mp_url"
    )

    form_data = {
        "amount": "180.75",
        "receipt_url": "https://storage.sahakaar.org/pre-uploaded/bill99.pdf",
        "description": "Solvent cement bottle",
    }

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        data=form_data,
    )
    assert res.status_code == 201
    data = res.json()["data"]
    assert float(data["amount"]) == 180.75
    assert data["receipt_url"] == "https://storage.sahakaar.org/pre-uploaded/bill99.pdf"


def test_multipart_invalid_file_mime_rejected(
    client: TestClient, db_session: Session
):
    """Uploading non-permitted file MIME types (e.g. .exe or script) is rejected."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="mp_bad"
    )

    files = {"receipt_file": ("exploit.exe", io.BytesIO(b"MZfake"), "application/x-msdownload")}
    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        data={"amount": "100.00"},
        files=files,
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "INVALID_FILE_TYPE"


def test_multipart_empty_file_rejected(
    client: TestClient, db_session: Session
):
    """Uploading a 0-byte file is rejected."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="mp_empty"
    )

    files = {"receipt_file": ("empty.jpg", io.BytesIO(b""), "image/jpeg")}
    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        data={"amount": "100.00"},
        files=files,
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "EMPTY_FILE"


def test_multipart_missing_proof_rejected(
    client: TestClient, db_session: Session
):
    """Submitting form data without file and without receipt_url is rejected."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="mp_noprf"
    )

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        data={"amount": "100.00", "description": "No receipt attached"},
    )
    assert res.status_code == 400
    assert res.json()["error"]["code"] == "RECEIPT_PROOF_REQUIRED"


# ==============================================================================
# 3. ROLE & PARTICIPATION AUTHORIZATION
# ==============================================================================

def test_customer_cannot_upload_material_receipt(
    client: TestClient, db_session: Session
):
    """Customers are forbidden from uploading material receipts."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="cust_up"
    )

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"amount": 100.00, "receipt_url": "https://storage.sahakaar.org/r.jpg"},
    )
    assert res.status_code == 403


def test_unrelated_worker_cannot_upload_material_receipt(
    client: TestClient, db_session: Session
):
    """A worker not assigned or accepted on the gig cannot upload receipts."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="unrel_w"
    )
    token_w2, w2 = create_test_worker(client, db_session, cat.id, email_prefix="w2_unrel")

    res = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={"amount": 100.00, "receipt_url": "https://storage.sahakaar.org/r.jpg"},
    )
    assert res.status_code == 403


def test_accepted_collaborator_can_upload_receipt(
    client: TestClient, db_session: Session
):
    """An accepted collaborating worker (Sprint 10) can legitimately upload material receipts."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="collab"
    )
    token_w2, w2 = create_test_worker(client, db_session, cat.id, email_prefix="w2_collab")

    # Invite and accept collaborator
    res_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "EQUAL_SHARING",
        },
    )
    assert res_inv.status_code == 201
    part_id = res_inv.json()["data"]["id"]

    res_join = client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )
    assert res_join.status_code == 200

    # Collaborator uploads receipt
    res_receipt = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={
            "amount": 275.50,
            "receipt_url": "https://storage.sahakaar.org/collab_bill.jpg",
            "description": "Additional pipe fittings purchased by collaborator",
        },
    )
    assert res_receipt.status_code == 201
    data = res_receipt.json()["data"]
    assert data["worker_id"] == w2["id"]
    assert float(data["amount"]) == 275.50
    assert data["worker_name"] == w2["full_name"]


def test_pending_or_rejected_collaborator_cannot_upload_receipt(
    client: TestClient, db_session: Session
):
    """A collaborator with PENDING or REJECTED participation cannot upload receipts."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="collab_pend"
    )
    token_w2, w2 = create_test_worker(client, db_session, cat.id, email_prefix="w2_pend")

    # Invite worker 2 but DO NOT accept (remains PENDING)
    res_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "additional_worker_id": w2["id"],
            "classification": "ROOKIE",
        },
    )
    assert res_inv.status_code == 201

    res_up = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={"amount": 150.00, "receipt_url": "https://storage.sahakaar.org/p.jpg"},
    )
    assert res_up.status_code == 403
    assert res_up.json()["error"]["code"] == "COLLABORATOR_NOT_ACCEPTED"


# ==============================================================================
# 4. PRIVACY & ACCESS CONTROL (GET)
# ==============================================================================

def test_privacy_gating_on_view_receipts(
    client: TestClient, db_session: Session
):
    """Only authorized participants (customer, primary worker, collaborator) can view receipts."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="priv"
    )
    token_unrelated, _ = create_test_customer(client, db_session, email_prefix="unrel_cust")

    # Upload a receipt
    client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 300.00, "receipt_url": "https://storage.sahakaar.org/r.jpg"},
    )

    # 1. Customer can view
    res_c = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_c.status_code == 200
    assert len(res_c.json()["data"]["receipts"]) == 1

    # 2. Worker can view
    res_w = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_w.status_code == 200
    assert len(res_w.json()["data"]["receipts"]) == 1

    # 3. Unrelated user is forbidden
    res_u = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_unrelated}"},
    )
    assert res_u.status_code == 403

    # 4. Anonymous user is unauthorized
    res_anon = client.get(f"/api/v1/gigs/{gig_id}/material-receipts")
    assert res_anon.status_code in {401, 403}


# ==============================================================================
# 5. ITEMIZED ACCOUNTING & ADDITIVE TOTALS
# ==============================================================================

def test_itemized_accounting_and_additive_totals(
    client: TestClient, db_session: Session
):
    """Multiple receipts from primary worker and collaborator calculate exact total."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="tot"
    )
    token_w2, w2 = create_test_worker(client, db_session, cat.id, email_prefix="w2_tot")

    # Invite & join collaborator
    res_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"additional_worker_id": w2["id"], "classification": "EQUAL_SHARING"},
    )
    part_id = res_inv.json()["data"]["id"]
    client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )

    # Worker 1 uploads receipt 1: 345.50
    client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 345.50, "receipt_url": "https://storage.sahakaar.org/r1.jpg", "description": "Pipes"},
    )
    # Collaborator uploads receipt 2: 154.50
    client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={"amount": 154.50, "receipt_url": "https://storage.sahakaar.org/r2.jpg", "description": "Joints"},
    )
    # Worker 1 uploads receipt 3: 200.00
    client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 200.00, "receipt_url": "https://storage.sahakaar.org/r3.jpg", "description": "Solvent"},
    )

    res = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["receipt_count"] == 3
    # 345.50 + 154.50 + 200.00 = 700.00 exactly
    assert float(data["total_material_cost"]) == 700.00
    assert data["material_procurement_mode"] == "WORKER_PURCHASES"


def test_zero_or_negative_receipt_amount_rejected(
    client: TestClient, db_session: Session
):
    """Receipt amounts <= 0 are rejected by validation."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="neg_amt"
    )

    res_zero = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 0.00, "receipt_url": "https://storage.sahakaar.org/zero.jpg"},
    )
    assert res_zero.status_code in {400, 422}

    res_neg = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": -50.00, "receipt_url": "https://storage.sahakaar.org/neg.jpg"},
    )
    assert res_neg.status_code in {400, 422}


# ==============================================================================
# 6. RECEIPT DELETION & LIFECYCLE LOCKING
# ==============================================================================

def test_worker_deletes_own_receipt_in_progress(
    client: TestClient, db_session: Session
):
    """Worker can delete their own receipt during active work, updating total."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="del_ok"
    )

    # Worker starts work -> IN_PROGRESS
    res_start = client.post(
        f"/api/v1/gigs/{gig_id}/start",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_start.status_code == 200

    # Worker uploads two receipts
    r1 = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 300.00, "receipt_url": "https://storage.sahakaar.org/r1.jpg"},
    ).json()["data"]

    r2 = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 150.00, "receipt_url": "https://storage.sahakaar.org/r2.jpg"},
    ).json()["data"]

    # Delete receipt 1
    res_del = client.delete(
        f"/api/v1/gigs/{gig_id}/material-receipts/{r1['id']}",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_del.status_code == 200

    # Total should now be 150.00
    res_list = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_list.json()["data"]["receipt_count"] == 1
    assert float(res_list.json()["data"]["total_material_cost"]) == 150.00


def test_worker_cannot_delete_another_workers_receipt(
    client: TestClient, db_session: Session
):
    """A worker cannot delete a receipt uploaded by another worker."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="del_other"
    )
    token_w2, w2 = create_test_worker(client, db_session, cat.id, email_prefix="w2_del")

    # Invite & join collaborator
    res_inv = client.post(
        f"/api/v1/gigs/{gig_id}/participations",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"additional_worker_id": w2["id"], "classification": "EQUAL_SHARING"},
    )
    part_id = res_inv.json()["data"]["id"]
    client.post(
        f"/api/v1/participations/{part_id}/accept",
        headers={"Authorization": f"Bearer {token_w2}"},
    )

    # Collaborator uploads receipt
    res_collab = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w2}"},
        json={"amount": 200.00, "receipt_url": "https://storage.sahakaar.org/rc.jpg"},
    )
    assert res_collab.status_code == 201
    r_collab = res_collab.json()["data"]

    # Primary worker attempts to delete collaborator's receipt
    res_del = client.delete(
        f"/api/v1/gigs/{gig_id}/material-receipts/{r_collab['id']}",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_del.status_code == 403


def test_receipt_deletion_locked_after_completion_submitted(
    client: TestClient, db_session: Session
):
    """Once completion is submitted, material receipts are locked and cannot be deleted."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="del_lock"
    )

    # Worker uploads receipt
    r = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 400.00, "receipt_url": "https://storage.sahakaar.org/r.jpg"},
    ).json()["data"]

    # Worker submits completion
    res_comp = client.post(
        f"/api/v1/gigs/{gig_id}/completion",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={
            "description": "Job finished and tested",
            "evidence_items": [
                {"file_url": "https://storage.sahakaar.org/completion.jpg", "file_type": "image/jpeg"}
            ],
        },
    )
    assert res_comp.status_code == 200

    # Attempt to delete receipt now -> 409 Conflict
    res_del = client.delete(
        f"/api/v1/gigs/{gig_id}/material-receipts/{r['id']}",
        headers={"Authorization": f"Bearer {token_w1}"},
    )
    assert res_del.status_code == 409
    assert res_del.json()["error"]["code"] == "MATERIAL_RECEIPTS_LOCKED"


# ==============================================================================
# 7. CANCELLATION & AUDIT PRESERVATION
# ==============================================================================

def test_cancellation_preserves_material_receipts_for_audit(
    client: TestClient, db_session: Session
):
    """Cancelling a gig leaves material receipts preserved for historical audit."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="audit_canc"
    )

    # Upload receipt
    client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 500.00, "receipt_url": "https://storage.sahakaar.org/r.jpg"},
    )

    # Customer cancels gig
    res_canc = client.post(
        f"/api/v1/gigs/{gig_id}/cancel",
        headers={"Authorization": f"Bearer {token_cust}"},
        json={"reason": "Emergency travel, must cancel"},
    )
    assert res_canc.status_code == 200

    # Receipts remain preserved and queryable
    res_get = client.get(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_cust}"},
    )
    assert res_get.status_code == 200
    assert res_get.json()["data"]["receipt_count"] == 1
    assert float(res_get.json()["data"]["total_material_cost"]) == 500.00

    # New receipt upload on cancelled gig is blocked
    res_new = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 100.00, "receipt_url": "https://storage.sahakaar.org/r2.jpg"},
    )
    assert res_new.status_code == 409
    assert res_new.json()["error"]["code"] == "INVALID_GIG_STATE"


# ==============================================================================
# 8. AUDIT EVENTS & NOTIFICATIONS
# ==============================================================================

def test_audit_events_and_customer_notifications_emitted(
    client: TestClient, db_session: Session
):
    """Material upload and deletion emit GigEvents and customer Notifications."""
    token_cust, cust, token_w1, w1, gig_id, cat = setup_assigned_materials_gig(
        client, db_session, procurement_mode="WORKER_PURCHASES", prefix="audit_ev"
    )

    # Upload receipt
    r = client.post(
        f"/api/v1/gigs/{gig_id}/material-receipts",
        headers={"Authorization": f"Bearer {token_w1}"},
        json={"amount": 320.00, "receipt_url": "https://storage.sahakaar.org/r.jpg", "description": "Valves"},
    ).json()["data"]

    # Check upload audit event and notification
    ev_upload = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "MATERIAL_RECEIPT_UPLOADED")
        .first()
    )
    assert ev_upload is not None
    assert ev_upload.metadata_json["amount"] == "320.00"

    notif_upload = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "MATERIAL_RECEIPT_UPLOADED")
        .first()
    )
    assert notif_upload is not None
    assert str(notif_upload.recipient_id) == cust["id"]

    # Delete receipt
    client.delete(
        f"/api/v1/gigs/{gig_id}/material-receipts/{r['id']}",
        headers={"Authorization": f"Bearer {token_w1}"},
    )

    # Check delete audit event and notification
    ev_del = (
        db_session.query(GigEvent)
        .filter(GigEvent.gig_id == uuid.UUID(gig_id), GigEvent.event_type == "MATERIAL_RECEIPT_DELETED")
        .first()
    )
    assert ev_del is not None
    assert ev_del.metadata_json["amount"] == "320.00"

    notif_del = (
        db_session.query(Notification)
        .filter(Notification.gig_id == uuid.UUID(gig_id), Notification.type == "MATERIAL_RECEIPT_DELETED")
        .first()
    )
    assert notif_del is not None
    assert str(notif_del.recipient_id) == cust["id"]
