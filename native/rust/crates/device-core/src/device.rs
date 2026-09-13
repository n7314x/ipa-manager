#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeviceRecord {
    pub identifier: String,
    pub display_name: String,
    pub product_version: Option<String>,
}
