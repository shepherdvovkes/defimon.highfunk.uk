use std::sync::Arc;
use tracing::{info, error, warn};
use chrono::{DateTime, Utc};
use serde_json::Value;
use reqwest::Client;

use crate::database::{DatabaseManager, Block, Transaction, NetworkStats};

pub struct L2Collector {
    db: Arc<DatabaseManager>,
    networks: Vec<L2Network>,
    client: Client,
}

#[derive(Clone)]
struct L2Network {
    name: String,
    rpc_url: String,
    chain_id: i64,
}

impl L2Collector {
    pub fn new(db: Arc<DatabaseManager>) -> Self {
        let networks = vec![
            L2Network {
                name: "polygon".to_string(),
                rpc_url: "https://polygon-rpc.com".to_string(),
                chain_id: 137,
            },
            L2Network {
                name: "arbitrum".to_string(),
                rpc_url: "https://arb1.arbitrum.io/rpc".to_string(),
                chain_id: 42161,
            },
            L2Network {
                name: "optimism".to_string(),
                rpc_url: "https://mainnet.optimism.io".to_string(),
                chain_id: 10,
            },
            L2Network {
                name: "base".to_string(),
                rpc_url: "https://mainnet.base.org".to_string(),
                chain_id: 8453,
            },
            L2Network {
                name: "zksync".to_string(),
                rpc_url: "https://mainnet.era.zksync.io".to_string(),
                chain_id: 324,
            },
            L2Network {
                name: "linea".to_string(),
                rpc_url: "https://rpc.linea.build".to_string(),
                chain_id: 59144,
            },
            L2Network {
                name: "scroll".to_string(),
                rpc_url: "https://rpc.scroll.io".to_string(),
                chain_id: 534352,
            },
        ];

        Self {
            db,
            networks,
            client: Client::new(),
        }
    }

    pub async fn start_collection(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        info!("Starting L2 data collection...");

        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(15));
        
        loop {
            interval.tick().await;
            
            for network in &self.networks {
                if let Err(e) = self.collect_network_data(network).await {
                    error!("L2 collection error for {}: {}", network.name, e);
                }
            }
        }
    }

    async fn collect_network_data(&self, network: &L2Network) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        // Get latest block number
        let latest_block_number = self.get_latest_block_number(network).await?;
        
        // Get last processed block from database
        let last_processed = self.get_last_processed_block(network).await?;
        
        // Collect new blocks (limit to 10 blocks per cycle to avoid overwhelming)
        let end_block = std::cmp::min(latest_block_number, last_processed + 10);
        
        for block_number in (last_processed + 1)..=end_block {
            if let Err(e) = self.collect_block(network, block_number).await {
                warn!("Failed to collect block {} on {}: {}", block_number, network.name, e);
                continue;
            }
        }

        // Update network statistics
        self.update_network_stats(network).await?;

        info!("L2 collection completed for {}: blocks {} to {}", network.name, last_processed + 1, end_block);
        Ok(())
    }

    async fn collect_block(&self, network: &L2Network, block_number: i64) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        // Get block data
        let block_data = self.get_block_by_number(network, block_number).await?;
        
        // Parse block
        let block = self.parse_block(&block_data, network).await?;
        
        // Save block to database
        self.db.save_block(&block).await?;
        
        // Collect transactions for this block
        if let Some(transactions) = block_data.get("transactions").and_then(|t| t.as_array()) {
            for tx_data in transactions {
                if let Ok(transaction) = self.parse_transaction(tx_data, &block).await {
                    self.db.save_transaction(&transaction).await?;
                }
            }
        }

        Ok(())
    }

    async fn get_latest_block_number(&self, network: &L2Network) -> Result<i64, Box<dyn std::error::Error + Send + Sync>> {
        let response = self.client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "eth_blockNumber",
                "params": [],
                "id": 1
            }))
            .send()
            .await?;

        let data: Value = response.json().await?;
        let hex_number = data["result"].as_str().ok_or("No result in response")?;
        
        let number = i64::from_str_radix(hex_number.trim_start_matches("0x"), 16)?;
        Ok(number)
    }

    async fn get_block_by_number(&self, network: &L2Network, block_number: i64) -> Result<Value, Box<dyn std::error::Error>> {
        let response = self.client
            .post(&network.rpc_url)
            .json(&serde_json::json!({
                "jsonrpc": "2.0",
                "method": "eth_getBlockByNumber",
                "params": [format!("0x{:x}", block_number), true],
                "id": 1
            }))
            .send()
            .await?;

        let data: Value = response.json().await?;
        let block = data["result"].clone();
        
        if block.is_null() {
            return Err("Block not found".into());
        }

        Ok(block)
    }

    async fn parse_block(&self, block_data: &Value, network: &L2Network) -> Result<Block, Box<dyn std::error::Error>> {
        let number = i64::from_str_radix(
            block_data["number"].as_str().unwrap().trim_start_matches("0x"),
            16
        )?;

        let timestamp = i64::from_str_radix(
            block_data["timestamp"].as_str().unwrap().trim_start_matches("0x"),
            16
        )?;

        let empty_vec = Vec::new();
        let transactions = block_data["transactions"].as_array().unwrap_or(&empty_vec);

        Ok(Block {
            number,
            hash: block_data["hash"].as_str().unwrap().to_string(),
            timestamp: DateTime::from_timestamp(timestamp, 0).unwrap_or_else(|| Utc::now()),
            transaction_count: transactions.len() as i32,
            gas_used: Some(block_data["gasUsed"].as_str().unwrap().to_string()),
            gas_limit: Some(block_data["gasLimit"].as_str().unwrap().to_string()),
            miner: Some(block_data["miner"].as_str().unwrap().to_string()),
            network: network.name.clone(),
        })
    }

    async fn parse_transaction(&self, tx_data: &Value, block: &Block) -> Result<Transaction, Box<dyn std::error::Error>> {
        let timestamp = block.timestamp;

        Ok(Transaction {
            hash: tx_data["hash"].as_str().unwrap().to_string(),
            block_number: block.number,
            from_address: tx_data["from"].as_str().unwrap().to_string(),
            to_address: tx_data["to"].as_str().map(|s| s.to_string()),
            value: tx_data["value"].as_str().unwrap().to_string(),
            gas_price: tx_data["gasPrice"].as_str().unwrap().to_string(),
            gas_used: "0".to_string(), // Will be updated when we get receipt
            network: block.network.clone(),
            timestamp,
        })
    }

    async fn get_last_processed_block(&self, network: &L2Network) -> Result<i64, Box<dyn std::error::Error>> {
        // Get the highest block number from our database
        let blocks = self.db.get_blocks(&network.name, 1, 0).await?;
        
        if blocks.is_empty() {
            Ok(0)
        } else {
            Ok(blocks[0].number)
        }
    }

    async fn update_network_stats(&self, network: &L2Network) -> Result<(), Box<dyn std::error::Error>> {
        // Get latest block
        let blocks = self.db.get_blocks(&network.name, 1, 0).await?;
        if blocks.is_empty() {
            return Ok(());
        }

        let latest_block = &blocks[0];
        
        // Get total counts (simplified - in production you'd want to cache these)
        let total_blocks = latest_block.number;
        let total_transactions = total_blocks * 100; // Simplified estimate
        
        let stats = NetworkStats {
            network: network.name.clone(),
            total_blocks,
            total_transactions,
            total_volume: "0".to_string(), // Would need to calculate from transactions
            avg_gas_price: "0".to_string(), // Would need to calculate from transactions
            last_block_number: latest_block.number,
            last_block_timestamp: latest_block.timestamp,
        };

        self.db.update_network_stats(&stats).await?;
        Ok(())
    }
}
