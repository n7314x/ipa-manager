#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Architecture {
    Arm64,
    Arm64e,
    X86_64,
    Unknown(i32),
}
