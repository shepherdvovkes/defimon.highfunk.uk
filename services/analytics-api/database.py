from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration
POSTGRES_URL = (
    os.getenv("POSTGRES_URL") or
    os.getenv("DATABASE_URL") or
    "postgresql://postgres:password@postgres:5432/defi_analytics"
)
CLICKHOUSE_URL = os.getenv("CLICKHOUSE_URL", "http://clickhouse:8123")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

# Create SQLAlchemy engine
engine = create_engine(
    POSTGRES_URL,
    poolclass=StaticPool,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=False
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class
Base = declarative_base()

def get_db():
    """Dependency to get database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ClickHouse connection
import clickhouse_connect

def get_clickhouse_client():
    """Get ClickHouse client"""
    try:
        client = clickhouse_connect.get_client(
            host=os.getenv("CLICKHOUSE_HOST", "clickhouse"),
            port=int(os.getenv("CLICKHOUSE_PORT", "8123")),
            username=os.getenv("CLICKHOUSE_USER", "default"),
            password=os.getenv("CLICKHOUSE_PASSWORD", "password"),
            database=os.getenv("CLICKHOUSE_DB", "analytics")
        )
        return client
    except Exception as e:
        print(f"Error connecting to ClickHouse: {e}")
        return None

# Redis connection
import redis

def get_redis_client():
    """Get Redis client"""
    try:
        client = redis.from_url(REDIS_URL)
        client.ping()  # Test connection
        return client
    except Exception as e:
        print(f"Error connecting to Redis: {e}")
        return None
