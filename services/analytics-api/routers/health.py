from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db, get_redis_client, get_clickhouse_client
import httpx
import os

router = APIRouter()

@router.get("/")
async def health_check():
    """Basic health check endpoint"""
    return {
        "status": "healthy",
        "service": "analytics-api",
        "timestamp": "2024-01-01T00:00:00Z"
    }

@router.get("/detailed")
async def detailed_health_check(db: Session = Depends(get_db)):
    """Detailed health check with database connectivity"""
    health_status = {
        "status": "healthy",
        "service": "analytics-api",
        "timestamp": "2024-01-01T00:00:00Z",
        "dependencies": {}
    }
    
    # Check PostgreSQL
    try:
        db.execute("SELECT 1")
        health_status["dependencies"]["postgresql"] = "healthy"
    except Exception as e:
        health_status["dependencies"]["postgresql"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check Redis
    try:
        redis_client = get_redis_client()
        if redis_client:
            redis_client.ping()
            health_status["dependencies"]["redis"] = "healthy"
        else:
            health_status["dependencies"]["redis"] = "unhealthy: connection failed"
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["dependencies"]["redis"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check ClickHouse
    try:
        clickhouse_client = get_clickhouse_client()
        if clickhouse_client:
            clickhouse_client.command("SELECT 1")
            health_status["dependencies"]["clickhouse"] = "healthy"
        else:
            health_status["dependencies"]["clickhouse"] = "unhealthy: connection failed"
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["dependencies"]["clickhouse"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    # Check ML Service
    try:
        ml_service_url = os.getenv("AI_ML_SERVICE_URL", "http://ai-ml-service:8001")
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{ml_service_url}/health", timeout=5.0)
            if response.status_code == 200:
                health_status["dependencies"]["ml_service"] = "healthy"
            else:
                health_status["dependencies"]["ml_service"] = f"unhealthy: status {response.status_code}"
                health_status["status"] = "degraded"
    except Exception as e:
        health_status["dependencies"]["ml_service"] = f"unhealthy: {str(e)}"
        health_status["status"] = "degraded"
    
    return health_status

@router.get("/ready")
async def readiness_check():
    """Kubernetes readiness probe endpoint"""
    return {"status": "ready"}

@router.get("/live")
async def liveness_check():
    """Kubernetes liveness probe endpoint"""
    return {"status": "alive"}
