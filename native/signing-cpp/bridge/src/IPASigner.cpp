#include "IPASigner.h"

#include <cstddef>

namespace {
bool valid_required_view(const ipa_byte_view_t view) noexcept {
    return view.data != nullptr && view.length > 0;
}

bool valid_optional_view(const ipa_byte_view_t view) noexcept {
    return view.data != nullptr || view.length == 0;
}

bool valid_profile_paths(const ipa_utf8_view_list_t paths) noexcept {
    if (paths.items == nullptr || paths.count == 0 || paths.count > 1'024) {
        return false;
    }
    for (uint64_t index = 0; index < paths.count; ++index) {
        if (!valid_required_view(paths.items[index])) {
            return false;
        }
    }
    return true;
}
}  // namespace

extern "C" uint32_t ipa_signer_api_version(void) { return IPA_SIGNER_API_VERSION; }

extern "C" ipa_sign_status_t ipa_sign_ipa(const ipa_sign_request_t *request) {
    try {
        if (request == nullptr || request->struct_size < sizeof(ipa_sign_request_t) ||
            request->api_version != IPA_SIGNER_API_VERSION ||
            !valid_required_view(request->input_ipa_path) ||
            !valid_required_view(request->output_ipa_path) ||
            !valid_required_view(request->p12_path) ||
            !valid_profile_paths(request->provisioning_profile_paths) ||
            !valid_optional_view(request->p12_password) ||
            !valid_optional_view(request->bundle_id_override) ||
            !valid_optional_view(request->display_name_override)) {
            return IPA_SIGN_INVALID_ARGUMENT;
        }

        // The embedded zsign-style engine is a later, separately licensed integration spike.
        return IPA_SIGN_UNSUPPORTED;
    } catch (...) {
        return IPA_SIGN_EXCEPTION;
    }
}
