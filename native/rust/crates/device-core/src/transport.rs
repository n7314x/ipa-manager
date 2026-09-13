use crate::error::DeviceError;

pub trait DeviceTransport {
    fn send(&mut self, request: &[u8]) -> Result<Vec<u8>, DeviceError>;
}
