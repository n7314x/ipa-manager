use crate::error::DeviceError;

pub trait AfcService {
    fn stage_ipa(&mut self, ipa: &[u8]) -> Result<String, DeviceError>;
}
