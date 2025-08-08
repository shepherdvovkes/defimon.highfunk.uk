use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct StarknetModule { desc: NetworkDescriptor }

impl StarknetModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Starknet, NetworkCategory::EthereumLayer2);
        desc.priority = 8;
        Self { desc }
    }
}

impl NetworkModule for StarknetModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


