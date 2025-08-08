use ethers::{
    providers::{Http, Provider, Ws},
    types::{Block, H256, U256, Address, U64},
    middleware::Middleware,
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::{info, error};
use futures_util::StreamExt;
use std::fmt;

#[derive(Debug)]
pub struct EthereumError {
    message: String,
}

impl EthereumError {
    pub fn new(message: &str) -> Self {
        EthereumError {
            message: message.to_string(),
        }
    }
}

impl fmt::Display for EthereumError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Ethereum error: {}", self.message)
    }
}

impl std::error::Error for EthereumError {}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockData {
    pub number: u64,
    pub hash: H256,
    pub timestamp: u64,
    pub transactions: Vec<TransactionData>,
    pub logs: Vec<LogData>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionData {
    pub hash: H256,
    pub from: Address,
    pub to: Option<Address>,
    pub value: U256,
    pub gas_price: U256,
    pub gas_used: U256,
    pub block_number: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LogData {
    pub address: Address,
    pub topics: Vec<H256>,
    pub data: Vec<u8>,
    pub block_number: u64,
    pub transaction_hash: H256,
}

pub struct EthereumNode {
    provider: Provider<Http>,
    ws_provider: Option<Provider<Ws>>,
    contract_addresses: HashMap<String, Address>,
}

impl EthereumNode {
    pub async fn new(node_url: &str) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let provider = Provider::<Http>::try_from(node_url)?;
        
        // Попытка подключения к WebSocket
        let ws_url = node_url.replace("http", "ws");
        let ws_provider = Provider::<Ws>::connect(&ws_url).await.ok();

        let mut contract_addresses = HashMap::new();
        contract_addresses.insert(
            "uniswap_v3".to_string(),
            "0x1f98431c8ad98523631ae4a59f267346ea31f984".parse()?
        );
        contract_addresses.insert(
            "aave_v3".to_string(),
            "0x87870bace4f61ad5d8ba8c16b2e9ae4b6e79a1a7".parse()?
        );
        contract_addresses.insert(
            "compound_v3".to_string(),
            "0xc3d688b66703497daa19211eedff47f25384cdc3".parse()?
        );

        Ok(EthereumNode {
            provider,
            ws_provider,
            contract_addresses,
        })
    }

    pub async fn get_latest_block(&self) -> Result<Block<H256>, Box<dyn std::error::Error + Send + Sync>> {
        let block = self.provider.get_block(ethers::types::BlockNumber::Latest).await?;
        Ok(block.ok_or("No latest block found")?)
    }

    pub async fn get_block_data(&self, block_number: u64) -> Result<BlockData, Box<dyn std::error::Error + Send + Sync>> {
        let block = self.provider.get_block_with_txs(block_number).await?;
        let block = block.ok_or("Block not found")?;

        let mut transactions = Vec::new();
        for tx in &block.transactions {
            let receipt = self.provider.get_transaction_receipt(tx.hash).await?;
            let gas_used = receipt.map(|r| r.gas_used).unwrap_or(Some(U256::zero())).unwrap_or(U256::zero());

            transactions.push(TransactionData {
                hash: tx.hash,
                from: tx.from,
                to: tx.to,
                value: tx.value,
                gas_price: tx.gas_price.unwrap_or(U256::zero()),
                gas_used: gas_used,
                block_number,
            });
        }

        let logs = self.get_block_logs(block_number).await?;

        Ok(BlockData {
            number: block_number,
            hash: block.hash.unwrap_or(H256::zero()),
            timestamp: block.timestamp.as_u64(),
            transactions,
            logs,
        })
    }

    pub async fn get_block_logs(&self, block_number: u64) -> Result<Vec<LogData>, Box<dyn std::error::Error + Send + Sync>> {
        let logs = self.provider.get_logs(&ethers::types::Filter::new()
            .from_block(block_number)
            .to_block(block_number)).await?;

        let mut log_data = Vec::new();
        for log in logs {
            log_data.push(LogData {
                address: log.address,
                topics: log.topics,
                data: log.data.to_vec(),
                block_number: log.block_number.unwrap_or(U64::from(0)).as_u64(),
                transaction_hash: log.transaction_hash.unwrap_or(H256::zero()),
            });
        }

        Ok(log_data)
    }

    pub async fn get_contract_events(
        &self,
        contract_name: &str,
        from_block: u64,
        to_block: u64,
    ) -> Result<Vec<LogData>, Box<dyn std::error::Error + Send + Sync>> {
        let contract_address = self.contract_addresses.get(contract_name)
            .ok_or("Contract not found")?;

        let filter = ethers::types::Filter::new()
            .address(*contract_address)
            .from_block(from_block)
            .to_block(to_block);

        let logs = self.provider.get_logs(&filter).await?;

        let mut log_data = Vec::new();
        for log in logs {
            log_data.push(LogData {
                address: log.address,
                topics: log.topics,
                data: log.data.to_vec(),
                block_number: log.block_number.unwrap_or(U64::from(0)).as_u64(),
                transaction_hash: log.transaction_hash.unwrap_or(H256::zero()),
            });
        }

        Ok(log_data)
    }

    pub async fn get_contract_state(
        &self,
        contract_name: &str,
        function_signature: &str,
        params: Vec<ethers::types::U256>,
    ) -> Result<Vec<u8>, Box<dyn std::error::Error + Send + Sync>> {
        let contract_address = self.contract_addresses.get(contract_name)
            .ok_or("Contract not found")?;

        // Создание вызова контракта
        let data = self.encode_function_call(function_signature, &params)?;
        
        let call_data = ethers::types::TransactionRequest::new()
            .to(*contract_address)
            .data(data);

        // Исправленный вызов для ethers 2.0
        let result = self.provider.call(&call_data.into(), None).await?;
        Ok(result.to_vec())
    }

    fn encode_function_call(
        &self,
        function_signature: &str,
        params: &[ethers::types::U256],
    ) -> Result<Vec<u8>, Box<dyn std::error::Error + Send + Sync>> {
        // Простое кодирование вызова функции
        // В реальном приложении нужно использовать ABI
        let mut data = Vec::new();
        
        // Добавление селектора функции (первые 4 байта хеша)
        let selector = ethers::utils::keccak256(function_signature.as_bytes());
        data.extend_from_slice(&selector[..4]);
        
        // Добавление параметров
        for param in params {
            let mut bytes = [0u8; 32];
            param.to_big_endian(&mut bytes);
            data.extend_from_slice(&bytes);
        }
        
        Ok(data)
    }

    pub async fn subscribe_to_blocks(&self) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        if let Some(ws_provider) = &self.ws_provider {
            let mut stream = ws_provider.subscribe_blocks().await?;
            
            while let Some(block) = stream.next().await {
                info!("New block: {:?}", block);
            }
        }
        
        Ok(())
    }
}
