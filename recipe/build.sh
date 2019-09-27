#!/bin/bash

mkdir -p _build
pushd _build

# link librt to get clock_gettime on older glibc versions
if [ "$(uname)" == "Linux" ]; then
	export LDFLAGS="-lrt ${LDFLAGS}"
fi

# configure
cmake ${SRC_DIR} \
	-DCMAKE_INSTALL_PREFIX=${PREFIX} \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_INSTALL_LIBDIR="lib" \
	-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=true

# build
cmake --build . -- -j${CPU_COUNT}

# test
ctest -V

cmake --build . --target install
