#include "IPASigner.h"

#include <cassert>
#include <cstddef>
#include <cstdint>

namespace {
ipa_utf8_view_t view(const char *text, std::size_t size) {
    return {reinterpret_cast<const uint8_t *>(text), size};
}
}  // namespace

int main() {
    assert(ipa_signer_api_version() == IPA_SIGNER_API_VERSION);
    assert(ipa_sign_ipa(nullptr) == IPA_SIGN_INVALID_ARGUMENT);

    const char input[] = "input.ipa";
    const char output[] = "output.ipa";
    const char p12[] = "identity.p12";
    const char profile[] = "profile.mobileprovision";
    ipa_sign_request_t request{};
    request.struct_size = sizeof(request);
    request.api_version = IPA_SIGNER_API_VERSION;
    request.input_ipa_path = view(input, sizeof(input) - 1);
    request.output_ipa_path = view(output, sizeof(output) - 1);
    request.p12_path = view(p12, sizeof(p12) - 1);
    const ipa_utf8_view_t profiles[] = {view(profile, sizeof(profile) - 1)};
    request.provisioning_profile_paths = {profiles, 1};
    assert(ipa_sign_ipa(&request) == IPA_SIGN_UNSUPPORTED);
    return 0;
}
