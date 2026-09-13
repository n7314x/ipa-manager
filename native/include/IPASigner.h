#ifndef IPA_SIGNER_H
#define IPA_SIGNER_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define IPA_SIGNER_API_VERSION 1u

typedef int32_t ipa_sign_status_t;
enum {
    IPA_SIGN_OK = 0,
    IPA_SIGN_INVALID_ARGUMENT = 1,
    IPA_SIGN_UNSUPPORTED = 2,
    IPA_SIGN_IO_ERROR = 3,
    IPA_SIGN_CERTIFICATE_ERROR = 10,
    IPA_SIGN_PROFILE_ERROR = 11,
    IPA_SIGN_ENTITLEMENT_ERROR = 12,
    IPA_SIGN_SIGNING_ERROR = 20,
    IPA_SIGN_VERIFICATION_ERROR = 21,
    IPA_SIGN_EXCEPTION = 254,
    IPA_SIGN_INTERNAL_ERROR = 255
};

typedef struct ipa_byte_view {
    const uint8_t *data;
    uint64_t length;
} ipa_byte_view_t;

typedef ipa_byte_view_t ipa_utf8_view_t;

typedef struct ipa_utf8_view_list {
    const ipa_utf8_view_t *items;
    uint64_t count;
} ipa_utf8_view_list_t;

typedef struct ipa_sign_request {
    uint32_t struct_size;
    uint32_t api_version;
    ipa_utf8_view_t input_ipa_path;
    ipa_utf8_view_t output_ipa_path;
    ipa_utf8_view_t p12_path;
    ipa_byte_view_t p12_password;
    ipa_utf8_view_list_t provisioning_profile_paths;
    ipa_utf8_view_t bundle_id_override;
    ipa_utf8_view_t display_name_override;
} ipa_sign_request_t;

/*
 * Every view is borrowed for this call only. No pointer is retained or freed by the callee.
 * UTF-8 views are not NUL-terminated. An optional view is {NULL, 0}. Lists borrow both
 * their item array and each item. At least one provisioning profile path is required.
 * The caller must erase its password buffer as soon as the call returns.
 */
uint32_t ipa_signer_api_version(void);
ipa_sign_status_t ipa_sign_ipa(const ipa_sign_request_t *request);

#ifdef __cplusplus
}
#endif

#endif
