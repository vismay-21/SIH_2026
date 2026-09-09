from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.exceptions import AppException
from app.db.session import check_db_connection


def test_health_endpoint(client: TestClient):
    """Verify GET /api/v1/health returns 200 OK with healthy status and database status."""
    response = client.get("/api/v1/health")
    assert response.status_code == status.HTTP_200_OK

    data = response.json()
    assert "data" in data
    health_data = data["data"]
    assert health_data["status"] == "ok"
    assert health_data["database"] == "connected"
    assert health_data["version"] == "0.1.0"
    assert "timestamp" in health_data


def test_root_endpoint(client: TestClient):
    """Verify GET / returns application information and discovery endpoints."""
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["name"] == "Sahakaar Seva API"
    assert data["version"] == "0.1.0"
    assert data["health"] == "/api/v1/health"
    assert data["docs"] == "/api/v1/docs"


def test_database_connection(db_session: Session):
    """Verify database connectivity directly using the session and engine."""
    assert check_db_connection() is True

    result = db_session.execute(text("SELECT 1")).scalar()
    assert result == 1


def test_custom_exception_handler(client: TestClient):
    """Verify custom AppException formats into 05_API_DESIGN.md error contract."""
    from app.main import app

    @app.get("/api/v1/test-error")
    def trigger_error():
        raise AppException(
            message="Test domain error occurred",
            code="TEST_DOMAIN_ERROR",
            status_code=status.HTTP_400_BAD_REQUEST,
            details={"sample_key": "sample_val"},
        )

    response = client.get("/api/v1/test-error")
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()

    assert "error" in data
    err = data["error"]
    assert err["code"] == "TEST_DOMAIN_ERROR"
    assert err["message"] == "Test domain error occurred"
    assert err["details"] == {"sample_key": "sample_val"}


def test_cors_headers(client: TestClient):
    """Verify CORS middleware headers are present."""
    response = client.options(
        "/api/v1/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert response.headers.get("access-control-allow-origin") == "http://localhost:3000"
    assert "GET" in response.headers.get("access-control-allow-methods", "")
