from sqlalchemy import Column, Integer, String, Float, DateTime, JSON, Boolean, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    api_key = Column(String(255), unique=True, index=True)
    subscription_tier = Column(String(50), default='free')
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True))

class Protocol(Base):
    __tablename__ = "protocols"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False)
    display_name = Column(String(200))
    category = Column(String(50))  # dex, lending, yield, etc.
    chain = Column(String(50))
    contract_address = Column(String(42))
    logo_url = Column(Text)
    website_url = Column(Text)
    audit_status = Column(Boolean, default=False)
    audit_firm = Column(String(100))
    launch_date = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class ProtocolData(Base):
    __tablename__ = "protocol_data"
    
    id = Column(Integer, primary_key=True, index=True)
    protocol_id = Column(Integer, index=True)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    total_value_locked = Column(Float)
    volume_24h = Column(Float)
    fees_24h = Column(Float)
    users_24h = Column(Integer)
    token_price = Column(Float)
    market_cap = Column(Float)
    metadata = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class TokenPrice(Base):
    __tablename__ = "token_prices"
    
    id = Column(Integer, primary_key=True, index=True)
    token_id = Column(String(100), nullable=False, index=True)
    symbol = Column(String(20))
    name = Column(String(100))
    price_usd = Column(Float)
    market_cap_usd = Column(Float)
    volume_24h_usd = Column(Float)
    price_change_24h = Column(Float)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class RiskScore(Base):
    __tablename__ = "risk_scores"
    
    id = Column(Integer, primary_key=True, index=True)
    protocol_id = Column(Integer, index=True)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    overall_risk = Column(Float)
    smart_contract_risk = Column(Float)
    liquidity_risk = Column(Float)
    market_risk = Column(Float)
    governance_risk = Column(Float)
    counterparty_risk = Column(Float)
    risk_factors = Column(JSON)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Prediction(Base):
    __tablename__ = "predictions"
    
    id = Column(Integer, primary_key=True, index=True)
    protocol_id = Column(Integer, index=True)
    prediction_type = Column(String(50))  # price, risk, volume, etc.
    timeframe = Column(String(20))  # 1h, 24h, 7d, 30d
    predicted_value = Column(Float)
    confidence_score = Column(Float)
    model_version = Column(String(50))
    features_used = Column(JSON)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class UserPortfolio(Base):
    __tablename__ = "user_portfolios"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    name = Column(String(200))
    positions = Column(JSON)  # Array of token positions
    total_value_usd = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class ApiUsage(Base):
    __tablename__ = "api_usage"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    endpoint = Column(String(200))
    method = Column(String(10))
    status_code = Column(Integer)
    response_time_ms = Column(Integer)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

class UniswapPool(Base):
    __tablename__ = "uniswap_pools"
    
    id = Column(Integer, primary_key=True, index=True)
    pool_id = Column(String(42), nullable=False, index=True)
    pair_name = Column(String(50))
    token0_symbol = Column(String(20))
    token1_symbol = Column(String(20))
    token0_address = Column(String(42))
    token1_address = Column(String(42))
    fee_tier = Column(Integer)
    tvl_usd = Column(Float)
    volume_24h_usd = Column(Float)
    fees_24h_usd = Column(Float)
    sqrt_price = Column(Float)
    tick = Column(Integer)
    liquidity = Column(Float)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class AaveReserve(Base):
    __tablename__ = "aave_reserves"
    
    id = Column(Integer, primary_key=True, index=True)
    reserve_id = Column(String(42), nullable=False, index=True)
    symbol = Column(String(20))
    name = Column(String(100))
    total_deposits = Column(Float)
    total_borrows = Column(Float)
    available_liquidity = Column(Float)
    utilization_rate = Column(Float)
    liquidity_rate = Column(Float)
    borrow_rate = Column(Float)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
