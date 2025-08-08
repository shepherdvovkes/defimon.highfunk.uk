from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta

from database import get_db, get_clickhouse_client
from models import Protocol, ProtocolData

router = APIRouter()

@router.get("/overview")
async def get_market_overview(db: Session = Depends(get_db)):
    """Get overall DeFi market overview"""
    
    # Get total TVL across all protocols
    total_tvl = db.query(func.sum(ProtocolData.total_value_locked)).filter(
        ProtocolData.timestamp >= datetime.utcnow() - timedelta(hours=1)
    ).scalar() or 0
    
    # Get top protocols by TVL
    top_protocols = db.query(
        Protocol.name,
        Protocol.display_name,
        ProtocolData.total_value_locked,
        ProtocolData.volume_24h
    ).join(ProtocolData, Protocol.id == ProtocolData.protocol_id).filter(
        ProtocolData.timestamp >= datetime.utcnow() - timedelta(hours=1)
    ).order_by(ProtocolData.total_value_locked.desc()).limit(10).all()
    
    return {
        "total_tvl": total_tvl,
        "top_protocols": [
            {
                "name": p.name,
                "display_name": p.display_name,
                "tvl": p.total_value_locked,
                "volume_24h": p.volume_24h
            } for p in top_protocols
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/trends")
async def get_market_trends(
    timeframe: str = Query("7d", regex="^(1d|7d|30d)$"),
    db: Session = Depends(get_db)
):
    """Get market trends and insights"""
    
    # Calculate time range
    now = datetime.utcnow()
    if timeframe == "1d":
        start_time = now - timedelta(days=1)
    elif timeframe == "7d":
        start_time = now - timedelta(days=7)
    else:  # 30d
        start_time = now - timedelta(days=30)
    
    # Get TVL trends
    tvl_trends = db.query(
        func.date_trunc('day', ProtocolData.timestamp).label('date'),
        func.avg(ProtocolData.total_value_locked).label('avg_tvl'),
        func.sum(ProtocolData.volume_24h).label('total_volume')
    ).filter(
        ProtocolData.timestamp >= start_time
    ).group_by(
        func.date_trunc('day', ProtocolData.timestamp)
    ).order_by(
        func.date_trunc('day', ProtocolData.timestamp)
    ).all()
    
    # Get category breakdown
    category_breakdown = db.query(
        Protocol.category,
        func.sum(ProtocolData.total_value_locked).label('total_tvl'),
        func.count(Protocol.id.distinct()).label('protocol_count')
    ).join(ProtocolData, Protocol.id == ProtocolData.protocol_id).filter(
        ProtocolData.timestamp >= start_time
    ).group_by(Protocol.category).all()
    
    return {
        "timeframe": timeframe,
        "tvl_trends": [
            {
                "date": trend.date.isoformat(),
                "avg_tvl": trend.avg_tvl,
                "total_volume": trend.total_volume
            } for trend in tvl_trends
        ],
        "category_breakdown": [
            {
                "category": breakdown.category,
                "total_tvl": breakdown.total_tvl,
                "protocol_count": breakdown.protocol_count
            } for breakdown in category_breakdown
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/comparison")
async def compare_protocols(
    protocols: List[str] = Query(...),
    metric: str = Query("tvl", regex="^(tvl|volume|fees|users)$"),
    timeframe: str = Query("7d", regex="^(1d|7d|30d)$"),
    db: Session = Depends(get_db)
):
    """Compare multiple protocols"""
    
    if len(protocols) > 10:
        raise HTTPException(status_code=400, detail="Maximum 10 protocols allowed for comparison")
    
    # Calculate time range
    now = datetime.utcnow()
    if timeframe == "1d":
        start_time = now - timedelta(days=1)
    elif timeframe == "7d":
        start_time = now - timedelta(days=7)
    else:  # 30d
        start_time = now - timedelta(days=30)
    
    comparison_data = []
    
    for protocol_name in protocols:
        protocol = db.query(Protocol).filter(Protocol.name == protocol_name).first()
        if not protocol:
            continue
        
        # Get latest data
        latest_data = db.query(ProtocolData).filter(
            ProtocolData.protocol_id == protocol.id,
            ProtocolData.timestamp >= start_time
        ).order_by(ProtocolData.timestamp.desc()).first()
        
        if latest_data:
            metric_value = getattr(latest_data, f"{metric}_24h" if metric != "tvl" else "total_value_locked")
            comparison_data.append({
                "protocol": protocol_name,
                "display_name": protocol.display_name,
                "category": protocol.category,
                "metric_value": metric_value,
                "last_updated": latest_data.timestamp.isoformat()
            })
    
    return {
        "metric": metric,
        "timeframe": timeframe,
        "comparison": comparison_data,
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/performance")
async def get_performance_metrics(
    db: Session = Depends(get_db),
    limit: int = Query(20, le=50)
):
    """Get performance metrics for top protocols"""
    
    # Get protocols with best performance (highest TVL growth)
    performance_data = db.query(
        Protocol.name,
        Protocol.display_name,
        Protocol.category,
        func.max(ProtocolData.total_value_locked).label('current_tvl'),
        func.min(ProtocolData.total_value_locked).label('min_tvl'),
        func.avg(ProtocolData.volume_24h).label('avg_volume'),
        func.avg(ProtocolData.fees_24h).label('avg_fees')
    ).join(ProtocolData, Protocol.id == ProtocolData.protocol_id).filter(
        ProtocolData.timestamp >= datetime.utcnow() - timedelta(days=7)
    ).group_by(
        Protocol.id, Protocol.name, Protocol.display_name, Protocol.category
    ).order_by(
        func.max(ProtocolData.total_value_locked).desc()
    ).limit(limit).all()
    
    return {
        "performance_metrics": [
            {
                "protocol": p.name,
                "display_name": p.display_name,
                "category": p.category,
                "current_tvl": p.current_tvl,
                "tvl_growth": ((p.current_tvl - p.min_tvl) / p.min_tvl * 100) if p.min_tvl and p.min_tvl > 0 else 0,
                "avg_volume": p.avg_volume,
                "avg_fees": p.avg_fees
            } for p in performance_data
        ],
        "timestamp": datetime.utcnow().isoformat()
    }

@router.get("/real-time")
async def get_real_time_data():
    """Get real-time data from ClickHouse"""
    
    clickhouse_client = get_clickhouse_client()
    if not clickhouse_client:
        raise HTTPException(status_code=503, detail="ClickHouse not available")
    
    try:
        # Get real-time protocol metrics
        query = """
        SELECT 
            protocol_name,
            avg(tvl_usd) as current_tvl,
            sum(volume_24h_usd) as total_volume,
            max(timestamp) as last_update
        FROM protocol_metrics 
        WHERE timestamp >= now() - INTERVAL 1 HOUR
        GROUP BY protocol_name
        ORDER BY current_tvl DESC
        LIMIT 20
        """
        
        result = clickhouse_client.query(query)
        
        real_time_data = []
        for row in result.result_rows:
            real_time_data.append({
                "protocol": row[0],
                "current_tvl": row[1],
                "total_volume": row[2],
                "last_update": row[3].isoformat() if row[3] else None
            })
        
        return {
            "real_time_data": real_time_data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error querying ClickHouse: {str(e)}")
