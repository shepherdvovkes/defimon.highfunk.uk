use serde::Deserialize;
use std::env;
use dotenv::dotenv;

#[derive(Debug, Deserialize, Clone)]
pub struct Config {
    pub ethereum_node_url: String,
    pub database_url: String,
    pub kafka_bootstrap_servers: String,
    pub redis_url: String,
    pub log_level: String,
    pub sync_mode: String,
    pub cache_size: u64,
    pub max_peers: u32,
    pub rpc_port: u16,
    pub ws_port: u16,
    pub p2p_port: u16,
    // L2 Networks Configuration
    pub l2_sync_enabled: bool,
    pub l2_networks: Vec<String>, // List of enabled L2 networks
    pub l2_sync_interval: u64, // seconds
    pub l2_batch_size: u32,
    pub l2_max_concurrent_requests: u32,
    pub l2_data_retention_days: u32,
    pub l2_archive_mode: bool,
    pub l2_priority_threshold: u8, // Only sync networks with priority >= this value

    // EVM Networks Configuration
    pub evm_sync_enabled: bool,
    pub evm_networks: Vec<String>,
    
    // Substrate Networks Configuration
    pub substrate_sync_enabled: bool,
    pub substrate_networks: Vec<String>,
    pub substrate_sync_interval: u64,
    pub substrate_batch_size: u32,
    pub substrate_max_concurrent_requests: u32,
    pub substrate_data_retention_days: u32,
    pub substrate_priority_threshold: u8,
    
    // Cosmos Networks Configuration
    pub cosmos_sync_enabled: bool,
    pub cosmos_networks: Vec<String>,
    pub cosmos_sync_interval: u64,
    pub cosmos_batch_size: u32,
    pub cosmos_max_concurrent_requests: u32,
    pub cosmos_data_retention_days: u32,
    pub cosmos_priority_threshold: u8,
    
    // Polkadot Networks Configuration
    pub polkadot_sync_enabled: bool,
    pub polkadot_networks: Vec<String>,
    pub polkadot_sync_interval: u64,
    pub polkadot_batch_size: u32,
    pub polkadot_max_concurrent_requests: u32,
    pub polkadot_data_retention_days: u32,
    pub polkadot_priority_threshold: u8,
}

impl Config {
    pub fn load() -> Result<Self, Box<dyn std::error::Error>> {
        dotenv().ok();

        let config = Config {
            ethereum_node_url: env::var("ETHEREUM_NODE_URL")
                .unwrap_or_else(|_| "http://localhost:8545".to_string()),
            database_url: env::var("DATABASE_URL")
                .unwrap_or_else(|_| "postgresql://postgres:password@postgres:5432/defi_analytics".to_string()),
            kafka_bootstrap_servers: env::var("KAFKA_BOOTSTRAP_SERVERS")
                .unwrap_or_else(|_| "kafka:9092".to_string()),
            redis_url: env::var("REDIS_URL")
                .unwrap_or_else(|_| "redis://redis:6379".to_string()),
            log_level: env::var("RUST_LOG")
                .unwrap_or_else(|_| "info".to_string()),
            sync_mode: env::var("SYNC_MODE")
                .unwrap_or_else(|_| "full".to_string()),
            cache_size: env::var("CACHE_SIZE")
                .unwrap_or_else(|_| "4096".to_string())
                .parse()
                .unwrap_or(4096),
            max_peers: env::var("MAX_PEERS")
                .unwrap_or_else(|_| "50".to_string())
                .parse()
                .unwrap_or(50),
            rpc_port: env::var("RPC_PORT")
                .unwrap_or_else(|_| "8545".to_string())
                .parse()
                .unwrap_or(8545),
            ws_port: env::var("WS_PORT")
                .unwrap_or_else(|_| "8546".to_string())
                .parse()
                .unwrap_or(8546),
            p2p_port: env::var("P2P_PORT")
                .unwrap_or_else(|_| "30303".to_string())
                .parse()
                .unwrap_or(30303),
            // L2 Networks Configuration
            l2_sync_enabled: env::var("L2_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            l2_networks: env::var("L2_NETWORKS")
                .unwrap_or_else(|_| "optimism,arbitrum_one,polygon_zkevm,base,zksync_era,starknet,linea,scroll".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            l2_sync_interval: env::var("L2_SYNC_INTERVAL")
                .unwrap_or_else(|_| "12".to_string())
                .parse()
                .unwrap_or(12),
            l2_batch_size: env::var("L2_BATCH_SIZE")
                .unwrap_or_else(|_| "100".to_string())
                .parse()
                .unwrap_or(100),
            l2_max_concurrent_requests: env::var("L2_MAX_CONCURRENT_REQUESTS")
                .unwrap_or_else(|_| "10".to_string())
                .parse()
                .unwrap_or(10),
            l2_data_retention_days: env::var("L2_DATA_RETENTION_DAYS")
                .unwrap_or_else(|_| "90".to_string())
                .parse()
                .unwrap_or(90),
            l2_archive_mode: env::var("L2_ARCHIVE_MODE")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),
            l2_priority_threshold: env::var("L2_PRIORITY_THRESHOLD")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),

            // EVM Networks Configuration
            evm_sync_enabled: env::var("EVM_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            evm_networks: env::var("EVM_NETWORKS")
                .unwrap_or_else(|_| "ethereum,arbitrum_one,base,op_mainnet,blast,mantle,mode,world_chain,opbnb,metis,boba,zksync_era,linea,scroll,polygon_zkevm,bsc_mainnet,avalanche_c,polygon_pos,fantom,cronos,gnosis,celo,klaytn,moonbeam,moonriver,harmony,okx_xlayer,taiko,immutable_zkevm,kroma,sophon,apecoin_apechain,zircuit,flare,meter,syscoin,telos,core,bitlayer,merlin,aurora,evmos,kava_evm,canto,oasis_emerald,astar,shiden,reef,fuse,iotex,heco,okc,kcc,palm,etc,callisto,smartbch,nahmii,bttc,conflux_espace,zklink_nova,zora,pgn,redstone_l2,fraxchain,metal_l2,ancient8,xai,treasure,beam_evm,dfk_chain,songbird,shibarium,pulsechain,rootstock,bob,bevm,bsquared,zkfair,manta_pacific".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),

            // Substrate Networks Configuration
            substrate_sync_enabled: env::var("SUBSTRATE_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            substrate_networks: env::var("SUBSTRATE_NETWORKS")
                .unwrap_or_else(|_| "polkadot,kusama,westend,rococo,moonbeam,moonriver,astar,acala,parallel,centrifuge,hydradx,bifrost,interlay,unique,phala,zeitgeist".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect(),
            substrate_sync_interval: env::var("SUBSTRATE_SYNC_INTERVAL")
                .unwrap_or_else(|_| "8".to_string())
                .parse()
                .unwrap_or(8),
            substrate_batch_size: env::var("SUBSTRATE_BATCH_SIZE")
                .unwrap_or_else(|_| "25".to_string())
                .parse()
                .unwrap_or(25),
            substrate_max_concurrent_requests: env::var("SUBSTRATE_MAX_CONCURRENT_REQUESTS")
                .unwrap_or_else(|_| "6".to_string())
                .parse()
                .unwrap_or(6),
            substrate_data_retention_days: env::var("SUBSTRATE_DATA_RETENTION_DAYS")
                .unwrap_or_else(|_| "90".to_string())
                .parse()
                .unwrap_or(90),
            substrate_priority_threshold: env::var("SUBSTRATE_PRIORITY_THRESHOLD")
                .unwrap_or_else(|_| "5".to_string())
                .parse()
                .unwrap_or(5),

            // Cosmos Networks Configuration
            cosmos_sync_enabled: env::var("COSMOS_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            cosmos_networks: env::var("COSMOS_NETWORKS")
                .unwrap_or_else(|_| "cosmos_hub,osmosis,injective,celestia,sei,neutron,stride,quicksilver,persistence,agoric,evmos,kava,terra,terra_classic,secret,band,akash,stargaze,comdex,gravity_bridge,iris,likecoin,sentinel,regen,bitcanna,cheqd,emoney,impacthub,ixo,medibloc,microtick,panacea,passage,provenance,rizon,shentu,starname,teritori,umee,vidulum,assetmantle,axelar,binance_smart_chain,binance_chain,thorchain,binance_chain,binance_smart_chain,binance_chain,binance_smart_chain".to_string())
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

            // Polkadot Networks Configuration
            polkadot_sync_enabled: env::var("POLKADOT_SYNC_ENABLED")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),
            polkadot_networks: env::var("POLKADOT_NETWORKS")
                .unwrap_or_else(|_| "polkadot,kusama,westend,rococo".to_string())
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
        };

        Ok(config)
    }
}
