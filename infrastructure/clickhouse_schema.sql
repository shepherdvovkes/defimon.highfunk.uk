-- Time-series data for high-frequency analytics
CREATE TABLE IF NOT EXISTS protocol_metrics (
    timestamp DateTime64(3),
    protocol_name String,
    protocol_id UInt32,
    tvl_usd Float64,
    volume_24h_usd Float64,
    fees_24h_usd Float64,
    users_24h UInt32,
    price_usd Float64,
    market_cap_usd Float64,
    metadata String -- JSON string
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (protocol_name, timestamp)
SETTINGS index_granularity = 8192;

-- Real-time pool metrics for DEX protocols
CREATE TABLE IF NOT EXISTS pool_metrics (
    timestamp DateTime64(3),
    protocol_name String,
    pool_id String,
    pair_name String,
    tvl_usd Float64,
    volume_1h_usd Float64,
    volume_24h_usd Float64,
    fees_1h_usd Float64,
    fees_24h_usd Float64,
    price_impact Float64,
    liquidity_utilization Float64,
    fee_apr Float64,
    volatility_1h Float64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (protocol_name, pool_id, timestamp)
SETTINGS index_granularity = 8192;

-- User interaction events
CREATE TABLE IF NOT EXISTS user_events (
    timestamp DateTime64(3),
    user_id UInt32,
    event_type String, -- 'api_call', 'dashboard_view', 'prediction_request'
    endpoint String,
    parameters String, -- JSON
    response_time_ms UInt32,
    success Bool
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (user_id, timestamp)
SETTINGS index_granularity = 8192;

-- Model performance tracking
CREATE TABLE IF NOT EXISTS model_performance (
    timestamp DateTime64(3),
    model_name String,
    model_version String,
    prediction_type String,
    timeframe String,
    predicted_value Float64,
    actual_value Float64,
    absolute_error Float64,
    percentage_error Float64,
    confidence_score Float64
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (model_name, timestamp)
SETTINGS index_granularity = 8192;

-- Materialized views for common aggregations
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_protocol_stats
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (protocol_name, timestamp)
AS SELECT
    toStartOfHour(timestamp) as timestamp,
    protocol_name,
    avg(tvl_usd) as avg_tvl_usd,
    sum(volume_24h_usd) as total_volume_usd,
    sum(fees_24h_usd) as total_fees_usd,
    max(users_24h) as max_users_24h
FROM protocol_metrics
GROUP BY protocol_name, toStartOfHour(timestamp);

-- Daily aggregations
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_protocol_stats
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (protocol_name, timestamp)
AS SELECT
    toStartOfDay(timestamp) as timestamp,
    protocol_name,
    avg(tvl_usd) as avg_tvl_usd,
    sum(volume_24h_usd) as total_volume_usd,
    sum(fees_24h_usd) as total_fees_usd,
    max(users_24h) as max_users_24h,
    avg(price_usd) as avg_price_usd
FROM protocol_metrics
GROUP BY protocol_name, toStartOfDay(timestamp);

-- Pool performance aggregations
CREATE MATERIALIZED VIEW IF NOT EXISTS hourly_pool_stats
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (protocol_name, pool_id, timestamp)
AS SELECT
    toStartOfHour(timestamp) as timestamp,
    protocol_name,
    pool_id,
    pair_name,
    avg(tvl_usd) as avg_tvl_usd,
    sum(volume_1h_usd) as total_volume_1h_usd,
    sum(fees_1h_usd) as total_fees_1h_usd,
    avg(price_impact) as avg_price_impact,
    avg(liquidity_utilization) as avg_liquidity_utilization,
    avg(fee_apr) as avg_fee_apr,
    avg(volatility_1h) as avg_volatility_1h
FROM pool_metrics
GROUP BY protocol_name, pool_id, pair_name, toStartOfHour(timestamp);
