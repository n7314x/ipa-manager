use crate::ffi_error::IpaDeviceStatus;

#[unsafe(no_mangle)]
pub extern "C" fn ipa_device_services_status() -> IpaDeviceStatus {
    IpaDeviceStatus::Unsupported
}
