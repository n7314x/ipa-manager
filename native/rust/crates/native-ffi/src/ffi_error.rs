#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IpaInspectStatus {
    Ok = 0,
    InvalidArgument = 1,
    ParseError = 2,
    Panic = 254,
    InternalError = 255,
}

#[repr(i32)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IpaDeviceStatus {
    Unsupported = 2,
    Panic = 254,
}
