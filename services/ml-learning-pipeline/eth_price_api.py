#!/usr/bin/env python3
"""
ETH Price Prediction API
Answers the 5 most popular ETH price questions
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, List, Optional
import structlog
from datetime import datetime
import json
import redis
import asyncio

from models.eth_price_predictor import ETHPricePredictor

# Configure logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Initialize FastAPI app
app = FastAPI(
    title="ETH Price Prediction API",
    description="API for predicting ETH prices across different timeframes",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Redis connection
redis_client = None
try:
    redis_client = redis.Redis(host="localhost", port=6379, db=0, decode_responses=True)
    redis_client.ping()
    logger.info("Redis connected successfully")
except Exception as e:
    logger.warning("Redis not available", error=str(e))
    redis_client = None

# Initialize ETH price predictor
eth_predictor = ETHPricePredictor()

# Pydantic models
class ETHPriceRequest(BaseModel):
    timeframe: str  # "1m", "5m", "6m", "1y"
    include_analysis: bool = True

class ETHPriceResponse(BaseModel):
    asset: str
    timeframe: str
    current_price: float
    predicted_price: float
    confidence_interval: Dict[str, float]
    expected_return_percent: float
    confidence: float
    prediction_time: str
    analysis: Optional[Dict[str, Any]] = None

class AllTimeframesResponse(BaseModel):
    current_price: float
    predictions: Dict[str, ETHPriceResponse]
    summary: Dict[str, Any]

class PopularQuestionsResponse(BaseModel):
    questions: List[Dict[str, str]]
    answers: Dict[str, ETHPriceResponse]
    generated_at: str

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "name": "ETH Price Prediction API",
        "version": "1.0.0",
        "description": "Answers the 5 most popular ETH price questions",
        "endpoints": {
            "/predict/eth/{timeframe}": "Predict ETH price for specific timeframe",
            "/predict/eth/all": "Get predictions for all timeframes",
            "/questions/popular": "Get the 5 most popular ETH price questions",
            "/health": "Health check"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "redis_connected": redis_client is not None,
        "predictor_ready": True
    }

@app.post("/predict/eth/{timeframe}", response_model=ETHPriceResponse)
async def predict_eth_price(
    timeframe: str,
    request: ETHPriceRequest,
    background_tasks: BackgroundTasks
):
    """
    Predict ETH price for specific timeframe
    
    **Question**: "What will be the ETH price in {timeframe}?"
    
    Supported timeframes:
    - 1m: 1 month
    - 5m: 5 months  
    - 6m: 6 months
    - 1y: 1 year
    """
    try:
        logger.info("ETH price prediction request", timeframe=timeframe)
        
        # Validate timeframe
        valid_timeframes = ["1m", "5m", "6m", "1y"]
        if timeframe not in valid_timeframes:
            raise HTTPException(
                status_code=400, 
                detail=f"Invalid timeframe. Must be one of: {valid_timeframes}"
            )
        
        # Check cache first
        cache_key = f"eth_prediction:{timeframe}"
        if redis_client:
            cached_result = redis_client.get(cache_key)
            if cached_result:
                logger.info("Returning cached prediction", timeframe=timeframe)
                return json.loads(cached_result)
        
        # Get prediction
        result = await eth_predictor.predict_eth_price(timeframe)
        
        # Format response
        response = ETHPriceResponse(
            asset=result["asset"],
            timeframe=result["timeframe"],
            current_price=result["current_price"],
            predicted_price=result["prediction"]["predicted_price"],
            confidence_interval=result["prediction"]["confidence_interval"],
            expected_return_percent=result["prediction"]["expected_return_percent"],
            confidence=result["prediction"]["confidence"],
            prediction_time=result["prediction_time"]
        )
        
        # Add analysis if requested
        if request.include_analysis:
            response.analysis = {
                "volatility": result["prediction"]["volatility"],
                "trend": result["prediction"]["trend"],
                "sma_30": result["prediction"]["sma_30"],
                "sma_90": result["prediction"]["sma_90"],
                "data_points_used": result["data_points_used"],
                "model_version": result["model_version"]
            }
        
        # Cache result for 5 minutes
        if redis_client:
            redis_client.setex(cache_key, 300, response.json())
        
        logger.info("ETH price prediction completed", 
                   timeframe=timeframe,
                   predicted_price=response.predicted_price)
        
        return response
        
    except Exception as e:
        logger.error("ETH price prediction failed", timeframe=timeframe, error=str(e))
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")

@app.get("/predict/eth/all", response_model=AllTimeframesResponse)
async def get_all_eth_predictions():
    """
    Get ETH price predictions for all timeframes
    
    **Question**: "What are the ETH price predictions for 1 month, 5 months, 6 months, and 1 year?"
    """
    try:
        logger.info("Getting all ETH price predictions")
        
        # Check cache first
        cache_key = "eth_predictions_all"
        if redis_client:
            cached_result = redis_client.get(cache_key)
            if cached_result:
                logger.info("Returning cached all predictions")
                return json.loads(cached_result)
        
        # Get all predictions
        result = await eth_predictor.get_all_timeframe_predictions()
        
        # Format response
        predictions = {}
        for timeframe, pred_data in result["predictions"].items():
            predictions[timeframe] = ETHPriceResponse(
                asset=pred_data["asset"],
                timeframe=pred_data["timeframe"],
                current_price=pred_data["current_price"],
                predicted_price=pred_data["predicted_price"],
                confidence_interval=pred_data["confidence_interval"],
                expected_return_percent=pred_data["expected_return_percent"],
                confidence=pred_data["confidence"],
                prediction_time=pred_data["prediction_time"]
            )
        
        response = AllTimeframesResponse(
            current_price=result["current_price"],
            predictions=predictions,
            summary=result["summary"]
        )
        
        # Cache result for 5 minutes
        if redis_client:
            redis_client.setex(cache_key, 300, response.json())
        
        logger.info("All ETH predictions completed", 
                   timeframes=list(predictions.keys()))
        
        return response
        
    except Exception as e:
        logger.error("All ETH predictions failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Predictions failed: {str(e)}")

@app.get("/questions/popular", response_model=PopularQuestionsResponse)
async def get_popular_eth_questions():
    """
    Get the 5 most popular ETH price questions and their answers
    
    **Questions**:
    1. "What will be the ETH price in 1 month?"
    2. "What will be the ETH price in 5 months?"
    3. "What will be the ETH price in 6 months?"
    4. "What will be the ETH price in 1 year?"
    5. "What are the ETH price trends and predictions?"
    """
    try:
        logger.info("Getting popular ETH questions and answers")
        
        # Define the 5 most popular questions
        questions = [
            {
                "id": "1",
                "question": "What will be the ETH price in 1 month?",
                "timeframe": "1m",
                "category": "short_term"
            },
            {
                "id": "2", 
                "question": "What will be the ETH price in 5 months?",
                "timeframe": "5m",
                "category": "medium_term"
            },
            {
                "id": "3",
                "question": "What will be the ETH price in 6 months?",
                "timeframe": "6m", 
                "category": "medium_term"
            },
            {
                "id": "4",
                "question": "What will be the ETH price in 1 year?",
                "timeframe": "1y",
                "category": "long_term"
            },
            {
                "id": "5",
                "question": "What are the ETH price trends and predictions?",
                "timeframe": "all",
                "category": "analysis"
            }
        ]
        
        # Get answers for each question
        answers = {}
        
        for q in questions:
            if q["timeframe"] == "all":
                # Get all predictions for trend analysis
                all_predictions = await eth_predictor.get_all_timeframe_predictions()
                current_price = all_predictions["current_price"]
                
                # Calculate trend summary
                predictions = all_predictions["predictions"]
                trend_analysis = {
                    "short_term": predictions["1m"]["predicted_price"],
                    "medium_term": predictions["6m"]["predicted_price"], 
                    "long_term": predictions["1y"]["predicted_price"],
                    "overall_trend": "bullish" if predictions["1y"]["predicted_price"] > current_price else "bearish",
                    "confidence_range": f"{min(p['confidence'] for p in predictions.values()):.1%} - {max(p['confidence'] for p in predictions.values()):.1%}"
                }
                
                answers[q["id"]] = {
                    "question": q["question"],
                    "answer": f"ETH price trends show a {trend_analysis['overall_trend']} outlook. Short-term (1 month): ${trend_analysis['short_term']:.2f}, Medium-term (6 months): ${trend_analysis['medium_term']:.2f}, Long-term (1 year): ${trend_analysis['long_term']:.2f}. Confidence range: {trend_analysis['confidence_range']}",
                    "analysis": trend_analysis,
                    "current_price": current_price
                }
            else:
                # Get specific timeframe prediction
                prediction = await eth_predictor.predict_eth_price(q["timeframe"])
                
                answers[q["id"]] = {
                    "question": q["question"],
                    "answer": f"ETH price prediction for {q['timeframe']}: ${prediction['prediction']['predicted_price']:.2f} (Expected return: {prediction['prediction']['expected_return_percent']:.1f}%, Confidence: {prediction['prediction']['confidence']:.1%})",
                    "prediction": prediction,
                    "current_price": prediction["current_price"]
                }
        
        response = PopularQuestionsResponse(
            questions=questions,
            answers=answers,
            generated_at=datetime.now().isoformat()
        )
        
        logger.info("Popular questions and answers completed", 
                   questions_count=len(questions))
        
        return response
        
    except Exception as e:
        logger.error("Popular questions failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Questions failed: {str(e)}")

@app.get("/analysis/eth/trends")
async def get_eth_trend_analysis():
    """
    Get detailed ETH trend analysis
    
    **Question**: "What are the current ETH market trends and analysis?"
    """
    try:
        logger.info("Getting ETH trend analysis")
        
        # Get current price and historical data
        current_price = await eth_predictor.get_current_eth_price()
        historical_data = await eth_predictor.get_historical_eth_data(365)
        
        if historical_data.empty:
            raise HTTPException(status_code=500, detail="Unable to fetch historical data")
        
        # Calculate trend metrics
        recent_30d = historical_data.tail(30)
        recent_90d = historical_data.tail(90)
        
        trend_30d = (recent_30d["price"].iloc[-1] - recent_30d["price"].iloc[0]) / recent_30d["price"].iloc[0]
        trend_90d = (recent_90d["price"].iloc[-1] - recent_90d["price"].iloc[0]) / recent_90d["price"].iloc[0]
        
        volatility_30d = recent_30d["price_change"].std()
        volatility_90d = recent_90d["price_change"].std()
        
        # Calculate support and resistance levels
        support_level = historical_data["price"].tail(30).min()
        resistance_level = historical_data["price"].tail(30).max()
        
        analysis = {
            "current_price": current_price,
            "trends": {
                "30_day": {
                    "change_percent": trend_30d * 100,
                    "direction": "bullish" if trend_30d > 0 else "bearish",
                    "volatility": volatility_30d
                },
                "90_day": {
                    "change_percent": trend_90d * 100,
                    "direction": "bullish" if trend_90d > 0 else "bearish", 
                    "volatility": volatility_90d
                }
            },
            "technical_levels": {
                "support": support_level,
                "resistance": resistance_level,
                "sma_30": historical_data["sma_30"].iloc[-1],
                "sma_90": historical_data["sma_90"].iloc[-1]
            },
            "market_sentiment": {
                "trend_strength": "strong" if abs(trend_30d) > 0.1 else "weak",
                "volatility_level": "high" if volatility_30d > 0.05 else "low",
                "overall_sentiment": "bullish" if trend_30d > 0 and trend_90d > 0 else "bearish"
            },
            "data_points": len(historical_data),
            "analysis_date": datetime.now().isoformat()
        }
        
        logger.info("ETH trend analysis completed")
        return analysis
        
    except Exception as e:
        logger.error("ETH trend analysis failed", error=str(e))
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
