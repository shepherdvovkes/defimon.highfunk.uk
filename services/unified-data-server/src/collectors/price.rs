use std::sync::Arc;
use tracing::{info, error, warn};
use chrono::{DateTime, Utc};
use serde_json::Value;
use reqwest::Client;

use crate::database::{DatabaseManager, PriceData};

pub struct PriceCollector {
    db: Arc<DatabaseManager>,
    client: Client,
}

impl PriceCollector {
    pub fn new(db: Arc<DatabaseManager>) -> Self {
        Self {
            db,
            client: Client::new(),
        }
    }

    pub async fn start_collection(&self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting price data collection...");

        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60));
        
        loop {
            interval.tick().await;
            
            if let Err(e) = self.collect_price_data().await {
                error!("Price collection error: {}", e);
            }
        }
    }

    async fn collect_price_data(&self) -> Result<(), Box<dyn std::error::Error>> {
        let assets = vec![
            "bitcoin", "ethereum", "polygon", "arbitrum", "optimism", 
            "base", "zksync", "linea", "scroll", "cosmos", "osmosis",
            "polkadot", "kusama", "moonbeam", "moonriver", "astar", "acala"
        ];

        for asset in assets {
            if let Err(e) = self.collect_asset_price(asset).await {
                warn!("Failed to collect price for {}: {}", asset, e);
                continue;
            }
        }

        info!("Price collection completed");
        Ok(())
    }

    async fn collect_asset_price(&self, asset: &str) -> Result<(), Box<dyn std::error::Error>> {
        // Try CoinGecko first
        if let Ok(price_data) = self.get_coingecko_price(asset).await {
            self.db.save_price(&price_data).await?;
            return Ok(());
        }

        // Fallback to CoinMarketCap
        if let Ok(price_data) = self.get_coinmarketcap_price(asset).await {
            self.db.save_price(&price_data).await?;
            return Ok(());
        }

        // Fallback to Binance
        if let Ok(price_data) = self.get_binance_price(asset).await {
            self.db.save_price(&price_data).await?;
            return Ok(());
        }

        Err("Failed to get price from all sources".into())
    }

    async fn get_coingecko_price(&self, asset: &str) -> Result<PriceData, Box<dyn std::error::Error>> {
        let url = format!(
            "https://api.coingecko.com/api/v3/simple/price?ids={}&vs_currencies=usd&include_24hr_vol=true&include_24hr_change=true&include_market_cap=true",
            self.get_coingecko_id(asset)
        );

        let response = self.client
            .get(&url)
            .header("User-Agent", "DEFIMON-Price-Collector/1.0")
            .send()
            .await?;

        let data: Value = response.json().await?;
        let coin_id = self.get_coingecko_id(asset);
        
        if let Some(coin_data) = data.get(&coin_id) {
            let price_usd = coin_data["usd"].as_f64().unwrap_or(0.0).to_string();
            let volume_24h = coin_data["usd_24h_vol"].as_f64().map(|v| v.to_string());
            let market_cap = coin_data["usd_market_cap"].as_f64().map(|v| v.to_string());
            let change_24h = coin_data["usd_24h_change"].as_f64().map(|v| v.to_string());

            Ok(PriceData {
                asset: asset.to_string(),
                price_usd,
                volume_24h_usd: volume_24h,
                market_cap_usd: market_cap,
                price_change_24h_percent: change_24h,
                last_updated: Utc::now(),
            })
        } else {
            Err("Asset not found in CoinGecko response".into())
        }
    }

    async fn get_coinmarketcap_price(&self, asset: &str) -> Result<PriceData, Box<dyn std::error::Error>> {
        // Note: CoinMarketCap requires an API key
        // This is a simplified implementation
        let url = format!(
            "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest?symbol={}",
            asset.to_uppercase()
        );

        let response = self.client
            .get(&url)
            .header("X-CMC_PRO_API_KEY", "your-api-key-here") // Would need to be configured
            .send()
            .await?;

        let data: Value = response.json().await?;
        
        if let Some(quote) = data["data"][asset.to_uppercase()]["quote"]["USD"].as_object() {
            let price_usd = quote["price"].as_f64().unwrap_or(0.0).to_string();
            let volume_24h = quote["volume_24h"].as_f64().map(|v| v.to_string());
            let market_cap = quote["market_cap"].as_f64().map(|v| v.to_string());
            let change_24h = quote["percent_change_24h"].as_f64().map(|v| v.to_string());

            Ok(PriceData {
                asset: asset.to_string(),
                price_usd,
                volume_24h_usd: volume_24h,
                market_cap_usd: market_cap,
                price_change_24h_percent: change_24h,
                last_updated: Utc::now(),
            })
        } else {
            Err("Asset not found in CoinMarketCap response".into())
        }
    }

    async fn get_binance_price(&self, asset: &str) -> Result<PriceData, Box<dyn std::error::Error>> {
        let symbol = format!("{}USDT", asset.to_uppercase());
        let url = format!("https://api.binance.com/api/v3/ticker/24hr?symbol={}", symbol);

        let response = self.client
            .get(&url)
            .send()
            .await?;

        let data: Value = response.json().await?;
        
        if data.get("code").is_some() {
            // Try with different symbol format
            let symbol = format!("{}BTC", asset.to_uppercase());
            let url = format!("https://api.binance.com/api/v3/ticker/24hr?symbol={}", symbol);
            
            let response = self.client
                .get(&url)
                .send()
                .await?;

            let data: Value = response.json().await?;
            
            if data.get("code").is_some() {
                return Err("Asset not available on Binance".into());
            }
        }

        let price_usd = data["lastPrice"].as_str().unwrap_or("0").to_string();
        let volume_24h = data["volume"].as_str().map(|v| v.to_string());
        let change_24h = data["priceChangePercent"].as_str().map(|v| v.to_string());

        Ok(PriceData {
            asset: asset.to_string(),
            price_usd,
            volume_24h_usd: volume_24h,
            market_cap_usd: None, // Binance doesn't provide market cap in this endpoint
            price_change_24h_percent: change_24h,
            last_updated: Utc::now(),
        })
    }

    fn get_coingecko_id(&self, asset: &str) -> String {
        match asset {
            "bitcoin" => "bitcoin".to_string(),
            "ethereum" => "ethereum".to_string(),
            "polygon" => "matic-network".to_string(),
            "arbitrum" => "arbitrum".to_string(),
            "optimism" => "optimism".to_string(),
            "base" => "base".to_string(),
            "zksync" => "zksync".to_string(),
            "linea" => "linea".to_string(),
            "scroll" => "scroll".to_string(),
            "cosmos" => "cosmos".to_string(),
            "osmosis" => "osmosis".to_string(),
            "polkadot" => "polkadot".to_string(),
            "kusama" => "kusama".to_string(),
            "moonbeam" => "moonbeam".to_string(),
            "moonriver" => "moonriver".to_string(),
            "astar" => "astar".to_string(),
            "acala" => "acala".to_string(),
            _ => asset.to_string(),
        }
    }
}
