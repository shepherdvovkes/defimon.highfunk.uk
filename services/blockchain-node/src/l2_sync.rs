use crate::l2_networks::{L2NetworkRegistry, L2Network};
use crate::ethereum::{BlockData, TransactionData, LogData};
use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;
use ethers::{
    providers::{Http, Provider, Ws},
    types::{Block, Transaction, Log, H256, U256, Address},
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};
use tracing::{info, error, warn, debug};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L2BlockData {
    pub network: String,
    pub chain_id: u64,
    pub number: u64,
    pub hash: H256,
    pub timestamp: u64,
    pub transactions: Vec<L2TransactionData>,
    pub logs: Vec<L2LogData>,
    pub l2_specific_data: L2SpecificData,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L2TransactionData {
    pub hash: H256,
    pub from: Address,
    pub to: Option<Address>,
    pub value: U256,
    pub gas_price: U256,
    pub gas_used: U256,
    pub block_number: u64,
    pub l2_gas_price: Option<U256>,
    pub l1_gas_price: Option<U256>,
    pub l1_batch_number: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L2LogData {
    pub address: Address,
    pub topics: Vec<H256>,
    pub data: Vec<u8>,
    pub block_number: u64,
    pub transaction_hash: H256,
    pub l2_specific_metadata: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L2SpecificData {
    pub l1_batch_submissions: u64,
    pub l1_batch_size: u64,
    pub finality_time: u64, // seconds
    pub gas_fees_l2: U256,
    pub gas_fees_l1: Option<U256>,
    pub sequencer_fees: Option<U256>,
    pub compression_ratio: Option<f64>,
    pub proof_generation_time: Option<u64>,
}

pub struct L2SyncManager {
    registry: L2NetworkRegistry,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    last_processed_blocks: HashMap<String, u64>,
    sync_interval: u64,
    batch_size: u32,
    max_concurrent_requests: u32,
    priority_threshold: u8,
}

impl L2SyncManager {
    pub fn new(
        db_manager: Arc<DatabaseManager>,
        kafka_producer: Arc<KafkaProducer>,
        metrics_collector: Arc<MetricsCollector>,
        sync_interval: u64,
        batch_size: u32,
        max_concurrent_requests: u32,
        priority_threshold: u8,
    ) -> Self {
        L2SyncManager {
            registry: L2NetworkRegistry::new(),
            db_manager,
            kafka_producer,
            metrics_collector,
            last_processed_blocks: HashMap::new(),
            sync_interval,
            batch_size,
            max_concurrent_requests,
            priority_threshold,
        }
    }

    pub async fn start_sync(&mut self, enabled_networks: &[String]) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting L2 sync for networks: {:?}", enabled_networks);

        // Initialize last processed blocks from database
        for network in enabled_networks {
            if let Some(network_config) = self.registry.get_network(network) {
                let last_block = self.db_manager.get_last_l2_processed_block(network).await?;
                self.last_processed_blocks.insert(network.clone(), last_block);
                info!("Network {}: starting from block {}", network, last_block);
            }
        }

        loop {
            self.sync_all_networks(enabled_networks).await?;
            sleep(Duration::from_secs(self.sync_interval)).await;
        }
    }

    async fn sync_all_networks(&mut self, enabled_networks: &[String]) -> Result<(), Box<dyn std::error::Error>> {
        let mut sync_tasks = Vec::new();

        for network_name in enabled_networks {
            if let Some(network) = self.registry.get_network(network_name) {
                if network.priority >= self.priority_threshold && network.sync_enabled {
                    let task = self.sync_network(network_name, network);
                    sync_tasks.push(task);
                }
            }
        }

        // Execute sync tasks concurrently with rate limiting
        let semaphore = Arc::new(tokio::sync::Semaphore::new(self.max_concurrent_requests as usize));
        
        let mut handles = Vec::new();
        for task in sync_tasks {
            let permit = semaphore.clone().acquire_owned().await?;
            let handle = tokio::spawn(async move {
                let _permit = permit;
                task.await
            });
            handles.push(handle);
        }

        // Wait for all tasks to complete
        for handle in handles {
            if let Err(e) = handle.await {
                error!("L2 sync task failed: {}", e);
            }
        }

        Ok(())
    }

    async fn sync_network(&self, network_name: &str, network: &L2Network) -> Result<(), Box<dyn std::error::Error>> {
        let start_time = std::time::Instant::now();
        
        match self.sync_network_data(network_name, network).await {
            Ok(blocks_processed) => {
                let duration = start_time.elapsed();
                info!(
                    "Network {}: processed {} blocks in {:?}",
                    network_name, blocks_processed, duration
                );
                self.metrics_collector.record_l2_sync_success(network_name, blocks_processed, duration).await;
            }
            Err(e) => {
                error!("Failed to sync network {}: {}", network_name, e);
                self.metrics_collector.record_l2_sync_error(network_name).await;
            }
        }

        Ok(())
    }

    async fn sync_network_data(&self, network_name: &str, network: &L2Network) -> Result<u32, Box<dyn std::error::Error>> {
        let provider = Provider::<Http>::try_from(&network.rpc_url)?;
        
        // Get latest block
        let latest_block = provider.get_block_number().await?;
        let last_processed = self.last_processed_blocks.get(network_name).unwrap_or(&0);
        
        if latest_block.as_u64() <= *last_processed {
            return Ok(0);
        }

        let start_block = *last_processed + 1;
        let end_block = std::cmp::min(
            latest_block.as_u64(),
            start_block + self.batch_size as u64 - 1
        );

        let mut blocks_processed = 0;
        
        for block_number in start_block..=end_block {
            match self.process_l2_block(&provider, network_name, network, block_number).await {
                Ok(_) => {
                    blocks_processed += 1;
                    self.last_processed_blocks.insert(network_name.to_string(), block_number);
                }
                Err(e) => {
                    warn!("Failed to process block {} on network {}: {}", block_number, network_name, e);
                }
            }
        }

        Ok(blocks_processed)
    }

    async fn process_l2_block(
        &self,
        provider: &Provider<Http>,
        network_name: &str,
        network: &L2Network,
        block_number: u64,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let block = provider.get_block_with_txs(block_number).await?;
        let block = block.ok_or("Block not found")?;

        let mut transactions = Vec::new();
        for tx in &block.transactions {
            let receipt = provider.get_transaction_receipt(tx.hash).await?;
            let gas_used = receipt.map(|r| r.gas_used).unwrap_or(U256::zero());

            // Extract L2-specific data
            let l2_gas_price = self.extract_l2_gas_price(&receipt);
            let l1_gas_price = self.extract_l1_gas_price(&receipt);
            let l1_batch_number = self.extract_l1_batch_number(&receipt);

            transactions.push(L2TransactionData {
                hash: tx.hash,
                from: tx.from,
                to: tx.to,
                value: tx.value,
                gas_price: tx.gas_price.unwrap_or(U256::zero()),
                gas_used,
                block_number,
                l2_gas_price,
                l1_gas_price,
                l1_batch_number,
            });
        }

        let logs = self.get_l2_block_logs(provider, block_number).await?;
        let l2_specific_data = self.extract_l2_specific_data(provider, network, block_number).await?;

        let l2_block_data = L2BlockData {
            network: network_name.to_string(),
            chain_id: network.chain_id,
            number: block_number,
            hash: block.hash.unwrap_or(H256::zero()),
            timestamp: block.timestamp.as_u64(),
            transactions,
            logs,
            l2_specific_data,
        };

        // Save to database
        self.db_manager.save_l2_block_data(&l2_block_data).await?;

        // Send to Kafka
        self.kafka_producer.send_message("l2_blockchain_data", &l2_block_data).await?;

        // Update metrics
        self.metrics_collector.record_l2_block_processed(network_name, block_number).await;

        debug!("Processed L2 block {} on network {}", block_number, network_name);
        Ok(())
    }

    async fn get_l2_block_logs(&self, provider: &Provider<Http>, block_number: u64) -> Result<Vec<L2LogData>, Box<dyn std::error::Error>> {
        let logs = provider.get_logs(&ethers::types::Filter::new()
            .from_block(block_number)
            .to_block(block_number)).await?;

        let mut log_data = Vec::new();
        for log in logs {
            log_data.push(L2LogData {
                address: log.address,
                topics: log.topics,
                data: log.data.to_vec(),
                block_number: log.block_number.unwrap_or(0).as_u64(),
                transaction_hash: log.transaction_hash.unwrap_or(H256::zero()),
                l2_specific_metadata: None, // Can be extended with L2-specific metadata
            });
        }

        Ok(log_data)
    }

    async fn extract_l2_specific_data(
        &self,
        provider: &Provider<Http>,
        network: &L2Network,
        block_number: u64,
    ) -> Result<L2SpecificData, Box<dyn std::error::Error>> {
        // This is a simplified implementation
        // In a real implementation, you would extract L2-specific data based on the network type
        Ok(L2SpecificData {
            l1_batch_submissions: 1, // Placeholder
            l1_batch_size: 100, // Placeholder
            finality_time: 300, // 5 minutes placeholder
            gas_fees_l2: U256::from(1000000), // Placeholder
            gas_fees_l1: Some(U256::from(500000)), // Placeholder
            sequencer_fees: Some(U256::from(100000)), // Placeholder
            compression_ratio: Some(0.8), // Placeholder
            proof_generation_time: Some(60), // Placeholder
        })
    }

    fn extract_l2_gas_price(&self, receipt: &Option<ethers::types::TransactionReceipt>) -> Option<U256> {
        // Extract L2 gas price from receipt metadata
        receipt.as_ref().map(|r| r.gas_used.unwrap_or(U256::zero()))
    }

    fn extract_l1_gas_price(&self, receipt: &Option<ethers::types::TransactionReceipt>) -> Option<U256> {
        // Extract L1 gas price from receipt metadata
        receipt.as_ref().map(|r| r.gas_used.unwrap_or(U256::zero()))
    }

    fn extract_l1_batch_number(&self, receipt: &Option<ethers::types::TransactionReceipt>) -> Option<u64> {
        // Extract L1 batch number from receipt metadata
        receipt.as_ref().map(|r| r.block_number.unwrap_or(0).as_u64())
    }

    pub async fn get_network_stats(&self, network_name: &str) -> Result<NetworkStats, Box<dyn std::error::Error>> {
        let network = self.registry.get_network(network_name)
            .ok_or("Network not found")?;

        let total_blocks = self.db_manager.get_l2_total_blocks(network_name).await?;
        let total_transactions = self.db_manager.get_l2_total_transactions(network_name).await?;
        let total_volume = self.db_manager.get_l2_total_volume(network_name).await?;
        let last_sync_time = self.db_manager.get_l2_last_sync_time(network_name).await?;

        Ok(NetworkStats {
            network_name: network_name.to_string(),
            chain_id: network.chain_id,
            total_blocks,
            total_transactions,
            total_volume,
            last_sync_time,
            tvl_usd: network.tvl_usd,
            volume_24h: network.volume_24h,
        })
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkStats {
    pub network_name: String,
    pub chain_id: u64,
    pub total_blocks: u64,
    pub total_transactions: u64,
    pub total_volume: f64,
    pub last_sync_time: Option<DateTime<Utc>>,
    pub tvl_usd: Option<f64>,
    pub volume_24h: Option<f64>,
}
