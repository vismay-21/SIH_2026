"""Sprint 15 Integration Hardening: Development Authentication Tests."""

import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.models.enums import UserRole
from app.db.models.user import User


def test_dev_login_customer_creates_and_returns_token(client: TestClient, db_session: Session):
    """POST /api/v1/auth/login initializes a customer and returns valid JWT token."""
    email = f"cust_{uuid.uuid4().hex[:8]}@sahakaar.org"
    res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "role": "CUSTOMER", "full_name": "Test Customer Dev"},
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert "access_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == email
    assert data["user"]["role"] == "CUSTOMER"

    # Use returned access_token on /api/v1/me
    token = data["access_token"]
    res_me = client.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert res_me.status_code == 200
    assert res_me.json()["data"]["email"] == email


def test_dev_login_worker_creates_and_links_category(client: TestClient, db_session: Session):
    """POST /api/v1/auth/login initializes a worker and returns valid JWT token."""
    email = f"worker_{uuid.uuid4().hex[:8]}@sahakaar.org"
    res = client.post(
        "/api/v1/auth/login",
        json={"email": email, "role": "WORKER", "full_name": "Test Worker Dev"},
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["user"]["role"] == "WORKER"

    token = data["access_token"]
    res_w = client.get("/api/v1/worker/profile", headers={"Authorization": f"Bearer {token}"})
    assert res_w.status_code == 200


def test_dev_login_role_conflict_rejected(client: TestClient, db_session: Session):
    """Attempting to login an existing customer as worker returns 409 ROLE_IMMUTABLE."""
    email = f"conflict_{uuid.uuid4().hex[:8]}@sahakaar.org"
    client.post("/api/v1/auth/login", json={"email": email, "role": "CUSTOMER"})
    res_bad = client.post("/api/v1/auth/login", json={"email": email, "role": "WORKER"})
    assert res_bad.status_code == 409
    assert res_bad.json()["error"]["code"] == "ROLE_IMMUTABLE"


def test_get_demo_users(client: TestClient, db_session: Session):
    """GET /api/v1/auth/demo-users returns active user list."""
    res = client.get("/api/v1/auth/demo-users")
    assert res.status_code == 200
    assert isinstance(res.json()["data"], list)


def test_dev_auth_environment_guard_matrix(client: TestClient, monkeypatch):
    """Verify explicit allowlist and rejection of prod, staging, live, and unexpected envs."""
    allowed_envs = ["development", "dev", "test", "local", "DEVELOPMENT", "Local"]
    for env in allowed_envs:
        monkeypatch.setattr(settings, "ENVIRONMENT", env)
        res = client.get("/api/v1/auth/demo-users")
        assert res.status_code == 200, f"Expected {env} to be allowed, got {res.status_code}"

    blocked_envs = ["production", "prod", "staging", "live", "PROD", "Staging", "unknown_env", ""]
    for env in blocked_envs:
        monkeypatch.setattr(settings, "ENVIRONMENT", env)
        res = client.get("/api/v1/auth/demo-users")
        assert res.status_code == 403, f"Expected {env} to be blocked, got {res.status_code}"
        assert res.json()["error"]["code"] == "DEV_ENDPOINT_DISABLED"

        # Also verify POST /api/v1/auth/login is blocked
        res_post = client.post(
            "/api/v1/auth/login",
            json={"email": "hacker@evil.com", "role": "CUSTOMER"},
        )
        assert res_post.status_code == 403
        assert res_post.json()["error"]["code"] == "DEV_ENDPOINT_DISABLED"

