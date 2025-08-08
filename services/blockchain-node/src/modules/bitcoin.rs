use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct BitcoinModule { desc: NetworkDescriptor }

impl BitcoinModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Bitcoin, NetworkCategory::Alternative);
        desc.priority = 6;
        Self { desc }
    }
}

impl NetworkModule for BitcoinModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


