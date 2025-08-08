use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L2Network {
    pub name: String,
    pub chain_id: u64,
    pub rpc_url: String,
    pub ws_url: Option<String>,
    pub explorer_url: String,
    pub category: L2Category,
    pub technology: L2Technology,
    pub tvl_usd: Option<f64>,
    pub volume_24h: Option<f64>,
    pub protocols: Vec<String>,
    pub priority: u8, // 1-10, higher = more important
    pub sync_enabled: bool,
    pub contract_addresses: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum L2Category {
    OptimisticRollup,
    ZKRollup,
    Validium,
    Plasma,
    Sidechain,
    StateChannel,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum L2Technology {
    Optimism,
    Arbitrum,
    Polygon,
    StarkNet,
    ZkSync,
    Loopring,
    ImmutableX,
    Boba,
    Metis,
    Mantle,
    Base,
    Linea,
    Scroll,
    PolygonZkEVM,
    ConsenSysZkEVM,
    Custom,
}

#[derive(Clone)]
pub struct L2NetworkRegistry {
    networks: HashMap<String, L2Network>,
}

impl L2NetworkRegistry {
    pub fn new() -> Self {
        let mut networks = HashMap::new();
        
        // === MAJOR L2 NETWORKS (Top Tier) ===
        
        // Optimism
        networks.insert("optimism".to_string(), L2Network {
            name: "Optimism".to_string(),
            chain_id: 10,
            rpc_url: "https://mainnet.optimism.io".to_string(),
            ws_url: Some("wss://mainnet.optimism.io".to_string()),
            explorer_url: "https://optimistic.etherscan.io".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Optimism,
            tvl_usd: Some(850_000_000.0),
            volume_24h: Some(50_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "aave_v3".to_string(),
                "curve".to_string(),
                "balancer".to_string(),
                "synthetix".to_string(),
                "velodrome".to_string(),
                "perpetual_protocol".to_string(),
            ],
            priority: 10,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Arbitrum One
        networks.insert("arbitrum_one".to_string(), L2Network {
            name: "Arbitrum One".to_string(),
            chain_id: 42161,
            rpc_url: "https://arb1.arbitrum.io/rpc".to_string(),
            ws_url: Some("wss://arb1.arbitrum.io/ws".to_string()),
            explorer_url: "https://arbiscan.io".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Arbitrum,
            tvl_usd: Some(2_100_000_000.0),
            volume_24h: Some(120_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "aave_v3".to_string(),
                "curve".to_string(),
                "balancer".to_string(),
                "gmx".to_string(),
                "camelot".to_string(),
                "radiant".to_string(),
                "pendle".to_string(),
            ],
            priority: 10,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Polygon zkEVM
        networks.insert("polygon_zkevm".to_string(), L2Network {
            name: "Polygon zkEVM".to_string(),
            chain_id: 1101,
            rpc_url: "https://zkevm-rpc.com".to_string(),
            ws_url: None,
            explorer_url: "https://zkevm.polygonscan.com".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::PolygonZkEVM,
            tvl_usd: Some(45_000_000.0),
            volume_24h: Some(2_500_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "quickswap".to_string(),
                "aave_v3".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Base
        networks.insert("base".to_string(), L2Network {
            name: "Base".to_string(),
            chain_id: 8453,
            rpc_url: "https://mainnet.base.org".to_string(),
            ws_url: Some("wss://mainnet.base.org".to_string()),
            explorer_url: "https://basescan.org".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Base,
            tvl_usd: Some(750_000_000.0),
            volume_24h: Some(35_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "aerodrome".to_string(),
                "compound_v3".to_string(),
                "aave_v3".to_string(),
                "balancer".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === ZK ROLLUPS ===

        // zkSync Era
        networks.insert("zksync_era".to_string(), L2Network {
            name: "zkSync Era".to_string(),
            chain_id: 324,
            rpc_url: "https://mainnet.era.zksync.io".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.zksync.io".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::ZkSync,
            tvl_usd: Some(650_000_000.0),
            volume_24h: Some(25_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "syncswap".to_string(),
                "mute".to_string(),
                "spacefi".to_string(),
                "izumi".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // StarkNet
        networks.insert("starknet".to_string(), L2Network {
            name: "StarkNet".to_string(),
            chain_id: 0x534e5f4d41494e, // SN_MAIN
            rpc_url: "https://alpha-mainnet.starknet.io".to_string(),
            ws_url: None,
            explorer_url: "https://starkscan.co".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::StarkNet,
            tvl_usd: Some(180_000_000.0),
            volume_24h: Some(8_000_000.0),
            protocols: vec![
                "myswap".to_string(),
                "jediswap".to_string(),
                "10kswap".to_string(),
                "sithswap".to_string(),
            ],
            priority: 8,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Linea
        networks.insert("linea".to_string(), L2Network {
            name: "Linea".to_string(),
            chain_id: 59144,
            rpc_url: "https://rpc.linea.build".to_string(),
            ws_url: None,
            explorer_url: "https://lineascan.build".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::Linea,
            tvl_usd: Some(120_000_000.0),
            volume_24h: Some(6_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "kyberswap".to_string(),
                "syncswap".to_string(),
                "izumi".to_string(),
            ],
            priority: 8,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Scroll
        networks.insert("scroll".to_string(), L2Network {
            name: "Scroll".to_string(),
            chain_id: 534352,
            rpc_url: "https://rpc.scroll.io".to_string(),
            ws_url: None,
            explorer_url: "https://scrollscan.com".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::Scroll,
            tvl_usd: Some(85_000_000.0),
            volume_24h: Some(4_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "syncswap".to_string(),
                "izumi".to_string(),
            ],
            priority: 8,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === OPTIMISTIC ROLLUPS ===

        // Mantle
        networks.insert("mantle".to_string(), L2Network {
            name: "Mantle".to_string(),
            chain_id: 5000,
            rpc_url: "https://rpc.mantle.xyz".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.mantle.xyz".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Mantle,
            tvl_usd: Some(45_000_000.0),
            volume_24h: Some(2_500_000.0),
            protocols: vec![
                "agility".to_string(),
                "fusionx".to_string(),
                "merchantmoe".to_string(),
            ],
            priority: 7,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Metis
        networks.insert("metis".to_string(), L2Network {
            name: "Metis".to_string(),
            chain_id: 1088,
            rpc_url: "https://andromeda.metis.io/?owner=1088".to_string(),
            ws_url: None,
            explorer_url: "https://andromeda-explorer.metis.io".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Metis,
            tvl_usd: Some(35_000_000.0),
            volume_24h: Some(1_500_000.0),
            protocols: vec![
                "netswap".to_string(),
                "tethys".to_string(),
                "maverick".to_string(),
            ],
            priority: 6,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Boba Network
        networks.insert("boba".to_string(), L2Network {
            name: "Boba Network".to_string(),
            chain_id: 288,
            rpc_url: "https://mainnet.boba.network".to_string(),
            ws_url: None,
            explorer_url: "https://bobascan.com".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Boba,
            tvl_usd: Some(15_000_000.0),
            volume_24h: Some(800_000.0),
            protocols: vec![
                "oolongswap".to_string(),
                "swapperchan".to_string(),
            ],
            priority: 5,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === GAMING & NFT FOCUSED ===

        // Immutable X
        networks.insert("immutable_x".to_string(), L2Network {
            name: "Immutable X".to_string(),
            chain_id: 0x1, // IMX mainnet
            rpc_url: "https://rpc.immutable.com".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.immutable.com".to_string(),
            category: L2Category::Validium,
            technology: L2Technology::ImmutableX,
            tvl_usd: Some(25_000_000.0),
            volume_24h: Some(1_200_000.0),
            protocols: vec![
                "gods_unchained".to_string(),
                "guild_of_guardians".to_string(),
            ],
            priority: 6,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Loopring
        networks.insert("loopring".to_string(), L2Network {
            name: "Loopring".to_string(),
            chain_id: 1, // Ethereum L1
            rpc_url: "https://api3.loopring.io".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.loopring.io".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::Loopring,
            tvl_usd: Some(120_000_000.0),
            volume_24h: Some(8_000_000.0),
            protocols: vec![
                "loopring_dex".to_string(),
            ],
            priority: 7,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === EMERGING L2s ===

        // Polygon (L2-like)
        networks.insert("polygon".to_string(), L2Network {
            name: "Polygon".to_string(),
            chain_id: 137,
            rpc_url: "https://polygon-rpc.com".to_string(),
            ws_url: None,
            explorer_url: "https://polygonscan.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Polygon,
            tvl_usd: Some(850_000_000.0),
            volume_24h: Some(45_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "quickswap".to_string(),
                "aave_v3".to_string(),
                "curve".to_string(),
                "balancer".to_string(),
                "sushiswap".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // BSC (L2-like)
        networks.insert("bsc".to_string(), L2Network {
            name: "BNB Smart Chain".to_string(),
            chain_id: 56,
            rpc_url: "https://bsc-dataseed.binance.org".to_string(),
            ws_url: None,
            explorer_url: "https://bscscan.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(5_200_000_000.0),
            volume_24h: Some(250_000_000.0),
            protocols: vec![
                "pancakeswap".to_string(),
                "venus".to_string(),
                "biswap".to_string(),
                "apollox".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Avalanche
        networks.insert("avalanche".to_string(), L2Network {
            name: "Avalanche".to_string(),
            chain_id: 43114,
            rpc_url: "https://api.avax.network/ext/bc/C/rpc".to_string(),
            ws_url: None,
            explorer_url: "https://snowtrace.io".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(1_100_000_000.0),
            volume_24h: Some(35_000_000.0),
            protocols: vec![
                "traderjoe".to_string(),
                "benqi".to_string(),
                "aave_v3".to_string(),
                "curve".to_string(),
            ],
            priority: 8,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Fantom
        networks.insert("fantom".to_string(), L2Network {
            name: "Fantom".to_string(),
            chain_id: 250,
            rpc_url: "https://rpc.ftm.tools".to_string(),
            ws_url: None,
            explorer_url: "https://ftmscan.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(85_000_000.0),
            volume_24h: Some(4_000_000.0),
            protocols: vec![
                "spookyswap".to_string(),
                "spiritswap".to_string(),
                "scream".to_string(),
            ],
            priority: 6,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === ARBITRUM ECOSYSTEM ===

        // Arbitrum Nova
        networks.insert("arbitrum_nova".to_string(), L2Network {
            name: "Arbitrum Nova".to_string(),
            chain_id: 42170,
            rpc_url: "https://nova.arbitrum.io/rpc".to_string(),
            ws_url: None,
            explorer_url: "https://nova.arbiscan.io".to_string(),
            category: L2Category::OptimisticRollup,
            technology: L2Technology::Arbitrum,
            tvl_usd: Some(15_000_000.0),
            volume_24h: Some(800_000.0),
            protocols: vec![
                "sushi".to_string(),
                "honeyswap".to_string(),
            ],
            priority: 5,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === POLYGON ECOSYSTEM ===

        // Polygon PoS
        networks.insert("polygon_pos".to_string(), L2Network {
            name: "Polygon PoS".to_string(),
            chain_id: 137,
            rpc_url: "https://polygon-rpc.com".to_string(),
            ws_url: None,
            explorer_url: "https://polygonscan.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Polygon,
            tvl_usd: Some(850_000_000.0),
            volume_24h: Some(45_000_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "quickswap".to_string(),
                "aave_v3".to_string(),
                "curve".to_string(),
                "balancer".to_string(),
                "sushiswap".to_string(),
            ],
            priority: 9,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === EMERGING ZK ROLLUPS ===

        // ConsenSys zkEVM
        networks.insert("consensys_zkevm".to_string(), L2Network {
            name: "ConsenSys zkEVM".to_string(),
            chain_id: 59140,
            rpc_url: "https://rpc.linea.build".to_string(),
            ws_url: None,
            explorer_url: "https://lineascan.build".to_string(),
            category: L2Category::ZKRollup,
            technology: L2Technology::ConsenSysZkEVM,
            tvl_usd: Some(25_000_000.0),
            volume_24h: Some(1_500_000.0),
            protocols: vec![
                "uniswap_v3".to_string(),
                "syncswap".to_string(),
            ],
            priority: 7,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === ADDITIONAL POPULAR NETWORKS ===

        // Cronos
        networks.insert("cronos".to_string(), L2Network {
            name: "Cronos".to_string(),
            chain_id: 25,
            rpc_url: "https://evm.cronos.org".to_string(),
            ws_url: None,
            explorer_url: "https://cronoscan.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(180_000_000.0),
            volume_24h: Some(8_000_000.0),
            protocols: vec![
                "vvs_finance".to_string(),
                "cronaswap".to_string(),
                "tectonic".to_string(),
            ],
            priority: 6,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Harmony
        networks.insert("harmony".to_string(), L2Network {
            name: "Harmony".to_string(),
            chain_id: 1666600000,
            rpc_url: "https://api.harmony.one".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.harmony.one".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(15_000_000.0),
            volume_24h: Some(800_000.0),
            protocols: vec![
                "sushi".to_string(),
                "defi_kingdoms".to_string(),
            ],
            priority: 4,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Celo
        networks.insert("celo".to_string(), L2Network {
            name: "Celo".to_string(),
            chain_id: 42220,
            rpc_url: "https://forno.celo.org".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.celo.org".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(45_000_000.0),
            volume_24h: Some(2_500_000.0),
            protocols: vec![
                "ubeswap".to_string(),
                "moola".to_string(),
            ],
            priority: 5,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Gnosis Chain
        networks.insert("gnosis".to_string(), L2Network {
            name: "Gnosis Chain".to_string(),
            chain_id: 100,
            rpc_url: "https://rpc.gnosischain.com".to_string(),
            ws_url: None,
            explorer_url: "https://gnosisscan.io".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(35_000_000.0),
            volume_24h: Some(1_500_000.0),
            protocols: vec![
                "honeyswap".to_string(),
                "agave".to_string(),
            ],
            priority: 5,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === GAMING & METAVERSE ===

        // Ronin
        networks.insert("ronin".to_string(), L2Network {
            name: "Ronin".to_string(),
            chain_id: 2020,
            rpc_url: "https://api.roninchain.com/rpc".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.roninchain.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(25_000_000.0),
            volume_24h: Some(1_200_000.0),
            protocols: vec![
                "katana".to_string(),
                "axie_infinity".to_string(),
            ],
            priority: 6,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // === ADDITIONAL NETWORKS FOR COMPREHENSIVE COVERAGE ===

        // Klaytn
        networks.insert("klaytn".to_string(), L2Network {
            name: "Klaytn".to_string(),
            chain_id: 8217,
            rpc_url: "https://public-node-api.klaytnapi.com/v1/cypress".to_string(),
            ws_url: None,
            explorer_url: "https://scope.klaytn.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(25_000_000.0),
            volume_24h: Some(1_500_000.0),
            protocols: vec![
                "klayswap".to_string(),
                "definix".to_string(),
            ],
            priority: 4,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // NEAR
        networks.insert("near".to_string(), L2Network {
            name: "NEAR".to_string(),
            chain_id: 1313161554,
            rpc_url: "https://rpc.mainnet.near.org".to_string(),
            ws_url: None,
            explorer_url: "https://explorer.near.org".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(15_000_000.0),
            volume_24h: Some(800_000.0),
            protocols: vec![
                "ref_finance".to_string(),
                "aurora".to_string(),
            ],
            priority: 4,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        // Solana (L1 but included for completeness)
        networks.insert("solana".to_string(), L2Network {
            name: "Solana".to_string(),
            chain_id: 101,
            rpc_url: "https://api.mainnet-beta.solana.com".to_string(),
            ws_url: Some("wss://api.mainnet-beta.solana.com".to_string()),
            explorer_url: "https://explorer.solana.com".to_string(),
            category: L2Category::Sidechain,
            technology: L2Technology::Custom,
            tvl_usd: Some(1_200_000_000.0),
            volume_24h: Some(85_000_000.0),
            protocols: vec![
                "raydium".to_string(),
                "orca".to_string(),
                "serum".to_string(),
                "saber".to_string(),
            ],
            priority: 8,
            sync_enabled: true,
            contract_addresses: HashMap::new(),
        });

        L2NetworkRegistry { networks }
    }

    pub fn get_network(&self, name: &str) -> Option<&L2Network> {
        self.networks.get(name)
    }

    pub fn get_all_networks(&self) -> &HashMap<String, L2Network> {
        &self.networks
    }

    pub fn get_networks_by_priority(&self, min_priority: u8) -> Vec<&L2Network> {
        self.networks
            .values()
            .filter(|network| network.priority >= min_priority)
            .collect()
    }

    pub fn get_networks_by_category(&self, category: &L2Category) -> Vec<&L2Network> {
        self.networks
            .values()
            .filter(|network| std::mem::discriminant(&network.category) == std::mem::discriminant(category))
            .collect()
    }

    pub fn get_networks_by_technology(&self, technology: &L2Technology) -> Vec<&L2Network> {
        self.networks
            .values()
            .filter(|network| std::mem::discriminant(&network.technology) == std::mem::discriminant(technology))
            .collect()
    }

    pub fn get_total_tvl(&self) -> f64 {
        self.networks
            .values()
            .filter_map(|network| network.tvl_usd)
            .sum()
    }

    pub fn get_total_volume_24h(&self) -> f64 {
        self.networks
            .values()
            .filter_map(|network| network.volume_24h)
            .sum()
    }
}
