import uuid
from datetime import time, timedelta
import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token
from app.db.models.cooperative import Cooperative
from app.db.models.service import ServiceCategory


@pytest.fixture
def test_cooperative(db_session: Session) -> Cooperative:
    """Fixture ensuring a test cooperative exists."""
    coop = db_session.query(Cooperative).first()
    if not coop:
        coop = Cooperative(
            name="Bangalore Artisans Labour Cooperative Society",
            city="Bangalore",
            service_area="Bangalore Urban",
            is_active=True,
        )
        db_session.add(coop)
        db_session.commit()
        db_session.refresh(coop)
    return coop


def test_missing_jwt_returns_401(client: TestClient):
    """Missing JWT must return 401 Unauthorized."""
    response = client.get("/api/v1/me")
    assert response.status_code == 401
    data = response.json()
    assert data["error"]["code"] == "MISSING_AUTH_HEADER"


def test_invalid_jwt_format_returns_401(client: TestClient):
    """Malformed Authorization header must return 401."""
    response = client.get("/api/v1/me", headers={"Authorization": "Token abcdef12345"})
    assert response.status_code == 401
    data = response.json()
    assert data["error"]["code"] == "INVALID_AUTH_HEADER"


def test_invalid_signature_jwt_returns_401(client: TestClient):
    """JWT with invalid signature must return 401."""
    fake_token = jwt.encode(
        {"sub": str(uuid.uuid4()), "role": "authenticated"},
        "wrong-secret-key-that-does-not-match",
        algorithm="HS256",
    )
    response = client.get("/api/v1/me", headers={"Authorization": f"Bearer {fake_token}"})
    assert response.status_code == 401
    data = response.json()
    assert data["error"]["code"] == "INVALID_TOKEN"


def test_expired_jwt_returns_401(client: TestClient):
    """Expired JWT must return 401."""
    expired_token = create_access_token(
        {"sub": str(uuid.uuid4())},
        expires_delta=timedelta(seconds=-10),
    )
    response = client.get("/api/v1/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert response.status_code == 401
    data = response.json()
    assert data["error"]["code"] == "TOKEN_EXPIRED"


def test_initialize_customer_and_profile_flow(client: TestClient, test_cooperative: Cooperative):
    """Customer initialization, profile retrieval, and profile update flow."""
    customer_sub = str(uuid.uuid4())
    token = create_access_token({"sub": customer_sub, "email": "customer@sahakaar.org"})
    auth_headers = {"Authorization": f"Bearer {token}"}

    # 1. Initialize user as CUSTOMER
    init_res = client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={
            "role": "CUSTOMER",
            "full_name": "Pooja Sharma",
            "phone": "9876543210",
        },
    )
    assert init_res.status_code == 201
    init_data = init_res.json()["data"]
    assert init_data["id"] == customer_sub
    assert init_data["role"] == "CUSTOMER"
    assert init_data["full_name"] == "Pooja Sharma"
    assert init_data["phone"] == "9876543210"
    assert init_data["email"] == "customer@sahakaar.org"

    # 2. Check /api/v1/me
    me_res = client.get("/api/v1/me", headers=auth_headers)
    assert me_res.status_code == 200
    assert me_res.json()["data"]["role"] == "CUSTOMER"

    # 3. Get customer profile
    prof_res = client.get("/api/v1/customer/profile", headers=auth_headers)
    assert prof_res.status_code == 200
    prof_data = prof_res.json()["data"]
    assert prof_data["user_id"] == customer_sub
    assert prof_data["full_name"] == "Pooja Sharma"
    assert prof_data["address"] is None

    # 4. Update customer profile
    update_res = client.patch(
        "/api/v1/customer/profile",
        headers=auth_headers,
        json={
            "address": "42, 12th Main, HAL 2nd Stage, Indiranagar, Bangalore",
            "phone": "9998887770",
        },
    )
    assert update_res.status_code == 200
    updated_data = update_res.json()["data"]
    assert updated_data["address"] == "42, 12th Main, HAL 2nd Stage, Indiranagar, Bangalore"
    assert updated_data["phone"] == "9998887770"


def test_customer_access_to_worker_endpoints_rejected(client: TestClient, test_cooperative: Cooperative):
    """Customer attempting to call worker endpoints must be denied (403)."""
    customer_sub = str(uuid.uuid4())
    token = create_access_token({"sub": customer_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "CUSTOMER", "full_name": "Anita Rao"},
    )

    # Attempt to view worker profile
    res_prof = client.get("/api/v1/worker/profile", headers=auth_headers)
    assert res_prof.status_code == 403
    assert res_prof.json()["error"]["code"] == "FORBIDDEN_ROLE"

    # Attempt to access worker categories
    res_cats = client.get("/api/v1/worker/categories", headers=auth_headers)
    assert res_cats.status_code == 403
    assert res_cats.json()["error"]["code"] == "FORBIDDEN_ROLE"


def test_initialize_worker_and_profile_flow(client: TestClient, test_cooperative: Cooperative):
    """Worker initialization, metrics inspection, and profile update flow."""
    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub, "email": "electrician@sahakaar.org"})
    auth_headers = {"Authorization": f"Bearer {token}"}

    # 1. Initialize user as WORKER
    init_res = client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={
            "role": "WORKER",
            "full_name": "Ravi Kumar",
            "phone": "9123456780",
        },
    )
    assert init_res.status_code == 201
    assert init_res.json()["data"]["role"] == "WORKER"

    # 2. Get worker profile and verify rookie metric defaults
    prof_res = client.get("/api/v1/worker/profile", headers=auth_headers)
    assert prof_res.status_code == 200
    worker_data = prof_res.json()["data"]
    assert worker_data["user_id"] == worker_sub
    assert worker_data["full_name"] == "Ravi Kumar"
    assert worker_data["metrics"]["completed_jobs_count"] == 0
    assert worker_data["metrics"]["bayesian_score"] == 0.70000
    assert worker_data["metrics"]["experience_score"] == 0.00000
    assert worker_data["metrics"]["final_score"] == 0.35000

    # 3. Update worker profile
    update_res = client.patch(
        "/api/v1/worker/profile",
        headers=auth_headers,
        json={
            "address": "15, 5th Cross, Malleshwaram",
            "city": "Bangalore",
        },
    )
    assert update_res.status_code == 200
    updated = update_res.json()["data"]
    assert updated["address"] == "15, 5th Cross, Malleshwaram"
    assert updated["city"] == "Bangalore"


def test_worker_access_to_customer_endpoints_rejected(client: TestClient, test_cooperative: Cooperative):
    """Worker attempting to call customer endpoints must be denied (403)."""
    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "WORKER", "full_name": "Karthik Plumber"},
    )

    res = client.get("/api/v1/customer/profile", headers=auth_headers)
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "FORBIDDEN_ROLE"


def test_one_role_enforcement(client: TestClient, test_cooperative: Cooperative):
    """One-role-per-user enforcement: initialized user cannot switch roles."""
    user_sub = str(uuid.uuid4())
    token = create_access_token({"sub": user_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    # First initialization: CUSTOMER
    res1 = client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "CUSTOMER", "full_name": "Original Customer"},
    )
    assert res1.status_code == 201

    # Second initialization attempt with different role: WORKER
    res2 = client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "WORKER", "full_name": "Trying to be Worker"},
    )
    assert res2.status_code == 409
    assert res2.json()["error"]["code"] == "ROLE_IMMUTABLE"


def test_worker_aadhaar_upload_reference(client: TestClient, test_cooperative: Cooperative):
    """Uploading Aadhaar stores document reference without automatically verifying."""
    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "WORKER", "full_name": "Aadhaar Worker"},
    )

    doc_url = "https://upkxwtnxfnkjuuwrjutk.supabase.co/storage/v1/object/public/kyc/doc_123.pdf"
    res = client.post(
        "/api/v1/worker/profile/aadhaar",
        headers=auth_headers,
        json={"document_url": doc_url},
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["aadhaar_document_url"] == doc_url
    assert data["aadhaar_uploaded_at"] is not None

    # Check that worker profile now has the document reference
    prof_res = client.get("/api/v1/worker/profile", headers=auth_headers)
    assert prof_res.status_code == 200
    prof = prof_res.json()["data"]
    assert prof["aadhaar_document_url"] == doc_url
    assert prof["aadhaar_uploaded_at"] is not None


def test_worker_categories_management(client: TestClient, db_session: Session, test_cooperative: Cooperative):
    """Worker can select active categories and retrieve them."""
    # Seed two service categories
    cat1 = ServiceCategory(
        name="Plumbing",
        description="Pipes, taps, and plumbing fixtures",
        base_rate_per_minute=5.0,
        minimum_billable_minutes=45,
        is_active=True,
    )
    cat2 = ServiceCategory(
        name="Electrical",
        description="Wiring, fuses, and electrical appliances",
        base_rate_per_minute=6.0,
        minimum_billable_minutes=45,
        is_active=True,
    )
    db_session.add_all([cat1, cat2])
    db_session.commit()
    db_session.refresh(cat1)
    db_session.refresh(cat2)

    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "WORKER", "full_name": "Multi-Trade Worker"},
    )

    # Assign categories
    put_res = client.put(
        "/api/v1/worker/categories",
        headers=auth_headers,
        json={"category_ids": [str(cat1.id), str(cat2.id)]},
    )
    assert put_res.status_code == 200
    cats = put_res.json()["data"]
    assert len(cats) == 2
    cat_names = {c["name"] for c in cats}
    assert "Plumbing" in cat_names
    assert "Electrical" in cat_names

    # Retrieve categories
    get_res = client.get("/api/v1/worker/categories", headers=auth_headers)
    assert get_res.status_code == 200
    assert len(get_res.json()["data"]) == 2

    # Reject non-existent category
    bad_res = client.put(
        "/api/v1/worker/categories",
        headers=auth_headers,
        json={"category_ids": [str(uuid.uuid4())]},
    )
    assert bad_res.status_code == 400
    assert bad_res.json()["error"]["code"] == "INVALID_CATEGORY_SELECTION"


def test_worker_availability_management(client: TestClient, test_cooperative: Cooperative):
    """Worker can define weekly recurring availability slots and retrieve them."""
    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub})
    auth_headers = {"Authorization": f"Bearer {token}"}

    client.post(
        "/api/v1/me/initialize",
        headers=auth_headers,
        json={"role": "WORKER", "full_name": "Flexible Worker"},
    )

    # Set availability slots
    slots_payload = [
        {"day_of_week": 0, "start_time": "09:00:00", "end_time": "13:00:00", "is_available": True},
        {"day_of_week": 0, "start_time": "14:00:00", "end_time": "18:00:00", "is_available": True},
        {"day_of_week": 2, "start_time": "10:00:00", "end_time": "16:00:00", "is_available": True},
    ]
    put_res = client.put(
        "/api/v1/worker/availability",
        headers=auth_headers,
        json={"slots": slots_payload},
    )
    assert put_res.status_code == 200
    saved_slots = put_res.json()["data"]
    assert len(saved_slots) == 3

    # Retrieve availability slots
    get_res = client.get("/api/v1/worker/availability", headers=auth_headers)
    assert get_res.status_code == 200
    retrieved = get_res.json()["data"]
    assert len(retrieved) == 3
    assert retrieved[0]["day_of_week"] == 0

    # Reject invalid time slot (start >= end)
    bad_res = client.put(
        "/api/v1/worker/availability",
        headers=auth_headers,
        json={"slots": [{"day_of_week": 1, "start_time": "17:00:00", "end_time": "09:00:00"}]},
    )
    assert bad_res.status_code == 400
    assert bad_res.json()["error"]["code"] == "INVALID_AVAILABILITY_SLOT"


def test_profile_ownership_isolation(client: TestClient, test_cooperative: Cooperative):
    """Customer A and Customer B have independent, isolated profiles."""
    sub_a = str(uuid.uuid4())
    sub_b = str(uuid.uuid4())
    token_a = create_access_token({"sub": sub_a})
    token_b = create_access_token({"sub": sub_b})

    # Initialize both
    client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token_a}"},
        json={"role": "CUSTOMER", "full_name": "Customer A"},
    )
    client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token_b}"},
        json={"role": "CUSTOMER", "full_name": "Customer B"},
    )

    # Customer A updates address
    client.patch(
        "/api/v1/customer/profile",
        headers={"Authorization": f"Bearer {token_a}"},
        json={"address": "Customer A Private Address"},
    )

    # Customer B reads their own profile
    res_b = client.get(
        "/api/v1/customer/profile",
        headers={"Authorization": f"Bearer {token_b}"},
    )
    assert res_b.status_code == 200
    data_b = res_b.json()["data"]
    assert data_b["full_name"] == "Customer B"
    assert data_b["address"] is None  # Remains unaffected by Customer A
