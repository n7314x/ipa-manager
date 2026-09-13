#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LoadCommandSummary {
    pub command: u32,
    pub size: u32,
}
