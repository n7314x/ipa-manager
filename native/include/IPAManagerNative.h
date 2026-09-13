#ifndef IPA_MANAGER_NATIVE_H
#define IPA_MANAGER_NATIVE_H

#include <stddef.h>
#include <stdint.h>

#include "IPADevice.h"
#include "IPAInspector.h"

#ifdef __cplusplus
extern "C" {
#endif

#define IPA_MANAGER_NATIVE_API_VERSION 1u

/* All functions are thread-safe unless their documentation says otherwise. */
uint32_t ipa_manager_native_api_version(void);

#ifdef __cplusplus
}
#endif

#endif
