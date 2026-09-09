from fastapi import APIRouter
from app.api.v1.endpoints import (
    health,
    me,
    customer,
    worker,
    catalogue,
    gigs,
    participations,
    cancellation,
)

api_router = APIRouter()

# Health & System Status
api_router.include_router(health.router, tags=["Health"])

# Sprint 2: User & Identity
api_router.include_router(me.router, tags=["Current User & Auth"])

# Sprint 2: Profiles
api_router.include_router(customer.router, tags=["Customer Profile"])
api_router.include_router(worker.router, tags=["Worker Profile & Availability"])

# Sprint 3: Catalogue
api_router.include_router(catalogue.router, tags=["Service Catalogue"])

# Sprint 3: Pricing & Gigs
api_router.include_router(gigs.router, tags=["Pricing & Gigs"])

# Sprint 10: Multi-Worker Participations & Rookie Mentorship
api_router.include_router(participations.router, tags=["Multi-Worker Participations"])

# Sprint 11: Cancellation & Rescheduling
api_router.include_router(cancellation.router, tags=["Cancellation & Rescheduling"])


