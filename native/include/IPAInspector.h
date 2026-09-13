#ifndef IPA_INSPECTOR_H
#define IPA_INSPECTOR_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t ipa_inspect_status_t;
enum {
    IPA_INSPECT_OK = 0,
    IPA_INSPECT_INVALID_ARGUMENT = 1,
    IPA_INSPECT_PARSE_ERROR = 2,
    IPA_INSPECT_PANIC = 254,
    IPA_INSPECT_INTERNAL_ERROR = 255
};

typedef struct ipa_macho_summary {
    uint32_t struct_size;
    uint8_t is_macho;
    uint8_t is_fat;
    uint8_t reserved[2];
} ipa_macho_summary_t;

/*
 * `bytes` is borrowed for this call only and may be NULL only when length is zero.
 * `out_summary` is caller-owned and must remain writable for the duration of the call.
 * The function allocates no memory and retains no pointers.
 */
ipa_inspect_status_t ipa_inspect_macho(
    const uint8_t *bytes,
    uint64_t length,
    ipa_macho_summary_t *out_summary
);

#ifdef __cplusplus
}
#endif

#endif
