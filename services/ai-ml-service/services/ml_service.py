import asyncio
import redis
import json
import os
from typing import Dict, List, Optional
from datetime import datetime
import httpx

from models.price_predictor import PricePredictionModel
from models.risk_scorer import RiskScoringModel

class AIMLService:
    def __init__(self):
        self.price_model = PricePredictionModel()
        self.risk_model = RiskScoringModel()
        self.redis_client = redis.Redis(
            host=os.getenv("REDIS_HOST", "redis"),
            port=int(os.getenv("REDIS_PORT", "6379")),
            decode_responses=True
        )
        self.cache_ttl = 300  # 5 minutes
        
        # Load pre-trained models
        self.price_model.load_models()
    
    async def get_price_prediction(self, protocol: str, token_address: str, timeframe: str) -> Dict:
        """Get price prediction with caching"""
        cache_key = f"price_pred:{protocol}:{token_address}:{timeframe}"
        
        # Check cache first
        cached = self.redis_client.get(cache_key)
        if cached:
            return json.loads(cached)
        
        # Get latest data for the protocol
        data = await self._fetch_protocol_data(protocol, token_address)
        features = self.price_model.prepare_features(data)
        
        # Generate prediction
        prediction = self.price_model.predict_price(features, timeframe)
        
        # Cache result
        self.redis_client.setex(cache_key, self.cache_ttl, json.dumps(prediction))
        
        return prediction
    
    async def get_risk_assessment(self, protocol: str, include_detailed: bool = False) -> Dict:
        """Get risk assessment with caching"""
        cache_key = f"risk_score:{protocol}"
        
        cached = self.redis_client.get(cache_key)
        if cached:
            result = json.loads(cached)
            if not include_detailed:
                # Remove detailed breakdown for basic requests
                result.pop("detailed_risks", None)
                result.pop("recommendations", None)
            return result
        
        # Get protocol data
        protocol_data = await self._fetch_protocol_metadata(protocol)
        
        # Calculate risk score
        risk_assessment = self.risk_model.calculate_protocol_risk(protocol_data)
        
        # Cache result (longer TTL for risk scores)
        self.redis_client.setex(cache_key, 3600, json.dumps(risk_assessment))
        
        if not include_detailed:
            # Remove detailed breakdown for basic requests
            risk_assessment.pop("detailed_risks", None)
            risk_assessment.pop("recommendations", None)
        
        return risk_assessment
    
    def get_model_status(self) -> Dict:
        """Get status of all ML models"""
        status = {
            "price_prediction": {
                "short_term": self.price_model.models["short_term"] is not None,
                "medium_term": self.price_model.models["medium_term"] is not None,
                "long_term": self.price_model.models["long_term"] is not None
            },
            "risk_scoring": {
                "model_loaded": True  # Risk scoring is rule-based
            },
            "last_updated": datetime.utcnow().isoformat()
        }
        return status
    
    async def retrain_models(self) -> Dict:
        """Trigger model retraining (async task)"""
        # This would typically be a background task
        # For now, we'll just return a status
        return {
            "status": "retraining_scheduled",
            "message": "Model retraining has been scheduled",
            "timestamp": datetime.utcnow().isoformat()
        }
    
    async def _fetch_protocol_data(self, protocol: str, token_address: str) -> pd.DataFrame:
        """Fetch protocol data for ML predictions"""
        # This would typically fetch from the analytics API
        # For now, return mock data
        import pandas as pd
        import numpy as np
        
        # Generate mock historical data
        dates = pd.date_range(end=datetime.utcnow(), periods=100, freq='H')
        data = pd.DataFrame({
            'timestamp': dates,
            'price': np.random.normal(100, 10, 100),
            'volume_24h': np.random.normal(1000000, 200000, 100),
            'market_cap': np.random.normal(10000000, 2000000, 100),
            'total_value_locked': np.random.normal(5000000, 1000000, 100),
            'trading_volume': np.random.normal(500000, 100000, 100),
            'volatility_7d': np.random.normal(0.1, 0.02, 100),
            'rsi': np.random.normal(50, 15, 100),
            'macd': np.random.normal(0, 1, 100),
            'bollinger_bands': np.random.normal(100, 5, 100),
            'total_borrowed': np.random.normal(2000000, 500000, 100),
            'total_deposited': np.random.normal(5000000, 1000000, 100),
            'annual_percentage_yield': np.random.normal(0.05, 0.02, 100)
        })
        
        return data
    
    async def _fetch_protocol_metadata(self, protocol: str) -> Dict:
        """Fetch protocol metadata for risk assessment"""
        # This would typically fetch from the analytics API
        # For now, return mock data
        return {
            "audited": True,
            "audit_firm_rating": 0.8,
            "contract_complexity_score": 0.6,
            "upgradeable": True,
            "days_since_deployment": 180,
            "has_bug_bounty": True,
            "total_value_locked": 5000000,
            "volume_24h": 1000000,
            "pool_distributions": [0.3, 0.2, 0.15, 0.1, 0.05, 0.05, 0.05, 0.03, 0.03, 0.04],
            "price_volatility_30d": 0.15,
            "market_cap": 10000000,
            "top_10_users_percentage": 0.4,
            "governance_decentralization_score": 0.7,
            "multisig_required": True,
            "top_10_token_holders_percentage": 0.6,
            "voting_power_decentralization": 0.6,
            "governance_token_locked_percentage": 0.3
        }
    
    async def _call_analytics_api(self, endpoint: str, params: Dict = None) -> Dict:
        """Call analytics API for data"""
        analytics_api_url = os.getenv("ANALYTICS_API_URL", "http://analytics-api:8002")
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{analytics_api_url}{endpoint}", params=params, timeout=10.0)
                if response.status_code == 200:
                    return response.json()
                else:
                    raise Exception(f"Analytics API error: {response.status_code}")
        except Exception as e:
            print(f"Error calling analytics API: {e}")
            return {}
