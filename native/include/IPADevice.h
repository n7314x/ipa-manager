#ifndef IPA_DEVICE_H
#define IPA_DEVICE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int32_t ipa_device_status_t;
enum {
    IPA_DEVICE_OK = 0,
    IPA_DEVICE_INVALID_ARGUMENT = 1,
    IPA_DEVICE_UNSUPPORTED = 2,
    IPA_DEVICE_NOT_CONNECTED = 3,
    IPA_DEVICE_PAIRING_ERROR = 4,
    IPA_DEVICE_TRANSPORT_ERROR = 5,
    IPA_DEVICE_INSTALL_ERROR = 6,
    IPA_DEVICE_PANIC = 254,
    IPA_DEVICE_INTERNAL_ERROR = 255
};

/* Returns IPA_DEVICE_UNSUPPORTED until the pinned idevice integration is added. */
ipa_device_status_t ipa_device_services_status(void);

#ifdef __cplusplus
}
#endif

#endif
