use std::sync::Arc;
use tokio::sync::Mutex;
use serde::{Deserialize, Serialize};
use tracing::{info, error, warn};
use chrono::{DateTime, Utc};

use crate::ethereum::{EthereumNode, BlockData, LogData};
use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolData {
    pub name: String,
    pub tvl: f64,
    pub volume_24h: f64,
    pub fees_24h: f64,
    pub users_24h: u64,
    pub timestamp: DateTime<Utc>,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UniswapV3Data {
    pub pool_count: u64,
    pub total_volume: f64,
    pub total_fees: f64,
    pub tvl: f64,
    pub active_pools: Vec<PoolData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PoolData {
    pub address: String,
    pub token0: String,
    pub token1: String,
    pub fee_tier: u32,
    pub liquidity: f64,
    pub volume_24h: f64,
    pub fees_24h: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AaveV3Data {
    pub total_deposits: f64,
    pub total_borrows: f64,
    pub utilization_rate: f64,
    pub reserves: Vec<ReserveData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReserveData {
    pub symbol: String,
    pub total_deposits: f64,
    pub total_borrows: f64,
    pub liquidity_rate: f64,
    pub borrow_rate: f64,
    pub utilization_rate: f64,
}

pub struct ProtocolMonitor {
    ethereum_node: Arc<Mutex<EthereumNode>>,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    last_processed_block: u64,
}

impl ProtocolMonitor {
    pub fn new(
        ethereum_node: Arc<Mutex<EthereumNode>>,
        db_manager: Arc<DatabaseManager>,
        kafka_producer: Arc<KafkaProducer>,
        metrics_collector: Arc<MetricsCollector>,
    ) -> Self {
        ProtocolMonitor {
            ethereum_node,
            db_manager,
            kafka_producer,
            metrics_collector,
            last_processed_block: 0,
        }
    }

    pub async fn start_monitoring(&self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting protocol monitoring...");

        // Получение последнего обработанного блока
        self.last_processed_block = self.db_manager.get_last_processed_block().await?;

        loop {
            let current_block = {
                let node = self.ethereum_node.lock().await;
                node.get_latest_block().await?.number.as_u64()
            };

            if current_block > self.last_processed_block {
                self.process_new_blocks(current_block).await?;
                self.last_processed_block = current_block;
            }

            // Ожидание новых блоков
            tokio::time::sleep(tokio::time::Duration::from_secs(12)).await;
        }
    }

    async fn process_new_blocks(&self, latest_block: u64) -> Result<(), Box<dyn std::error::Error>> {
        let start_block = self.last_processed_block + 1;
        
        for block_number in start_block..=latest_block {
            self.process_block(block_number).await?;
        }

        Ok(())
    }

    async fn process_block(&self, block_number: u64) -> Result<(), Box<dyn std::error::Error>> {
        let block_data = {
            let node = self.ethereum_node.lock().await;
            node.get_block_data(block_number).await?
        };

        // Обработка транзакций Uniswap V3
        self.process_uniswap_v3_transactions(&block_data).await?;

        // Обработка транзакций Aave V3
        self.process_aave_v3_transactions(&block_data).await?;

        // Сохранение данных в базу
        self.db_manager.save_block_data(&block_data).await?;

        // Отправка в Kafka
        self.kafka_producer.send_message("blockchain_data", &block_data).await?;

        // Обновление метрик
        self.metrics_collector.record_block_processed(block_number).await;

        info!("Processed block {}", block_number);
        Ok(())
    }

    async fn process_uniswap_v3_transactions(&self, block_data: &BlockData) -> Result<(), Box<dyn std::error::Error>> {
        let uniswap_address = "0x1f98431c8ad98523631ae4a59f267346ea31f984";
        
        for transaction in &block_data.transactions {
            if let Some(to) = transaction.to {
                if to.to_string().to_lowercase() == uniswap_address.to_lowercase() {
                    // Анализ транзакции Uniswap V3
                    let pool_data = self.analyze_uniswap_transaction(transaction).await?;
                    
                    if let Some(data) = pool_data {
                        self.db_manager.save_uniswap_data(&data).await?;
                        self.kafka_producer.send_message("uniswap_v3_data", &data).await?;
                    }
                }
            }
        }

        Ok(())
    }

    async fn process_aave_v3_transactions(&self, block_data: &BlockData) -> Result<(), Box<dyn std::error::Error>> {
        let aave_address = "0x87870bace4f61ad5d8ba8c16b2e9ae4b6e79a1a7";
        
        for transaction in &block_data.transactions {
            if let Some(to) = transaction.to {
                if to.to_string().to_lowercase() == aave_address.to_lowercase() {
                    // Анализ транзакции Aave V3
                    let reserve_data = self.analyze_aave_transaction(transaction).await?;
                    
                    if let Some(data) = reserve_data {
                        self.db_manager.save_aave_data(&data).await?;
                        self.kafka_producer.send_message("aave_v3_data", &data).await?;
                    }
                }
            }
        }

        Ok(())
    }

    async fn analyze_uniswap_transaction(&self, transaction: &crate::ethereum::TransactionData) -> Result<Option<UniswapV3Data>, Box<dyn std::error::Error>> {
        // Анализ данных транзакции Uniswap V3
        // Здесь можно добавить более сложную логику анализа
        
        let pool_data = PoolData {
            address: transaction.hash.to_string(),
            token0: "UNKNOWN".to_string(),
            token1: "UNKNOWN".to_string(),
            fee_tier: 3000, // 0.3%
            liquidity: 0.0,
            volume_24h: 0.0,
            fees_24h: 0.0,
        };

        let uniswap_data = UniswapV3Data {
            pool_count: 1,
            total_volume: transaction.value.as_u128() as f64 / 1e18,
            total_fees: 0.0,
            tvl: 0.0,
            active_pools: vec![pool_data],
        };

        Ok(Some(uniswap_data))
    }

    async fn analyze_aave_transaction(&self, transaction: &crate::ethereum::TransactionData) -> Result<Option<AaveV3Data>, Box<dyn std::error::Error>> {
        // Анализ данных транзакции Aave V3
        // Здесь можно добавить более сложную логику анализа
        
        let reserve_data = ReserveData {
            symbol: "UNKNOWN".to_string(),
            total_deposits: 0.0,
            total_borrows: 0.0,
            liquidity_rate: 0.0,
            borrow_rate: 0.0,
            utilization_rate: 0.0,
        };

        let aave_data = AaveV3Data {
            total_deposits: transaction.value.as_u128() as f64 / 1e18,
            total_borrows: 0.0,
            utilization_rate: 0.0,
            reserves: vec![reserve_data],
        };

        Ok(Some(aave_data))
    }

    pub async fn get_protocol_summary(&self, protocol_name: &str) -> Result<ProtocolData, Box<dyn std::error::Error>> {
        let latest_data = self.db_manager.get_latest_protocol_data(protocol_name).await?;
        
        Ok(ProtocolData {
            name: protocol_name.to_string(),
            tvl: latest_data.tvl,
            volume_24h: latest_data.volume_24h,
            fees_24h: latest_data.fees_24h,
            users_24h: latest_data.users_24h,
            timestamp: Utc::now(),
            metadata: serde_json::json!({}),
        })
    }
}
