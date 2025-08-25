use crate::network::{NetworkCategory, NetworkDescriptor, NetworkModule, NetworkRuntime};

pub struct MoveVmModule { desc: NetworkDescriptor }

impl MoveVmModule {
    pub fn new(key: &str, name: &str, category: NetworkCategory) -> Self {
        let mut desc = NetworkDescriptor::new(key, name, NetworkRuntime::MoveVm, category);
        desc.priority = 7;
        Self { desc }
    }
}

impl NetworkModule for MoveVmModule {
    fn descriptor(&self) -> &NetworkDescriptor { &self.desc }
}


