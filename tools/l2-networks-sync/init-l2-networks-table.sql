-- L2 Networks Table Initialization Script
-- Run this script to add L2 networks table to existing admin_dashboard database

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create L2 networks table
CREATE TABLE IF NOT EXISTS l2_networks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    chain_id BIGINT UNIQUE NOT NULL,
    network_type VARCHAR(50) NOT NULL DEFAULT 'L2',
    rpc_url TEXT,
    explorer_url TEXT,
    native_currency VARCHAR(100),
    block_time INTEGER,
    is_active BOOLEAN DEFAULT true,
    last_block_number BIGINT,
    last_sync_time TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    source VARCHAR(50) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_l2_networks_name ON l2_networks(name);
CREATE INDEX IF NOT EXISTS idx_l2_networks_chain_id ON l2_networks(chain_id);
CREATE INDEX IF NOT EXISTS idx_l2_networks_network_type ON l2_networks(network_type);
CREATE INDEX IF NOT EXISTS idx_l2_networks_is_active ON l2_networks(is_active);
CREATE INDEX IF NOT EXISTS idx_l2_networks_source ON l2_networks(source);
CREATE INDEX IF NOT EXISTS idx_l2_networks_last_sync_time ON l2_networks(last_sync_time);

-- Create function for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_l2_networks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for automatic timestamp updates
DROP TRIGGER IF EXISTS update_l2_networks_updated_at ON l2_networks;
CREATE TRIGGER update_l2_networks_updated_at 
    BEFORE UPDATE ON l2_networks
    FOR EACH ROW EXECUTE FUNCTION update_l2_networks_updated_at();

-- Insert some known L2 networks as initial data
INSERT INTO l2_networks (
    name, chain_id, network_type, rpc_url, explorer_url, 
    native_currency, block_time, is_active, metadata, source
) VALUES
    ('Arbitrum One', 42161, 'L2', 'https://arb1.arbitrum.io/rpc', 'https://arbiscan.io', 'ETH', 1, true, 
     '{"rollup_type": "optimistic", "data_availability": "ethereum", "fraud_proof": true}', 'known_networks'),
    
    ('Optimism', 10, 'L2', 'https://mainnet.optimism.io', 'https://optimistic.etherscan.io', 'ETH', 2, true,
     '{"rollup_type": "optimistic", "data_availability": "ethereum", "fraud_proof": true}', 'known_networks'),
    
    ('Base', 8453, 'L2', 'https://mainnet.base.org', 'https://basescan.org', 'ETH', 2, true,
     '{"rollup_type": "optimistic", "data_availability": "ethereum", "fraud_proof": true}', 'known_networks'),
    
    ('zkSync Era', 324, 'L2', 'https://mainnet.era.zksync.io', 'https://explorer.zksync.io', 'ETH', 1, true,
     '{"rollup_type": "zk", "data_availability": "ethereum", "fraud_proof": false}', 'known_networks'),
    
    ('Polygon zkEVM', 1101, 'L2', 'https://zkevm-rpc.com', 'https://zkevm.polygonscan.com', 'ETH', 1, true,
     '{"rollup_type": "zk", "data_availability": "ethereum", "fraud_proof": false}', 'known_networks'),
    
    ('Scroll', 534352, 'L2', 'https://rpc.scroll.io', 'https://scrollscan.com', 'ETH', 1, true,
     '{"rollup_type": "zk", "data_availability": "ethereum", "fraud_proof": false}', 'known_networks'),
    
    ('Mantle', 5000, 'L2', 'https://rpc.mantle.xyz', 'https://explorer.mantle.xyz', 'MNT', 2, true,
     '{"rollup_type": "optimistic", "data_availability": "ethereum", "fraud_proof": true}', 'known_networks'),
    
    ('Linea', 59144, 'L2', 'https://rpc.linea.build', 'https://lineascan.build', 'ETH', 2, true,
     '{"rollup_type": "zk", "data_availability": "ethereum", "fraud_proof": false}', 'known_networks')
ON CONFLICT (chain_id) DO NOTHING;

-- Create view for L2 networks summary
CREATE OR REPLACE VIEW l2_networks_summary AS
SELECT 
    network_type,
    COUNT(*) as total_networks,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_networks,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_networks,
    MAX(last_sync_time) as last_sync,
    COUNT(CASE WHEN source = 'geth_sync' THEN 1 END) as from_geth,
    COUNT(CASE WHEN source = 'lighthouse_sync' THEN 1 END) as from_lighthouse,
    COUNT(CASE WHEN source = 'known_networks' THEN 1 END) as predefined
FROM l2_networks
GROUP BY network_type;

-- Create view for recent sync activity
CREATE OR REPLACE VIEW l2_networks_sync_activity AS
SELECT 
    source,
    COUNT(*) as networks_count,
    MAX(last_sync_time) as last_sync,
    AVG(EXTRACT(EPOCH FROM (NOW() - last_sync_time))) as avg_sync_age_seconds
FROM l2_networks
WHERE last_sync_time IS NOT NULL
GROUP BY source;

-- Grant permissions (adjust as needed for your setup)
-- GRANT ALL PRIVILEGES ON TABLE l2_networks TO admin_user;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_user;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin_user;

-- Create a function to get network statistics
CREATE OR REPLACE FUNCTION get_l2_networks_stats()
RETURNS TABLE(
    total_networks INTEGER,
    l1_networks INTEGER,
    l2_networks INTEGER,
    active_networks INTEGER,
    inactive_networks INTEGER,
    last_sync_time TIMESTAMP WITH TIME ZONE,
    networks_by_source JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM l2_networks)::INTEGER as total_networks,
        (SELECT COUNT(*) FROM l2_networks WHERE network_type = 'L1')::INTEGER as l1_networks,
        (SELECT COUNT(*) FROM l2_networks WHERE network_type = 'L2')::INTEGER as l2_networks,
        (SELECT COUNT(*) FROM l2_networks WHERE is_active = true)::INTEGER as active_networks,
        (SELECT COUNT(*) FROM l2_networks WHERE is_active = false)::INTEGER as inactive_networks,
        (SELECT MAX(last_sync_time) FROM l2_networks) as last_sync_time,
        (SELECT jsonb_object_agg(source, count) 
         FROM (SELECT source, COUNT(*) as count 
               FROM l2_networks 
               GROUP BY source) as source_counts) as networks_by_source;
END;
$$ LANGUAGE plpgsql;

-- Create a function to clean up old sync data
CREATE OR REPLACE FUNCTION cleanup_old_l2_networks_data()
RETURNS void AS $$
BEGIN
    -- This function can be used to clean up old data if needed
    -- For now, we keep all data as it's valuable for tracking
    -- You can add cleanup logic here if needed in the future
    NULL;
END;
$$ LANGUAGE plpgsql;

-- Output success message
DO $$
BEGIN
    RAISE NOTICE 'L2 networks table initialized successfully!';
    RAISE NOTICE 'Run the sync tool to populate with live data from your nodes.';
END $$;
