from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta
import httpx
import os

from database import get_db, get_redis_client
from models import Protocol, ProtocolData, RiskScore, Prediction

router = APIRouter()

@router.get("/")
async def get_protocols(
    db: Session = Depends(get_db),
    limit: int = Query(50, le=100),
    offset: int = Query(0, ge=0),
    category: Optional[str] = Query(None),
    chain: Optional[str] = Query(None)
):
    """Get list of tracked DeFi protocols"""
    query = db.query(Protocol)
    
    if category:
        query = query.filter(Protocol.category == category)
    if chain:
        query = query.filter(Protocol.chain == chain)
    
    protocols = query.offset(offset).limit(limit).all()
    
    return {
        "protocols": [
            {
                "id": p.id,
                "name": p.name,
                "display_name": p.display_name,
                "category": p.category,
                "chain": p.chain,
                "contract_address": p.contract_address,
                "logo_url": p.logo_url,
                "website_url": p.website_url,
                "audit_status": p.audit_status,
                "audit_firm": p.audit_firm,
                "launch_date": p.launch_date.isoformat() if p.launch_date else None
            } for p in protocols
        ],
        "total": query.count(),
        "limit": limit,
        "offset": offset
    }

@router.get("/{protocol_name}/metrics")
async def get_protocol_metrics(
    protocol_name: str,
    timeframe: str = Query("24h", regex="^(1h|24h|7d|30d)$"),
    db: Session = Depends(get_db)
):
    """Get metrics for a specific protocol"""
    
    # Get protocol
    protocol = db.query(Protocol).filter(Protocol.name == protocol_name).first()
    if not protocol:
        raise HTTPException(status_code=404, detail="Protocol not found")
    
    # Calculate time range
    now = datetime.utcnow()
    if timeframe == "1h":
        start_time = now - timedelta(hours=1)
    elif timeframe == "24h":
        start_time = now - timedelta(days=1)
    elif timeframe == "7d":
        start_time = now - timedelta(days=7)
    else:  # 30d
        start_time = now - timedelta(days=30)
    
    # Query data
    data = db.query(ProtocolData).filter(
        ProtocolData.protocol_id == protocol.id,
        ProtocolData.timestamp >= start_time
    ).order_by(ProtocolData.timestamp).all()
    
    if not data:
        raise HTTPException(status_code=404, detail="No data found for protocol")
    
    # Calculate metrics
    latest = data[-1]
    oldest = data[0]
    
    tvl_change = ((latest.total_value_locked - oldest.total_value_locked) / oldest.total_value_locked * 100) if oldest.total_value_locked and oldest.total_value_locked > 0 else 0
    volume_24h = latest.volume_24h
    fees_24h = latest.fees_24h
    
    return {
        "protocol": protocol_name,
        "timeframe": timeframe,
        "current_tvl": latest.total_value_locked,
        "tvl_change_percent": tvl_change,
        "volume_24h": volume_24h,
        "fees_24h": fees_24h,
        "users_24h": latest.users_24h,
        "token_price": latest.token_price,
        "market_cap": latest.market_cap,
        "last_updated": latest.timestamp.isoformat()
    }

@router.get("/{protocol_name}/risk")
async def get_protocol_risk(
    protocol_name: str,
    db: Session = Depends(get_db)
):
    """Get risk assessment for a protocol"""
    
    # Get protocol
    protocol = db.query(Protocol).filter(Protocol.name == protocol_name).first()
    if not protocol:
        raise HTTPException(status_code=404, detail="Protocol not found")
    
    # Get latest risk score
    risk_data = db.query(RiskScore).filter(
        RiskScore.protocol_id == protocol.id
    ).order_by(RiskScore.timestamp.desc()).first()
    
    if not risk_data:
        raise HTTPException(status_code=404, detail="Risk data not found")
    
    return {
        "protocol": protocol_name,
        "overall_risk_score": risk_data.overall_risk,
        "risk_level": "Low" if risk_data.overall_risk < 0.3 else "Medium" if risk_data.overall_risk < 0.7 else "High",
        "risk_breakdown": {
            "smart_contract_risk": risk_data.smart_contract_risk,
            "liquidity_risk": risk_data.liquidity_risk,
            "market_risk": risk_data.market_risk,
            "governance_risk": risk_data.governance_risk,
            "counterparty_risk": risk_data.counterparty_risk
        },
        "risk_factors": risk_data.risk_factors,
        "last_updated": risk_data.timestamp.isoformat()
    }

@router.get("/{protocol_name}/predictions")
async def get_price_predictions(
    protocol_name: str,
    timeframes: List[str] = Query(["1h", "24h", "7d"])
):
    """Get AI price predictions for a protocol"""
    
    predictions = {}
    
    for timeframe in timeframes:
        try:
            # Call AI/ML service
            prediction = await call_ml_service(
                protocol_name, 
                "price_prediction", 
                timeframe
            )
            predictions[timeframe] = prediction
        except Exception as e:
            predictions[timeframe] = {"error": str(e)}
    
    return {
        "protocol": protocol_name,
        "predictions": predictions,
        "generated_at": datetime.utcnow().isoformat()
    }

@router.get("/{protocol_name}/historical")
async def get_protocol_historical(
    protocol_name: str,
    timeframe: str = Query("7d", regex="^(1d|7d|30d|90d)$"),
    db: Session = Depends(get_db)
):
    """Get historical data for a protocol"""
    
    # Get protocol
    protocol = db.query(Protocol).filter(Protocol.name == protocol_name).first()
    if not protocol:
        raise HTTPException(status_code=404, detail="Protocol not found")
    
    # Calculate time range
    now = datetime.utcnow()
    if timeframe == "1d":
        start_time = now - timedelta(days=1)
    elif timeframe == "7d":
        start_time = now - timedelta(days=7)
    elif timeframe == "30d":
        start_time = now - timedelta(days=30)
    else:  # 90d
        start_time = now - timedelta(days=90)
    
    # Query historical data
    data = db.query(ProtocolData).filter(
        ProtocolData.protocol_id == protocol.id,
        ProtocolData.timestamp >= start_time
    ).order_by(ProtocolData.timestamp).all()
    
    return {
        "protocol": protocol_name,
        "timeframe": timeframe,
        "data": [
            {
                "timestamp": d.timestamp.isoformat(),
                "tvl": d.total_value_locked,
                "volume_24h": d.volume_24h,
                "fees_24h": d.fees_24h,
                "users_24h": d.users_24h,
                "token_price": d.token_price,
                "market_cap": d.market_cap
            } for d in data
        ]
    }

async def call_ml_service(protocol: str, service_type: str, timeframe: str = None):
    """Call AI/ML microservice"""
    ml_service_url = os.getenv("AI_ML_SERVICE_URL", "http://ai-ml-service:8001")
    
    async with httpx.AsyncClient() as client:
        url = f"{ml_service_url}/predict"
        payload = {
            "protocol": protocol,
            "token_address": "",  # Will be resolved by ML service
            "prediction_type": service_type,
            "timeframe": timeframe
        }
        
        response = await client.post(url, json=payload, timeout=10.0)
        if response.status_code == 200:
            result = response.json()
            return result.get("data", {})
        else:
            raise HTTPException(status_code=500, detail="ML service error")
