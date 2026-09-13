use core::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DeviceError {
    Unsupported,
}

impl fmt::Display for DeviceError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Unsupported => formatter.write_str("device services are not implemented"),
        }
    }
}

impl std::error::Error for DeviceError {}
