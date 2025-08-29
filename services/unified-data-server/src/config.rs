use serde::{Deserialize, Serialize};
use std::env;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    // Database configuration
    pub database_url: String,
    
    // API configuration
    pub api_port: u16,
    
    // Ethereum configuration
    pub ethereum_sync_enabled: bool,
    pub ethereum_node_url: String,
    pub ethereum_sync_interval: u64,
    
    // L2 networks configuration
    pub l2_sync_enabled: bool,
    pub l2_networks: Vec<String>,
    pub l2_sync_interval: u64,
    pub l2_batch_size: u32,
    pub l2_max_concurrent_requests: u32,
    pub l2_priority_threshold: u32,
    
    // Cosmos configuration
    pub cosmos_sync_enabled: bool,
    pub cosmos_networks: Vec<String>,
    pub cosmos_sync_interval: u64,
    pub cosmos_batch_size: u32,
    pub cosmos_max_concurrent_requests: u32,
    pub cosmos_data_retention_days: u32,
    pub cosmos_priority_threshold: u32,
    
    // Polkadot configuration
    pub polkadot_sync_enabled: bool,
    pub polkadot_networks: Vec<String>,
    pub polkadot_sync_interval: u64,
    pub polkadot_batch_size: u32,
    pub polkadot_max_concurrent_requests: u32,
    pub polkadot_data_retention_days: u32,
    pub polkadot_priority_threshold: u32,
    
    // Price oracle configuration
    pub price_sync_enabled: bool,
    pub price_sync_interval: u64,
    pub price_oracle_sources: Vec<String>,
    
    // Monitoring configuration
    pub metrics_enabled: bool,
    pub log_level: String,
}

impl Config {
    pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
        let config = Config {
            // Database
            database_url: env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgresql://postgres:password@localhost:5432/defi_analytics".to_string()),
            
            // API
            api_port: env::var("API_PORT")
                .unwrap_or_else(|_| "8002".to_string())
                .parse()
                .unwrap_or(8002),
            
            // Ethereum
            ethereum_sync_enabled: env::var("ETHEREUM_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            ethereum_node_url: env::var("ETHEREUM_NODE_URL")
                .unwrap_or_else(|_| "http://localhost:8545".to_string()),
            ethereum_sync_interval: env::var("ETHEREUM_SYNC_INTERVAL")
                .unwrap_or_else(|_| "12".to_string())
                .parse()
                .unwrap_or(12),
            
            // L2 Networks
            l2_sync_enabled: env::var("L2_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            l2_networks: env::var("L2_NETWORKS")
                .unwrap_or_else(|_| "polygon,arbitrum,optimism,base,zksync,linea,scroll".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            l2_sync_interval: env::var("L2_SYNC_INTERVAL")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .unwrap_or(10),
            l2_batch_size: env::var("L2_BATCH_SIZE")
                .unwrap_or_else(|_| "50".to_string())
                .parse()
                .unwrap_or(50),
            l2_max_concurrent_requests: env::var("L2_MAX_CONCURRENT_REQUESTS")
                .unwrap_or_else(|_| "8".to_string())
                .parse()
                .unwrap_or(8),
            l2_priority_threshold: env::var("L2_PRIORITY_THRESHOLD")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            
            // Cosmos Networks
            cosmos_sync_enabled: env::var("COSMOS_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            cosmos_networks: env::var("COSMOS_NETWORKS")
                .unwrap_or_else(|_| "cosmos,osmosis,injective,celestia,sei,neutron".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            cosmos_sync_interval: env::var("COSMOS_SYNC_INTERVAL")
                .unwrap_or_else(|_| "15".to_string())
                .parse()
                .unwrap_or(15),
            cosmos_batch_size: env::var("COSMOS_BATCH_SIZE")
                .unwrap_or_else(|_| "50".to_string())
                .parse()
                .unwrap_or(50),
            cosmos_max_concurrent_requests: env::var("COSMOS_MAX_CONCURRENT_REQUESTS")
                .unwrap_or_else(|_| "8".to_string())
                .parse()
                .unwrap_or(8),
            cosmos_data_retention_days: env::var("COSMOS_DATA_RETENTION_DAYS")
                .unwrap_or_else(|_| "90".to_string())
                .parse()
                .unwrap_or(90),
            cosmos_priority_threshold: env::var("COSMOS_PRIORITY_THRESHOLD")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            
            // Polkadot Networks
            polkadot_sync_enabled: env::var("POLKADOT_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            polkadot_networks: env::var("POLKADOT_NETWORKS")
                .unwrap_or_else(|_| "polkadot,kusama,moonbeam,moonriver,astar,acala".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            polkadot_sync_interval: env::var("POLKADOT_SYNC_INTERVAL")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .unwrap_or(10),
            polkadot_batch_size: env::var("POLKADOT_BATCH_SIZE")
                .unwrap_or_else(|_| "20".to_string())
                .parse()
                .unwrap_or(20),
            polkadot_max_concurrent_requests: env::var("POLKADOT_MAX_CONCURRENT_REQUESTS")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            polkadot_data_retention_days: env::var("POLKADOT_DATA_RETENTION_DAYS")
                .unwrap_or_else(|_| "90".to_string())
                .parse()
                .unwrap_or(90),
            polkadot_priority_threshold: env::var("POLKADOT_PRIORITY_THRESHOLD")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),
            
            // Price Oracle
            price_sync_enabled: env::var("PRICE_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            price_sync_interval: env::var("PRICE_SYNC_INTERVAL")
                .unwrap_or_else(|_| "60".to_string())
                .parse()
                .unwrap_or(60),
            price_oracle_sources: env::var("PRICE_ORACLE_SOURCES")
                .unwrap_or_else(|_| "coingecko,coinmarketcap,binance".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            
            // Monitoring
            metrics_enabled: env::var("METRICS_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            log_level: env::var("LOG_LEVEL")
                .unwrap_or_else(|_| "info".to_string()),
        };

        Ok(config)
    }
}
