use std::collections::HashMap;
use std::sync::Arc;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use tokio::time::{sleep, Duration};
use tracing::{debug, error, info, warn};

use crate::database::DatabaseManager;
use crate::kafka::KafkaProducer;
use crate::monitoring::MetricsCollector;
use crate::network::{NetworkDescriptor, NetworkRuntime};
use crate::network_registry::NetworkRegistry;

// Substrate deps
use subxt::{OnlineClient, PolkadotConfig};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubstrateBlockData {
    pub network: String,
    pub number: u64,
    pub hash: String,
    pub timestamp_ms: u64,
    pub extrinsics_count: u32,
    pub events: Vec<SubstrateEvent>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubstrateEvent {
    pub pallet: String,
    pub variant: String,
    pub fields: serde_json::Value,
}

pub struct SubstrateSyncManager {
    registry: NetworkRegistry,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
    sync_interval: u64,
}

impl SubstrateSyncManager {
    pub fn new(
        registry: NetworkRegistry,
        db_manager: Arc<DatabaseManager>,
        kafka_producer: Arc<KafkaProducer>,
        metrics_collector: Arc<MetricsCollector>,
        sync_interval: u64,
    ) -> Self {
        Self { registry, db_manager, kafka_producer, metrics_collector, sync_interval }
    }

    pub async fn start_sync(&self, enabled_networks: &[String]) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting Substrate sync for: {:?}", enabled_networks);

        let mut handles = Vec::new();
        for key in enabled_networks {
            if let Some(module) = self.registry.get(key) {
                let desc = module.descriptor();
                if desc.runtime == NetworkRuntime::Substrate {
                    let network_key = key.clone();
                    let rpc_url = resolve_ws_url(desc).unwrap_or_else(|| "wss://rpc.polkadot.io".to_string());
                    let db = self.db_manager.clone();
                    let kafka = self.kafka_producer.clone();
                    let metrics = self.metrics_collector.clone();
                    let handle = tokio::spawn(async move {
                        if let Err(e) = sync_substrate_network_streaming(&network_key, &rpc_url, db, kafka, metrics).await {
                            warn!("Substrate streaming sync failed for {}: {}", network_key, e);
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

fn resolve_ws_url(desc: &NetworkDescriptor) -> Option<String> {
    if let Some(ws) = &desc.ws_url { return Some(ws.clone()); }
    let key_upper = desc.key.to_uppercase().replace(['-', ' '], "_");
    let specific = format!("WS_URL_{}", key_upper);
    if let Ok(val) = std::env::var(&specific) { if !val.is_empty() { return Some(val); } }
    None
}

async fn sync_substrate_network(
    network_key: &str,
    ws_url: &str,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
) -> Result<(), Box<dyn std::error::Error>> {
    let api = OnlineClient::<PolkadotConfig>::from_url(ws_url).await?;

    // Determine range
    // TODO: Fix API call for substrate
    let head = api.blocks().at_latest().await?;
    let latest: u64 = head.number().into();
    let mut last = db_manager.get_last_substrate_processed_block(network_key).await.unwrap_or(0);
    if last == 0 && latest > 10 { last = latest - 10; } // warm start window

    if latest <= last { return Ok(()); }

    for n in (last + 1)..=latest {
        if let Err(e) = process_and_store_block(&api, network_key, n, &db_manager, &kafka_producer, &metrics_collector).await {
            warn!("{}: failed to process block {}: {}", network_key, n, e);
        }
    }

    Ok(())
}

async fn sync_substrate_network_streaming(
    network_key: &str,
    ws_url: &str,
    db_manager: Arc<DatabaseManager>,
    kafka_producer: Arc<KafkaProducer>,
    metrics_collector: Arc<MetricsCollector>,
) -> Result<(), Box<dyn std::error::Error>> {
    let api = OnlineClient::<PolkadotConfig>::from_url(ws_url).await?;

    // First catch up from last processed to latest
    if let Err(e) = sync_substrate_network(network_key, ws_url, db_manager.clone(), kafka_producer.clone(), metrics_collector.clone()).await {
        warn!("{}: initial catch-up failed: {}", network_key, e);
    }

    // Then subscribe to new blocks stream
    let mut blocks = api.blocks().subscribe_finalized().await?;
    while let Some(Ok(block)) = blocks.next().await {
        let number: u64 = block.number().into();
        let hash = block.hash();
        let hash_str = format!("0x{:?}", hash);

        // Timestamp
        let _now_val: Option<u64> = None; // TODO: Fix storage access
        let timestamp_ms: u64 = 0; // TODO: Fix timestamp extraction

        // Extrinsics + events
        let extrinsics_count = block.extrinsics().await?.len() as u32;
        let mut events_vec = Vec::new();
        if let Ok(events) = api.events().at(hash).await {
            for ev in events.iter() {
                if let Ok(ev) = ev {
                    let pallet = ev.pallet_name().to_string();
                    let variant = ev.variant_name().to_string();
                    let fields = typed_event_fields_json(&pallet, &variant, &ev);
                    events_vec.push(SubstrateEvent { pallet, variant, fields });
                }
            }
        }

        let record = SubstrateBlockData {
            network: network_key.to_string(),
            number,
            hash: hash_str,
            timestamp_ms,
            extrinsics_count,
            events: events_vec,
        };

        db_manager.save_substrate_block_data(&record).await?;
        db_manager.save_substrate_events(&record).await?;
        if let Err(e) = kafka_producer.send_message("substrate_blockchain_data", &record).await {
            warn!("Failed to send to Kafka: {}", e);
        }
        metrics_collector.record_block_processed(number).await;
    }

    Ok(())
}
async fn process_and_store_block(
    api: &OnlineClient<PolkadotConfig>,
    network_key: &str,
    number: u64,
    db_manager: &DatabaseManager,
    kafka_producer: &KafkaProducer,
    metrics_collector: &MetricsCollector,
) -> Result<(), Box<dyn std::error::Error>> {
    let block = api.blocks().at_latest().await?;
    let hash = block.hash();
    let hash_str = format!("0x{:?}", hash);

    // Read timestamp: storage Timestamp.Now (milliseconds)
    let _now_val: Option<u64> = None; // TODO: Fix storage access
    let timestamp_ms: u64 = 0; // TODO: Fix timestamp extraction

    // Extrinsics count
    let block = api.blocks().at(hash).await?;
    let extrinsics = block.extrinsics().await?;
    let extrinsics_count = extrinsics.len() as u32;

    // Collect events (pallet/variant + typed fields where possible)
    let mut events_vec: Vec<SubstrateEvent> = Vec::new();
    if let Ok(events) = api.events().at(hash).await {
        for ev in events.iter() {
            if let Ok(ev) = ev {
                let pallet = ev.pallet_name().to_string();
                let variant = ev.variant_name().to_string();
                let fields = typed_event_fields_json(&pallet, &variant, &ev);
                events_vec.push(SubstrateEvent { pallet, variant, fields });
            }
        }
    }

    let record = SubstrateBlockData {
        network: network_key.to_string(),
        number,
        hash: hash_str,
        timestamp_ms,
        extrinsics_count,
        events: events_vec,
    };

    db_manager.save_substrate_block_data(&record).await?;
    db_manager.save_substrate_events(&record).await?;
    if let Err(e) = kafka_producer.send_message("substrate_blockchain_data", &record).await {
        warn!("Failed to send to Kafka: {}", e);
    }
    metrics_collector.record_block_processed(number).await;
    Ok(())
}

fn typed_event_fields_json<T: subxt::Config>(pallet: &str, variant: &str, ev: &subxt::events::EventDetails<T>) -> serde_json::Value {
    if pallet == "Balances" && variant == "Transfer" {
        let mut from = None;
        let mut to = None;
        let mut amount = None;
        let mut idx = 0;
        for f in ev.field_values() {
            let s = format!("{:?}", f);
            match idx {
                0 => from = Some(s),
                1 => to = Some(s),
                2 => amount = Some(s),
                _ => {}
            }
            idx += 1;
        }
        return serde_json::json!({ "from": from.unwrap_or_default(), "to": to.unwrap_or_default(), "amount": amount.unwrap_or_default() });
    }
    if pallet == "Staking" && (variant == "Rewarded" || variant == "PaidOut") {
        let mut account = None;
        let mut amount = None;
        let mut idx = 0;
        for f in ev.field_values() {
            let s = format!("{:?}", f);
            match idx { 0 => account = Some(s), 1 => amount = Some(s), _ => {} }
            idx += 1;
        }
        return serde_json::json!({ "account": account.unwrap_or_default(), "amount": amount.unwrap_or_default() });
    }
    if pallet == "Tokens" && variant == "Transfer" {
        let mut currency = None;
        let mut from = None;
        let mut to = None;
        let mut amount = None;
        let mut idx = 0;
        for f in ev.field_values() {
            let s = format!("{:?}", f);
            match idx { 0 => currency = Some(s), 1 => from = Some(s), 2 => to = Some(s), 3 => amount = Some(s), _ => {} }
            idx += 1;
        }
        return serde_json::json!({ "currency": currency.unwrap_or_default(), "from": from.unwrap_or_default(), "to": to.unwrap_or_default(), "amount": amount.unwrap_or_default() });
    }
    let arr: Vec<String> = Vec::new();
    serde_json::json!(arr)
}


