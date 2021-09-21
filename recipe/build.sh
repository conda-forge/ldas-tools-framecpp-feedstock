#!/bin/bash

mkdir -p _build
pushd _build

# link librt to get clock_gettime on older glibc versions
if [ "$(uname)" == "Linux" ]; then
	export LDFLAGS="-lrt ${LDFLAGS}"
fi

# configure
cmake \
	${SRC_DIR} \
	${CMAKE_ARGS} \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=true \
	-DCMAKE_OSX_ARCHITECTURES:STRING="${OSX_ARCH}" \
;

# build
cmake --build . --parallel ${CPU_COUNT} --verbose

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" ]]; then
	ctest --parallel ${CPU_COUNT} --verbose
fi

# install
cmake --build . --parallel ${CPU_COUNT} --verbose --target install
