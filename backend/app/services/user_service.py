import uuid
from typing import Optional
from sqlalchemy.orm import Session

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.db.models.cooperative import Cooperative
from app.db.models.user import User, CustomerProfile, WorkerProfile, WorkerMetric
from app.db.models.enums import UserRole
from app.schemas.user import (
    UserInitializeRequest,
    CustomerProfileResponse,
    CustomerProfileUpdateRequest,
)
from app.core.exceptions import ForbiddenException
from app.services.score_service import get_rookie_initial_metrics

DEFAULT_COOPERATIVE_NAME = "Bangalore Artisans Labour Cooperative Society"


def get_or_create_default_cooperative(db: Session) -> Cooperative:
    """Retrieve the primary active cooperative or create the baseline cooperative uniquely."""
    coop = db.query(Cooperative).filter(Cooperative.name == DEFAULT_COOPERATIVE_NAME).first()
    if not coop:
        coop = db.query(Cooperative).filter(Cooperative.is_active == True).first()
    if not coop:
        coop = Cooperative(
            name=DEFAULT_COOPERATIVE_NAME,
            city="Bangalore",
            service_area="Bangalore Urban",
            is_active=True,
        )
        db.add(coop)
        db.commit()
        db.refresh(coop)
    return coop


class UserService:
    @staticmethod
    def initialize_user(
        db: Session,
        user_id: uuid.UUID,
        email: Optional[str],
        data: UserInitializeRequest,
    ) -> User:
        """Create or initialize application-level user and role-specific profile."""
        existing_user = db.query(User).filter(User.id == user_id).first()
        if existing_user:
            # Reject deactivated/inactive users
            if not existing_user.is_active:
                raise ForbiddenException(
                    message="User account is deactivated or inactive",
                    code="USER_INACTIVE",
                )

            # One-role enforcement per 05_API_DESIGN.md Section 6
            if existing_user.role != data.role:
                raise ConflictException(
                    message=f"User already registered with role '{existing_user.role.value}'. Role changes are not permitted.",
                    code="ROLE_IMMUTABLE",
                    details={
                        "existing_role": existing_user.role.value,
                        "requested_role": data.role.value,
                    },
                )
            # Update editable core details if provided
            if data.full_name:
                existing_user.full_name = data.full_name
            if data.phone:
                existing_user.phone = data.phone
            db.commit()
            db.refresh(existing_user)
            return existing_user

        # Resolve cooperative
        if data.cooperative_id:
            coop = db.query(Cooperative).filter(
                Cooperative.id == data.cooperative_id,
                Cooperative.is_active == True,
            ).first()
            if not coop:
                raise NotFoundException(
                    message="Specified cooperative was not found or is inactive",
                    code="COOPERATIVE_NOT_FOUND",
                )
        else:
            coop = get_or_create_default_cooperative(db)

        # Create application user
        new_user = User(
            id=user_id,
            role=data.role,
            cooperative_id=coop.id,
            full_name=data.full_name,
            phone=data.phone,
            email=email,
            is_active=True,
        )
        db.add(new_user)
        db.flush()

        # Create role-specific profiles
        if data.role == UserRole.CUSTOMER:
            customer_profile = CustomerProfile(user_id=new_user.id)
            db.add(customer_profile)
        elif data.role == UserRole.WORKER:
            worker_profile = WorkerProfile(user_id=new_user.id, is_active=True)
            db.add(worker_profile)
            db.flush()

            # Baseline metrics for rookie/new worker (centralized from score_service)
            worker_metric = WorkerMetric(
                worker_id=new_user.id,
                **get_rookie_initial_metrics(),
            )
            db.add(worker_metric)

        db.commit()
        db.refresh(new_user)
        return new_user

    @staticmethod
    def get_customer_profile(db: Session, user: User) -> CustomerProfileResponse:
        """Fetch customer profile data."""
        profile = (
            db.query(CustomerProfile)
            .filter(CustomerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = CustomerProfile(user_id=user.id)
            db.add(profile)
            db.commit()
            db.refresh(profile)

        return CustomerProfileResponse(
            user_id=user.id,
            full_name=user.full_name,
            phone=user.phone,
            email=user.email,
            profile_photo_url=user.profile_photo_url,
            address=profile.address,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )

    @staticmethod
    def update_customer_profile(
        db: Session,
        user: User,
        data: CustomerProfileUpdateRequest,
    ) -> CustomerProfileResponse:
        """Update customer profile information."""
        profile = (
            db.query(CustomerProfile)
            .filter(CustomerProfile.user_id == user.id)
            .first()
        )
        if not profile:
            profile = CustomerProfile(user_id=user.id)
            db.add(profile)

        if data.full_name is not None:
            user.full_name = data.full_name
        if data.phone is not None:
            user.phone = data.phone
        if data.profile_photo_url is not None:
            user.profile_photo_url = data.profile_photo_url
        if data.address is not None:
            profile.address = data.address

        db.commit()
        db.refresh(user)
        db.refresh(profile)

        return CustomerProfileResponse(
            user_id=user.id,
            full_name=user.full_name,
            phone=user.phone,
            email=user.email,
            profile_photo_url=user.profile_photo_url,
            address=profile.address,
            created_at=profile.created_at,
            updated_at=profile.updated_at,
        )
