-- Price Oracle Database Schema
-- This file contains the database schema for cryptocurrency price data and oracle feeds

-- Oracle Sources table
CREATE TABLE IF NOT EXISTS oracle_sources (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    endpoint_url TEXT,
    api_key_required BOOLEAN DEFAULT FALSE,
    rate_limit_per_minute INTEGER DEFAULT 60,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cryptocurrency Assets table
CREATE TABLE IF NOT EXISTS crypto_assets (
    id SERIAL PRIMARY KEY,
    symbol VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    coingecko_id VARCHAR(100),
    contract_address BYTEA, -- For ERC-20 tokens
    network VARCHAR(50), -- ethereum, polygon, arbitrum, etc.
    decimals INTEGER DEFAULT 18,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Price Feeds table
CREATE TABLE IF NOT EXISTS price_feeds (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
    oracle_source_id INTEGER NOT NULL REFERENCES oracle_sources(id),
    price_usd DECIMAL(30,18) NOT NULL,
    volume_24h_usd DECIMAL(30,2),
    market_cap_usd DECIMAL(30,2),
    price_change_24h_percent DECIMAL(10,4),
    price_change_7d_percent DECIMAL(10,4),
    price_change_30d_percent DECIMAL(10,4),
    high_24h_usd DECIMAL(30,18),
    low_24h_usd DECIMAL(30,18),
    circulating_supply DECIMAL(30,18),
    total_supply DECIMAL(30,18),
    max_supply DECIMAL(30,18),
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(asset_id, oracle_source_id, last_updated)
);

-- L2 Network Price Data table
CREATE TABLE IF NOT EXISTS l2_network_prices (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    network_token_symbol VARCHAR(20) NOT NULL,
    price_usd DECIMAL(30,18) NOT NULL,
    volume_24h_usd DECIMAL(30,2),
    market_cap_usd DECIMAL(30,2),
    price_change_24h_percent DECIMAL(10,4),
    tvl_usd DECIMAL(30,2),
    total_transactions_24h BIGINT,
    avg_gas_price_gwei DECIMAL(10,2),
    oracle_source_id INTEGER REFERENCES oracle_sources(id),
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Oracle Feed History table (for historical analysis)
CREATE TABLE IF NOT EXISTS oracle_feed_history (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
    oracle_source_id INTEGER NOT NULL REFERENCES oracle_sources(id),
    price_usd DECIMAL(30,18) NOT NULL,
    volume_24h_usd DECIMAL(30,2),
    market_cap_usd DECIMAL(30,2),
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Price Aggregation table (consolidated prices from multiple oracles)
CREATE TABLE IF NOT EXISTS price_aggregations (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
    median_price_usd DECIMAL(30,18) NOT NULL,
    mean_price_usd DECIMAL(30,18) NOT NULL,
    weighted_price_usd DECIMAL(30,18) NOT NULL,
    price_volatility DECIMAL(10,6), -- Standard deviation
    oracle_count INTEGER NOT NULL,
    confidence_score DECIMAL(5,4), -- 0-1, based on oracle agreement
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Oracle Performance Metrics table
CREATE TABLE IF NOT EXISTS oracle_performance (
    id SERIAL PRIMARY KEY,
    oracle_source_id INTEGER NOT NULL REFERENCES oracle_sources(id),
    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
    uptime_percentage DECIMAL(5,2),
    response_time_avg_ms INTEGER,
    price_deviation_avg DECIMAL(10,6), -- Average deviation from median
    last_successful_update TIMESTAMP WITH TIME ZONE,
    error_count_24h INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(oracle_source_id, asset_id)
);

-- Price Alerts table
CREATE TABLE IF NOT EXISTS price_alerts (
    id SERIAL PRIMARY KEY,
    asset_id INTEGER NOT NULL REFERENCES crypto_assets(id),
    alert_type VARCHAR(20) NOT NULL, -- price_above, price_below, volume_spike, etc.
    threshold_value DECIMAL(30,18) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    triggered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_price_feeds_asset_timestamp ON price_feeds(asset_id, last_updated);
CREATE INDEX IF NOT EXISTS idx_price_feeds_oracle_timestamp ON price_feeds(oracle_source_id, last_updated);
CREATE INDEX IF NOT EXISTS idx_l2_network_prices_network_timestamp ON l2_network_prices(network, last_updated);
CREATE INDEX IF NOT EXISTS idx_oracle_feed_history_asset_timestamp ON oracle_feed_history(asset_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_price_aggregations_asset_timestamp ON price_aggregations(asset_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_oracle_performance_oracle_asset ON oracle_performance(oracle_source_id, asset_id);

-- Partitioning for large tables
CREATE TABLE IF NOT EXISTS price_feeds_2024 PARTITION OF price_feeds
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS oracle_feed_history_2024 PARTITION OF oracle_feed_history
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Views for common queries
CREATE OR REPLACE VIEW current_prices AS
SELECT 
    ca.symbol,
    ca.name,
    ca.network,
    pf.price_usd,
    pf.volume_24h_usd,
    pf.market_cap_usd,
    pf.price_change_24h_percent,
    pf.last_updated,
    os.name as oracle_source
FROM price_feeds pf
JOIN crypto_assets ca ON pf.asset_id = ca.id
JOIN oracle_sources os ON pf.oracle_source_id = os.id
WHERE pf.last_updated >= NOW() - INTERVAL '1 hour'
ORDER BY ca.symbol, pf.last_updated DESC;

CREATE OR REPLACE VIEW l2_network_overview AS
SELECT 
    network,
    network_token_symbol,
    price_usd,
    volume_24h_usd,
    market_cap_usd,
    tvl_usd,
    total_transactions_24h,
    avg_gas_price_gwei,
    last_updated
FROM l2_network_prices
WHERE last_updated >= NOW() - INTERVAL '1 hour'
ORDER BY network, last_updated DESC;

-- Materialized view for daily price statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_price_stats AS
SELECT 
    ca.symbol,
    ca.name,
    DATE(pf.last_updated) as date,
    AVG(pf.price_usd) as avg_price_usd,
    MIN(pf.price_usd) as min_price_usd,
    MAX(pf.price_usd) as max_price_usd,
    STDDEV(pf.price_usd) as price_volatility,
    SUM(pf.volume_24h_usd) as total_volume_usd,
    COUNT(*) as price_points
FROM price_feeds pf
JOIN crypto_assets ca ON pf.asset_id = ca.id
WHERE pf.last_updated >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ca.symbol, ca.name, DATE(pf.last_updated)
ORDER BY ca.symbol, date;

-- Functions
CREATE OR REPLACE FUNCTION update_oracle_performance(
    p_oracle_source_id INTEGER,
    p_asset_id INTEGER,
    p_response_time_ms INTEGER,
    p_price_deviation DECIMAL(10,6),
    p_success BOOLEAN
) RETURNS VOID AS $$
BEGIN
    INSERT INTO oracle_performance (
        oracle_source_id, 
        asset_id, 
        response_time_avg_ms, 
        price_deviation_avg, 
        last_successful_update,
        error_count_24h,
        updated_at
    )
    VALUES (
        p_oracle_source_id,
        p_asset_id,
        p_response_time_ms,
        p_price_deviation,
        CASE WHEN p_success THEN NOW() ELSE NULL END,
        CASE WHEN NOT p_success THEN 1 ELSE 0 END,
        NOW()
    )
    ON CONFLICT (oracle_source_id, asset_id) DO UPDATE SET
        response_time_avg_ms = (oracle_performance.response_time_avg_ms + p_response_time_ms) / 2,
        price_deviation_avg = (oracle_performance.price_deviation_avg + p_price_deviation) / 2,
        last_successful_update = CASE WHEN p_success THEN NOW() ELSE oracle_performance.last_successful_update END,
        error_count_24h = CASE WHEN NOT p_success THEN oracle_performance.error_count_24h + 1 ELSE 0 END,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to calculate price aggregations
CREATE OR REPLACE FUNCTION calculate_price_aggregation(p_asset_id INTEGER)
RETURNS VOID AS $$
DECLARE
    median_price DECIMAL(30,18);
    mean_price DECIMAL(30,18);
    weighted_price DECIMAL(30,18);
    price_volatility DECIMAL(10,6);
    oracle_count INTEGER;
    confidence_score DECIMAL(5,4);
BEGIN
    -- Get recent prices (last hour)
    WITH recent_prices AS (
        SELECT price_usd, oracle_source_id
        FROM price_feeds 
        WHERE asset_id = p_asset_id 
        AND last_updated >= NOW() - INTERVAL '1 hour'
    ),
    price_stats AS (
        SELECT 
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price_usd) as median_price,
            AVG(price_usd) as mean_price,
            STDDEV(price_usd) as price_volatility,
            COUNT(*) as oracle_count
        FROM recent_prices
    )
    SELECT 
        median_price,
        mean_price,
        price_volatility,
        oracle_count
    INTO median_price, mean_price, price_volatility, oracle_count
    FROM price_stats;
    
    -- Calculate weighted price (simple average for now)
    weighted_price := mean_price;
    
    -- Calculate confidence score based on oracle agreement
    confidence_score := LEAST(1.0, oracle_count::DECIMAL / 5.0);
    
    -- Insert aggregation
    INSERT INTO price_aggregations (
        asset_id,
        median_price_usd,
        mean_price_usd,
        weighted_price_usd,
        price_volatility,
        oracle_count,
        confidence_score,
        timestamp
    )
    VALUES (
        p_asset_id,
        median_price,
        mean_price,
        weighted_price,
        price_volatility,
        oracle_count,
        confidence_score,
        NOW()
    );
END;
$$ LANGUAGE plpgsql;

-- Insert initial oracle sources
INSERT INTO oracle_sources (name, description, endpoint_url, api_key_required, rate_limit_per_minute) VALUES
('CoinGecko', 'Free cryptocurrency price API', 'https://api.coingecko.com/api/v3', FALSE, 50),
('CoinMarketCap', 'Professional cryptocurrency data API', 'https://pro-api.coinmarketcap.com/v1', TRUE, 100),
('Binance', 'Binance cryptocurrency exchange API', 'https://api.binance.com/api/v3', FALSE, 1200),
('Kraken', 'Kraken cryptocurrency exchange API', 'https://api.kraken.com/0', FALSE, 15),
('Coinbase', 'Coinbase cryptocurrency exchange API', 'https://api.coinbase.com/v2', FALSE, 30),
('Chainlink', 'Decentralized oracle network', 'https://api.chain.link', FALSE, 100),
('Pyth Network', 'High-frequency oracle network', 'https://api.pyth.network', FALSE, 1000),
('Band Protocol', 'Cross-chain oracle network', 'https://api.bandprotocol.com', FALSE, 100);

-- Insert popular crypto assets
INSERT INTO crypto_assets (symbol, name, coingecko_id, network, decimals) VALUES
('ETH', 'Ethereum', 'ethereum', 'ethereum', 18),
('BTC', 'Bitcoin', 'bitcoin', 'bitcoin', 8),
('USDC', 'USD Coin', 'usd-coin', 'ethereum', 6),
('USDT', 'Tether', 'tether', 'ethereum', 6),
('MATIC', 'Polygon', 'matic-network', 'polygon', 18),
('ARB', 'Arbitrum', 'arbitrum', 'arbitrum', 18),
('OP', 'Optimism', 'optimism', 'optimism', 18),
('LINK', 'Chainlink', 'chainlink', 'ethereum', 18),
('UNI', 'Uniswap', 'uniswap', 'ethereum', 18),
('AAVE', 'Aave', 'aave', 'ethereum', 18),
('CRV', 'Curve DAO Token', 'curve-dao-token', 'ethereum', 18),
('SNX', 'Synthetix', 'havven', 'ethereum', 18);

-- Grant permissions
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO defi_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO defi_user;
