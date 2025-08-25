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
pub struct CosmosBlockData {
    pub network: String,
    pub height: u64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub proposer: String,
    pub transactions: Vec<CosmosTransactionData>,
    pub validators: Vec<CosmosValidatorData>,
    pub inflation_rate: Option<f64>,
    pub bonded_tokens: Option<u64>,
    pub total_supply: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosTransactionData {
    pub hash: String,
    pub height: u64,
    pub fee: CosmosFee,
    pub gas_used: u64,
    pub gas_wanted: u64,
    pub memo: Option<String>,
    pub messages: Vec<CosmosMessage>,
    pub result: CosmosTxResult,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosFee {
    pub amount: Vec<CosmosCoin>,
    pub gas: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosCoin {
    pub denom: String,
    pub amount: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosMessage {
    pub type_url: String,
    pub value: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosTxResult {
    pub code: u32,
    pub log: Option<String>,
    pub gas_wanted: String,
    pub gas_used: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosValidatorData {
    pub address: String,
    pub voting_power: u64,
    pub commission_rate: Option<f64>,
    pub jailed: bool,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CosmosNetworkInfo {
    pub name: String,
    pub chain_id: String,
    pub rpc_url: String,
    pub rest_url: String,
    pub explorer_url: String,
    pub bech32_prefix: String,
    pub coin_denom: String,
    pub min_gas_price: f64,
    pub priority: u8,
    pub enabled: bool,
}

pub struct CosmosSyncManager {
    config: Config,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    networks: Vec<CosmosNetworkInfo>,
    last_processed_heights: std::collections::HashMap<String, u64>,
}

impl CosmosSyncManager {
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
            last_processed_heights: std::collections::HashMap::new(),
        }
    }

    fn initialize_networks(config: &Config) -> Vec<CosmosNetworkInfo> {
        let mut networks = Vec::new();
        
        // Cosmos Hub
        networks.push(CosmosNetworkInfo {
            name: "cosmos_hub".to_string(),
            chain_id: "cosmoshub-4".to_string(),
            rpc_url: "https://rpc.cosmos.network:26657".to_string(),
            rest_url: "https://api.cosmos.network".to_string(),
            explorer_url: "https://www.mintscan.io/cosmos".to_string(),
            bech32_prefix: "cosmos".to_string(),
            coin_denom: "uatom".to_string(),
            min_gas_price: 0.025,
            priority: 10,
            enabled: true,
        });

        // Osmosis
        networks.push(CosmosNetworkInfo {
            name: "osmosis".to_string(),
            chain_id: "osmosis-1".to_string(),
            rpc_url: "https://rpc.osmosis.zone:26657".to_string(),
            rest_url: "https://api.osmosis.zone".to_string(),
            explorer_url: "https://www.mintscan.io/osmosis".to_string(),
            bech32_prefix: "osmo".to_string(),
            coin_denom: "uosmo".to_string(),
            min_gas_price: 0.025,
            priority: 9,
            enabled: true,
        });

        // Injective
        networks.push(CosmosNetworkInfo {
            name: "injective".to_string(),
            chain_id: "injective-1".to_string(),
            rpc_url: "https://rpc.injective.network:26657".to_string(),
            rest_url: "https://api.injective.network".to_string(),
            explorer_url: "https://www.mintscan.io/injective".to_string(),
            bech32_prefix: "inj".to_string(),
            coin_denom: "uinj".to_string(),
            min_gas_price: 0.025,
            priority: 8,
            enabled: true,
        });

        // Celestia
        networks.push(CosmosNetworkInfo {
            name: "celestia".to_string(),
            chain_id: "celestia".to_string(),
            rpc_url: "https://rpc.celestia.nodestake.top:26657".to_string(),
            rest_url: "https://api.celestia.nodestake.top".to_string(),
            explorer_url: "https://www.mintscan.io/celestia".to_string(),
            bech32_prefix: "celestia".to_string(),
            coin_denom: "utia".to_string(),
            min_gas_price: 0.025,
            priority: 8,
            enabled: true,
        });

        // Sei Network
        networks.push(CosmosNetworkInfo {
            name: "sei".to_string(),
            chain_id: "sei-1".to_string(),
            rpc_url: "https://rpc.sei.io:26657".to_string(),
            rest_url: "https://api.sei.io".to_string(),
            explorer_url: "https://www.mintscan.io/sei".to_string(),
            bech32_prefix: "sei".to_string(),
            coin_denom: "usei".to_string(),
            min_gas_price: 0.025,
            priority: 7,
            enabled: true,
        });

        // Neutron
        networks.push(CosmosNetworkInfo {
            name: "neutron".to_string(),
            chain_id: "neutron-1".to_string(),
            rpc_url: "https://rpc.neutron.org:26657".to_string(),
            rest_url: "https://api.neutron.org".to_string(),
            explorer_url: "https://www.mintscan.io/neutron".to_string(),
            bech32_prefix: "neutron".to_string(),
            coin_denom: "untrn".to_string(),
            min_gas_price: 0.025,
            priority: 7,
            enabled: true,
        });

        // Stride
        networks.push(CosmosNetworkInfo {
            name: "stride".to_string(),
            chain_id: "stride-1".to_string(),
            rpc_url: "https://rpc.stride.zone:26657".to_string(),
            rest_url: "https://api.stride.zone".to_string(),
            explorer_url: "https://www.mintscan.io/stride".to_string(),
            bech32_prefix: "stride".to_string(),
            coin_denom: "ustrd".to_string(),
            min_gas_price: 0.025,
            priority: 6,
            enabled: true,
        });

        // Quicksilver
        networks.push(CosmosNetworkInfo {
            name: "quicksilver".to_string(),
            chain_id: "quicksilver-2".to_string(),
            rpc_url: "https://rpc.quicksilver.zone:26657".to_string(),
            rest_url: "https://api.quicksilver.zone".to_string(),
            explorer_url: "https://www.mintscan.io/quicksilver".to_string(),
            bech32_prefix: "quick".to_string(),
            coin_denom: "uqck".to_string(),
            min_gas_price: 0.025,
            priority: 6,
            enabled: true,
        });

        // Persistence
        networks.push(CosmosNetworkInfo {
            name: "persistence".to_string(),
            chain_id: "core-1".to_string(),
            rpc_url: "https://rpc.core.persistence.one:26657".to_string(),
            rest_url: "https://api.core.persistence.one".to_string(),
            explorer_url: "https://www.mintscan.io/persistence".to_string(),
            bech32_prefix: "persistence".to_string(),
            coin_denom: "uxprt".to_string(),
            min_gas_price: 0.025,
            priority: 6,
            enabled: true,
        });

        // Agoric
        networks.push(CosmosNetworkInfo {
            name: "agoric".to_string(),
            chain_id: "agoric-3".to_string(),
            rpc_url: "https://rpc.agoric.net:26657".to_string(),
            rest_url: "https://api.agoric.net".to_string(),
            explorer_url: "https://www.mintscan.io/agoric".to_string(),
            bech32_prefix: "agoric".to_string(),
            coin_denom: "ubld".to_string(),
            min_gas_price: 0.025,
            priority: 5,
            enabled: true,
        });

        // Evmos
        networks.push(CosmosNetworkInfo {
            name: "evmos".to_string(),
            chain_id: "evmos_9001-2".to_string(),
            rpc_url: "https://rpc.evmos.org:26657".to_string(),
            rest_url: "https://api.evmos.org".to_string(),
            explorer_url: "https://www.mintscan.io/evmos".to_string(),
            bech32_prefix: "evmos".to_string(),
            coin_denom: "aevmos".to_string(),
            min_gas_price: 0.025,
            priority: 7,
            enabled: true,
        });

        // Kava
        networks.push(CosmosNetworkInfo {
            name: "kava".to_string(),
            chain_id: "kava_2222-10".to_string(),
            rpc_url: "https://rpc.kava.io:26657".to_string(),
            rest_url: "https://api.kava.io".to_string(),
            explorer_url: "https://www.mintscan.io/kava".to_string(),
            bech32_prefix: "kava".to_string(),
            coin_denom: "ukava".to_string(),
            min_gas_price: 0.025,
            priority: 6,
            enabled: true,
        });

        // Filter networks based on config
        networks.retain(|network| {
            config.cosmos_networks.contains(&network.name) && network.enabled
        });

        networks
    }

    pub async fn start_sync(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting Cosmos sync for {} networks", self.networks.len());

        for network in &self.networks {
            if network.priority >= self.config.cosmos_priority_threshold {
                info!("Starting sync for {} (priority: {})", network.name, network.priority);
                self.sync_network(network).await?;
            }
        }

        Ok(())
    }

    async fn sync_network(&mut self, network: &CosmosNetworkInfo) -> Result<(), Box<dyn std::error::Error>> {
        let last_height = self.last_processed_heights.get(&network.name).unwrap_or(&0);
        
        // Get latest block height
        let latest_height = self.get_latest_height(network).await?;
        
        if latest_height <= *last_height {
            info!("Network {} is up to date (height: {})", network.name, latest_height);
            return Ok(());
        }

        let start_height = *last_height + 1;
        let end_height = std::cmp::min(start_height + self.config.cosmos_batch_size as u64, latest_height);

        info!("Syncing {} from height {} to {}", network.name, start_height, end_height);

        for height in start_height..=end_height {
            match self.fetch_block(network, height).await {
                Ok(block_data) => {
                    self.process_block(block_data).await?;
                    self.last_processed_heights.insert(network.name.clone(), height);
                }
                Err(e) => {
                    error!("Failed to fetch block {} from {}: {}", height, network.name, e);
                }
            }
        }

        Ok(())
    }

    async fn get_latest_height(&self, network: &CosmosNetworkInfo) -> Result<u64, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let response: serde_json::Value = client
            .get(&format!("{}/status", network.rpc_url))
            .send()
            .await?
            .json()
            .await?;

        let height = response["result"]["sync_info"]["latest_block_height"]
            .as_str()
            .ok_or("Invalid response format")?
            .parse::<u64>()?;

        Ok(height)
    }

    async fn fetch_block(&self, network: &CosmosNetworkInfo, height: u64) -> Result<CosmosBlockData, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        
        // Fetch block
        let block_response: serde_json::Value = client
            .get(&format!("{}/block?height={}", network.rpc_url, height))
            .send()
            .await?
            .json()
            .await?;

        // Fetch block results
        let results_response: serde_json::Value = client
            .get(&format!("{}/block_results?height={}", network.rpc_url, height))
            .send()
            .await?
            .json()
            .await?;

        let block = &block_response["result"]["block"];
        let block_header = &block["header"];
        
        let timestamp_str = block_header["time"]
            .as_str()
            .ok_or("Missing timestamp")?;
        let timestamp = DateTime::parse_from_rfc3339(timestamp_str)?.with_timezone(&Utc);

        let mut transactions = Vec::new();
        if let Some(txs) = block["data"]["txs"].as_array() {
            for (i, tx) in txs.iter().enumerate() {
                if let Some(tx_result) = results_response["result"]["txs_results"].get(i) {
                    let tx_data = self.parse_transaction(network, height, tx, tx_result)?;
                    transactions.push(tx_data);
                }
            }
        }

        let validators = self.fetch_validators(network).await?;

        Ok(CosmosBlockData {
            network: network.name.clone(),
            height,
            hash: block_header["last_block_id"]["hash"].as_str().unwrap_or("").to_string(),
            timestamp,
            proposer: block_header["proposer_address"].as_str().unwrap_or("").to_string(),
            transactions,
            validators,
            inflation_rate: None, // Would need additional API call
            bonded_tokens: None,  // Would need additional API call
            total_supply: None,   // Would need additional API call
        })
    }

    async fn fetch_validators(&self, network: &CosmosNetworkInfo) -> Result<Vec<CosmosValidatorData>, Box<dyn std::error::Error>> {
        let client = reqwest::Client::new();
        let response: serde_json::Value = client
            .get(&format!("{}/validators", network.rest_url))
            .send()
            .await?
            .json()
            .await?;

        let mut validators = Vec::new();
        if let Some(validators_array) = response["validators"].as_array() {
            for validator in validators_array {
                validators.push(CosmosValidatorData {
                    address: validator["operator_address"].as_str().unwrap_or("").to_string(),
                    voting_power: validator["tokens"].as_str().unwrap_or("0").parse().unwrap_or(0),
                    commission_rate: validator["commission"]["commission_rates"]["rate"]
                        .as_str()
                        .and_then(|s| s.parse().ok()),
                    jailed: validator["jailed"].as_bool().unwrap_or(false),
                    status: validator["status"].as_str().unwrap_or("").to_string(),
                });
            }
        }

        Ok(validators)
    }

    fn parse_transaction(
        &self,
        network: &CosmosNetworkInfo,
        height: u64,
        tx: &serde_json::Value,
        tx_result: &serde_json::Value,
    ) -> Result<CosmosTransactionData, Box<dyn std::error::Error>> {
        // Decode base64 transaction
        let tx_bytes = base64::decode(tx.as_str().unwrap_or(""))?;
        let tx_json: serde_json::Value = serde_json::from_slice(&tx_bytes)?;

        let fee = CosmosFee {
            amount: tx_json["fee"]["amount"]
                .as_array()
                .unwrap_or(&Vec::new())
                .iter()
                .map(|coin| CosmosCoin {
                    denom: coin["denom"].as_str().unwrap_or("").to_string(),
                    amount: coin["amount"].as_str().unwrap_or("0").to_string(),
                })
                .collect(),
            gas: tx_json["fee"]["gas"].as_str().unwrap_or("0").to_string(),
        };

        let messages = tx_json["msg"]
            .as_array()
            .unwrap_or(&Vec::new())
            .iter()
            .map(|msg| CosmosMessage {
                type_url: msg["@type"].as_str().unwrap_or("").to_string(),
                value: msg.clone(),
            })
            .collect();

        let result = CosmosTxResult {
            code: tx_result["code"].as_u64().unwrap_or(0) as u32,
            log: tx_result["log"].as_str().map(|s| s.to_string()),
            gas_wanted: tx_result["gas_wanted"].as_str().unwrap_or("0").to_string(),
            gas_used: tx_result["gas_used"].as_str().unwrap_or("0").to_string(),
        };

        Ok(CosmosTransactionData {
            hash: format!("{:x}", sha2::Sha256::digest(&tx_bytes)),
            height,
            fee,
            gas_used: result.gas_used.parse().unwrap_or(0),
            gas_wanted: result.gas_wanted.parse().unwrap_or(0),
            memo: tx_json["memo"].as_str().map(|s| s.to_string()),
            messages,
            result,
        })
    }

    async fn process_block(&self, block_data: CosmosBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Store in database
        self.store_block_data(&block_data).await?;

        // Send to Kafka
        self.send_to_kafka(&block_data).await?;

        // Update metrics
        self.update_metrics(&block_data).await?;

        info!("Processed block {} from {}", block_data.height, block_data.network);
        Ok(())
    }

    async fn store_block_data(&self, block_data: &CosmosBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Implementation for storing to PostgreSQL
        // This would include storing blocks, transactions, and validator data
        Ok(())
    }

    async fn send_to_kafka(&self, block_data: &CosmosBlockData) -> Result<(), Box<dyn std::error::Error>> {
        let topic = format!("cosmos.blocks.{}", block_data.network);
        let message = serde_json::to_string(block_data)?;
        self.kafka_producer.send_message(&topic, &message).await?;
        Ok(())
    }

    async fn update_metrics(&self, block_data: &CosmosBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Update Prometheus metrics
        self.metrics_collector.increment_counter(
            "cosmos_blocks_processed_total",
            &[("network", &block_data.network)],
        );

        self.metrics_collector.set_gauge(
            "cosmos_latest_block_height",
            block_data.height as f64,
            &[("network", &block_data.network)],
        );

        Ok(())
    }
}
