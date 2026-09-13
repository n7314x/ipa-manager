use core::{mem::size_of, slice};
use std::panic::{AssertUnwindSafe, catch_unwind};

use crate::{ffi_error::IpaInspectStatus, ffi_types::IpaMachOSummary};

#[unsafe(no_mangle)]
/// Inspects a borrowed byte buffer and writes a caller-owned summary.
///
/// # Safety
///
/// For nonzero `length`, `bytes` must address at least that many readable bytes.
/// `out_summary` must address a writable, initialized `IpaMachOSummary`.
pub unsafe extern "C" fn ipa_inspect_macho(
    bytes: *const u8,
    length: u64,
    out_summary: *mut IpaMachOSummary,
) -> IpaInspectStatus {
    match catch_unwind(AssertUnwindSafe(|| {
        inspect_impl(bytes, length, out_summary)
    })) {
        Ok(status) => status,
        Err(_) => IpaInspectStatus::Panic,
    }
}

fn inspect_impl(
    bytes: *const u8,
    length: u64,
    out_summary: *mut IpaMachOSummary,
) -> IpaInspectStatus {
    if out_summary.is_null() || (bytes.is_null() && length != 0) {
        return IpaInspectStatus::InvalidArgument;
    }
    let Ok(length) = usize::try_from(length) else {
        return IpaInspectStatus::InvalidArgument;
    };
    let input = if length == 0 {
        &[]
    } else {
        // SAFETY: a non-null pointer and its caller-provided length are borrowed only for this call.
        unsafe { slice::from_raw_parts(bytes, length) }
    };
    // SAFETY: the caller promises a writable summary; struct_size is checked before replacement.
    let output = unsafe { &mut *out_summary };
    if output.struct_size < size_of::<IpaMachOSummary>() as u32 {
        return IpaInspectStatus::InvalidArgument;
    }
    match ipa_inspect::macho::inspect(input) {
        Ok(summary) => {
            *output = IpaMachOSummary {
                is_macho: 1,
                is_fat: u8::from(summary.is_fat),
                ..IpaMachOSummary::default()
            };
            IpaInspectStatus::Ok
        }
        Err(_) => IpaInspectStatus::ParseError,
    }
}
