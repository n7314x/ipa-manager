cmake_minimum_required(VERSION 3.20)
project(IPAManagerSigningCore VERSION 0.1.0 LANGUAGES CXX)

option(IPA_SIGNING_BUILD_TESTS "Build signing C ABI tests" ON)

add_library(ipa_signing_bridge STATIC bridge/src/IPASigner.cpp)
target_include_directories(ipa_signing_bridge PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/../include)
target_compile_features(ipa_signing_bridge PUBLIC cxx_std_17)
set_target_properties(ipa_signing_bridge PROPERTIES
    CXX_EXTENSIONS OFF
    POSITION_INDEPENDENT_CODE ON
    PUBLIC_HEADER "${CMAKE_CURRENT_SOURCE_DIR}/../include/IPASigner.h"
)

if(IPA_SIGNING_BUILD_TESTS)
    enable_testing()
    add_executable(ipa_signing_bridge_tests tests/IPASignerTests.cpp)
    target_link_libraries(ipa_signing_bridge_tests PRIVATE ipa_signing_bridge)
    add_test(NAME ipa_signing_bridge_tests COMMAND ipa_signing_bridge_tests)
endif()
