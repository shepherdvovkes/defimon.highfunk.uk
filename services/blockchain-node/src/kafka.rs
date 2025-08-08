use rdkafka::{
    producer::{FutureProducer, FutureRecord},
    ClientConfig,
};
use serde::Serialize;
use tracing::{info, error};

pub struct KafkaProducer {
    producer: FutureProducer,
}

impl KafkaProducer {
    pub async fn new(bootstrap_servers: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let producer: FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", bootstrap_servers)
            .set("message.timeout.ms", "5000")
            .set("delivery.timeout.ms", "10000")
            .set("request.timeout.ms", "5000")
            .set("retry.backoff.ms", "100")
            .set("max.in.flight.requests.per.connection", "5")
            .set("enable.idempotence", "true")
            .set("compression.type", "snappy")
            .create()?;

        Ok(KafkaProducer { producer })
    }

    pub async fn send_message<T: Serialize>(
        &self,
        topic: &str,
        data: &T,
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let json_data = serde_json::to_string(data)?;
        
        let key = format!("{}", chrono::Utc::now().timestamp());
        let record = FutureRecord::to(topic)
            .payload(&json_data)
            .key(&key);

        match self.producer.send(record, std::time::Duration::from_secs(5)).await {
            Ok(_) => {
                info!("Message sent to topic: {}", topic);
                Ok(())
            }
            Err((e, _)) => {
                error!("Failed to send message to topic {}: {}", topic, e);
                Err(Box::new(e))
            }
        }
    }

    pub async fn send_batch_messages<T: Serialize>(
        &self,
        topic: &str,
        messages: &[T],
    ) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        for (i, message) in messages.iter().enumerate() {
            let json_data = serde_json::to_string(message)?;
            
            let key = format!("{}_{}", chrono::Utc::now().timestamp(), i);
            let record = FutureRecord::to(topic)
                .payload(&json_data)
                .key(&key);

            match self.producer.send(record, std::time::Duration::from_secs(5)).await {
                Ok(_) => {
                    info!("Batch message {} sent to topic: {}", i, topic);
                }
                Err((e, _)) => {
                    error!("Failed to send batch message {} to topic {}: {}", i, topic, e);
                    return Err(Box::new(e));
                }
            }
        }

        Ok(())
    }
}
