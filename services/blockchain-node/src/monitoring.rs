use std::sync::atomic::{AtomicU64, Ordering};
use tracing::{info, error};

pub struct MetricsCollector {
    blocks_processed: AtomicU64,
    transactions_processed: AtomicU64,
    logs_processed: AtomicU64,
    errors_count: AtomicU64,
    last_block_number: AtomicU64,
}

impl MetricsCollector {
    pub fn new() -> Self {
        MetricsCollector {
            blocks_processed: AtomicU64::new(0),
            transactions_processed: AtomicU64::new(0),
            logs_processed: AtomicU64::new(0),
            errors_count: AtomicU64::new(0),
            last_block_number: AtomicU64::new(0),
        }
    }

    pub async fn record_block_processed(&self, block_number: u64) {
        self.blocks_processed.fetch_add(1, Ordering::Relaxed);
        self.last_block_number.store(block_number, Ordering::Relaxed);
        info!("Block {} processed", block_number);
    }

    pub async fn record_transactions_processed(&self, count: u64) {
        self.transactions_processed.fetch_add(count, Ordering::Relaxed);
    }

    pub async fn record_logs_processed(&self, count: u64) {
        self.logs_processed.fetch_add(count, Ordering::Relaxed);
    }

    pub async fn record_error(&self) {
        self.errors_count.fetch_add(1, Ordering::Relaxed);
        error!("Error recorded in metrics");
    }

    pub fn get_metrics(&self) -> MetricsSnapshot {
        MetricsSnapshot {
            blocks_processed: self.blocks_processed.load(Ordering::Relaxed),
            transactions_processed: self.transactions_processed.load(Ordering::Relaxed),
            logs_processed: self.logs_processed.load(Ordering::Relaxed),
            errors_count: self.errors_count.load(Ordering::Relaxed),
            last_block_number: self.last_block_number.load(Ordering::Relaxed),
        }
    }

    pub async fn start_collecting(&self) -> Result<(), Box<dyn std::error::Error>> {
        info!("Starting metrics collection...");
        
        loop {
            let metrics = self.get_metrics();
            info!("Metrics snapshot: {:?}", metrics);
            
            // Здесь можно добавить отправку метрик в Prometheus
            // или другие системы мониторинга
            
            tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
        }
    }
}

#[derive(Debug, Clone)]
pub struct MetricsSnapshot {
    pub blocks_processed: u64,
    pub transactions_processed: u64,
    pub logs_processed: u64,
    pub errors_count: u64,
    pub last_block_number: u64,
}
