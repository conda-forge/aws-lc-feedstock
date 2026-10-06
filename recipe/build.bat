@echo on

:: The Go toolchain is only used to generate crypto/err/err_data.c, which
:: imports nothing outside the standard library. Keep it from reaching out to
:: the network to resolve the (test-only) module dependencies.
set "GOPROXY=off"
set "GOFLAGS=-mod=mod"
set "GOCACHE=%SRC_DIR%\.gocache"
set "GOPATH=%SRC_DIR%\.gopath"

:: See build.sh for why ENABLE_DIST_PKG is used. On Windows this yields
:: crypto-awslc.dll / ssl-awslc.dll, headers in include\aws-lc\openssl and
:: aws-lc-bssl.exe / aws-lc-openssl.exe, so we do not clash with `openssl`.
cmake -GNinja -B build -S . ^
  %CMAKE_ARGS% ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_INSTALL_LIBDIR=lib ^
  -DBUILD_SHARED_LIBS=ON ^
  -DBUILD_TESTING=OFF ^
  -DBUILD_LIBSSL=ON ^
  -DBUILD_TOOL=ON ^
  -DENABLE_DIST_PKG=ON ^
  -DENABLE_DIST_PKG_OPENSSL_SHIM=OFF
if errorlevel 1 exit 1

cmake --build build --config Release
if errorlevel 1 exit 1

cmake --install build --config Release
if errorlevel 1 exit 1
