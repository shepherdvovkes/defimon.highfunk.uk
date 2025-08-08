use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{info, error, warn};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod database;
mod ethereum;
mod kafka;
mod monitoring;
mod protocols;
mod l2_networks;
mod l2_sync;
mod cosmos_sync;
mod polkadot_sync;
mod network;
mod network_registry;
mod modules;
mod evm_sync;
mod substrate_sync;

use config::Config;
use database::DatabaseManager;
use ethereum::EthereumNode;
use kafka::KafkaProducer;
use monitoring::MetricsCollector;
use protocols::ProtocolMonitor;
use l2_sync::L2SyncManager;
use cosmos_sync::CosmosSyncManager;
use polkadot_sync::PolkadotSyncManager;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize logging
    tracing_subscriber::fmt::init();

    info!("Starting DEFIMON blockchain node...");

    // Load configuration
    let config = Config::load()?;
    info!("Configuration loaded successfully");

    // Initialize generic network registry (modular architecture scaffold)
    let generic_registry = network_registry::NetworkRegistry::new_from_env_or_default();
    info!("Generic NetworkRegistry initialized with {} networks", generic_registry.len());

    // Initialize database
    let db_config = database::DatabaseConfig {
        url: config.database_url.clone(),
        max_connections: 20,
        min_connections: 5,
        connection_timeout: 30,
    };
    let db_manager = Arc::new(DatabaseManager::new(db_config).await?);
    info!("Database connection established");

    // Initialize Kafka producer
    let kafka_producer = Arc::new(KafkaProducer::new(&config.kafka_bootstrap_servers).await?);
    info!("Kafka producer initialized");

    // Initialize metrics collector
    let metrics_collector = Arc::new(MetricsCollector::new());
    info!("Metrics collector initialized");

    // Initialize Ethereum node
    let ethereum_node = Arc::new(Mutex::new(EthereumNode::new(&config.ethereum_node_url).await?));
    info!("Ethereum node initialized");

    // Initialize protocol monitor
    let protocol_monitor = ProtocolMonitor::new(
        ethereum_node.clone(),
        db_manager.clone(),
        kafka_producer.clone(),
        metrics_collector.clone(),
    );

    // Initialize L2 sync manager
    let mut l2_sync_manager = L2SyncManager::new(
        db_manager.clone(),
        kafka_producer.clone(),
        metrics_collector.clone(),
        config.l2_sync_interval,
        config.l2_batch_size,
        config.l2_max_concurrent_requests,
        config.l2_priority_threshold,
    );

    // Start monitoring tasks
    let mut tasks = Vec::new();

    // Start Ethereum protocol monitoring
    if config.sync_mode == "full" {
        let protocol_task = tokio::spawn(async move {
            if let Err(e) = protocol_monitor.start_monitoring().await {
                error!("Protocol monitoring failed: {}", e);
            }
        });
        tasks.push(protocol_task);
    }

    // Start L2 sync if enabled
    if config.l2_sync_enabled {
        let l2_sync_task = tokio::spawn(async move {
            if let Err(e) = l2_sync_manager.start_sync(&config.l2_networks).await {
                error!("L2 sync failed: {}", e);
            }
        });
        tasks.push(l2_sync_task);
    }

    // Start EVM sync for configured networks (reuse L2 env list for now)
    if config.evm_sync_enabled {
        let mut evm_manager = evm_sync::EvmSyncManager::new(
            generic_registry,
            db_manager.clone(),
            kafka_producer.clone(),
            metrics_collector.clone(),
            config.l2_sync_interval,
            config.l2_batch_size,
            config.l2_max_concurrent_requests,
        );
        let evm_enabled = config.evm_networks.clone();
        let evm_task = tokio::spawn(async move {
            if let Err(e) = evm_manager.start_sync(&evm_enabled).await {
                error!("EVM sync failed: {}", e);
            }
        });
        tasks.push(evm_task);
    }

    // Start Substrate (Polkadot ecosystem) sync using SUBSTRATE_NETWORKS
    let substrate_networks: Vec<String> = std::env::var("SUBSTRATE_NETWORKS")
        .unwrap_or_else(|_| "polkadot,moonbeam,moonriver,astar,acala,parallel,centrifuge,hydradx,bifrost,interlay,unique,phala,zeitgeist".to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();
    if !substrate_networks.is_empty() {
        let substrate_registry = network_registry::NetworkRegistry::new_from_env_or_default();
        let substrate_task = {
            let db = db_manager.clone();
            let kafka = kafka_producer.clone();
            let metrics = metrics_collector.clone();
            tokio::spawn(async move {
                let manager = substrate_sync::SubstrateSyncManager::new(
                    substrate_registry,
                    db,
                    kafka,
                    metrics,
                    12,
                );
                if let Err(e) = manager.start_sync(&substrate_networks).await {
                    error!("Substrate sync failed: {}", e);
                }
            })
        };
        tasks.push(substrate_task);
    }

    // Start Cosmos sync if enabled
    if config.cosmos_sync_enabled {
        let cosmos_task = {
            let db = db_manager.clone();
            let kafka = kafka_producer.clone();
            let metrics = metrics_collector.clone();
            let cosmos_config = config.clone();
            tokio::spawn(async move {
                let mut manager = CosmosSyncManager::new(
                    cosmos_config,
                    db,
                    kafka,
                    metrics,
                );
                if let Err(e) = manager.start_sync().await {
                    error!("Cosmos sync failed: {}", e);
                }
            })
        };
        tasks.push(cosmos_task);
    }

    // Start Polkadot sync if enabled
    if config.polkadot_sync_enabled {
        let polkadot_task = {
            let db = db_manager.clone();
            let kafka = kafka_producer.clone();
            let metrics = metrics_collector.clone();
            let polkadot_config = config.clone();
            tokio::spawn(async move {
                let mut manager = PolkadotSyncManager::new(
                    polkadot_config,
                    db,
                    kafka,
                    metrics,
                );
                if let Err(e) = manager.start_sync().await {
                    error!("Polkadot sync failed: {}", e);
                }
            })
        };
        tasks.push(polkadot_task);
    }

    // Start metrics collection
    let metrics_task = tokio::spawn(async move {
        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(60));
        loop {
            interval.tick().await;
            metrics_collector.collect_system_metrics().await;
        }
    });
    tasks.push(metrics_task);

    // Start data cleanup task
    let cleanup_db = db_manager.clone();
    let cleanup_task = tokio::spawn(async move {
        let mut interval = tokio::time::interval(tokio::time::Duration::from_secs(3600)); // Every hour
        loop {
            interval.tick().await;
            if let Err(e) = cleanup_db.cleanup_old_data(30).await { // 30 days retention
                error!("Data cleanup failed: {}", e);
            }
            if let Err(e) = cleanup_db.cleanup_old_l2_data(30).await { // 30 days retention
                error!("L2 data cleanup failed: {}", e);
            }
        }
    });
    tasks.push(cleanup_task);

    info!("All services started successfully. Waiting for tasks to complete...");

    // Wait for all tasks to complete
    for task in tasks {
        if let Err(e) = task.await {
            error!("Task failed: {}", e);
        }
    }

    Ok(())
}
