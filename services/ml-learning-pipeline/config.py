#!/usr/bin/env python3
"""
Configuration for ML Learning Pipeline
Optimized for Apple M4 Neural Engine and QuickNode API integration
"""

import os
from typing import Dict, List, Optional
from dataclasses import dataclass
from pydantic import BaseSettings, Field
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class QuickNodeConfig:
    """QuickNode API configuration using existing credentials"""
    endpoint_name: str = "hidden-holy-seed"
    token_id: str = "97d6d8e7659b49b126c43455edc4607949bfb52b"
    api_key: str = "QN_6a9c24b3a5fc491f88e8c24c3294ef36"
    http_url: str = "https://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"
    ws_url: str = "wss://hidden-holy-seed.quiknode.pro/97d6d8e7659b49b126c43455edc4607949bfb52b"
    timeout: int = 30
    max_retries: int = 3

@dataclass
class M4NeuralEngineConfig:
    """Apple M4 Neural Engine optimization settings"""
    enable_neural_engine: bool = True
    enable_metal_acceleration: bool = True
    enable_core_ml: bool = True
    batch_size: int = 32
    num_threads: int = 8
    memory_limit_gb: int = 16
    precision: str = "float16"  # float16 for better performance

@dataclass
class ModelConfig:
    """ML Model configurations for the 5 popular questions"""
    price_prediction: Dict = Field(default_factory=lambda: {
        "model_type": "lstm_attention",
        "sequence_length": 100,
        "features": 50,
        "layers": [128, 64, 32],
        "dropout": 0.2,
        "learning_rate": 0.001,
        "batch_size": 32,
        "epochs": 100
    })
    
    gas_optimization: Dict = Field(default_factory=lambda: {
        "model_type": "random_forest",
        "n_estimators": 100,
        "max_depth": 20,
        "min_samples_split": 5,
        "min_samples_leaf": 2
    })
    
    defi_risk_assessment: Dict = Field(default_factory=lambda: {
        "model_type": "neural_network",
        "layers": [256, 128, 64],
        "dropout": 0.3,
        "activation": "relu",
        "output_activation": "sigmoid"
    })
    
    network_congestion: Dict = Field(default_factory=lambda: {
        "model_type": "prophet",
        "changepoint_prior_scale": 0.05,
        "seasonality_prior_scale": 10.0,
        "holidays_prior_scale": 10.0
    })
    
    smart_contract_security: Dict = Field(default_factory=lambda: {
        "model_type": "transformer",
        "vocab_size": 10000,
        "d_model": 512,
        "nhead": 8,
        "num_layers": 6,
        "dropout": 0.1
    })

class PipelineSettings(BaseSettings):
    """Main pipeline settings"""
    
    # QuickNode Configuration
    quicknode: QuickNodeConfig = QuickNodeConfig()
    
    # M4 Neural Engine Configuration
    m4_neural_engine: M4NeuralEngineConfig = M4NeuralEngineConfig()
    
    # Model Configurations
    models: ModelConfig = ModelConfig()
    
    # Data Collection Settings
    data_collection_interval: int = 60  # seconds
    historical_data_days: int = 365
    real_time_enabled: bool = True
    
    # Feature Engineering
    technical_indicators: List[str] = Field(default_factory=lambda: [
        "rsi", "macd", "bollinger_bands", "moving_averages", "volume_indicators"
    ])
    
    # Networks to monitor
    networks: List[str] = Field(default_factory=lambda: [
        "ethereum", "polygon", "arbitrum", "optimism", "base", "bsc", "avalanche"
    ])
    
    # API Settings
    api_host: str = "0.0.0.0"
    api_port: int = 8003
    api_workers: int = 4
    
    # Database Settings
    database_url: str = "postgresql://postgres:password@localhost:5432/defi_analytics"
    redis_url: str = "redis://localhost:6379"
    
    # Logging
    log_level: str = "INFO"
    log_file: str = "logs/ml-pipeline.log"
    
    # Monitoring
    prometheus_enabled: bool = True
    prometheus_port: int = 9091
    
    # Security
    api_key_required: bool = True
    rate_limit_per_minute: int = 100
    
    class Config:
        env_file = ".env"
        case_sensitive = False

# Global configuration instance
config = PipelineSettings()

# Network-specific configurations
NETWORK_CONFIGS = {
    "ethereum": {
        "chain_id": 1,
        "currency": "ETH",
        "priority": 10,
        "archive_enabled": True
    },
    "polygon": {
        "chain_id": 137,
        "currency": "MATIC",
        "priority": 9,
        "archive_enabled": True
    },
    "arbitrum": {
        "chain_id": 42161,
        "currency": "ETH",
        "priority": 9,
        "archive_enabled": True
    },
    "optimism": {
        "chain_id": 10,
        "currency": "ETH",
        "priority": 8,
        "archive_enabled": True
    },
    "base": {
        "chain_id": 8453,
        "currency": "ETH",
        "priority": 8,
        "archive_enabled": True
    },
    "bsc": {
        "chain_id": 56,
        "currency": "BNB",
        "priority": 7,
        "archive_enabled": True
    },
    "avalanche": {
        "chain_id": 43114,
        "currency": "AVAX",
        "priority": 7,
        "archive_enabled": True
    }
}

# Popular DeFi protocols for risk assessment
DEFI_PROTOCOLS = {
    "uniswap_v3": {
        "address": "0x1f98431c8ad98523631ae4a59f267346ea31f984",
        "category": "DEX",
        "risk_factors": ["impermanent_loss", "slippage", "liquidity"]
    },
    "aave_v3": {
        "address": "0x87870bace4f61ad5d8ba8c16b2e9ae4b6e79a1a7",
        "category": "Lending",
        "risk_factors": ["liquidation", "interest_rate", "collateral"]
    },
    "compound_v3": {
        "address": "0xc3d688b66703497daa19211eedff47f25384cdc3",
        "category": "Lending",
        "risk_factors": ["liquidation", "interest_rate", "collateral"]
    },
    "curve_finance": {
        "address": "0xd51a44d3fae010294c616388b506acda1bfaae46",
        "category": "StableSwap",
        "risk_factors": ["impermanent_loss", "peg_stability", "liquidity"]
    },
    "balancer": {
        "address": "0xba12222222228d8ba445958a75a0704d566bf2c8",
        "category": "DEX",
        "risk_factors": ["impermanent_loss", "slippage", "liquidity"]
    }
}

# Technical indicators configuration
TECHNICAL_INDICATORS = {
    "rsi": {"period": 14, "overbought": 70, "oversold": 30},
    "macd": {"fast_period": 12, "slow_period": 26, "signal_period": 9},
    "bollinger_bands": {"period": 20, "std_dev": 2},
    "moving_averages": {"sma_periods": [10, 20, 50, 200], "ema_periods": [12, 26]},
    "volume_indicators": ["obv", "vwap", "volume_sma"]
}

# Model performance thresholds
PERFORMANCE_THRESHOLDS = {
    "price_prediction": {
        "min_accuracy": 0.85,
        "max_mae": 0.05,
        "min_r2": 0.80
    },
    "gas_optimization": {
        "min_accuracy": 0.90,
        "max_error_percentage": 10.0
    },
    "defi_risk_assessment": {
        "min_accuracy": 0.88,
        "max_false_positive": 0.05,
        "max_false_negative": 0.10
    },
    "network_congestion": {
        "min_accuracy": 0.82,
        "max_mae": 0.08
    },
    "smart_contract_security": {
        "min_accuracy": 0.91,
        "max_false_positive": 0.03,
        "max_false_negative": 0.05
    }
}
