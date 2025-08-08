from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import asyncio
import redis
import json
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(
    title="DeFi AI/ML Service",
    description="AI/ML service for DeFi predictions and risk assessment",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import models and services
from models.price_predictor import PricePredictionModel
from models.risk_scorer import RiskScoringModel
from services.ml_service import AIMLService

# Initialize services
ml_service = AIMLService()

class PredictionRequest(BaseModel):
    protocol: str
    token_address: str = ""
    prediction_type: str  # "price" or "risk"
    timeframe: str = "short_term"

class RiskAssessmentRequest(BaseModel):
    protocol: str
    include_detailed: bool = False

@app.get("/")
async def root():
    """Root endpoint with service information"""
    return {
        "name": "DeFi AI/ML Service",
        "version": "1.0.0",
        "description": "AI/ML service for DeFi predictions and risk assessment",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "ai-ml-service",
        "timestamp": "2024-01-01T00:00:00Z"
    }

@app.post("/predict")
async def get_prediction(request: PredictionRequest):
    """Get AI prediction for protocol/token"""
    try:
        if request.prediction_type == "price":
            result = await ml_service.get_price_prediction(
                request.protocol, 
                request.token_address, 
                request.timeframe
            )
        elif request.prediction_type == "risk":
            result = await ml_service.get_risk_assessment(request.protocol)
        else:
            raise HTTPException(status_code=400, detail="Invalid prediction type")
        
        return {"success": True, "data": result}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/risk-assessment")
async def get_risk_assessment(request: RiskAssessmentRequest):
    """Get comprehensive risk assessment for a protocol"""
    try:
        result = await ml_service.get_risk_assessment(
            request.protocol, 
            include_detailed=request.include_detailed
        )
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/models/status")
async def get_model_status():
    """Get status of all ML models"""
    try:
        status = ml_service.get_model_status()
        return {"success": True, "data": status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/models/retrain")
async def retrain_models():
    """Trigger model retraining"""
    try:
        # This would typically be an async task
        result = await ml_service.retrain_models()
        return {"success": True, "message": "Model retraining started", "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    from fastapi.responses import Response
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
