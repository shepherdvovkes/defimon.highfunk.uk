from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from sqlalchemy.orm import Session
from typing import List, Optional, Dict
import asyncio
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(
    title="DeFi Analytics API",
    description="API for DeFi protocol analytics and monitoring",
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

app.add_middleware(GZipMiddleware, minimum_size=1000)

# Import database models and utilities
from database import get_db, engine
from models import Base
from routers import protocols, analytics, health

# Create database tables
Base.metadata.create_all(bind=engine)

# Include routers
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(protocols.router, prefix="/api/protocols", tags=["protocols"])
app.include_router(analytics.router, prefix="/api/analytics", tags=["analytics"])

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "DeFi Analytics API",
        "version": "1.0.0",
        "description": "API for DeFi protocol analytics and monitoring",
        "docs": "/docs",
        "health": "/health"
    }

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    from fastapi.responses import Response
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
