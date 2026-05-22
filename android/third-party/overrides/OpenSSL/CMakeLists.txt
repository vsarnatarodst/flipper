cmake_minimum_required(VERSION 3.6)
project(openssl_static C)

include(ExternalProject)

# Derive toolchain bin dir from the compiler path set by the NDK toolchain file
get_filename_component(TOOLCHAIN_BIN ${CMAKE_C_COMPILER} DIRECTORY)

# Map Android ABI to OpenSSL configure target
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(OPENSSL_TARGET "android-arm64")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(OPENSSL_TARGET "android-arm")
elseif(ANDROID_ABI STREQUAL "x86_64")
    set(OPENSSL_TARGET "android-x86_64")
elseif(ANDROID_ABI STREQUAL "x86")
    set(OPENSSL_TARGET "android-x86")
else()
    message(FATAL_ERROR "Unsupported ANDROID_ABI: ${ANDROID_ABI}")
endif()

set(OPENSSL_SRC_DIR   ${CMAKE_CURRENT_SOURCE_DIR}/openssl-1.1.1w)
set(OPENSSL_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/openssl_build)
set(OPENSSL_INST_DIR  ${CMAKE_CURRENT_BINARY_DIR}/install)

# Create output dirs now so CMake does not reject INTERFACE_INCLUDE_DIRECTORIES
# pointing to non-existent paths at configure time (cmake policy CMP0095 /
# the check introduced in CMake 3.22).
file(MAKE_DIRECTORY ${OPENSSL_INST_DIR}/include)
file(MAKE_DIRECTORY ${OPENSSL_INST_DIR}/lib)

ExternalProject_Add(
    openssl_build
    SOURCE_DIR    ${OPENSSL_SRC_DIR}
    BINARY_DIR    ${OPENSSL_BUILD_DIR}
    # The configure/build/install are all handled by build_openssl.sh
    CONFIGURE_COMMAND
        bash ${CMAKE_CURRENT_SOURCE_DIR}/build_openssl.sh
            ${OPENSSL_SRC_DIR}
            ${OPENSSL_BUILD_DIR}
            ${OPENSSL_INST_DIR}
            ${OPENSSL_TARGET}
            ${ANDROID_NATIVE_API_LEVEL}
            ${TOOLCHAIN_BIN}
            ${ANDROID_NDK}
    BUILD_COMMAND   ""
    INSTALL_COMMAND ""
    BUILD_BYPRODUCTS
        ${OPENSSL_INST_DIR}/lib/libssl.a
        ${OPENSSL_INST_DIR}/lib/libcrypto.a
)

# --- Imported static targets ---

add_library(openssl_crypto STATIC IMPORTED GLOBAL)
set_target_properties(openssl_crypto PROPERTIES
    IMPORTED_LOCATION          ${OPENSSL_INST_DIR}/lib/libcrypto.a
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INST_DIR}/include
)
add_dependencies(openssl_crypto openssl_build)

add_library(openssl_ssl STATIC IMPORTED GLOBAL)
set_target_properties(openssl_ssl PROPERTIES
    IMPORTED_LOCATION          ${OPENSSL_INST_DIR}/lib/libssl.a
    INTERFACE_INCLUDE_DIRECTORIES ${OPENSSL_INST_DIR}/include
    INTERFACE_LINK_LIBRARIES   openssl_crypto
)
add_dependencies(openssl_ssl openssl_build)

# Alias targets matching the naming used by the former prefab package
add_library(openssl::ssl    ALIAS openssl_ssl)
add_library(openssl::crypto ALIAS openssl_crypto)
