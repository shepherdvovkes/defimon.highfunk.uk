use std::sync::Arc;

use serde::{Deserialize, Serialize};

use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum NetworkRuntime {
    Evm,
    Cosmos,
    Substrate,
    Bitcoin,
    Solana,
    Starknet,
    MoveVm,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum NetworkCategory {
    Layer1,
    EthereumLayer2,
    BitcoinLayer2,
    Specialized,
    Cosmos,
    Polkadot,
    Alternative,
    CrossChain,
    Enterprise,
    Testing,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkDescriptor {
    pub key: String,
    pub name: String,
    pub chain_id: Option<u64>,
    pub rpc_url: Option<String>,
    pub ws_url: Option<String>,
    pub explorer_url: Option<String>,
    pub runtime: NetworkRuntime,
    pub category: NetworkCategory,
    pub priority: u8, // 1-10
    pub enabled: bool,
}

impl NetworkDescriptor {
    pub fn new(
        key: impl Into<String>,
        name: impl Into<String>,
        runtime: NetworkRuntime,
        category: NetworkCategory,
    ) -> Self {
        Self {
            key: key.into(),
            name: name.into(),
            chain_id: None,
            rpc_url: None,
            ws_url: None,
            explorer_url: None,
            runtime,
            category,
            priority: 5,
            enabled: true,
        }
    }
}

#[derive(Clone)]
pub struct NetworkContext {
    pub db_manager: Arc<DatabaseManager>,
    pub kafka_producer: Arc<KafkaProducer>,
    pub metrics: Arc<MetricsCollector>,
}

pub trait NetworkModule: Send + Sync {
    fn descriptor(&self) -> &NetworkDescriptor;
}


