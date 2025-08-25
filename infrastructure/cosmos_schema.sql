-- Cosmos Networks Schema
-- This file contains the database schema for Cosmos blockchain data

-- Cosmos Blocks table
CREATE TABLE IF NOT EXISTS cosmos_blocks (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id VARCHAR(50) NOT NULL,
    height BIGINT NOT NULL,
    hash VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    proposer_address VARCHAR(255) NOT NULL,
    total_transactions INTEGER DEFAULT 0,
    total_fees JSONB,
    inflation_rate DECIMAL(10,8),
    bonded_tokens BIGINT,
    total_supply BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, height)
);

-- Cosmos Transactions table
CREATE TABLE IF NOT EXISTS cosmos_transactions (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    hash VARCHAR(255) NOT NULL UNIQUE,
    height BIGINT NOT NULL,
    fee_amount JSONB NOT NULL,
    gas_used BIGINT NOT NULL,
    gas_wanted BIGINT NOT NULL,
    memo TEXT,
    messages JSONB NOT NULL,
    result_code INTEGER NOT NULL,
    result_log TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cosmos Validators table
CREATE TABLE IF NOT EXISTS cosmos_validators (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    address VARCHAR(255) NOT NULL,
    height BIGINT NOT NULL,
    voting_power BIGINT NOT NULL,
    commission_rate DECIMAL(10,8),
    jailed BOOLEAN DEFAULT FALSE,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, address, height)
);

-- Cosmos Network Statistics table
CREATE TABLE IF NOT EXISTS cosmos_network_stats (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    total_blocks BIGINT DEFAULT 0,
    total_transactions BIGINT DEFAULT 0,
    total_volume DECIMAL(30,18) DEFAULT 0,
    avg_gas_used DECIMAL(10,2),
    avg_gas_wanted DECIMAL(10,2),
    total_validators INTEGER DEFAULT 0,
    total_voting_power BIGINT DEFAULT 0,
    inflation_rate DECIMAL(10,8),
    bonded_tokens BIGINT,
    total_supply BIGINT,
    unique_addresses BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, date)
);

-- Cosmos Protocol Data table
CREATE TABLE IF NOT EXISTS cosmos_protocol_data (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    protocol_name VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    tvl_usd DECIMAL(30,2),
    volume_24h_usd DECIMAL(30,2),
    fees_24h_usd DECIMAL(30,2),
    users_24h BIGINT,
    total_transactions BIGINT,
    avg_gas_used DECIMAL(10,2),
    total_validators INTEGER,
    total_voting_power BIGINT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cosmos Sync Status table
CREATE TABLE IF NOT EXISTS cosmos_sync_status (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL UNIQUE,
    last_processed_height BIGINT DEFAULT 0,
    last_sync_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_status VARCHAR(20) DEFAULT 'idle', -- idle, syncing, error
    error_message TEXT,
    blocks_per_second DECIMAL(10,2),
    total_blocks_processed BIGINT DEFAULT 0,
    total_transactions_processed BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cosmos IBC Transfers table
CREATE TABLE IF NOT EXISTS cosmos_ibc_transfers (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    source_chain VARCHAR(50) NOT NULL,
    destination_chain VARCHAR(50) NOT NULL,
    transfer_hash VARCHAR(255) NOT NULL,
    height BIGINT NOT NULL,
    amount DECIMAL(30,18) NOT NULL,
    denom VARCHAR(50) NOT NULL,
    sender_address VARCHAR(255) NOT NULL,
    receiver_address VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL, -- pending, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cosmos Staking Data table
CREATE TABLE IF NOT EXISTS cosmos_staking_data (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    height BIGINT NOT NULL,
    total_bonded_tokens BIGINT NOT NULL,
    total_unbonded_tokens BIGINT NOT NULL,
    total_unbonding_tokens BIGINT NOT NULL,
    inflation_rate DECIMAL(10,8),
    community_pool DECIMAL(30,18),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, height)
);

-- Cosmos Governance Proposals table
CREATE TABLE IF NOT EXISTS cosmos_governance_proposals (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    proposal_id BIGINT NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL, -- deposit_period, voting_period, passed, rejected, failed
    submit_time TIMESTAMP WITH TIME ZONE,
    voting_start_time TIMESTAMP WITH TIME ZONE,
    voting_end_time TIMESTAMP WITH TIME ZONE,
    total_votes BIGINT DEFAULT 0,
    yes_votes BIGINT DEFAULT 0,
    no_votes BIGINT DEFAULT 0,
    abstain_votes BIGINT DEFAULT 0,
    no_with_veto_votes BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, proposal_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_cosmos_blocks_network_height ON cosmos_blocks(network, height);
CREATE INDEX IF NOT EXISTS idx_cosmos_blocks_timestamp ON cosmos_blocks(timestamp);
CREATE INDEX IF NOT EXISTS idx_cosmos_transactions_network_height ON cosmos_transactions(network, height);
CREATE INDEX IF NOT EXISTS idx_cosmos_transactions_hash ON cosmos_transactions(hash);
CREATE INDEX IF NOT EXISTS idx_cosmos_validators_network_address ON cosmos_validators(network, address);
CREATE INDEX IF NOT EXISTS idx_cosmos_validators_network_height ON cosmos_validators(network, height);
CREATE INDEX IF NOT EXISTS idx_cosmos_network_stats_network_date ON cosmos_network_stats(network, date);
CREATE INDEX IF NOT EXISTS idx_cosmos_protocol_data_network_timestamp ON cosmos_protocol_data(network, timestamp);
CREATE INDEX IF NOT EXISTS idx_cosmos_sync_status_network ON cosmos_sync_status(network);
CREATE INDEX IF NOT EXISTS idx_cosmos_ibc_transfers_network_height ON cosmos_ibc_transfers(network, height);
CREATE INDEX IF NOT EXISTS idx_cosmos_staking_data_network_height ON cosmos_staking_data(network, height);
CREATE INDEX IF NOT EXISTS idx_cosmos_governance_proposals_network_id ON cosmos_governance_proposals(network, proposal_id);

-- View for Cosmos network overview
CREATE OR REPLACE VIEW cosmos_network_overview AS
SELECT 
    cs.network,
    cs.chain_id,
    cs.last_processed_height,
    cs.sync_status,
    cs.last_sync_time,
    cs.blocks_per_second,
    cs.total_blocks_processed,
    cs.total_transactions_processed,
    cns.total_blocks as daily_blocks,
    cns.total_transactions as daily_transactions,
    cns.total_volume as daily_volume,
    cns.avg_gas_used,
    cns.total_validators,
    cns.total_voting_power,
    cns.inflation_rate
FROM cosmos_sync_status cs
LEFT JOIN cosmos_network_stats cns ON cs.network = cns.network 
    AND cns.date = CURRENT_DATE;

-- Materialized view for daily statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS cosmos_daily_stats AS
SELECT 
    network,
    chain_id,
    DATE(timestamp) as date,
    COUNT(*) as total_blocks,
    SUM(total_transactions) as total_transactions,
    AVG(inflation_rate) as avg_inflation_rate,
    MAX(bonded_tokens) as max_bonded_tokens,
    MAX(total_supply) as max_total_supply
FROM cosmos_blocks
GROUP BY network, chain_id, DATE(timestamp)
ORDER BY network, date;

-- Function to update Cosmos sync status
CREATE OR REPLACE FUNCTION update_cosmos_sync_status(
    p_network VARCHAR(50),
    p_last_height BIGINT,
    p_status VARCHAR(20),
    p_error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO cosmos_sync_status (network, last_processed_height, sync_status, error_message, updated_at)
    VALUES (p_network, p_last_height, p_status, p_error_message, NOW())
    ON CONFLICT (network) DO UPDATE SET
        last_processed_height = EXCLUDED.last_processed_height,
        sync_status = EXCLUDED.sync_status,
        error_message = EXCLUDED.error_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old Cosmos data
CREATE OR REPLACE FUNCTION cleanup_old_cosmos_data(retention_days INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM cosmos_blocks 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM cosmos_transactions 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM cosmos_validators 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM cosmos_ibc_transfers 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM cosmos_staking_data 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM cosmos_governance_proposals 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate Cosmos network statistics
CREATE OR REPLACE FUNCTION calculate_cosmos_network_stats(p_network VARCHAR(50), p_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO cosmos_network_stats (
        network, chain_id, date, total_blocks, total_transactions, 
        avg_gas_used, avg_gas_wanted, total_validators, total_voting_power,
        inflation_rate, bonded_tokens, total_supply
    )
    SELECT 
        cb.network,
        cb.chain_id,
        p_date,
        COUNT(cb.id) as total_blocks,
        SUM(cb.total_transactions) as total_transactions,
        AVG(ct.gas_used) as avg_gas_used,
        AVG(ct.gas_wanted) as avg_gas_wanted,
        COUNT(DISTINCT cv.address) as total_validators,
        SUM(cv.voting_power) as total_voting_power,
        AVG(cb.inflation_rate) as inflation_rate,
        MAX(cb.bonded_tokens) as bonded_tokens,
        MAX(cb.total_supply) as total_supply
    FROM cosmos_blocks cb
    LEFT JOIN cosmos_transactions ct ON cb.network = ct.network AND cb.height = ct.height
    LEFT JOIN cosmos_validators cv ON cb.network = cv.network AND cb.height = cv.height
    WHERE cb.network = p_network 
        AND DATE(cb.timestamp) = p_date
    GROUP BY cb.network, cb.chain_id
    ON CONFLICT (network, date) DO UPDATE SET
        total_blocks = EXCLUDED.total_blocks,
        total_transactions = EXCLUDED.total_transactions,
        avg_gas_used = EXCLUDED.avg_gas_used,
        avg_gas_wanted = EXCLUDED.avg_gas_wanted,
        total_validators = EXCLUDED.total_validators,
        total_voting_power = EXCLUDED.total_voting_power,
        inflation_rate = EXCLUDED.inflation_rate,
        bonded_tokens = EXCLUDED.bonded_tokens,
        total_supply = EXCLUDED.total_supply,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
