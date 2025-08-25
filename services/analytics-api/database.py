from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import os
from dotenv import load_dotenv

load_dotenv()

# Database configuration - use SQLite for testing
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    poolclass=StaticPool,
    pool_pre_ping=True,
    pool_recycle=300,
    echo=False,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
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

# Mock ClickHouse connection for testing
def get_clickhouse_client():
    """Get ClickHouse client - mocked for testing"""
    class MockClickHouseClient:
        def query(self, *args, **kwargs):
            return {"data": [], "rows": 0}
        
        def close(self):
            pass
    
    return MockClickHouseClient()

# Mock Redis connection for testing
def get_redis_client():
    """Get Redis client - mocked for testing"""
    class MockRedisClient:
        def get(self, key):
            return None
        
        def set(self, key, value, ex=None):
            return True
        
        def ping(self):
            return True
    
    return MockRedisClient()
