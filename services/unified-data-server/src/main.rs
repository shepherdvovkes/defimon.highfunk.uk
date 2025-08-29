use std::sync::Arc;
use tracing::{info, error};
use tracing_subscriber;
use axum::{
    routing::get,
    Router,
    extract::{State, Path, Query},
    Json,
    http::StatusCode,
    response::IntoResponse,
};
use serde_json;
use chrono::Utc;

mod config;
mod database;
mod collectors;
mod api;
mod models;

use config::Config;
use database::DatabaseManager;
use collectors::{
    ethereum::EthereumCollector,
    l2::L2Collector,
    cosmos::CosmosCollector,
    polkadot::PolkadotCollector,
    price::PriceCollector,
};

#[derive(Clone)]
struct AppState {
    db: Arc<DatabaseManager>,
    config: Config,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt::init();
    info!("Starting DEFIMON Unified Data Server...");
    let config = Config::load()?;
    info!("Configuration loaded successfully");
    let db_config = database::DatabaseConfig {
        url: config.database_url.clone(),
        max_connections: 20,
        min_connections: 5,
        connection_timeout: 30,
    };
    let db_manager = Arc::new(DatabaseManager::new(db_config).await?);
    info!("Database connection established");
    let state = AppState {
        db: db_manager.clone(),
        config: config.clone(),
    };

    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/v1/networks", get(get_networks))
        .route("/api/v1/networks/:network/blocks", get(get_blocks))
        .route("/api/v1/networks/:network/transactions", get(get_transactions))
        .route("/api/v1/networks/:network/stats", get(get_network_stats))
        .route("/api/v1/protocols", get(get_protocols))
        .route("/api/v1/protocols/:protocol", get(get_protocol_data))
        .route("/api/v1/prices", get(get_prices))
        .route("/api/v1/prices/:asset", get(get_asset_price))
        .route("/api/v1/dashboard", get(get_dashboard_data))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", config.api_port);
    info!("Starting API server on {}", addr);

    // Start data collectors
    let db_for_ethereum = db_manager.clone();
    let ethereum_collector = EthereumCollector::new(db_for_ethereum, config.ethereum_node_url.clone());
    let ethereum_task = tokio::spawn(async move {
        if let Err(e) = ethereum_collector.start_collection().await {
            error!("Ethereum collector failed: {}", e);
        }
    });

    let db_for_l2 = db_manager.clone();
    let l2_collector = L2Collector::new(db_for_l2);
    let l2_task = tokio::spawn(async move {
        if let Err(e) = l2_collector.start_collection().await {
            error!("L2 collector failed: {}", e);
        }
    });

    let db_for_price = db_manager.clone();
    let price_collector = PriceCollector::new(db_for_price);
    let price_task = tokio::spawn(async move {
        if let Err(e) = price_collector.start_collection().await {
            error!("Price collector failed: {}", e);
        }
    });

    let server_task = tokio::spawn(async move {
        axum::serve(
            tokio::net::TcpListener::bind(&addr).await.unwrap(),
            app
        ).await.unwrap();
    });

    info!("All services started successfully. Waiting for tasks to complete...");
    
    // Wait for all tasks
    tokio::select! {
        _ = ethereum_task => error!("Ethereum collector task ended"),
        _ = l2_task => error!("L2 collector task ended"),
        _ = price_task => error!("Price collector task ended"),
        _ = server_task => error!("Server task ended"),
    }

    Ok(())
}

// Health check endpoint
async fn health_check() -> impl IntoResponse {
    Json(serde_json::json!({
        "status": "healthy",
        "timestamp": Utc::now().to_rfc3339(),
        "service": "defimon-unified-data-server"
    }))
}

// Get all supported networks
async fn get_networks(_state: State<AppState>) -> impl IntoResponse {
    let networks = vec![
        "ethereum",
        "polygon",
        "arbitrum",
        "optimism",
        "base",
        "zksync",
        "linea",
        "scroll",
        "cosmos",
        "osmosis",
        "polkadot",
        "kusama",
        "moonbeam",
        "moonriver",
        "astar",
        "acala"
    ];

    Json(serde_json::json!({
        "networks": networks,
        "total": networks.len()
    }))
}

// Get blocks for a specific network
async fn get_blocks(
    state: State<AppState>,
    Path(network): Path<String>,
    Query(params): Query<std::collections::HashMap<String, String>>,
) -> impl IntoResponse {
    let limit = params.get("limit").and_then(|s| s.parse::<i64>().ok()).unwrap_or(100);
    let offset = params.get("offset").and_then(|s| s.parse::<i64>().ok()).unwrap_or(0);

    match state.db.get_blocks(&network, limit, offset).await {
        Ok(blocks) => Json(serde_json::json!({
            "network": network,
            "blocks": blocks,
            "limit": limit,
            "offset": offset
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get transactions for a specific network
async fn get_transactions(
    state: State<AppState>,
    Path(network): Path<String>,
    Query(params): Query<std::collections::HashMap<String, String>>,
) -> impl IntoResponse {
    let limit = params.get("limit").and_then(|s| s.parse::<i64>().ok()).unwrap_or(100);
    let offset = params.get("offset").and_then(|s| s.parse::<i64>().ok()).unwrap_or(0);

    match state.db.get_transactions(&network, limit, offset).await {
        Ok(transactions) => Json(serde_json::json!({
            "network": network,
            "transactions": transactions,
            "limit": limit,
            "offset": offset
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get network statistics
async fn get_network_stats(
    state: State<AppState>,
    Path(network): Path<String>,
) -> impl IntoResponse {
    match state.db.get_network_stats(&network).await {
        Ok(stats) => Json(serde_json::json!({
            "network": network,
            "stats": stats
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get all protocols
async fn get_protocols(state: State<AppState>) -> impl IntoResponse {
    match state.db.get_protocols().await {
        Ok(protocols) => Json(serde_json::json!({
            "protocols": protocols
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get protocol data
async fn get_protocol_data(
    state: State<AppState>,
    Path(protocol): Path<String>,
) -> impl IntoResponse {
    match state.db.get_protocol_data(&protocol).await {
        Ok(data) => Json(serde_json::json!({
            "protocol": protocol,
            "data": data
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get all prices
async fn get_prices(state: State<AppState>) -> impl IntoResponse {
    match state.db.get_prices().await {
        Ok(prices) => Json(serde_json::json!({
            "prices": prices
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get specific asset price
async fn get_asset_price(
    state: State<AppState>,
    Path(asset): Path<String>,
) -> impl IntoResponse {
    match state.db.get_asset_price(&asset).await {
        Ok(price) => Json(serde_json::json!({
            "asset": asset,
            "price": price
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}

// Get dashboard data
async fn get_dashboard_data(state: State<AppState>) -> impl IntoResponse {
    match state.db.get_dashboard_data().await {
        Ok(data) => Json(serde_json::json!({
            "dashboard": data
        })).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({
            "error": e.to_string()
        }))).into_response(),
    }
}
