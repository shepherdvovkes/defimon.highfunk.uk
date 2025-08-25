-- Users and authentication
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    api_key VARCHAR(255) UNIQUE,
    subscription_tier VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
);

-- Protocol metadata
CREATE TABLE protocols (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200),
    category VARCHAR(50), -- dex, lending, yield, etc.
    chain VARCHAR(50),
    contract_address VARCHAR(42),
    logo_url TEXT,
    website_url TEXT,
    audit_status BOOLEAN DEFAULT FALSE,
    audit_firm VARCHAR(100),
    launch_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time protocol data
CREATE TABLE protocol_data (
    id SERIAL PRIMARY KEY,
    protocol_id INTEGER REFERENCES protocols(id),
    timestamp TIMESTAMP NOT NULL,
    total_value_locked DECIMAL(20,2),
    volume_24h DECIMAL(20,2),
    fees_24h DECIMAL(20,2),
    users_24h INTEGER,
    token_price DECIMAL(20,8),
    market_cap DECIMAL(20,2),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Token prices
CREATE TABLE token_prices (
    id SERIAL PRIMARY KEY,
    token_id VARCHAR(100) NOT NULL,
    symbol VARCHAR(20),
    name VARCHAR(100),
    price_usd DECIMAL(20,8),
    market_cap_usd DECIMAL(20,2),
    volume_24h_usd DECIMAL(20,2),
    price_change_24h DECIMAL(10,4),
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Risk assessments
CREATE TABLE risk_scores (
    id SERIAL PRIMARY KEY,
    protocol_id INTEGER REFERENCES protocols(id),
    timestamp TIMESTAMP NOT NULL,
    overall_risk DECIMAL(4,3),
    smart_contract_risk DECIMAL(4,3),
    liquidity_risk DECIMAL(4,3),
    market_risk DECIMAL(4,3),
    governance_risk DECIMAL(4,3),
    counterparty_risk DECIMAL(4,3),
    risk_factors JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI predictions
CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    protocol_id INTEGER REFERENCES protocols(id),
    prediction_type VARCHAR(50), -- price, risk, volume, etc.
    timeframe VARCHAR(20), -- 1h, 24h, 7d, 30d
    predicted_value DECIMAL(20,8),
    confidence_score DECIMAL(4,3),
    model_version VARCHAR(50),
    features_used JSONB,
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User portfolios
CREATE TABLE user_portfolios (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    name VARCHAR(200),
    positions JSONB, -- Array of token positions
    total_value_usd DECIMAL(20,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- API usage tracking
CREATE TABLE api_usage (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    endpoint VARCHAR(200),
    method VARCHAR(10),
    status_code INTEGER,
    response_time_ms INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Uniswap V3 specific data
CREATE TABLE uniswap_pools (
    id SERIAL PRIMARY KEY,
    pool_id VARCHAR(42) NOT NULL,
    pair_name VARCHAR(50),
    token0_symbol VARCHAR(20),
    token1_symbol VARCHAR(20),
    token0_address VARCHAR(42),
    token1_address VARCHAR(42),
    fee_tier INTEGER,
    tvl_usd DECIMAL(20,2),
    volume_24h_usd DECIMAL(20,2),
    fees_24h_usd DECIMAL(20,2),
    sqrt_price NUMERIC,
    tick INTEGER,
    liquidity NUMERIC,
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Aave V3 specific data
CREATE TABLE aave_reserves (
    id SERIAL PRIMARY KEY,
    reserve_id VARCHAR(42) NOT NULL,
    symbol VARCHAR(20),
    name VARCHAR(100),
    total_deposits DECIMAL(20,2),
    total_borrows DECIMAL(20,2),
    available_liquidity DECIMAL(20,2),
    utilization_rate DECIMAL(10,6),
    liquidity_rate DECIMAL(10,6),
    borrow_rate DECIMAL(10,6),
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_protocol_data_protocol_timestamp ON protocol_data(protocol_id, timestamp);
CREATE INDEX idx_token_prices_token_timestamp ON token_prices(token_id, timestamp);
CREATE INDEX idx_risk_scores_protocol_timestamp ON risk_scores(protocol_id, timestamp);
CREATE INDEX idx_predictions_protocol_type_timeframe ON predictions(protocol_id, prediction_type, timeframe);
CREATE INDEX idx_api_usage_user_timestamp ON api_usage(user_id, timestamp);
CREATE INDEX idx_uniswap_pools_timestamp ON uniswap_pools(timestamp);
CREATE INDEX idx_aave_reserves_timestamp ON aave_reserves(timestamp);

-- Insert sample protocols
INSERT INTO protocols (name, display_name, category, chain, contract_address) VALUES
('uniswap_v3', 'Uniswap V3', 'dex', 'ethereum', '0x1f98431c8ad98523631ae4a59f267346ea31f984'),
('aave_v3', 'Aave V3', 'lending', 'ethereum', '0x87870bace4f61ad5d8ba8c16b2e9ae4b6e79a1a7'),
('compound_v3', 'Compound V3', 'lending', 'ethereum', '0xc3d688b66703497daa19211eedff47f25384cdc3'),
('curve', 'Curve Finance', 'dex', 'ethereum', '0xd51a44d3fae010294c616388b506acda1bfaae46'),
('lido', 'Lido Finance', 'staking', 'ethereum', '0xae7ab96520de3a18e5e111b5eaab095312d7fe84');

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for user_portfolios table
CREATE TRIGGER update_user_portfolios_updated_at 
    BEFORE UPDATE ON user_portfolios 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
