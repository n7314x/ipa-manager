#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PairingReference {
    pub device_identifier: String,
    pub protected_record_key: String,
}
