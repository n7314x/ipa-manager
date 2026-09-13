use crate::error::DeviceError;

pub fn install_ipa(_ipa: &[u8]) -> Result<(), DeviceError> {
    Err(DeviceError::Unsupported)
}
