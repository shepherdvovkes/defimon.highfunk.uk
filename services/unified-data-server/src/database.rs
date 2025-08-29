use sqlx::{PgPool, postgres::PgPoolOptions};
use serde::{Deserialize, Serialize};
use tracing::info;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    pub url: String,
    pub max_connections: u32,
    pub min_connections: u32,
    pub connection_timeout: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub number: i64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub transaction_count: i32,
    pub gas_used: Option<String>,
    pub gas_limit: Option<String>,
    pub miner: Option<String>,
    pub network: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction {
    pub hash: String,
    pub block_number: i64,
    pub from_address: String,
    pub to_address: Option<String>,
    pub value: String,
    pub gas_price: String,
    pub gas_used: String,
    pub network: String,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkStats {
    pub network: String,
    pub total_blocks: i64,
    pub total_transactions: i64,
    pub total_volume: String,
    pub avg_gas_price: String,
    pub last_block_number: i64,
    pub last_block_timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Protocol {
    pub name: String,
    pub network: String,
    pub tvl: Option<String>,
    pub volume_24h: Option<String>,
    pub fees_24h: Option<String>,
    pub users_24h: Option<i64>,
    pub last_updated: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PriceData {
    pub asset: String,
    pub price_usd: String,
    pub volume_24h_usd: Option<String>,
    pub market_cap_usd: Option<String>,
    pub price_change_24h_percent: Option<String>,
    pub last_updated: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DashboardData {
    pub total_networks: i64,
    pub total_blocks: i64,
    pub total_transactions: i64,
    pub total_protocols: i64,
    pub total_volume_24h: String,
    pub network_stats: Vec<NetworkStats>,
    pub top_protocols: Vec<Protocol>,
    pub price_summary: Vec<PriceData>,
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
        // Unified blocks table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS unified_blocks (
                network VARCHAR(50) NOT NULL,
                number BIGINT NOT NULL,
                hash VARCHAR(66) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                transaction_count INTEGER NOT NULL,
                gas_used VARCHAR(100),
                gas_limit VARCHAR(100),
                miner VARCHAR(42),
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                PRIMARY KEY (network, number)
            )
            "#
        ).execute(pool).await?;

        // Unified transactions table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS unified_transactions (
                network VARCHAR(50) NOT NULL,
                hash VARCHAR(66) NOT NULL,
                block_number BIGINT NOT NULL,
                from_address VARCHAR(42) NOT NULL,
                to_address VARCHAR(42),
                value VARCHAR(100) NOT NULL,
                gas_price VARCHAR(100) NOT NULL,
                gas_used VARCHAR(100) NOT NULL,
                timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                PRIMARY KEY (network, hash)
            )
            "#
        ).execute(pool).await?;

        // Protocols table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS protocols (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                network VARCHAR(50) NOT NULL,
                tvl VARCHAR(100),
                volume_24h VARCHAR(100),
                fees_24h VARCHAR(100),
                users_24h BIGINT,
                metadata JSONB,
                last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(name, network)
            )
            "#
        ).execute(pool).await?;

        // Price data table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS price_data (
                id SERIAL PRIMARY KEY,
                asset VARCHAR(20) NOT NULL,
                price_usd VARCHAR(100) NOT NULL,
                volume_24h_usd VARCHAR(100),
                market_cap_usd VARCHAR(100),
                price_change_24h_percent VARCHAR(20),
                price_change_7d_percent VARCHAR(20),
                last_updated TIMESTAMP WITH TIME ZONE NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(asset, last_updated)
            )
            "#
        ).execute(pool).await?;

        // Network statistics table
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS network_statistics (
                id SERIAL PRIMARY KEY,
                network VARCHAR(50) NOT NULL,
                total_blocks BIGINT NOT NULL,
                total_transactions BIGINT NOT NULL,
                total_volume VARCHAR(100),
                avg_gas_price VARCHAR(100),
                last_block_number BIGINT NOT NULL,
                last_block_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(network)
            )
            "#
        ).execute(pool).await?;

        info!("Database tables created successfully");
        Ok(())
    }

    // Block operations
    pub async fn save_block(&self, block: &Block) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO unified_blocks (network, number, hash, timestamp, transaction_count, gas_used, gas_limit, miner)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            ON CONFLICT (network, number) DO UPDATE SET
                hash = EXCLUDED.hash,
                timestamp = EXCLUDED.timestamp,
                transaction_count = EXCLUDED.transaction_count,
                gas_used = EXCLUDED.gas_used,
                gas_limit = EXCLUDED.gas_limit,
                miner = EXCLUDED.miner
            "#
        )
        .bind(&block.network)
        .bind(block.number)
        .bind(&block.hash)
        .bind(block.timestamp)
        .bind(block.transaction_count)
        .bind(&block.gas_used)
        .bind(&block.gas_limit)
        .bind(&block.miner)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    // Simplified get_* methods to return dummy data for compilation
    pub async fn get_blocks(&self, network: &str, limit: i64, offset: i64) -> Result<Vec<Block>, Box<dyn std::error::Error>> {
        let rows = sqlx::query!(
            "SELECT number, hash, timestamp, transaction_count, gas_used, gas_limit, miner, network 
             FROM unified_blocks 
             WHERE network = $1 
             ORDER BY number DESC 
             LIMIT $2 OFFSET $3",
            network, limit, offset
        )
        .fetch_all(&self.pool)
        .await?;

        let blocks = rows.into_iter().map(|row| Block {
            number: row.number,
            hash: row.hash,
            timestamp: row.timestamp,
            transaction_count: row.transaction_count,
            gas_used: row.gas_used,
            gas_limit: row.gas_limit,
            miner: row.miner,
            network: row.network,
        }).collect();

        Ok(blocks)
    }

    // Transaction operations
    pub async fn save_transaction(&self, transaction: &Transaction) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO unified_transactions (network, hash, block_number, from_address, to_address, value, gas_price, gas_used, timestamp)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            ON CONFLICT (network, hash) DO UPDATE SET
                block_number = EXCLUDED.block_number,
                from_address = EXCLUDED.from_address,
                to_address = EXCLUDED.to_address,
                value = EXCLUDED.value,
                gas_price = EXCLUDED.gas_price,
                gas_used = EXCLUDED.gas_used,
                timestamp = EXCLUDED.timestamp
            "#
        )
        .bind(&transaction.network)
        .bind(&transaction.hash)
        .bind(transaction.block_number)
        .bind(&transaction.from_address)
        .bind(&transaction.to_address)
        .bind(&transaction.value)
        .bind(&transaction.gas_price)
        .bind(&transaction.gas_used)
        .bind(transaction.timestamp)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_transactions(&self, network: &str, limit: i64, offset: i64) -> Result<Vec<Transaction>, Box<dyn std::error::Error>> {
        let rows = sqlx::query!(
            "SELECT hash, block_number, from_address, to_address, value, gas_price, gas_used, network, timestamp 
             FROM unified_transactions 
             WHERE network = $1 
             ORDER BY timestamp DESC 
             LIMIT $2 OFFSET $3",
            network, limit, offset
        )
        .fetch_all(&self.pool)
        .await?;

        let transactions = rows.into_iter().map(|row| Transaction {
            hash: row.hash,
            block_number: row.block_number,
            from_address: row.from_address,
            to_address: row.to_address,
            value: row.value,
            gas_price: row.gas_price,
            gas_used: row.gas_used,
            network: row.network,
            timestamp: row.timestamp,
        }).collect();

        Ok(transactions)
    }

    // Network statistics operations
    pub async fn update_network_stats(&self, stats: &NetworkStats) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO network_statistics (network, total_blocks, total_transactions, total_volume, avg_gas_price, last_block_number, last_block_timestamp)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (network) DO UPDATE SET
                total_blocks = EXCLUDED.total_blocks,
                total_transactions = EXCLUDED.total_transactions,
                total_volume = EXCLUDED.total_volume,
                avg_gas_price = EXCLUDED.avg_gas_price,
                last_block_number = EXCLUDED.last_block_number,
                last_block_timestamp = EXCLUDED.last_block_timestamp,
                updated_at = NOW()
            "#
        )
        .bind(&stats.network)
        .bind(stats.total_blocks)
        .bind(stats.total_transactions)
        .bind(&stats.total_volume)
        .bind(&stats.avg_gas_price)
        .bind(stats.last_block_number)
        .bind(stats.last_block_timestamp)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_network_stats(&self, network: &str) -> Result<NetworkStats, Box<dyn std::error::Error>> {
        let row = sqlx::query!(
            "SELECT network, total_blocks, total_transactions, total_volume, avg_gas_price, last_block_number, last_block_timestamp 
             FROM network_statistics 
             WHERE network = $1",
            network
        )
        .fetch_optional(&self.pool)
        .await?;

        if let Some(row) = row {
            Ok(NetworkStats {
                network: row.network,
                total_blocks: row.total_blocks,
                total_transactions: row.total_transactions,
                total_volume: row.total_volume.unwrap_or_else(|| "0".to_string()),
                avg_gas_price: row.avg_gas_price.unwrap_or_else(|| "0".to_string()),
                last_block_number: row.last_block_number,
                last_block_timestamp: row.last_block_timestamp,
            })
        } else {
            // Return default stats if no data exists
            Ok(NetworkStats {
                network: network.to_string(),
                total_blocks: 0,
                total_transactions: 0,
                total_volume: "0".to_string(),
                avg_gas_price: "0".to_string(),
                last_block_number: 0,
                last_block_timestamp: Utc::now(),
            })
        }
    }

    // Protocol operations
    pub async fn save_protocol(&self, protocol: &Protocol) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO protocols (name, network, tvl, volume_24h, fees_24h, users_24h, last_updated)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (name, network) DO UPDATE SET
                tvl = EXCLUDED.tvl,
                volume_24h = EXCLUDED.volume_24h,
                fees_24h = EXCLUDED.fees_24h,
                users_24h = EXCLUDED.users_24h,
                last_updated = EXCLUDED.last_updated
            "#
        )
        .bind(&protocol.name)
        .bind(&protocol.network)
        .bind(&protocol.tvl)
        .bind(&protocol.volume_24h)
        .bind(&protocol.fees_24h)
        .bind(protocol.users_24h)
        .bind(protocol.last_updated)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_protocols(&self) -> Result<Vec<Protocol>, Box<dyn std::error::Error>> {
        let rows = sqlx::query!(
            "SELECT name, network, tvl, volume_24h, users_24h, last_updated 
             FROM protocols 
             ORDER BY tvl DESC NULLS LAST"
        )
        .fetch_all(&self.pool)
        .await?;

        let protocols = rows.into_iter().map(|row| Protocol {
            name: row.name,
            network: row.network,
            tvl: row.tvl,
            volume_24h: row.volume_24h,
            fees_24h: None,
            users_24h: row.users_24h,
            last_updated: row.last_updated,
        }).collect();

        Ok(protocols)
    }

    pub async fn get_protocol_data(&self, protocol: &str) -> Result<Vec<Protocol>, Box<dyn std::error::Error>> {
        let rows = sqlx::query!(
            "SELECT name, network, tvl, volume_24h, users_24h, last_updated 
             FROM protocols 
             WHERE name ILIKE $1 
             ORDER BY tvl DESC NULLS LAST",
            format!("%{}%", protocol)
        )
        .fetch_all(&self.pool)
        .await?;

        let protocols = rows.into_iter().map(|row| Protocol {
            name: row.name,
            network: row.network,
            tvl: row.tvl,
            volume_24h: row.volume_24h,
            fees_24h: None,
            users_24h: row.users_24h,
            last_updated: row.last_updated,
        }).collect();

        Ok(protocols)
    }

    // Price operations
    pub async fn save_price(&self, price: &PriceData) -> Result<(), Box<dyn std::error::Error>> {
        sqlx::query(
            r#"
            INSERT INTO price_data (asset, price_usd, volume_24h_usd, market_cap_usd, price_change_24h_percent, last_updated)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (asset, last_updated) DO UPDATE SET
                price_usd = EXCLUDED.price_usd,
                volume_24h_usd = EXCLUDED.volume_24h_usd,
                market_cap_usd = EXCLUDED.market_cap_usd,
                price_change_24h_percent = EXCLUDED.price_change_24h_percent
            "#
        )
        .bind(&price.asset)
        .bind(&price.price_usd)
        .bind(&price.volume_24h_usd)
        .bind(&price.market_cap_usd)
        .bind(&price.price_change_24h_percent)
        .bind(price.last_updated)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_prices(&self) -> Result<Vec<PriceData>, Box<dyn std::error::Error>> {
        let rows = sqlx::query!(
            "SELECT asset, price_usd, volume_24h_usd, market_cap_usd, price_change_24h_percent, last_updated 
             FROM price_data 
             ORDER BY market_cap_usd DESC NULLS LAST"
        )
        .fetch_all(&self.pool)
        .await?;

        let prices = rows.into_iter().map(|row| PriceData {
            asset: row.asset,
            price_usd: row.price_usd,
            volume_24h_usd: row.volume_24h_usd,
            market_cap_usd: row.market_cap_usd,
            price_change_24h_percent: row.price_change_24h_percent,
            last_updated: row.last_updated,
        }).collect();

        Ok(prices)
    }

    pub async fn get_asset_price(&self, asset: &str) -> Result<PriceData, Box<dyn std::error::Error>> {
        let row = sqlx::query!(
            "SELECT asset, price_usd, volume_24h_usd, market_cap_usd, price_change_24h_percent, last_updated 
             FROM price_data 
             WHERE asset ILIKE $1",
            format!("%{}%", asset)
        )
        .fetch_optional(&self.pool)
        .await?;

        if let Some(row) = row {
            Ok(PriceData {
                asset: row.asset,
                price_usd: row.price_usd,
                volume_24h_usd: row.volume_24h_usd,
                market_cap_usd: row.market_cap_usd,
                price_change_24h_percent: row.price_change_24h_percent,
                last_updated: row.last_updated,
            })
        } else {
            // Return default price data if no data exists
            Ok(PriceData {
                asset: asset.to_string(),
                price_usd: "0".to_string(),
                volume_24h_usd: None,
                market_cap_usd: None,
                price_change_24h_percent: None,
                last_updated: Utc::now(),
            })
        }
    }

    // Dashboard data
    pub async fn get_dashboard_data(&self) -> Result<DashboardData, Box<dyn std::error::Error>> {
        // Get total counts
        let total_blocks: i64 = sqlx::query!("SELECT COUNT(*) as count FROM unified_blocks")
            .fetch_one(&self.pool)
            .await?
            .count
            .unwrap_or(0);

        let total_transactions: i64 = sqlx::query!("SELECT COUNT(*) as count FROM unified_transactions")
            .fetch_one(&self.pool)
            .await?
            .count
            .unwrap_or(0);

        let total_protocols: i64 = sqlx::query!("SELECT COUNT(*) as count FROM protocols")
            .fetch_one(&self.pool)
            .await?
            .count
            .unwrap_or(0);

        // Get network stats
        let network_stats_rows = sqlx::query!(
            "SELECT network, total_blocks, total_transactions, total_volume, avg_gas_price, last_block_number, last_block_timestamp 
             FROM network_statistics 
             ORDER BY total_blocks DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        let network_stats: Vec<NetworkStats> = network_stats_rows.into_iter().map(|row| NetworkStats {
            network: row.network,
            total_blocks: row.total_blocks,
            total_transactions: row.total_transactions,
            total_volume: row.total_volume.unwrap_or_else(|| "0".to_string()),
            avg_gas_price: row.avg_gas_price.unwrap_or_else(|| "0".to_string()),
            last_block_number: row.last_block_number,
            last_block_timestamp: row.last_block_timestamp,
        }).collect();

        // Get top protocols
        let top_protocols = self.get_protocols().await?;

        // Get price summary
        let price_summary = self.get_prices().await?;

        // Calculate total volume
        let total_volume = network_stats.iter()
            .map(|stats| stats.total_volume.parse::<f64>().unwrap_or(0.0))
            .sum::<f64>()
            .to_string();

        Ok(DashboardData {
            total_networks: network_stats.len() as i64,
            total_blocks,
            total_transactions,
            total_protocols,
            total_volume_24h: total_volume,
            network_stats,
            top_protocols,
            price_summary,
        })
    }

    // Data cleanup
    pub async fn cleanup_old_data(&self, days: u32) -> Result<(), Box<dyn std::error::Error>> {
        let cutoff = Utc::now() - chrono::Duration::days(days as i64);

        sqlx::query("DELETE FROM price_data WHERE last_updated < $1")
            .bind(cutoff)
            .execute(&self.pool)
            .await?;

        info!("Cleaned up old price data");
        Ok(())
    }
}
