-- L2 Networks Schema
-- This file contains the database schema for L2 blockchain data

-- L2 Blocks table
CREATE TABLE IF NOT EXISTS l2_blocks (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id BIGINT NOT NULL,
    number BIGINT NOT NULL,
    hash BYTEA NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    l1_batch_submissions BIGINT,
    l1_batch_size BIGINT,
    finality_time BIGINT, -- seconds
    gas_fees_l2 TEXT,
    gas_fees_l1 TEXT,
    sequencer_fees TEXT,
    compression_ratio DECIMAL(5,4),
    proof_generation_time BIGINT, -- seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, number)
);

-- L2 Transactions table
CREATE TABLE IF NOT EXISTS l2_transactions (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    hash BYTEA NOT NULL UNIQUE,
    from_address BYTEA NOT NULL,
    to_address BYTEA,
    value TEXT NOT NULL,
    gas_price TEXT NOT NULL,
    gas_used TEXT NOT NULL,
    block_number BIGINT NOT NULL,
    l2_gas_price TEXT,
    l1_gas_price TEXT,
    l1_batch_number BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- L2 Logs table
CREATE TABLE IF NOT EXISTS l2_logs (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    address BYTEA NOT NULL,
    topics JSONB NOT NULL,
    data BYTEA NOT NULL,
    block_number BIGINT NOT NULL,
    transaction_hash BYTEA NOT NULL,
    l2_specific_metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- L2 Network Statistics table
CREATE TABLE IF NOT EXISTS l2_network_stats (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id BIGINT NOT NULL,
    date DATE NOT NULL,
    total_blocks BIGINT DEFAULT 0,
    total_transactions BIGINT DEFAULT 0,
    total_volume DECIMAL(30,18) DEFAULT 0,
    avg_gas_price_l2 DECIMAL(30,18),
    avg_gas_price_l1 DECIMAL(30,18),
    avg_finality_time DECIMAL(10,2),
    compression_ratio_avg DECIMAL(5,4),
    unique_addresses BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, date)
);

-- L2 Protocol Data table
CREATE TABLE IF NOT EXISTS l2_protocol_data (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    protocol_name VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    tvl_usd DECIMAL(30,2),
    volume_24h_usd DECIMAL(30,2),
    fees_24h_usd DECIMAL(30,2),
    users_24h BIGINT,
    gas_fees_l2 DECIMAL(30,18),
    gas_fees_l1 DECIMAL(30,18),
    l1_batch_submissions BIGINT,
    l1_batch_size BIGINT,
    finality_time BIGINT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- L2 Sync Status table
CREATE TABLE IF NOT EXISTS l2_sync_status (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL UNIQUE,
    last_processed_block BIGINT DEFAULT 0,
    last_sync_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_status VARCHAR(20) DEFAULT 'idle', -- idle, syncing, error
    error_message TEXT,
    blocks_per_second DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_l2_blocks_network_number ON l2_blocks(network, number);
CREATE INDEX IF NOT EXISTS idx_l2_blocks_timestamp ON l2_blocks(timestamp);
CREATE INDEX IF NOT EXISTS idx_l2_transactions_network_block ON l2_transactions(network, block_number);
CREATE INDEX IF NOT EXISTS idx_l2_transactions_hash ON l2_transactions(hash);
CREATE INDEX IF NOT EXISTS idx_l2_logs_network_block ON l2_logs(network, block_number);
CREATE INDEX IF NOT EXISTS idx_l2_logs_address ON l2_logs(address);
CREATE INDEX IF NOT EXISTS idx_l2_network_stats_network_date ON l2_network_stats(network, date);
CREATE INDEX IF NOT EXISTS idx_l2_protocol_data_network_timestamp ON l2_protocol_data(network, timestamp);
CREATE INDEX IF NOT EXISTS idx_l2_sync_status_network ON l2_sync_status(network);

-- Partitioning for large tables (optional, for very high volume)
-- CREATE TABLE l2_blocks_2024 PARTITION OF l2_blocks
-- FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Views for common queries
CREATE OR REPLACE VIEW l2_network_overview AS
SELECT 
    network,
    chain_id,
    COUNT(DISTINCT number) as total_blocks,
    COUNT(DISTINCT t.hash) as total_transactions,
    COALESCE(SUM(CAST(t.value AS DECIMAL)), 0) as total_volume,
    MAX(created_at) as last_sync_time,
    AVG(CAST(gas_fees_l2 AS DECIMAL)) as avg_gas_fees_l2,
    AVG(CAST(gas_fees_l1 AS DECIMAL)) as avg_gas_fees_l1,
    AVG(finality_time) as avg_finality_time,
    AVG(compression_ratio) as avg_compression_ratio
FROM l2_blocks b
LEFT JOIN l2_transactions t ON b.network = t.network AND b.number = t.block_number
GROUP BY network, chain_id;

-- Materialized view for daily statistics (refreshed every hour)
CREATE MATERIALIZED VIEW IF NOT EXISTS l2_daily_stats AS
SELECT 
    network,
    DATE(timestamp) as date,
    COUNT(DISTINCT number) as blocks_count,
    COUNT(DISTINCT t.hash) as transactions_count,
    COALESCE(SUM(CAST(t.value AS DECIMAL)), 0) as volume,
    AVG(CAST(gas_fees_l2 AS DECIMAL)) as avg_gas_fees_l2,
    AVG(CAST(gas_fees_l1 AS DECIMAL)) as avg_gas_fees_l1,
    AVG(finality_time) as avg_finality_time,
    AVG(compression_ratio) as avg_compression_ratio,
    COUNT(DISTINCT t.from_address) as unique_addresses
FROM l2_blocks b
LEFT JOIN l2_transactions t ON b.network = t.network AND b.number = t.block_number
WHERE timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY network, DATE(timestamp);

-- Function to update sync status
CREATE OR REPLACE FUNCTION update_l2_sync_status(
    p_network VARCHAR(50),
    p_last_block BIGINT,
    p_status VARCHAR(20),
    p_error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO l2_sync_status (network, last_processed_block, sync_status, error_message, updated_at)
    VALUES (p_network, p_last_block, p_status, p_error_message, NOW())
    ON CONFLICT (network) DO UPDATE SET
        last_processed_block = EXCLUDED.last_processed_block,
        sync_status = EXCLUDED.sync_status,
        error_message = EXCLUDED.error_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old data
CREATE OR REPLACE FUNCTION cleanup_old_l2_data(retention_days INTEGER)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM l2_blocks 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- Also cleanup related data
    DELETE FROM l2_transactions 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM l2_logs 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions (adjust as needed)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO defi_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO defi_user;
