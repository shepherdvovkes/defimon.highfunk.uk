#!/usr/bin/env python3
"""
Simple L2 Analytics Server

A simplified FastAPI server that serves the DEFIMON dashboard
without complex data collection dependencies.
"""

import os
import json
from datetime import datetime
from typing import Dict, List, Optional, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import uvicorn

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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="dashboards"), name="static")

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str

class ErrorResponse(BaseModel):
    error: str
    message: str
    timestamp: str

# Mock data for demonstration
MOCK_TVL_DATA = {
    "arbitrum": {
        "protocol": "Arbitrum One",
        "chain": "arbitrum",
        "tvl": 2500000000.0,
        "currency": "USD",
        "growth_rate": 15.5,
        "timestamp": datetime.now().isoformat()
    },
    "optimism": {
        "protocol": "Optimism",
        "chain": "optimism", 
        "tvl": 1800000000.0,
        "currency": "USD",
        "growth_rate": 12.3,
        "timestamp": datetime.now().isoformat()
    },
    "polygon": {
        "protocol": "Polygon",
        "chain": "polygon",
        "tvl": 3200000000.0,
        "currency": "USD",
        "growth_rate": 8.7,
        "timestamp": datetime.now().isoformat()
    },
    "base": {
        "protocol": "Base",
        "chain": "base",
        "tvl": 950000000.0,
        "currency": "USD",
        "growth_rate": 45.2,
        "timestamp": datetime.now().isoformat()
    }
}

MOCK_USER_ACTIVITY = {
    "arbitrum": {
        "protocol": "Arbitrum One",
        "dau": 45000,
        "wau": 180000,
        "mau": 650000,
        "new_users": 2500,
        "returning_users": 42500,
        "total_transactions": 125000,
        "timestamp": datetime.now().isoformat()
    },
    "optimism": {
        "protocol": "Optimism",
        "dau": 32000,
        "wau": 125000,
        "mau": 480000,
        "new_users": 1800,
        "returning_users": 30200,
        "total_transactions": 89000,
        "timestamp": datetime.now().isoformat()
    },
    "polygon": {
        "protocol": "Polygon",
        "dau": 68000,
        "wau": 280000,
        "mau": 950000,
        "new_users": 4200,
        "returning_users": 63800,
        "total_transactions": 210000,
        "timestamp": datetime.now().isoformat()
    },
    "base": {
        "protocol": "Base",
        "dau": 15000,
        "wau": 65000,
        "mau": 220000,
        "new_users": 1200,
        "returning_users": 13800,
        "total_transactions": 45000,
        "timestamp": datetime.now().isoformat()
    }
}

MOCK_GAS_SAVINGS = {
    "arbitrum": {
        "l2_protocol": "Arbitrum One",
        "l1_gas_price_gwei": 25.0,
        "l2_gas_price_gwei": 0.1,
        "l1_gas_price_usd": 0.75,
        "l2_gas_price_usd": 0.003,
        "savings_percentage": 99.6,
        "savings_usd": 0.747,
        "timestamp": datetime.now().isoformat()
    },
    "optimism": {
        "l2_protocol": "Optimism",
        "l1_gas_price_gwei": 25.0,
        "l2_gas_price_gwei": 0.05,
        "l1_gas_price_usd": 0.75,
        "l2_gas_price_usd": 0.0015,
        "savings_percentage": 99.8,
        "savings_usd": 0.7485,
        "timestamp": datetime.now().isoformat()
    },
    "polygon": {
        "l2_protocol": "Polygon",
        "l1_gas_price_gwei": 25.0,
        "l2_gas_price_gwei": 30.0,
        "l1_gas_price_usd": 0.75,
        "l2_gas_price_usd": 0.90,
        "savings_percentage": -20.0,
        "savings_usd": -0.15,
        "timestamp": datetime.now().isoformat()
    },
    "base": {
        "l2_protocol": "Base",
        "l1_gas_price_gwei": 25.0,
        "l2_gas_price_gwei": 0.02,
        "l1_gas_price_usd": 0.75,
        "l2_gas_price_usd": 0.0006,
        "savings_percentage": 99.92,
        "savings_usd": 0.7494,
        "timestamp": datetime.now().isoformat()
    }
}

# Routes
@app.get("/", response_class=HTMLResponse)
async def root():
    """Serve the DEFIMON dashboard"""
    try:
        with open("dashboards/defimon-dashboard.html", "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    except FileNotFoundError:
        return HTMLResponse(content="""
        <html>
            <head><title>DEFIMON L2 Analytics</title></head>
            <body>
                <h1>DEFIMON L2 Analytics</h1>
                <p>Dashboard file not found. Please check the installation.</p>
                <p><a href="/docs">API Documentation</a></p>
            </body>
        </html>
        """)

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        version="1.0.0"
    )

@app.get("/api/l2-analytics/tvl-growth")
async def get_tvl_growth():
    """Get TVL growth data for all protocols"""
    return list(MOCK_TVL_DATA.values())

@app.get("/api/l2-analytics/tvl-growth/{protocol}")
async def get_tvl_growth_by_protocol(protocol: str):
    """Get TVL growth data for specific protocol"""
    if protocol not in MOCK_TVL_DATA:
        raise HTTPException(status_code=404, detail="Protocol not found")
    return MOCK_TVL_DATA[protocol]

@app.get("/api/l2-analytics/daily-active-users")
async def get_daily_active_users():
    """Get daily active users data"""
    return list(MOCK_USER_ACTIVITY.values())

@app.get("/api/l2-analytics/user-retention")
async def get_user_retention():
    """Get user retention metrics"""
    retention_data = []
    for protocol, data in MOCK_USER_ACTIVITY.items():
        retention_rate = (data["returning_users"] / data["dau"]) * 100 if data["dau"] > 0 else 0
        retention_data.append({
            "protocol": data["protocol"],
            "retention_rate": round(retention_rate, 2),
            "dau": data["dau"],
            "returning_users": data["returning_users"],
            "timestamp": data["timestamp"]
        })
    return retention_data

@app.get("/api/l2-analytics/gas-savings")
async def get_gas_savings():
    """Get gas savings data"""
    return list(MOCK_GAS_SAVINGS.values())

@app.get("/api/l2-analytics/gas-savings/comparison")
async def get_gas_savings_comparison():
    """Get detailed gas savings comparison"""
    return MOCK_GAS_SAVINGS

@app.post("/api/l2-analytics/collect")
async def trigger_data_collection():
    """Trigger data collection (mock)"""
    return {
        "message": "Data collection completed (mock data)",
        "status": "completed",
        "timestamp": datetime.now().isoformat()
    }

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
    return JSONResponse(
        status_code=500,
        content=ErrorResponse(
            error="Internal server error",
            message="An unexpected error occurred",
            timestamp=datetime.now().isoformat()
        ).dict()
    )

if __name__ == "__main__":
    print("🚀 Starting DEFIMON L2 Analytics Server...")
    print("📊 Dashboard: http://localhost:8000")
    print("📚 API Docs: http://localhost:8000/docs")
    print("🔍 Health Check: http://localhost:8000/health")
    
    uvicorn.run(
        "simple_server:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
