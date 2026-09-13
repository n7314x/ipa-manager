use core::fmt;

#[derive(Debug)]
pub enum InspectionError {
    Parse(goblin::error::Error),
    NotMachO,
}

impl fmt::Display for InspectionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Parse(error) => write!(formatter, "failed to parse binary: {error}"),
            Self::NotMachO => formatter.write_str("binary is not Mach-O"),
        }
    }
}

impl std::error::Error for InspectionError {}
