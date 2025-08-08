use std::collections::HashMap;

use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct NetworkRegistry {
    modules: HashMap<String, Box<dyn NetworkModule>>, // key -> module
}

impl NetworkRegistry {
    pub fn new() -> Self {
        Self { modules: HashMap::new() }
    }

    pub fn clone(&self) -> Self {
        // Create a new registry with the same modules
        let mut new_registry = Self::new();
        for (key, module) in &self.modules {
            // We can't clone the trait object, so we'll create a new SimpleModule
            let desc = module.descriptor().clone();
            new_registry.modules.insert(key.clone(), Box::new(SimpleModule { desc }));
        }
        new_registry
    }

    pub fn register(&mut self, module: Box<dyn NetworkModule>) {
        let key = module.descriptor().key.clone();
        self.modules.insert(key, module);
    }

    pub fn get(&self, key: &str) -> Option<&Box<dyn NetworkModule>> {
        self.modules.get(key)
    }

    pub fn len(&self) -> usize { self.modules.len() }

    pub fn list(&self) -> impl Iterator<Item = (&String, &Box<dyn NetworkModule>)> { self.modules.iter() }

    pub fn new_default() -> Self {
        let mut registry = Self::new();

        // Tier 1 EVM L1 + L2 skeletons (first ~40 targets)
        let tier1 = vec![
            ("ethereum", "Ethereum", NetworkRuntime::Evm, NetworkCategory::Layer1, Some(1u64)),
            ("arbitrum_one", "Arbitrum One", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(42161u64)),
            ("base", "Base", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(8453u64)),
            ("op_mainnet", "OP Mainnet", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(10u64)),
            ("blast", "Blast", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("mantle", "Mantle", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(5000u64)),
            ("mode", "Mode", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("world_chain", "World Chain", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("opbnb", "opBNB", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(204u64)),
            ("metis", "Metis", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(1088u64)),
            ("boba", "Boba", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(288u64)),
            ("starknet", "Starknet", NetworkRuntime::Starknet, NetworkCategory::EthereumLayer2, None),
            ("zksync_era", "zkSync Era", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(324u64)),
            ("linea", "Linea", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(59144u64)),
            ("scroll", "Scroll", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(534352u64)),
            ("polygon_zkevm", "Polygon zkEVM", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(1101u64)),
            // Additional major EVM L1s and sidechains
            ("bsc_mainnet", "BNB Smart Chain", NetworkRuntime::Evm, NetworkCategory::Layer1, Some(56u64)),
            ("avalanche_c", "Avalanche C-Chain", NetworkRuntime::Evm, NetworkCategory::Layer1, Some(43114u64)),
            ("polygon_pos", "Polygon PoS", NetworkRuntime::Evm, NetworkCategory::Layer1, Some(137u64)),
            ("fantom", "Fantom", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(250u64)),
            ("cronos", "Cronos", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(25u64)),
            ("gnosis", "Gnosis Chain", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(100u64)),
            ("celo", "Celo", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(42220u64)),
            ("klaytn", "Klaytn", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(8217u64)),
            ("moonbeam", "Moonbeam", NetworkRuntime::Evm, NetworkCategory::Polkadot, Some(1284u64)),
            ("moonriver", "Moonriver", NetworkRuntime::Evm, NetworkCategory::Polkadot, Some(1285u64)),
            ("harmony", "Harmony", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(1666600000u64)),
            ("okx_xlayer", "OKX X Layer", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("taiko", "Taiko", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("immutable_zkevm", "Immutable zkEVM", NetworkRuntime::Evm, NetworkCategory::Specialized, None),
            ("kroma", "Kroma", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("sophon", "Sophon", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("apecoin_apechain", "ApeChain", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("zircuit", "Zircuit", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("flare", "Flare", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(14u64)),
            ("meter", "Meter", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(82u64)),
            ("syscoin", "Syscoin", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(57u64)),
            ("telos", "Telos EVM", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(40u64)),
            ("core", "CORE", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
            ("bitlayer", "BitLayer", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
            ("merlin", "Merlin", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
        ];

        // Next 40 EVM-compatible networks
        let more_evm: Vec<(&str, &str, NetworkRuntime, NetworkCategory, Option<u64>)> = vec![
            ("aurora", "Aurora", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(1313161554)),
            ("evmos", "Evmos", NetworkRuntime::Evm, NetworkCategory::Cosmos, Some(9001)),
            ("kava_evm", "Kava EVM", NetworkRuntime::Evm, NetworkCategory::Cosmos, Some(2222)),
            ("canto", "Canto", NetworkRuntime::Evm, NetworkCategory::Cosmos, Some(7700)),
            ("oasis_emerald", "Oasis Emerald", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(42262)),
            ("astar", "Astar", NetworkRuntime::Evm, NetworkCategory::Polkadot, Some(592)),
            ("shiden", "Shiden", NetworkRuntime::Evm, NetworkCategory::Polkadot, Some(336)),
            ("reef", "Reef", NetworkRuntime::Evm, NetworkCategory::Polkadot, Some(13939)),
            ("fuse", "Fuse", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(122)),
            ("iotex", "IoTeX", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(4689)),
            ("heco", "HECO", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(128)),
            ("okc", "OKC", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(66)),
            ("kcc", "KCC", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(321)),
            ("palm", "Palm", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(11297108109)),
            ("etc", "Ethereum Classic", NetworkRuntime::Evm, NetworkCategory::Layer1, Some(61)),
            ("callisto", "Callisto", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(820)),
            ("smartbch", "SmartBCH", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(10000)),
            ("nahmii", "Nahmii", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("bttc", "BitTorrent Chain", NetworkRuntime::Evm, NetworkCategory::CrossChain, Some(199)),
            ("conflux_espace", "Conflux eSpace", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(1030)),
            ("zklink_nova", "zkLink Nova", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("zora", "Zora", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(7777777)),
            ("pgn", "Public Goods Network", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(424)),
            ("redstone_l2", "Redstone L2", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("fraxchain", "Fraxchain (Fraxtal)", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("metal_l2", "Metal L2", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("ancient8", "Ancient8", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("xai", "Xai", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("treasure", "Treasure", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("beam_evm", "Beam", NetworkRuntime::Evm, NetworkCategory::Specialized, None),
            ("dfk_chain", "DeFi Kingdoms Chain", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(53935)),
            ("songbird", "Songbird", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(19)),
            ("shibarium", "Shibarium", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(109)),
            ("pulsechain", "PulseChain", NetworkRuntime::Evm, NetworkCategory::Alternative, Some(369)),
            ("rootstock", "Rootstock", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, Some(30)),
            ("bob", "BOB", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
            ("bevm", "BEVM", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
            ("bsquared", "B² Network", NetworkRuntime::Evm, NetworkCategory::BitcoinLayer2, None),
            ("zkfair", "zkFair", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, None),
            ("manta_pacific", "Manta Pacific", NetworkRuntime::Evm, NetworkCategory::EthereumLayer2, Some(169)),
        ];

        for (key, name, runtime, category, chain_id) in more_evm {
            let mut desc = NetworkDescriptor::new(key, name, runtime, category);
            desc.chain_id = chain_id;
            desc.priority = 8;
            registry.register(Box::new(SimpleModule { desc }));
        }

        for (key, name, runtime, category, chain_id) in tier1 {
            let mut desc = NetworkDescriptor::new(key, name, runtime, category);
            desc.chain_id = chain_id;
            desc.priority = 10;
            // Keep RPC empty to rely on env / per-module defaults
            registry.register(Box::new(SimpleModule { desc }));
        }

        // Solana, Bitcoin, Cosmos scaffolds
        let others = vec![
            ("solana", "Solana", NetworkRuntime::Solana, NetworkCategory::Alternative),
            ("bitcoin", "Bitcoin", NetworkRuntime::Bitcoin, NetworkCategory::Alternative),
            ("bsc_mainnet", "BNB Smart Chain", NetworkRuntime::Evm, NetworkCategory::Layer1),
            ("tron", "Tron", NetworkRuntime::Other, NetworkCategory::Layer1),
            ("avalanche_c", "Avalanche C-Chain", NetworkRuntime::Evm, NetworkCategory::Layer1),
            ("polygon_pos", "Polygon PoS", NetworkRuntime::Evm, NetworkCategory::Layer1),
            ("cosmos_hub", "Cosmos Hub", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("osmosis", "Osmosis", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("injective", "Injective", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("celestia", "Celestia", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("sei", "Sei Network", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("neutron", "Neutron", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("stride", "Stride", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("quicksilver", "Quicksilver", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("persistence", "Persistence", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("agoric", "Agoric", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("evmos", "Evmos", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("kava", "Kava", NetworkRuntime::Cosmos, NetworkCategory::Cosmos),
            ("polkadot", "Polkadot", NetworkRuntime::Substrate, NetworkCategory::Polkadot),
            ("moonbeam", "Moonbeam", NetworkRuntime::Substrate, NetworkCategory::Polkadot),
        ];
        for (key, name, runtime, category) in others {
            let mut desc = NetworkDescriptor::new(key, name, runtime, category);
            desc.priority = 8;
            registry.register(Box::new(SimpleModule { desc }));
        }

        registry
    }

    pub fn new_from_env_or_default() -> Self {
        let mut registry = Self::new_default();

        // Helper to register from comma-separated env list
        let mut register_list = |env_key: &str, runtime: NetworkRuntime, category: NetworkCategory, default_list: Option<&str>| {
            let raw = std::env::var(env_key).ok().or(default_list.map(|s| s.to_string()));
            if let Some(list) = raw {
                for key in list.split(',').map(|s| s.trim()).filter(|s| !s.is_empty()) {
                    if registry.modules.contains_key(key) { continue; }
                    let mut desc = NetworkDescriptor::new(key, key, runtime.clone(), category.clone());
                    // Optional chain id
                    let cid_key = format!("CHAIN_ID_{}", key.to_uppercase().replace(['-', ' '], "_"));
                    if let Ok(cid) = std::env::var(&cid_key) { if let Ok(v) = cid.parse::<u64>() { desc.chain_id = Some(v); } }
                    // Optional RPC URL
                    let rpc_key = format!("RPC_URL_{}", key.to_uppercase().replace(['-', ' '], "_"));
                    if let Ok(url) = std::env::var(&rpc_key) { if !url.is_empty() { desc.rpc_url = Some(url); } }
                    // Optional Explorer URL
                    let exp_key = format!("EXPLORER_URL_{}", key.to_uppercase().replace(['-', ' '], "_"));
                    if let Ok(url) = std::env::var(&exp_key) { if !url.is_empty() { desc.explorer_url = Some(url); } }
                    // Optional Priority
                    let prio_key = format!("PRIORITY_{}", key.to_uppercase().replace(['-', ' '], "_"));
                    if let Ok(p) = std::env::var(&prio_key) { if let Ok(v) = p.parse::<u8>() { desc.priority = v; } }

                    registry.register(Box::new(SimpleModule { desc }));
                }
            }
        };

        // Use env-provided lists to add any networks not hardcoded
        register_list("EVM_NETWORKS", NetworkRuntime::Evm, NetworkCategory::Alternative, None);
        register_list("COSMOS_NETWORKS", NetworkRuntime::Cosmos, NetworkCategory::Cosmos, None);
        register_list("SUBSTRATE_NETWORKS", NetworkRuntime::Substrate, NetworkCategory::Polkadot, None);
        register_list("BITCOIN_NETWORKS", NetworkRuntime::Bitcoin, NetworkCategory::BitcoinLayer2, None);
        register_list("SOLANA_NETWORKS", NetworkRuntime::Solana, NetworkCategory::Alternative, None);
        register_list("STARKNET_NETWORKS", NetworkRuntime::Starknet, NetworkCategory::EthereumLayer2, None);
        register_list("MOVEVM_NETWORKS", NetworkRuntime::MoveVm, NetworkCategory::Alternative, None);

        registry
    }
}

struct SimpleModule { desc: NetworkDescriptor }

impl NetworkModule for SimpleModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


