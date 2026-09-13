use core::mem::size_of;

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct IpaMachOSummary {
    pub struct_size: u32,
    pub is_macho: u8,
    pub is_fat: u8,
    pub reserved: [u8; 2],
}

impl Default for IpaMachOSummary {
    fn default() -> Self {
        Self {
            struct_size: size_of::<Self>() as u32,
            is_macho: 0,
            is_fat: 0,
            reserved: [0; 2],
        }
    }
}
