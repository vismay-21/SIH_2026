import uuid
from datetime import timedelta
import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token
from app.db.models.cooperative import Cooperative
from app.db.models.user import User
from app.db.models.enums import UserRole
from app.services.score_service import compute_final_score, get_rookie_initial_metrics
from app.services.user_service import get_or_create_default_cooperative


# --- 1. Score Calculation & Rookie Defaults Centralization ---

def test_rookie_metric_defaults_and_score_centralization():
    """Verify rookie metrics are centralized, configurable, and follow W = 0.5 * B + 0.5 * E."""
    # 1. Configured defaults
    assert settings.BAYESIAN_PRIOR_MEAN == 0.70
    assert settings.ROOKIE_EXPERIENCE_SCORE == 0.00
    assert settings.ROOKIE_FINAL_SCORE == 0.35000

    # 2. Formula verification
    calc_final = compute_final_score(0.70, 0.00)
    assert calc_final == 0.35000

    # Intermediate / expert examples per WAGES.md
    assert compute_final_score(0.80, 0.60) == 0.70000
    assert compute_final_score(1.00, 1.00) == 1.00000

    # Centralized dictionary
    metrics = get_rookie_initial_metrics()
    assert metrics["bayesian_score"] == 0.70
    assert metrics["experience_score"] == 0.00
    assert metrics["final_score"] == 0.35
    assert metrics["completed_jobs_count"] == 0


def test_worker_initialization_uses_centralized_rookie_metrics(client: TestClient, db_session: Session):
    """Verify worker initialization receives exact rookie baseline metrics from service."""
    worker_sub = str(uuid.uuid4())
    token = create_access_token({"sub": worker_sub, "email": "rookie@sahakaar.org"})

    res = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token}"},
        json={"role": "WORKER", "full_name": "Rookie Technician"},
    )
    assert res.status_code == 201

    prof_res = client.get(
        "/api/v1/worker/profile",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert prof_res.status_code == 200
    metrics = prof_res.json()["data"]["metrics"]
    assert metrics["bayesian_score"] == 0.70000
    assert metrics["experience_score"] == 0.00000
    assert metrics["final_score"] == 0.35000
    assert metrics["completed_jobs_count"] == 0


# --- 2. JWT Security & Validation Audit ---

def test_jwt_rejects_none_algorithm(client: TestClient):
    """Token with 'none' algorithm must be rejected (security audit)."""
    none_token = jwt.encode({"sub": str(uuid.uuid4())}, key="", algorithm="none")
    res = client.get("/api/v1/me", headers={"Authorization": f"Bearer {none_token}"})
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "INVALID_TOKEN"


def test_jwt_rejects_empty_or_missing_sub(client: TestClient):
    """Token with empty or missing 'sub' must be rejected."""
    # Missing sub
    no_sub_token = jwt.encode({"email": "test@sahakaar.org"}, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
    res1 = client.get("/api/v1/me", headers={"Authorization": f"Bearer {no_sub_token}"})
    assert res1.status_code == 401
    assert res1.json()["error"]["code"] == "INVALID_TOKEN_CLAIMS"

    # Empty sub
    empty_sub_token = jwt.encode({"sub": "   "}, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
    res2 = client.get("/api/v1/me", headers={"Authorization": f"Bearer {empty_sub_token}"})
    assert res2.status_code == 401
    assert res2.json()["error"]["code"] == "INVALID_TOKEN_CLAIMS"


def test_jwt_rejects_non_uuid_sub(client: TestClient):
    """Token with non-UUID 'sub' string must be rejected with INVALID_USER_ID."""
    malformed_sub_token = jwt.encode({"sub": "admin' OR 1=1 --"}, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
    res = client.get("/api/v1/me", headers={"Authorization": f"Bearer {malformed_sub_token}"})
    assert res.status_code == 401
    assert res.json()["error"]["code"] == "INVALID_USER_ID"


def test_jwt_rejects_inactive_user(client: TestClient, db_session: Session):
    """Inactive/deactivated users cannot access endpoints even with a valid signed token."""
    user_id = str(uuid.uuid4())
    token = create_access_token({"sub": user_id})
    headers = {"Authorization": f"Bearer {token}"}

    # Initialize user
    client.post(
        "/api/v1/me/initialize",
        headers=headers,
        json={"role": "CUSTOMER", "full_name": "Active User"},
    )

    # Deactivate user in database
    user = db_session.query(User).filter(User.id == uuid.UUID(user_id)).first()
    user.is_active = False
    db_session.commit()

    # Call /me -> must be forbidden
    res = client.get("/api/v1/me", headers=headers)
    assert res.status_code == 403
    assert res.json()["error"]["code"] == "USER_INACTIVE"

    # Call /me/initialize again -> must also be forbidden
    res_init = client.post(
        "/api/v1/me/initialize",
        headers=headers,
        json={"role": "CUSTOMER", "full_name": "Attempting Reactivation"},
    )
    assert res_init.status_code == 403
    assert res_init.json()["error"]["code"] == "USER_INACTIVE"


def test_merely_signed_token_cannot_access_protected_endpoints(client: TestClient):
    """A valid token for a user NOT yet in the database cannot access protected resources."""
    unregistered_uuid = str(uuid.uuid4())
    token = create_access_token({"sub": unregistered_uuid})
    headers = {"Authorization": f"Bearer {token}"}

    res_me = client.get("/api/v1/me", headers=headers)
    assert res_me.status_code == 401
    assert res_me.json()["error"]["code"] == "USER_NOT_INITIALIZED"

    res_cust = client.get("/api/v1/customer/profile", headers=headers)
    assert res_cust.status_code == 401
    assert res_cust.json()["error"]["code"] == "USER_NOT_INITIALIZED"


# --- 3. Cooperative Isolation & Integrity ---

def test_default_cooperative_idempotency_and_no_duplicates(db_session: Session):
    """Repeated default cooperative lookups must return the same entity without duplicates."""
    coop1 = get_or_create_default_cooperative(db_session)
    coop2 = get_or_create_default_cooperative(db_session)
    assert coop1.id == coop2.id

    # Total cooperatives matching the name must be exactly 1
    total_coops = (
        db_session.query(Cooperative)
        .filter(Cooperative.name == "Bangalore Artisans Labour Cooperative Society")
        .count()
    )
    assert total_coops == 1


def test_initialize_rejects_invalid_or_inactive_cooperative(client: TestClient, db_session: Session):
    """Users cannot initialize under non-existent or inactive cooperatives."""
    # 1. Non-existent cooperative
    token1 = create_access_token({"sub": str(uuid.uuid4())})
    res1 = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token1}"},
        json={
            "role": "CUSTOMER",
            "full_name": "Coop Test Customer",
            "cooperative_id": str(uuid.uuid4()),
        },
    )
    assert res1.status_code == 404
    assert res1.json()["error"]["code"] == "COOPERATIVE_NOT_FOUND"

    # 2. Inactive cooperative
    inactive_coop = Cooperative(
        name="Inactive Rural Cooperative",
        city="Mysore",
        service_area="Rural",
        is_active=False,
    )
    db_session.add(inactive_coop)
    db_session.commit()
    db_session.refresh(inactive_coop)

    token2 = create_access_token({"sub": str(uuid.uuid4())})
    res2 = client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token2}"},
        json={
            "role": "CUSTOMER",
            "full_name": "Coop Test Customer 2",
            "cooperative_id": str(inactive_coop.id),
        },
    )
    assert res2.status_code == 404
    assert res2.json()["error"]["code"] == "COOPERATIVE_NOT_FOUND"


def test_cross_cooperative_user_data_isolation(client: TestClient, db_session: Session):
    """Users in different cooperatives cannot see or mutate each other's data."""
    # Create Coop 1 and Coop 2
    coop1 = Cooperative(
        name="Bangalore Artisans Guild",
        city="Bangalore",
        is_active=True,
    )
    coop2 = Cooperative(
        name="Mysore Craft Cooperative",
        city="Mysore",
        is_active=True,
    )
    db_session.add_all([coop1, coop2])
    db_session.commit()
    db_session.refresh(coop1)
    db_session.refresh(coop2)

    # User 1 in Coop 1
    user1_id = str(uuid.uuid4())
    token1 = create_access_token({"sub": user1_id})
    client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token1}"},
        json={"role": "CUSTOMER", "full_name": "Bangalore Customer", "cooperative_id": str(coop1.id)},
    )
    client.patch(
        "/api/v1/customer/profile",
        headers={"Authorization": f"Bearer {token1}"},
        json={"address": "Bangalore Confidential Address"},
    )

    # User 2 in Coop 2
    user2_id = str(uuid.uuid4())
    token2 = create_access_token({"sub": user2_id})
    client.post(
        "/api/v1/me/initialize",
        headers={"Authorization": f"Bearer {token2}"},
        json={"role": "CUSTOMER", "full_name": "Mysore Customer", "cooperative_id": str(coop2.id)},
    )

    # Verify User 1's profile belongs strictly to User 1
    p1 = client.get("/api/v1/customer/profile", headers={"Authorization": f"Bearer {token1}"}).json()["data"]
    p2 = client.get("/api/v1/customer/profile", headers={"Authorization": f"Bearer {token2}"}).json()["data"]

    assert p1["full_name"] == "Bangalore Customer"
    assert p1["address"] == "Bangalore Confidential Address"

    assert p2["full_name"] == "Mysore Customer"
    assert p2["address"] is None  # Cannot see User 1's address
