#!/usr/bin/env python3
"""
L2 Analytics API Server

FastAPI server providing endpoints for L2 analytics data collection
and retrieval for investor metrics.
"""

import asyncio
import logging
import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import FastAPI, HTTPException, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import uvicorn

# Import our data collectors
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data_collection.tvl_collector import TVLCollector, TVLData, TVLGrowthMetrics
from data_collection.user_activity_collector import UserActivityCollector, UserActivityData, UserRetentionMetrics
from data_collection.gas_savings_collector import GasSavingsCollector, GasPriceData, GasSavingsData

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="DEFIMON L2 Analytics",
    description="Comprehensive analytics API for L2 protocols - investor metrics",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="../dashboards"), name="static")

# Pydantic models for API responses
class TVLResponse(BaseModel):
    protocol: str
    chain: str
    tvl: float
    currency: str
    timestamp: str
    source: str

class TVLGrowthResponse(BaseModel):
    protocol: str
    current_tvl: float
    previous_tvl: float
    growth_rate: float
    compound_growth_rate: float
    absolute_change: float
    period_days: int
    timestamp: str

class UserActivityResponse(BaseModel):
    protocol: str
    chain: str
    date: str
    dau: int
    wau: int
    mau: int
    new_users: int
    returning_users: int
    total_transactions: int
    timestamp: str

class GasSavingsResponse(BaseModel):
    l2_protocol: str
    l1_gas_price_gwei: float
    l2_gas_price_gwei: float
    l1_gas_price_usd: float
    l2_gas_price_usd: float
    savings_percentage: float
    savings_usd: float
    timestamp: str

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str
    services: Dict[str, str]

class ErrorResponse(BaseModel):
    error: str
    message: str
    timestamp: str

# Global data storage (in production, use a proper database)
tvl_cache = {}
user_activity_cache = {}
gas_savings_cache = {}

@app.get("/", response_class=HTMLResponse)
async def root():
    """Root endpoint - shows the main dashboard"""
    dashboard_path = os.path.join(os.path.dirname(__file__), "../dashboards/defimon-dashboard.html")
    if os.path.exists(dashboard_path):
        with open(dashboard_path, 'r', encoding='utf-8') as f:
            return HTMLResponse(content=f.read())
    else:
        return HTMLResponse(content="""
        <html>
        <head><title>DEFIMON L2 Analytics</title></head>
        <body>
            <h1>DEFIMON L2 Analytics</h1>
            <p>Dashboard not found. Please check the installation.</p>
            <p><a href="/docs">API Documentation</a></p>
        </body>
        </html>
        """)

@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard():
    """Dashboard endpoint"""
    return await root()

@app.get("/api", response_model=Dict[str, str])
async def api_info():
    """API information endpoint"""
    return {
        "message": "DEFIMON L2 Analytics API",
        "version": "1.0.0",
        "description": "Comprehensive analytics for L2 protocols",
        "docs": "/docs",
        "health": "/health",
        "dashboard": "/"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        version="1.0.0",
        services={
            "tvl_collector": "available",
            "user_activity_collector": "available",
            "gas_savings_collector": "available"
        }
    )

# TVL Endpoints
@app.get("/api/l2-analytics/tvl-growth", response_model=List[TVLResponse])
async def get_tvl_growth(
    protocol: Optional[str] = Query(None, description="Specific protocol to filter"),
    days: int = Query(30, description="Number of days for growth calculation")
):
    """Get TVL growth data for all protocols or a specific protocol"""
    try:
        async with TVLCollector() as collector:
            # Collect current TVL data
            current_tvl = await collector.collect_all_tvl()
            
            if not current_tvl:
                raise HTTPException(status_code=500, detail="Failed to collect TVL data")
            
            # Filter by protocol if specified
            if protocol:
                current_tvl = [data for data in current_tvl if data.protocol == protocol]
            
            # Convert to response format
            response_data = []
            for data in current_tvl:
                response_data.append(TVLResponse(
                    protocol=data.protocol,
                    chain=data.chain,
                    tvl=data.tvl,
                    currency=data.currency,
                    timestamp=data.timestamp.isoformat(),
                    source=data.source
                ))
            
            return response_data
            
    except Exception as e:
        logger.error(f"Error in TVL growth endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/l2-analytics/tvl-growth/{protocol}", response_model=TVLGrowthResponse)
async def get_tvl_growth_for_protocol(
    protocol: str,
    days: int = Query(30, description="Number of days for growth calculation")
):
    """Get TVL growth metrics for a specific protocol"""
    try:
        async with TVLCollector() as collector:
            # Collect current TVL data
            current_tvl = await collector.collect_all_tvl()
            
            if not current_tvl:
                raise HTTPException(status_code=500, detail="Failed to collect TVL data")
            
            # Find data for specific protocol
            protocol_data = [data for data in current_tvl if data.protocol == protocol]
            if not protocol_data:
                raise HTTPException(status_code=404, detail=f"Protocol {protocol} not found")
            
            current_data = protocol_data[0]
            
            # Load historical data
            historical_data = await collector.load_historical_data("tvl_data_historical.json")
            
            if historical_data:
                # Calculate growth metrics
                growth_metrics = collector.calculate_growth_metrics(
                    [current_data], historical_data, period_days=days
                )
                
                if growth_metrics:
                    metric = growth_metrics[0]
                    return TVLGrowthResponse(
                        protocol=metric.protocol,
                        current_tvl=metric.current_tvl,
                        previous_tvl=metric.previous_tvl,
                        growth_rate=metric.growth_rate,
                        compound_growth_rate=metric.compound_growth_rate,
                        absolute_change=metric.absolute_change,
                        period_days=metric.period_days,
                        timestamp=metric.timestamp.isoformat()
                    )
            
            # Return basic data if no historical data available
            return TVLGrowthResponse(
                protocol=current_data.protocol,
                current_tvl=current_data.tvl,
                previous_tvl=0,
                growth_rate=0,
                compound_growth_rate=0,
                absolute_change=0,
                period_days=days,
                timestamp=current_data.timestamp.isoformat()
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in TVL growth for protocol endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# User Activity Endpoints
@app.get("/api/l2-analytics/daily-active-users", response_model=List[UserActivityResponse])
async def get_daily_active_users(
    protocol: Optional[str] = Query(None, description="Specific protocol to filter"),
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format")
):
    """Get daily active users data for all protocols or a specific protocol"""
    try:
        async with UserActivityCollector() as collector:
            # Collect activity data
            activity_data = await collector.collect_all_protocols_activity(date)
            
            if not activity_data:
                raise HTTPException(status_code=500, detail="Failed to collect user activity data")
            
            # Filter by protocol if specified
            if protocol:
                activity_data = [data for data in activity_data if data.protocol == protocol]
            
            # Convert to response format
            response_data = []
            for data in activity_data:
                response_data.append(UserActivityResponse(
                    protocol=data.protocol,
                    chain=data.chain,
                    date=data.date,
                    dau=data.dau,
                    wau=data.wau,
                    mau=data.mau,
                    new_users=data.new_users,
                    returning_users=data.returning_users,
                    total_transactions=data.total_transactions,
                    timestamp=data.timestamp.isoformat()
                ))
            
            return response_data
            
    except Exception as e:
        logger.error(f"Error in daily active users endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/l2-analytics/user-retention", response_model=List[Dict[str, Any]])
async def get_user_retention(
    protocol: Optional[str] = Query(None, description="Specific protocol to filter")
):
    """Get user retention metrics"""
    try:
        async with UserActivityCollector() as collector:
            # Collect current activity data
            current_activity = await collector.collect_all_protocols_activity()
            
            if not current_activity:
                raise HTTPException(status_code=500, detail="Failed to collect user activity data")
            
            # Load historical data
            historical_data = await collector.load_historical_activity("user_activity_historical.json")
            
            retention_metrics = []
            for activity in current_activity:
                if protocol and activity.protocol != protocol:
                    continue
                
                metrics = collector.calculate_retention_metrics(activity, historical_data)
                if metrics:
                    retention_metrics.append({
                        "protocol": metrics.protocol,
                        "date": metrics.date,
                        "retention_1d": metrics.retention_1d,
                        "retention_7d": metrics.retention_7d,
                        "retention_30d": metrics.retention_30d,
                        "churn_rate": metrics.churn_rate,
                        "user_growth_rate": metrics.user_growth_rate,
                        "timestamp": metrics.timestamp.isoformat()
                    })
            
            return retention_metrics
            
    except Exception as e:
        logger.error(f"Error in user retention endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Gas Savings Endpoints
@app.get("/api/l2-analytics/gas-savings", response_model=List[GasSavingsResponse])
async def get_gas_savings(
    protocol: Optional[str] = Query(None, description="Specific L2 protocol to filter")
):
    """Get gas savings comparison between L1 and L2 protocols"""
    try:
        async with GasSavingsCollector() as collector:
            # Collect gas price data
            gas_data = await collector.collect_gas_prices()
            
            if not gas_data:
                raise HTTPException(status_code=500, detail="Failed to collect gas price data")
            
            # Calculate gas savings
            savings_data = collector.calculate_gas_savings(gas_data)
            
            if not savings_data:
                raise HTTPException(status_code=500, detail="Failed to calculate gas savings")
            
            # Filter by protocol if specified
            if protocol:
                savings_data = [data for data in savings_data if data.l2_protocol == protocol]
            
            # Convert to response format
            response_data = []
            for data in savings_data:
                response_data.append(GasSavingsResponse(
                    l2_protocol=data.l2_protocol,
                    l1_gas_price_gwei=data.l1_gas_price_gwei,
                    l2_gas_price_gwei=data.l2_gas_price_gwei,
                    l1_gas_price_usd=data.l1_gas_price_usd,
                    l2_gas_price_usd=data.l2_gas_price_usd,
                    savings_percentage=data.savings_percentage,
                    savings_usd=data.savings_usd,
                    timestamp=data.timestamp.isoformat()
                ))
            
            return response_data
            
    except Exception as e:
        logger.error(f"Error in gas savings endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/l2-analytics/gas-savings/comparison", response_model=Dict[str, Any])
async def get_gas_savings_comparison():
    """Get comprehensive gas savings comparison with transaction costs"""
    try:
        async with GasSavingsCollector() as collector:
            # Collect gas price data
            gas_data = await collector.collect_gas_prices()
            
            if not gas_data:
                raise HTTPException(status_code=500, detail="Failed to collect gas price data")
            
            # Calculate gas savings
            savings_data = collector.calculate_gas_savings(gas_data)
            
            # Calculate transaction costs
            transaction_costs = collector.calculate_transaction_costs(gas_data)
            
            # Organize data by protocol
            comparison_data = {}
            for savings in savings_data:
                protocol = savings.l2_protocol
                comparison_data[protocol] = {
                    "gas_savings": {
                        "savings_percentage": savings.savings_percentage,
                        "savings_usd": savings.savings_usd,
                        "l1_gas_price_gwei": savings.l1_gas_price_gwei,
                        "l2_gas_price_gwei": savings.l2_gas_price_gwei
                    },
                    "transaction_costs": {}
                }
                
                # Add transaction costs for this protocol
                for cost in transaction_costs:
                    if cost.protocol == protocol:
                        comparison_data[protocol]["transaction_costs"][cost.transaction_type] = {
                            "gas_used": cost.gas_used,
                            "total_cost_usd": cost.total_cost_usd
                        }
            
            return comparison_data
            
    except Exception as e:
        logger.error(f"Error in gas savings comparison endpoint: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Background task for data collection
async def collect_all_metrics():
    """Background task to collect all metrics"""
    try:
        logger.info("Starting background metrics collection...")
        
        # Collect TVL data
        async with TVLCollector() as tvl_collector:
            tvl_data = await tvl_collector.collect_all_tvl()
            if tvl_data:
                await tvl_collector.save_tvl_data(tvl_data)
                tvl_cache.update({data.protocol: data for data in tvl_data})
        
        # Collect user activity data
        async with UserActivityCollector() as activity_collector:
            activity_data = await activity_collector.collect_all_protocols_activity()
            if activity_data:
                await activity_collector.save_activity_data(activity_data)
                user_activity_cache.update({data.protocol: data for data in activity_data})
        
        # Collect gas savings data
        async with GasSavingsCollector() as gas_collector:
            gas_data = await gas_collector.collect_gas_prices()
            if gas_data:
                await gas_collector.save_gas_data(gas_data)
                savings_data = gas_collector.calculate_gas_savings(gas_data)
                if savings_data:
                    await gas_collector.save_savings_data(savings_data)
                    gas_savings_cache.update({data.l2_protocol: data for data in savings_data})
        
        logger.info("Background metrics collection completed")
        
    except Exception as e:
        logger.error(f"Error in background metrics collection: {e}")

@app.post("/api/l2-analytics/collect", response_model=Dict[str, str])
async def trigger_data_collection(background_tasks: BackgroundTasks):
    """Trigger data collection for all metrics"""
    try:
        background_tasks.add_task(collect_all_metrics)
        return {
            "message": "Data collection started",
            "status": "processing",
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Error triggering data collection: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error=exc.detail,
            message="An error occurred while processing your request",
            timestamp=datetime.now().isoformat()
        ).dict()
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content=ErrorResponse(
            error="Internal server error",
            message="An unexpected error occurred",
            timestamp=datetime.now().isoformat()
        ).dict()
    )

if __name__ == "__main__":
    # Run the server
    uvicorn.run(
        "l2_analytics_api:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
