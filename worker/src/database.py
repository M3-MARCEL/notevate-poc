import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

AZURE_SQL_SERVER = os.getenv("AZURE_SQL_SERVER", "localhost")
AZURE_SQL_DB = os.getenv("AZURE_SQL_DB", "notevate-db")
AZURE_SQL_USER = os.getenv("AZURE_SQL_USER", "sa")
AZURE_SQL_PASS = os.getenv("AZURE_SQL_PASS", "password")

DATABASE_URL = (
    f"mssql+pymssql://{AZURE_SQL_USER}:{AZURE_SQL_PASS}" f"@{AZURE_SQL_SERVER}/{AZURE_SQL_DB}"
)

engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
    pool_recycle=3600,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
