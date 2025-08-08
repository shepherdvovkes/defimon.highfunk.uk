use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct SubstrateModule { desc: NetworkDescriptor }

impl SubstrateModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Substrate, NetworkCategory::Polkadot);
        desc.priority = 7;
        Self { desc }
    }
}

impl NetworkModule for SubstrateModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


