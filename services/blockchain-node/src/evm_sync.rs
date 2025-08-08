use std::collections::HashMap;
use std::sync::Arc;

use chrono::{DateTime, Utc};
use ethers::providers::{Http, Provider};
use ethers::{
    types::{Address, H256, U256},
    middleware::Middleware,
};
use serde::{Deserialize, Serialize};
use tokio::time::{sleep, Duration};
use tracing::{error, info, warn};

use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;
use crate::network::{NetworkCategory, NetworkDescriptor, NetworkRuntime};
use crate::network_registry::NetworkRegistry;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvmBlockData {
    pub network: String,
    pub number: u64,
    pub hash: H256,
    pub timestamp: u64,
    pub transactions: Vec<EvmTransactionData>,
    pub logs: Vec<EvmLogData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvmTransactionData {
    pub hash: H256,
    pub from: Address,
    pub to: Option<Address>,
    pub value: U256,
    pub gas_price: U256,
    pub gas_used: U256,
    pub block_number: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvmLogData {
    pub address: Address,
    pub topics: Vec<H256>,
    pub data: Vec<u8>,
    pub block_number: u64,
    pub transaction_hash: H256,
}

pub struct EvmSyncManager {
    registry: NetworkRegistry,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    last_processed_blocks: HashMap<String, u64>,
    sync_interval: u64,
    batch_size: u32,
    max_concurrent_requests: u32,
}

impl EvmSyncManager {
    pub fn new(
        registry: NetworkRegistry,
        db_manager: Arc<DatabaseManager>,
        kafka_producer: Arc<KafkaProducer>,
        metrics_collector: Arc<MetricsCollector>,
        sync_interval: u64,
        batch_size: u32,
        max_concurrent_requests: u32,
    ) -> Self {
        Self {
            registry,
            db_manager,
            kafka_producer,
            metrics_collector,
            last_processed_blocks: HashMap::new(),
            sync_interval,
            batch_size,
            max_concurrent_requests,
        }
    }

    pub async fn start_sync(&mut self, enabled_networks: &[String]) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        info!("Starting EVM sync for: {:?}", enabled_networks);

        // Seed last processed blocks
        for network in enabled_networks {
            let last_block = self.db_manager.get_last_evm_processed_block(network).await.unwrap_or(0);
            self.last_processed_blocks.insert(network.clone(), last_block);
        }

        loop {
            self.sync_all_networks(enabled_networks).await?;
            sleep(Duration::from_secs(self.sync_interval)).await;
        }
    }

    async fn sync_all_networks(&mut self, enabled_networks: &[String]) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let semaphore = Arc::new(tokio::sync::Semaphore::new(self.max_concurrent_requests as usize));
        let mut handles = Vec::new();

        for key in enabled_networks {
            if let Some(module) = self.registry.get(key) {
                let desc = module.descriptor();
                if desc.enabled && desc.runtime == NetworkRuntime::Evm {
                    let permit = semaphore.clone().acquire_owned().await?;
                    let network_key = key.clone();
                    let start_from = *self.last_processed_blocks.get(key).unwrap_or(&0u64);
                    let rpc_url = resolve_rpc_url(desc);
                    let db = self.db_manager.clone();
                    let kafka = self.kafka_producer.clone();
                    let metrics = self.metrics_collector.clone();
                    let batch_size = self.batch_size;
                    let handle = tokio::spawn(async move {
                        let _permit = permit;
                        if rpc_url.is_empty() {
                            warn!("Skipping {}: missing RPC endpoint. Set RPC_URL_{}", network_key, network_key.to_uppercase().replace(['-', ' '], "_"));
                            return;
                        }
                        if let Err(e) = sync_evm_network(&network_key, &rpc_url, start_from, batch_size, db, kafka, metrics).await {
                            error!("EVM sync failed for {}: {}", network_key, e);
                        }
                    });
                    handles.push(handle);
                }
            }
        }

        for h in handles { let _ = h.await; }
        Ok(())
    }
}

fn resolve_rpc_url(desc: &NetworkDescriptor) -> String {
    if let Some(url) = &desc.rpc_url { return url.clone(); }
    let key_upper = desc.key.to_uppercase().replace(['-', ' '], "_");
    let specific = format!("RPC_URL_{}", key_upper);
    if let Ok(val) = std::env::var(&specific) { if !val.is_empty() { return val; } }
    // Only Ethereum fallback; others require explicit RPC_URL_* to avoid accidental wrong chain
    if desc.key == "ethereum" {
        return std::env::var("ETHEREUM_NODE_URL").unwrap_or_else(|_| "http://localhost:8545".to_string());
    }
    String::new()
}

async fn sync_evm_network(
    network_key: &str,
    rpc_url: &str,
    last_processed_block: u64,
    batch_size: u32,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let provider = Provider::<Http>::try_from(rpc_url)?;
    let latest_block = provider.get_block_number().await?.as_u64();
    if latest_block <= last_processed_block { return Ok(()); }

    let start_block = last_processed_block + 1;
    let end_block = std::cmp::min(latest_block, start_block + batch_size as u64 - 1);

    for bn in start_block..=end_block {
        match process_block(&provider, network_key, bn).await {
            Ok(block) => {
                db_manager.save_evm_block_data(&block).await
                    .map_err(|e| Box::new(std::io::Error::new(std::io::ErrorKind::Other, e.to_string())) as Box<dyn std::error::Error + Send + Sync>)?;
                kafka_producer.send_message("evm_blockchain_data", &block).await?;
                metrics_collector.record_block_processed(bn).await;
            }
            Err(e) => warn!("Failed to process block {} on {}: {}", bn, network_key, e),
        }
    }

    Ok(())
}

async fn process_block(provider: &Provider<Http>, network_key: &str, block_number: u64) -> Result<EvmBlockData, Box<dyn std::error::Error + Send + Sync>> {
    let block = provider.get_block_with_txs(block_number).await?.ok_or("Block not found")?;

    let mut transactions = Vec::new();
    for tx in &block.transactions {
        let receipt = provider.get_transaction_receipt(tx.hash).await?;
        let gas_used = receipt.map(|r| r.gas_used).unwrap_or(Some(U256::zero())).unwrap_or(U256::zero());
        transactions.push(EvmTransactionData {
            hash: tx.hash,
            from: tx.from,
            to: tx.to,
            value: tx.value,
            gas_price: tx.gas_price.unwrap_or(U256::zero()),
            gas_used: gas_used,
            block_number,
        });
    }

    let logs = get_block_logs(provider, block_number).await?;

    Ok(EvmBlockData {
        network: network_key.to_string(),
        number: block_number,
        hash: block.hash.unwrap_or(H256::zero()),
        timestamp: block.timestamp.as_u64(),
        transactions,
        logs,
    })
}

async fn get_block_logs(provider: &Provider<Http>, block_number: u64) -> Result<Vec<EvmLogData>, Box<dyn std::error::Error + Send + Sync>> {
    let logs = provider
        .get_logs(&ethers::types::Filter::new().from_block(block_number).to_block(block_number))
        .await?;
    let mut out = Vec::new();
    for log in logs {
        out.push(EvmLogData {
            address: log.address,
            topics: log.topics,
            data: log.data.to_vec(),
            block_number: log.block_number.unwrap_or_default().as_u64(),
            transaction_hash: log.transaction_hash.unwrap_or(H256::zero()),
        });
    }
    Ok(out)
}


