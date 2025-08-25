use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct EvmModule { desc: NetworkDescriptor }

impl EvmModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Evm, NetworkCategory::Layer1);
        desc.priority = 9;
        Self { desc }
    }
}

impl NetworkModule for EvmModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


