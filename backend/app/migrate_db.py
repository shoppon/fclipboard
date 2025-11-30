from sqlalchemy import text

from app.db import engine
from app.models import Base


def run():
    Base.metadata.create_all(bind=engine)
    with engine.begin() as conn:
        conn.execute(text("ALTER TABLE entries ADD COLUMN IF NOT EXISTS parameters JSONB DEFAULT '[]'::jsonb"))


if __name__ == "__main__":
    run()
