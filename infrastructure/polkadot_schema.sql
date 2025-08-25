-- Polkadot Networks Schema
-- This file contains the database schema for Polkadot blockchain data

-- Polkadot Blocks table
CREATE TABLE IF NOT EXISTS polkadot_blocks (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id VARCHAR(50) NOT NULL,
    number BIGINT NOT NULL,
    hash VARCHAR(255) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    parent_hash VARCHAR(255) NOT NULL,
    total_issuance BIGINT,
    active_era INTEGER,
    session_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, number)
);

-- Polkadot Extrinsics table
CREATE TABLE IF NOT EXISTS polkadot_extrinsics (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    hash VARCHAR(255) NOT NULL UNIQUE,
    block_number BIGINT NOT NULL,
    extrinsic_index INTEGER NOT NULL,
    call_module VARCHAR(100) NOT NULL,
    call_function VARCHAR(100) NOT NULL,
    params JSONB NOT NULL,
    signer VARCHAR(255),
    fee BIGINT,
    success BOOLEAN NOT NULL,
    error TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Polkadot Events table
CREATE TABLE IF NOT EXISTS polkadot_events (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    block_number BIGINT NOT NULL,
    extrinsic_index INTEGER,
    event_index INTEGER NOT NULL,
    module VARCHAR(100) NOT NULL,
    event VARCHAR(100) NOT NULL,
    params JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Polkadot Validators table
CREATE TABLE IF NOT EXISTS polkadot_validators (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    address VARCHAR(255) NOT NULL,
    stash_address VARCHAR(255) NOT NULL,
    controller_address VARCHAR(255) NOT NULL,
    block_number BIGINT NOT NULL,
    commission INTEGER, -- percentage * 10000
    bonded_amount BIGINT,
    total_stake BIGINT,
    is_active BOOLEAN NOT NULL,
    is_offline BOOLEAN NOT NULL,
    era_points INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, address, block_number)
);

-- Polkadot Network Statistics table
CREATE TABLE IF NOT EXISTS polkadot_network_stats (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    chain_id VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    total_blocks BIGINT DEFAULT 0,
    total_extrinsics BIGINT DEFAULT 0,
    total_events BIGINT DEFAULT 0,
    total_validators INTEGER DEFAULT 0,
    total_stake BIGINT DEFAULT 0,
    total_issuance BIGINT,
    active_era INTEGER,
    session_index INTEGER,
    unique_addresses BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, date)
);

-- Polkadot Protocol Data table
CREATE TABLE IF NOT EXISTS polkadot_protocol_data (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    protocol_name VARCHAR(100) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    tvl_usd DECIMAL(30,2),
    volume_24h_usd DECIMAL(30,2),
    fees_24h_usd DECIMAL(30,2),
    users_24h BIGINT,
    total_extrinsics BIGINT,
    total_events BIGINT,
    total_validators INTEGER,
    total_stake BIGINT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Polkadot Sync Status table
CREATE TABLE IF NOT EXISTS polkadot_sync_status (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL UNIQUE,
    last_processed_block BIGINT DEFAULT 0,
    last_sync_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_status VARCHAR(20) DEFAULT 'idle', -- idle, syncing, error
    error_message TEXT,
    blocks_per_second DECIMAL(10,2),
    total_blocks_processed BIGINT DEFAULT 0,
    total_extrinsics_processed BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Polkadot Parachain Data table
CREATE TABLE IF NOT EXISTS polkadot_parachains (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    parachain_id INTEGER NOT NULL,
    name VARCHAR(100) NOT NULL,
    token_symbol VARCHAR(20),
    block_number BIGINT NOT NULL,
    total_issuance BIGINT,
    active_validators INTEGER,
    total_stake BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, parachain_id, block_number)
);

-- Polkadot Governance Proposals table
CREATE TABLE IF NOT EXISTS polkadot_governance_proposals (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    proposal_id BIGINT NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL, -- proposed, approved, executed, rejected
    proposer VARCHAR(255) NOT NULL,
    value BIGINT,
    beneficiary VARCHAR(255),
    bond BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, proposal_id)
);

-- Polkadot Referenda table
CREATE TABLE IF NOT EXISTS polkadot_referenda (
    id SERIAL PRIMARY KEY,
    network VARCHAR(50) NOT NULL,
    referendum_id BIGINT NOT NULL,
    proposal_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL, -- active, approved, rejected, cancelled
    end_block BIGINT,
    delay BIGINT,
    ayes BIGINT DEFAULT 0,
    nays BIGINT DEFAULT 0,
    turnout BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(network, referendum_id)
);

-- Indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_polkadot_blocks_network_number ON polkadot_blocks(network, number);
CREATE INDEX IF NOT EXISTS idx_polkadot_blocks_timestamp ON polkadot_blocks(timestamp);
CREATE INDEX IF NOT EXISTS idx_polkadot_extrinsics_network_block ON polkadot_extrinsics(network, block_number);
CREATE INDEX IF NOT EXISTS idx_polkadot_extrinsics_hash ON polkadot_extrinsics(hash);
CREATE INDEX IF NOT EXISTS idx_polkadot_events_network_block ON polkadot_events(network, block_number);
CREATE INDEX IF NOT EXISTS idx_polkadot_validators_network_address ON polkadot_validators(network, address);
CREATE INDEX IF NOT EXISTS idx_polkadot_validators_network_block ON polkadot_validators(network, block_number);
CREATE INDEX IF NOT EXISTS idx_polkadot_network_stats_network_date ON polkadot_network_stats(network, date);
CREATE INDEX IF NOT EXISTS idx_polkadot_protocol_data_network_timestamp ON polkadot_protocol_data(network, timestamp);
CREATE INDEX IF NOT EXISTS idx_polkadot_sync_status_network ON polkadot_sync_status(network);
CREATE INDEX IF NOT EXISTS idx_polkadot_parachains_network_id ON polkadot_parachains(network, parachain_id);
CREATE INDEX IF NOT EXISTS idx_polkadot_governance_proposals_network_id ON polkadot_governance_proposals(network, proposal_id);
CREATE INDEX IF NOT EXISTS idx_polkadot_referenda_network_id ON polkadot_referenda(network, referendum_id);

-- View for Polkadot network overview
CREATE OR REPLACE VIEW polkadot_network_overview AS
SELECT 
    ps.network,
    ps.chain_id,
    ps.last_processed_block,
    ps.sync_status,
    ps.last_sync_time,
    ps.blocks_per_second,
    ps.total_blocks_processed,
    ps.total_extrinsics_processed,
    pns.total_blocks as daily_blocks,
    pns.total_extrinsics as daily_extrinsics,
    pns.total_events as daily_events,
    pns.total_validators,
    pns.total_stake,
    pns.total_issuance,
    pns.active_era,
    pns.session_index
FROM polkadot_sync_status ps
LEFT JOIN polkadot_network_stats pns ON ps.network = pns.network 
    AND pns.date = CURRENT_DATE;

-- Materialized view for daily statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS polkadot_daily_stats AS
SELECT 
    network,
    chain_id,
    DATE(timestamp) as date,
    COUNT(*) as total_blocks,
    SUM(CASE WHEN total_issuance IS NOT NULL THEN 1 ELSE 0 END) as blocks_with_issuance,
    MAX(total_issuance) as max_total_issuance,
    MAX(active_era) as max_active_era,
    MAX(session_index) as max_session_index
FROM polkadot_blocks
GROUP BY network, chain_id, DATE(timestamp)
ORDER BY network, date;

-- Function to update Polkadot sync status
CREATE OR REPLACE FUNCTION update_polkadot_sync_status(
    p_network VARCHAR(50),
    p_last_block BIGINT,
    p_status VARCHAR(20),
    p_error_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    INSERT INTO polkadot_sync_status (network, last_processed_block, sync_status, error_message, updated_at)
    VALUES (p_network, p_last_block, p_status, p_error_message, NOW())
    ON CONFLICT (network) DO UPDATE SET
        last_processed_block = EXCLUDED.last_processed_block,
        sync_status = EXCLUDED.sync_status,
        error_message = EXCLUDED.error_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old Polkadot data
CREATE OR REPLACE FUNCTION cleanup_old_polkadot_data(retention_days INTEGER)
RETURNS VOID AS $$
BEGIN
    DELETE FROM polkadot_blocks 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_extrinsics 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_events 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_validators 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_parachains 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_governance_proposals 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
    
    DELETE FROM polkadot_referenda 
    WHERE created_at < NOW() - INTERVAL '1 day' * retention_days;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate Polkadot network statistics
CREATE OR REPLACE FUNCTION calculate_polkadot_network_stats(p_network VARCHAR(50), p_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO polkadot_network_stats (
        network, chain_id, date, total_blocks, total_extrinsics, 
        total_events, total_validators, total_stake, total_issuance,
        active_era, session_index
    )
    SELECT 
        pb.network,
        pb.chain_id,
        p_date,
        COUNT(pb.id) as total_blocks,
        COUNT(pe.id) as total_extrinsics,
        COUNT(pev.id) as total_events,
        COUNT(DISTINCT pv.address) as total_validators,
        SUM(pv.total_stake) as total_stake,
        MAX(pb.total_issuance) as total_issuance,
        MAX(pb.active_era) as active_era,
        MAX(pb.session_index) as session_index
    FROM polkadot_blocks pb
    LEFT JOIN polkadot_extrinsics pe ON pb.network = pe.network AND pb.number = pe.block_number
    LEFT JOIN polkadot_events pev ON pb.network = pev.network AND pb.number = pev.block_number
    LEFT JOIN polkadot_validators pv ON pb.network = pv.network AND pb.number = pv.block_number
    WHERE pb.network = p_network 
        AND DATE(pb.timestamp) = p_date
    GROUP BY pb.network, pb.chain_id
    ON CONFLICT (network, date) DO UPDATE SET
        total_blocks = EXCLUDED.total_blocks,
        total_extrinsics = EXCLUDED.total_extrinsics,
        total_events = EXCLUDED.total_events,
        total_validators = EXCLUDED.total_validators,
        total_stake = EXCLUDED.total_stake,
        total_issuance = EXCLUDED.total_issuance,
        active_era = EXCLUDED.active_era,
        session_index = EXCLUDED.session_index,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;
