#!/bin/bash
set -e

SRC_DIR="$1"
BUILD_DIR="$2"
INSTALL_DIR="$3"
TARGET="$4"
API_LEVEL="$5"
TOOLCHAIN_BIN="$6"
NDK="$7"

# Copy sources to avoid polluting the original source tree (needed for parallel ABI builds)
rm -rf "$BUILD_DIR"
cp -r "$SRC_DIR" "$BUILD_DIR"

export PATH="$TOOLCHAIN_BIN:$PATH"
export ANDROID_NDK_HOME="$NDK"

cd "$BUILD_DIR"
perl Configure "$TARGET" \
    "-D__ANDROID_API__=$API_LEVEL" \
    no-shared \
    no-tests \
    "--prefix=$INSTALL_DIR"

make -j4 build_libs
make install_dev
