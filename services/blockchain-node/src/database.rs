use sqlx::{PgPool, postgres::PgPoolOptions};
use serde::{Deserialize, Serialize};
use tracing::{info, error, warn};
use chrono::{DateTime, Utc};
use crate::l2_sync::{L2BlockData, NetworkStats};
use crate::evm_sync::EvmBlockData;
use crate::substrate_sync::SubstrateBlockData;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub connection_timeout: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseBlock {
    pub number: u64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub transaction_count: u64,
    pub log_count: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProtocolDataRecord {
    pub name: String,
    pub tvl: f64,
    pub volume_24h: f64,
    pub fees_24h: f64,
    pub users_24h: u64,
    pub timestamp: DateTime<Utc>,
}

pub struct DatabaseManager {
    pool: PgPool,
}

impl DatabaseManager {
    pub async fn new(config: DatabaseConfig) -> Result<Self, Box<dyn std::error::Error>> {
        let pool = PgPoolOptions::new()
            .max_connections(config.max_connections)
            .min_connections(config.min_connections)
            .acquire_timeout(std::time::Duration::from_secs(config.connection_timeout))
            .connect(&config.url)
            .await?;

        info!("Database connection established");
        DatabaseManager::create_tables(&pool).await?;
        Ok(DatabaseManager { pool })
    }

    async fn create_tables(pool: &PgPool) -> Result<(), Box<dyn std::error::Error>> {
        // Таблица для блоков
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS blockchain_blocks (
                number BIGINT PRIMARY KEY,
                hash VARCHAR(66) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                transaction_count INTEGER NOT NULL,
                log_count INTEGER NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // Таблица для транзакций
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS blockchain_transactions (
                hash VARCHAR(66) PRIMARY KEY,
                block_number BIGINT NOT NULL,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                value NUMERIC(78,0) NOT NULL,
                gas_price NUMERIC(78,0) NOT NULL,
                gas_used NUMERIC(78,0) NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                FOREIGN KEY (block_number) REFERENCES blockchain_blocks(number)
            )
            "#
        ).execute(pool).await?;

        // Таблица для логов
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS blockchain_logs (
                id SERIAL PRIMARY KEY,
                address VARCHAR(42) NOT NULL,
                block_number BIGINT NOT NULL,
                transaction_hash VARCHAR(66) NOT NULL,
                topics TEXT[] NOT NULL,
                data TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                FOREIGN KEY (block_number) REFERENCES blockchain_blocks(number)
            )
            "#
        ).execute(pool).await?;

        // Таблица для данных протоколов
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS protocol_data (
                id SERIAL PRIMARY KEY,
                protocol_name VARCHAR(100) NOT NULL,
                tvl NUMERIC(20,2),
                volume_24h NUMERIC(20,2),
                fees_24h NUMERIC(20,2),
                users_24h BIGINT,
                metadata JSONB,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // Таблица для Uniswap V3 данных
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS uniswap_v3_data (
                id SERIAL PRIMARY KEY,
                pool_count BIGINT NOT NULL,
                total_volume NUMERIC(20,2) NOT NULL,
                total_fees NUMERIC(20,2) NOT NULL,
                tvl NUMERIC(20,2) NOT NULL,
                active_pools JSONB,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // Таблица для Aave V3 данных
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS aave_v3_data (
                id SERIAL PRIMARY KEY,
                total_deposits NUMERIC(20,2) NOT NULL,
                total_borrows NUMERIC(20,2) NOT NULL,
                utilization_rate NUMERIC(10,6) NOT NULL,
                reserves JSONB,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // Индексы для производительности
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_blocks_timestamp ON blockchain_blocks(timestamp)").execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_transactions_block ON blockchain_transactions(block_number)").execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_logs_block ON blockchain_logs(block_number)").execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_protocol_data_name_timestamp ON protocol_data(protocol_name, timestamp)").execute(pool).await?;

        // ================= L2 Tables (used for L2/EVM sync generic storage) =================
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS l2_blocks (
                network TEXT NOT NULL,
                chain_id BIGINT NOT NULL,
                number BIGINT NOT NULL,
                hash VARCHAR(66) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                l1_batch_submissions BIGINT,
                l1_batch_size BIGINT,
                finality_time BIGINT,
                gas_fees_l2 TEXT,
                gas_fees_l1 TEXT,
                sequencer_fees TEXT,
                compression_ratio DOUBLE PRECISION,
                proof_generation_time BIGINT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                PRIMARY KEY (network, number)
            )
            "#
        ).execute(pool).await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS l2_transactions (
                hash VARCHAR(66) PRIMARY KEY,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                value TEXT NOT NULL,
                gas_price TEXT NOT NULL,
                gas_used TEXT NOT NULL,
                block_number BIGINT NOT NULL,
                l2_gas_price TEXT,
                l1_gas_price TEXT,
                l1_batch_number BIGINT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS l2_logs (
                id SERIAL PRIMARY KEY,
                address VARCHAR(42) NOT NULL,
                topics TEXT NOT NULL,
                data BYTEA NOT NULL,
                block_number BIGINT NOT NULL,
                transaction_hash VARCHAR(66) NOT NULL,
                l2_specific_metadata TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // ================= EVM Sync Tables =================
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS evm_blocks (
                network TEXT NOT NULL,
                number BIGINT NOT NULL,
                hash VARCHAR(66) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                tx_count INTEGER NOT NULL,
                log_count INTEGER NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                PRIMARY KEY (network, number)
            )
            "#
        ).execute(pool).await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS evm_transactions (
                network TEXT NOT NULL,
                hash VARCHAR(66) PRIMARY KEY,
                block_number BIGINT NOT NULL,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                value TEXT NOT NULL,
                gas_price TEXT NOT NULL,
                gas_used TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS evm_logs (
                network TEXT NOT NULL,
                id SERIAL PRIMARY KEY,
                address VARCHAR(42) NOT NULL,
                block_number BIGINT NOT NULL,
                transaction_hash VARCHAR(66) NOT NULL,
                topics TEXT NOT NULL,
                data BYTEA NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;

        // ================= Substrate Tables =================
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS substrate_blocks (
                network TEXT NOT NULL,
                number BIGINT NOT NULL,
                hash TEXT NOT NULL,
                timestamp_ms BIGINT,
                extrinsics_count INTEGER NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                PRIMARY KEY (network, number)
            )
            "#
        ).execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_substrate_blocks_network_number ON substrate_blocks(network, number)").execute(pool).await?;

        // Indexes for substrate_events if table exists later
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS substrate_events (
                id SERIAL PRIMARY KEY,
                network TEXT NOT NULL,
                block_number BIGINT NOT NULL,
                pallet TEXT NOT NULL,
                variant TEXT NOT NULL,
                fields JSONB,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_substrate_events_network_block ON substrate_events(network, block_number)").execute(pool).await?;
        sqlx::query("CREATE INDEX IF NOT EXISTS idx_substrate_events_pallet_variant ON substrate_events(pallet, variant)").execute(pool).await?;

        info!("Database tables created successfully");
        Ok(())
    }

    pub async fn save_block_data(&self, block_data: &crate::ethereum::BlockData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO blockchain_blocks (number, hash, timestamp, transaction_count, log_count)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (number) DO NOTHING
        "#;

        sqlx::query(query)
            .bind(block_data.number as i64)
            .bind(block_data.hash.as_bytes())
            .bind(DateTime::from_timestamp(block_data.timestamp as i64, 0))
            .bind(block_data.transactions.len() as i32)
            .bind(block_data.logs.len() as i32)
            .execute(&self.pool)
            .await?;

        // Save transactions
        for tx in &block_data.transactions {
            self.save_transaction(tx).await?;
        }

        // Save logs
        for log in &block_data.logs {
            self.save_log(log).await?;
        }

        Ok(())
    }

    async fn save_transaction(&self, tx: &crate::ethereum::TransactionData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO blockchain_transactions (hash, block_number, from_address, to_address, value, gas_price, gas_used)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (hash) DO NOTHING
        "#;

        sqlx::query(query)
            .bind(tx.hash.as_bytes())
            .bind(tx.block_number as i64)
            .bind(tx.from.as_bytes())
            .bind(tx.to.map(|addr| addr.as_bytes()))
            .bind(tx.value.to_string())
            .bind(tx.gas_price.to_string())
            .bind(tx.gas_used.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn save_log(&self, log: &crate::ethereum::LogData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO blockchain_logs (address, block_number, transaction_hash, topics, data)
            VALUES ($1, $2, $3, $4, $5)
        "#;

        let topics_json = serde_json::to_string(&log.topics)?;

        sqlx::query(query)
            .bind(log.address.as_bytes())
            .bind(log.block_number as i64)
            .bind(log.transaction_hash.as_bytes())
            .bind(&topics_json)
            .bind(&log.data)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    pub async fn save_uniswap_data(&self, data: &crate::protocols::UniswapV3Data) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO uniswap_v3_data (pool_count, total_volume, total_fees, tvl, active_pools, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6)
            "#
        )
        .bind(data.pool_count as i64)
        .bind(data.total_volume)
        .bind(data.total_fees)
        .bind(data.tvl)
        .bind(serde_json::to_value(&data.active_pools)?)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn save_aave_data(&self, data: &crate::protocols::AaveV3Data) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO aave_v3_data (total_deposits, total_borrows, utilization_rate, reserves, timestamp)
            VALUES ($1, $2, $3, $4, $5)
            "#
        )
        .bind(data.total_deposits)
        .bind(data.total_borrows)
        .bind(data.utilization_rate)
        .bind(serde_json::to_value(&data.reserves)?)
        .bind(Utc::now())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_last_processed_block(&self) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "SELECT COALESCE(MAX(number), 0) FROM blockchain_blocks";
        let result: Option<i64> = sqlx::query_scalar(query)
            .fetch_one(&self.pool)
            .await?;

        Ok(result.unwrap_or(0) as u64)
    }

    // ================= EVM Sync API =================

    pub async fn save_evm_block_data(&self, block: &EvmBlockData) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO evm_blocks (network, number, hash, timestamp, tx_count, log_count)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (network, number) DO NOTHING
            "#
        )
        .bind(&block.network)
        .bind(block.number as i64)
        .bind(block.hash.as_bytes())
        .bind(DateTime::from_timestamp(block.timestamp as i64, 0))
        .bind(block.transactions.len() as i32)
        .bind(block.logs.len() as i32)
        .execute(&self.pool)
        .await?;

        for tx in &block.transactions {
            sqlx::query(
                r#"
                INSERT INTO evm_transactions (network, hash, block_number, from_address, to_address, value, gas_price, gas_used)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                ON CONFLICT (hash) DO NOTHING
                "#
            )
            .bind(&block.network)
            .bind(tx.hash.as_bytes())
            .bind(tx.block_number as i64)
            .bind(tx.from.as_bytes())
            .bind(tx.to.map(|a| a.as_bytes()))
            .bind(tx.value.to_string())
            .bind(tx.gas_price.to_string())
            .bind(tx.gas_used.to_string())
            .execute(&self.pool)
            .await?;
        }

        for log in &block.logs {
            sqlx::query(
                r#"
                INSERT INTO evm_logs (network, address, block_number, transaction_hash, topics, data)
                VALUES ($1, $2, $3, $4, $5, $6)
                "#
            )
            .bind(&block.network)
            .bind(log.address.as_bytes())
            .bind(log.block_number as i64)
            .bind(log.transaction_hash.as_bytes())
            .bind(serde_json::to_string(&log.topics)?)
            .bind(&log.data)
            .execute(&self.pool)
            .await?;
        }

        // mark last processed block
        self.set_last_evm_processed_block(&block.network, block.number).await?;

        Ok(())
    }

    pub async fn get_last_evm_processed_block(&self, network: &str) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "SELECT COALESCE(MAX(number), 0) FROM evm_blocks WHERE network = $1";
        let result: Option<i64> = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;
        Ok(result.unwrap_or(0) as u64)
    }

    pub async fn set_last_evm_processed_block(&self, network: &str, number: u64) -> Result<(), Box<dyn std::error::Error>> {
        // no-op; using evm_blocks as source of truth
        let _ = network;
        let _ = number;
        Ok(())
    }

    // ================= Substrate Sync API =================
    pub async fn save_substrate_block_data(&self, block: &SubstrateBlockData) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO substrate_blocks (network, number, hash, timestamp_ms, extrinsics_count)
            VALUES ($1, $2, $3, $4, $5)
            ON CONFLICT (network, number) DO NOTHING
            "#
        )
        .bind(&block.network)
        .bind(block.number as i64)
        .bind(&block.hash)
        .bind(block.timestamp_ms as i64)
        .bind(block.extrinsics_count as i32)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn get_last_substrate_processed_block(&self, network: &str) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "SELECT COALESCE(MAX(number), 0) FROM substrate_blocks WHERE network = $1";
        let result: Option<i64> = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;
        Ok(result.unwrap_or(0) as u64)
    }

    pub async fn save_substrate_events(&self, block: &SubstrateBlockData) -> Result<(), Box<dyn std::error::Error>> {
        // Table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS substrate_events (
                id SERIAL PRIMARY KEY,
                network TEXT NOT NULL,
                block_number BIGINT NOT NULL,
                pallet TEXT NOT NULL,
                variant TEXT NOT NULL,
                fields JSONB,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            )
            "#
        ).execute(&self.pool).await?;

        for ev in &block.events {
            sqlx::query(
                r#"
                INSERT INTO substrate_events (network, block_number, pallet, variant, fields)
                VALUES ($1, $2, $3, $4, $5)
                "#
            )
            .bind(&block.network)
            .bind(block.number as i64)
            .bind(&ev.pallet)
            .bind(&ev.variant)
            .bind(serde_json::to_value(&ev.fields)?)
            .execute(&self.pool)
            .await?;
        }
        Ok(())
    }

    pub async fn get_latest_protocol_data(&self, protocol_name: &str) -> Result<ProtocolDataRecord, Box<dyn std::error::Error>> {
        let row = sqlx::query(
            r#"
            SELECT protocol_name, tvl, volume_24h, fees_24h, users_24h, timestamp
            FROM protocol_data
            WHERE protocol_name = $1
            ORDER BY timestamp DESC
            LIMIT 1
            "#
        )
        .bind(protocol_name)
        .fetch_one(&self.pool)
        .await?;

        Ok(ProtocolDataRecord {
            name: row.get("protocol_name"),
            tvl: row.get("tvl"),
            volume_24h: row.get("volume_24h"),
            fees_24h: row.get("fees_24h"),
            users_24h: row.get("users_24h"),
            timestamp: row.get("timestamp"),
        })
    }

    pub async fn get_block_statistics(&self, from_block: u64, to_block: u64) -> Result<Vec<DatabaseBlock>, Box<dyn std::error::Error>> {
        let rows = sqlx::query(
            r#"
            SELECT number, hash, timestamp, transaction_count, log_count
            FROM blockchain_blocks
            WHERE number BETWEEN $1 AND $2
            ORDER BY number
            "#
        )
        .bind(from_block as i64)
        .bind(to_block as i64)
        .fetch_all(&self.pool)
        .await?;

        let mut blocks = Vec::new();
        for row in rows {
            blocks.push(DatabaseBlock {
                number: row.get::<i64, _>("number") as u64,
                hash: row.get("hash"),
                timestamp: row.get("timestamp"),
                transaction_count: row.get::<i32, _>("transaction_count") as u64,
                log_count: row.get::<i32, _>("log_count") as u64,
            });
        }

        Ok(blocks)
    }

    // L2 Database Methods

    pub async fn save_l2_block_data(&self, l2_block_data: &L2BlockData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO l2_blocks (network, chain_id, number, hash, timestamp, l1_batch_submissions, l1_batch_size, finality_time, gas_fees_l2, gas_fees_l1, sequencer_fees, compression_ratio, proof_generation_time, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())
            ON CONFLICT (network, number) DO NOTHING
        "#;

        sqlx::query(query)
            .bind(&l2_block_data.network)
            .bind(l2_block_data.chain_id as i64)
            .bind(l2_block_data.number as i64)
            .bind(l2_block_data.hash.as_bytes())
            .bind(DateTime::from_timestamp(l2_block_data.timestamp as i64, 0))
            .bind(l2_block_data.l2_specific_data.l1_batch_submissions as i64)
            .bind(l2_block_data.l2_specific_data.l1_batch_size as i64)
            .bind(l2_block_data.l2_specific_data.finality_time as i64)
            .bind(l2_block_data.l2_specific_data.gas_fees_l2.to_string())
            .bind(l2_block_data.l2_specific_data.gas_fees_l1.map(|g| g.to_string()))
            .bind(l2_block_data.l2_specific_data.sequencer_fees.map(|s| s.to_string()))
            .bind(l2_block_data.l2_specific_data.compression_ratio)
            .bind(l2_block_data.l2_specific_data.proof_generation_time.map(|p| p as i64))
            .execute(&self.pool)
            .await?;

        // Save L2 transactions
        for tx in &l2_block_data.transactions {
            self.save_l2_transaction(tx).await?;
        }

        // Save L2 logs
        for log in &l2_block_data.logs {
            self.save_l2_log(log).await?;
        }

        Ok(())
    }

    async fn save_l2_transaction(&self, tx: &crate::l2_sync::L2TransactionData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO l2_transactions (hash, from_address, to_address, value, gas_price, gas_used, block_number, l2_gas_price, l1_gas_price, l1_batch_number, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW())
            ON CONFLICT (hash) DO NOTHING
        "#;

        sqlx::query(query)
            .bind(tx.hash.as_bytes())
            .bind(tx.from.as_bytes())
            .bind(tx.to.map(|addr| addr.as_bytes()))
            .bind(tx.value.to_string())
            .bind(tx.gas_price.to_string())
            .bind(tx.gas_used.to_string())
            .bind(tx.block_number as i64)
            .bind(tx.l2_gas_price.map(|g| g.to_string()))
            .bind(tx.l1_gas_price.map(|g| g.to_string()))
            .bind(tx.l1_batch_number.map(|b| b as i64))
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn save_l2_log(&self, log: &crate::l2_sync::L2LogData) -> Result<(), Box<dyn std::error::Error>> {
        let query = r#"
            INSERT INTO l2_logs (address, topics, data, block_number, transaction_hash, l2_specific_metadata, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, NOW())
        "#;

        let topics_json = serde_json::to_string(&log.topics)?;
        let metadata_json = log.l2_specific_metadata.as_ref().map(|m| serde_json::to_string(m)).transpose()?;

        sqlx::query(query)
            .bind(log.address.as_bytes())
            .bind(&topics_json)
            .bind(&log.data)
            .bind(log.block_number as i64)
            .bind(log.transaction_hash.as_bytes())
            .bind(metadata_json)
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    pub async fn get_last_l2_processed_block(&self, network: &str) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "SELECT COALESCE(MAX(number), 0) FROM l2_blocks WHERE network = $1";
        let result: Option<i64> = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;

        Ok(result.unwrap_or(0) as u64)
    }

    pub async fn get_l2_total_blocks(&self, network: &str) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "SELECT COUNT(*) FROM l2_blocks WHERE network = $1";
        let result: i64 = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;

        Ok(result as u64)
    }

    pub async fn get_l2_total_transactions(&self, network: &str) -> Result<u64, Box<dyn std::error::Error>> {
        let query = r#"
            SELECT COUNT(t.hash)
            FROM l2_transactions t
            JOIN l2_blocks b ON b.number = t.block_number
            WHERE b.network = $1
        "#;
        let result: i64 = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;

        Ok(result as u64)
    }

    pub async fn get_l2_total_volume(&self, network: &str) -> Result<f64, Box<dyn std::error::Error>> {
        let query = r#"
            SELECT COALESCE(SUM(CAST(t.value AS DECIMAL)), 0)
            FROM l2_transactions t
            JOIN l2_blocks b ON b.number = t.block_number
            WHERE b.network = $1
        "#;
        let result: Option<sqlx::types::Decimal> = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;

        Ok(result.map(|d| d.to_string().parse::<f64>().unwrap_or(0.0)).unwrap_or(0.0))
    }

    pub async fn get_l2_last_sync_time(&self, network: &str) -> Result<Option<DateTime<Utc>>, Box<dyn std::error::Error>> {
        let query = "SELECT MAX(created_at) FROM l2_blocks WHERE network = $1";
        let result: Option<DateTime<Utc>> = sqlx::query_scalar(query)
            .bind(network)
            .fetch_one(&self.pool)
            .await?;

        Ok(result)
    }

    pub async fn get_l2_network_stats(&self, network: &str, days: u32) -> Result<NetworkStats, Box<dyn std::error::Error>> {
        let query = r#"
            SELECT 
                COUNT(DISTINCT b.number) as total_blocks,
                COUNT(t.hash) as total_transactions,
                COALESCE(SUM(CAST(t.value AS DECIMAL)), 0) as total_volume,
                MAX(b.created_at) as last_sync_time
            FROM l2_blocks b
            LEFT JOIN l2_transactions t ON b.network = t.network AND b.number = t.block_number
            WHERE b.network = $1 AND b.created_at >= NOW() - INTERVAL '1 day' * $2
        "#;

        let row = sqlx::query_as!(
            NetworkStatsRow,
            query,
            network,
            days as i32
        )
        .fetch_one(&self.pool)
        .await?;

        Ok(NetworkStats {
            network_name: network.to_string(),
            chain_id: 0, // Will be filled by caller
            total_blocks: row.total_blocks.unwrap_or(0) as u64,
            total_transactions: row.total_transactions.unwrap_or(0) as u64,
            total_volume: row.total_volume.map(|d| d.to_string().parse::<f64>().unwrap_or(0.0)).unwrap_or(0.0),
            last_sync_time: row.last_sync_time,
            tvl_usd: None, // Will be filled by caller
            volume_24h: None, // Will be filled by caller
        })
    }

    pub async fn cleanup_old_l2_data(&self, retention_days: u32) -> Result<u64, Box<dyn std::error::Error>> {
        let query = "DELETE FROM l2_blocks WHERE created_at < NOW() - INTERVAL '1 day' * $1";
        let result = sqlx::query(query)
            .bind(retention_days as i32)
            .execute(&self.pool)
            .await?;

        Ok(result.rows_affected())
    }
}

#[derive(Debug)]
struct NetworkStatsRow {
    total_blocks: Option<i64>,
    total_transactions: Option<i64>,
    total_volume: Option<sqlx::types::Decimal>,
    last_sync_time: Option<DateTime<Utc>>,
}
