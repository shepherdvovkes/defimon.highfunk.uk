use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{info, error, warn};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;
use crate::config::Config;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotBlockData {
    pub network: String,
    pub number: u64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub parent_hash: String,
    pub extrinsics: Vec<PolkadotExtrinsicData>,
    pub events: Vec<PolkadotEventData>,
    pub validator_set: Vec<PolkadotValidatorData>,
    pub total_issuance: Option<u128>,
    pub active_era: Option<u32>,
    pub session_index: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotExtrinsicData {
    pub hash: String,
    pub block_number: u64,
    pub index: u32,
    pub call_module: String,
    pub call_function: String,
    pub params: serde_json::Value,
    pub signer: Option<String>,
    pub fee: Option<u128>,
    pub success: bool,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotEventData {
    pub block_number: u64,
    pub extrinsic_index: Option<u32>,
    pub event_index: u32,
    pub module: String,
    pub event: String,
    pub params: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotValidatorData {
    pub address: String,
    pub stash_address: String,
    pub controller_address: String,
    pub commission: Option<u32>, // percentage * 10000
    pub bonded_amount: Option<u128>,
    pub total_stake: Option<u128>,
    pub is_active: bool,
    pub is_offline: bool,
    pub era_points: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PolkadotNetworkInfo {
    pub name: String,
    pub chain_id: String,
    pub rpc_url: String,
    pub ws_url: String,
    pub explorer_url: String,
    pub token_symbol: String,
    pub decimals: u8,
    pub priority: u8,
    pub enabled: bool,
}

pub struct PolkadotSyncManager {
    config: Config,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    networks: Vec<PolkadotNetworkInfo>,
    last_processed_blocks: std::collections::HashMap<String, u64>,
}

impl PolkadotSyncManager {
    pub fn new(
        config: Config,
        db_manager: Arc<DatabaseManager>,
        kafka_producer: Arc<KafkaProducer>,
        metrics_collector: Arc<MetricsCollector>,
    ) -> Self {
        let networks = Self::initialize_networks(&config);
        
        Self {
            config,
            db_manager,
            kafka_producer,
            metrics_collector,
            networks,
            last_processed_blocks: std::collections::HashMap::new(),
        }
    }

    fn initialize_networks(config: &Config) -> Vec<PolkadotNetworkInfo> {
        let mut networks = Vec::new();
        
        // Polkadot Relay Chain
        networks.push(PolkadotNetworkInfo {
            name: "polkadot".to_string(),
            chain_id: "polkadot".to_string(),
            rpc_url: "https://rpc.polkadot.io".to_string(),
            ws_url: "wss://rpc.polkadot.io".to_string(),
            explorer_url: "https://polkascan.io/polkadot".to_string(),
            token_symbol: "DOT".to_string(),
            decimals: 10,
            priority: 10,
            enabled: true,
        });

        // Kusama Relay Chain
        networks.push(PolkadotNetworkInfo {
            name: "kusama".to_string(),
            chain_id: "kusama".to_string(),
            rpc_url: "https://kusama-rpc.polkadot.io".to_string(),
            ws_url: "wss://kusama-rpc.polkadot.io".to_string(),
            explorer_url: "https://polkascan.io/kusama".to_string(),
            token_symbol: "KSM".to_string(),
            decimals: 12,
            priority: 9,
            enabled: true,
        });

        // Westend Testnet
        networks.push(PolkadotNetworkInfo {
            name: "westend".to_string(),
            chain_id: "westend".to_string(),
            rpc_url: "https://westend-rpc.polkadot.io".to_string(),
            ws_url: "wss://westend-rpc.polkadot.io".to_string(),
            explorer_url: "https://polkascan.io/westend".to_string(),
            token_symbol: "WND".to_string(),
            decimals: 12,
            priority: 5,
            enabled: true,
        });

        // Rococo Testnet
        networks.push(PolkadotNetworkInfo {
            name: "rococo".to_string(),
            chain_id: "rococo".to_string(),
            rpc_url: "https://rococo-rpc.polkadot.io".to_string(),
            ws_url: "wss://rococo-rpc.polkadot.io".to_string(),
            explorer_url: "https://polkascan.io/rococo".to_string(),
            token_symbol: "ROC".to_string(),
            decimals: 12,
            priority: 4,
            enabled: true,
        });

        // Filter networks based on config
        networks.retain(|network| {
            config.polkadot_networks.contains(&network.name) && network.enabled
        });

        networks
    }

    pub async fn start_sync(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting Polkadot sync for {} networks", self.networks.len());

        for network in &self.networks {
            if network.priority >= self.config.polkadot_priority_threshold {
                info!("Starting sync for {} (priority: {})", network.name, network.priority);
                self.sync_network(network).await?;
            }
        }

        Ok(())
    }

    async fn sync_network(&mut self, network: &PolkadotNetworkInfo) -> Result<(), Box<dyn std::error::Error>> {
        let last_block = self.last_processed_blocks.get(&network.name).unwrap_or(&0);
        
        // Get latest block number
        let latest_block = self.get_latest_block_number(network).await?;
        
        if latest_block <= *last_block {
            info!("Network {} is up to date (block: {})", network.name, latest_block);
            return Ok(());
        }

        let start_block = *last_block + 1;
        let end_block = std::cmp::min(start_block + self.config.polkadot_batch_size as u64, latest_block);

        info!("Syncing {} from block {} to {}", network.name, start_block, end_block);

        for block_number in start_block..=end_block {
            match self.fetch_block(network, block_number).await {
                Ok(block_data) => {
                    self.process_block(block_data).await?;
                    self.last_processed_blocks.insert(network.name.clone(), block_number);
                }
                Err(e) => {
                    error!("Failed to fetch block {} from {}: {}", block_number, network.name, e);
                }
            }
        }

        Ok(())
    }

    async fn get_latest_block_number(&self, network: &PolkadotNetworkInfo) -> Result<u64, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let response: serde_json::Value = client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "chain_getHeader",
                "params": [],
                "id": 1
            }))
            .send()
            .await?
            .json()
            .await?;

        let block_number = response["result"]["number"]
            .as_str()
            .ok_or("Invalid response format")?
            .parse::<u64>()?;

        Ok(block_number)
    }

    async fn fetch_block(&self, network: &PolkadotNetworkInfo, block_number: u64) -> Result<PolkadotBlockData, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        
        // Get block hash
        let hash_response: serde_json::Value = client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "chain_getBlockHash",
                "params": [block_number],
                "id": 1
            }))
            .send()
            .await?
            .json()
            .await?;

        let block_hash = hash_response["result"]
            .as_str()
            .ok_or("Invalid block hash response")?;

        // Get block details
        let block_response: serde_json::Value = client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "chain_getBlock",
                "params": [block_hash],
                "id": 1
            }))
            .send()
            .await?
            .json()
            .await?;

        let block = &block_response["result"]["block"];
        let header = &block["header"];
        
        // Get events for this block
        let events = self.fetch_events(network, block_hash).await?;
        
        // Get validators for this block
        let validators = self.fetch_validators(network, block_number).await?;

        // Parse extrinsics
        let extrinsics = self.parse_extrinsics(network, block_number, &block["extrinsics"]).await?;

        Ok(PolkadotBlockData {
            network: network.name.clone(),
            number: block_number,
            hash: block_hash.to_string(),
            timestamp: Utc::now(), // Would need to get from block timestamp
            parent_hash: header["parentHash"].as_str().unwrap_or("").to_string(),
            extrinsics,
            events,
            validator_set: validators,
            total_issuance: None, // Would need additional API call
            active_era: None,      // Would need additional API call
            session_index: None,   // Would need additional API call
        })
    }

    async fn fetch_events(&self, network: &PolkadotNetworkInfo, block_hash: &str) -> Result<Vec<PolkadotEventData>, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let response: serde_json::Value = client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "state_getEvents",
                "params": [block_hash],
                "id": 1
            }))
            .send()
            .await?
            .json()
            .await?;

        let mut events = Vec::new();
        if let Some(events_array) = response["result"].as_array() {
            for (i, event) in events_array.iter().enumerate() {
                events.push(PolkadotEventData {
                    block_number: 0, // Would need to get from context
                    extrinsic_index: None, // Would need to parse from event
                    event_index: i as u32,
                    module: event["phase"]["Extrinsic"].as_u64().map(|_| "System".to_string()).unwrap_or_default(),
                    event: "Event".to_string(), // Would need to decode event
                    params: event.clone(),
                });
            }
        }

        Ok(events)
    }

    async fn fetch_validators(&self, network: &PolkadotNetworkInfo, block_number: u64) -> Result<Vec<PolkadotValidatorData>, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let response: serde_json::Value = client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "state_getValidators",
                "params": [block_number],
                "id": 1
            }))
            .send()
            .await?
            .json()
            .await?;

        let mut validators = Vec::new();
        if let Some(validators_array) = response["result"].as_array() {
            for validator in validators_array {
                validators.push(PolkadotValidatorData {
                    address: validator["accountId"].as_str().unwrap_or("").to_string(),
                    stash_address: validator["stash"].as_str().unwrap_or("").to_string(),
                    controller_address: validator["controller"].as_str().unwrap_or("").to_string(),
                    commission: validator["commission"].as_u64().map(|c| c as u32),
                    bonded_amount: validator["bonded"].as_str().and_then(|s| s.parse().ok()),
                    total_stake: validator["totalStake"].as_str().and_then(|s| s.parse().ok()),
                    is_active: validator["isActive"].as_bool().unwrap_or(false),
                    is_offline: validator["isOffline"].as_bool().unwrap_or(false),
                    era_points: validator["eraPoints"].as_u64().map(|p| p as u32),
                });
            }
        }

        Ok(validators)
    }

    async fn parse_extrinsics(
        &self,
        network: &PolkadotNetworkInfo,
        block_number: u64,
        extrinsics: &serde_json::Value,
    ) -> Result<Vec<PolkadotExtrinsicData>, Box<dyn std::error::Error>> {
        let mut parsed_extrinsics = Vec::new();
        
        if let Some(extrinsics_array) = extrinsics.as_array() {
            for (i, extrinsic) in extrinsics_array.iter().enumerate() {
                // Decode extrinsic (simplified)
                let extrinsic_data = PolkadotExtrinsicData {
                    hash: format!("extrinsic_{}_{}", block_number, i),
                    block_number,
                    index: i as u32,
                    call_module: "Unknown".to_string(), // Would need to decode
                    call_function: "Unknown".to_string(), // Would need to decode
                    params: extrinsic.clone(),
                    signer: None, // Would need to decode
                    fee: None,    // Would need to calculate
                    success: true, // Would need to check events
                    error: None,
                };
                
                parsed_extrinsics.push(extrinsic_data);
            }
        }

        Ok(parsed_extrinsics)
    }

    async fn process_block(&self, block_data: PolkadotBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Store in database
        self.store_block_data(&block_data).await?;

        // Send to Kafka
        self.send_to_kafka(&block_data).await?;

        // Update metrics
        self.update_metrics(&block_data).await?;

        info!("Processed block {} from {}", block_data.number, block_data.network);
        Ok(())
    }

    async fn store_block_data(&self, block_data: &PolkadotBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Implementation for storing to PostgreSQL
        // This would include storing blocks, extrinsics, events, and validator data
        Ok(())
    }

    async fn send_to_kafka(&self, block_data: &PolkadotBlockData) -> Result<(), Box<dyn std::error::Error>> {
        let topic = format!("polkadot.blocks.{}", block_data.network);
        let message = serde_json::to_string(block_data)?;
        self.kafka_producer.send_message(&topic, &message).await?;
        Ok(())
    }

    async fn update_metrics(&self, block_data: &PolkadotBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Update Prometheus metrics
        self.metrics_collector.increment_counter(
            "polkadot_blocks_processed_total",
            &[("network", &block_data.network)],
        );

        self.metrics_collector.set_gauge(
            "polkadot_latest_block_number",
            block_data.number as f64,
            &[("network", &block_data.network)],
        );

        Ok(())
    }
}
