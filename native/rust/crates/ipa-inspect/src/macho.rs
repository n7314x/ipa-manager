use goblin::{mach::Mach, Object};

use crate::error::InspectionError;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MachOSummary {
    pub is_fat: bool,
}

pub fn inspect(bytes: &[u8]) -> Result<MachOSummary, InspectionError> {
    match Object::parse(bytes).map_err(InspectionError::Parse)? {
        Object::Mach(Mach::Binary(_)) => Ok(MachOSummary { is_fat: false }),
        Object::Mach(Mach::Fat(_)) => Ok(MachOSummary { is_fat: true }),
        _ => Err(InspectionError::NotMachO),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_non_macho_bytes() {
        assert!(inspect(b"not a Mach-O file").is_err());
    }
}
