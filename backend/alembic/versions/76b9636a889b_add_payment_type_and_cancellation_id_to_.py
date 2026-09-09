"""add payment_type and cancellation_id to payments

Revision ID: 76b9636a889b
Revises: e29d3f46feb9
Create Date: 2026-09-09 23:34:35.781940

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '76b9636a889b'
down_revision: Union[str, None] = 'e29d3f46feb9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Use batch_alter_table for SQLite compatibility (used in migration tests)
    with op.batch_alter_table('payments', schema=None) as batch_op:
        batch_op.add_column(
            sa.Column(
                'payment_type',
                sa.Enum('LABOUR', 'CANCELLATION', name='paymenttype', native_enum=False, create_constraint=True, length=30),
                nullable=False,
                server_default='LABOUR',
            )
        )
        batch_op.add_column(sa.Column('cancellation_id', sa.Uuid(), nullable=True))
        batch_op.create_index(batch_op.f('ix_payments_payment_type'), ['payment_type'], unique=False)
        batch_op.create_unique_constraint('uq_payments_cancellation_id', ['cancellation_id'])
        batch_op.create_foreign_key('fk_payments_cancellation_id', 'gig_cancellations', ['cancellation_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    with op.batch_alter_table('payments', schema=None) as batch_op:
        batch_op.drop_constraint('fk_payments_cancellation_id', type_='foreignkey')
        batch_op.drop_constraint('uq_payments_cancellation_id', type_='unique')
        batch_op.drop_index(batch_op.f('ix_payments_payment_type'))
        batch_op.drop_column('cancellation_id')
        batch_op.drop_column('payment_type')
