use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct CosmosModule { desc: NetworkDescriptor }

impl CosmosModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Cosmos, NetworkCategory::Cosmos);
        desc.priority = 7;
        Self { desc }
    }
}

impl NetworkModule for CosmosModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


