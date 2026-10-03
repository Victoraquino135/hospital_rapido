from pathlib import Path
from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, sessionmaker
import os
from app.core.config import ROOT

DATABASE_URL = os.getenv('DATABASE_URL') or f"sqlite:///{ROOT / 'ubs_rapida.db'}"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

@event.listens_for(engine, 'connect')
def sqlite_foreign_keys(connection, _):
    connection.execute('PRAGMA foreign_keys=ON')
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

class Base(DeclarativeBase):
    pass

def get_db():
    db = SessionLocal()
    try: yield db
    finally: db.close()
