use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct SolanaModule { desc: NetworkDescriptor }

impl SolanaModule {
    pub fn new(key: &str, name: &str) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::Solana, NetworkCategory::Alternative);
        desc.priority = 8;
        Self { desc }
    }
}

impl NetworkModule for SolanaModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


