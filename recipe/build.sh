#!/bin/bash

set -euxo pipefail

# The Go toolchain is only used to generate crypto/err/err_data.c, which
# imports nothing outside the standard library. Keep it from reaching out to
# the network to resolve the (test-only) module dependencies.
export GOPROXY=off
export GOFLAGS="-mod=mod"
export GOCACHE="${SRC_DIR}/.gocache"
export GOPATH="${SRC_DIR}/.gopath"

# Go is not available when cross-compiling (see recipe.yaml); use the
# pre-generated sources in generated-src/ instead.
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
  CMAKE_ARGS="${CMAKE_ARGS} -DDISABLE_GO=ON"
fi

# GENERATE_RUST_BINDINGS runs bindgen on the build machine. libclang has no
# idea about conda's toolchain, so tell it which platform the bindings are
# for and where that platform's system headers live.
export BINDGEN_EXTRA_CLANG_ARGS="--target=${HOST} --sysroot=${CONDA_BUILD_SYSROOT}"

# ENABLE_DIST_PKG is upstream's packaging mode for installing AWS-LC alongside
# another OpenSSL implementation: headers land in include/aws-lc/openssl, the
# libraries are named libcrypto-awslc/libssl-awslc and the command line tools
# are prefixed with aws-lc-. Upstream restricts it to Linux, but everything it
# turns on that is Linux-specific (ELF symbol versioning) is independently
# gated on non-Apple UNIX, so it works on macOS and Windows as well.
cmake -GNinja -B build -S . \
  ${CMAKE_ARGS} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF \
  -DBUILD_LIBSSL=ON \
  -DBUILD_TOOL=ON \
  -DENABLE_DIST_PKG=ON \
  -DENABLE_DIST_PKG_OPENSSL_SHIM=OFF \
  -DGENERATE_RUST_BINDINGS=ON

cmake --build build --config Release
cmake --install build --config Release

# Only bindgen's input; the installed bindings are what consumers need.
rm "${PREFIX}/include/rust_wrapper.h"
