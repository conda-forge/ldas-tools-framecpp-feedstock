#!/bin/bash

mkdir -p _build
pushd _build

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
