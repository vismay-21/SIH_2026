import sys
import os

from sqlalchemy import text
from app.db.session import SessionLocal

def flush_all_gigs():
    print("=" * 60)
    print("Starting clean flush of all gig and transaction data...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Child to parent order to satisfy all foreign key constraints
        tables = [
            "review_answers",
            "reviews",
            "material_receipts",
            "payments",
            "completion_evidence",
            "completion_confirmations",
            "completion_submissions",
            "visitation_proposal_tasks",
            "visitation_proposals",
            "reschedule_requests",
            "previous_worker_requests",
            "gig_cancellations",
            "worker_participations",
            "gig_worker_opportunities",
            "gig_tasks",
            "gig_events",
            "messages",
            "conversations",
            "notifications",
            "worker_experience_records",
            "gigs",
        ]
        
        total_deleted = 0
        for table in tables:
            try:
                res = db.execute(text(f"DELETE FROM {table}"))
                cnt = res.rowcount if res.rowcount is not None and res.rowcount >= 0 else 0
                total_deleted += cnt
                print(f"  [x] Deleted from '{table}': {cnt} row(s)")
            except Exception as e:
                print(f"  [!] Error deleting from '{table}': {e}")
                db.rollback()
                raise e
        
        db.commit()
        print("=" * 60)
        print(f"SUCCESS: Flushed all gig data ({total_deleted} total rows deleted).")
        print("Customer profiles, worker profiles, and user accounts remain completely intact.")
        print("=" * 60)
    except Exception as e:
        db.rollback()
        print(f"FAILED during flush: {e}")
        raise e
    finally:
        db.close()

if __name__ == "__main__":
    flush_all_gigs()
