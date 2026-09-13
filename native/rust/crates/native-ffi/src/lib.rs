pub mod ffi_device;
pub mod ffi_error;
pub mod ffi_inspection;
pub mod ffi_types;

pub const NATIVE_FFI_API_VERSION: u32 = 1;

#[unsafe(no_mangle)]
pub extern "C" fn ipa_manager_native_api_version() -> u32 {
    NATIVE_FFI_API_VERSION
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_api_version() {
        assert_eq!(ipa_manager_native_api_version(), 1);
    }
}
