#!/bin/bash

set -e

mkdir -p _build
pushd _build

set -x

# if truly cross-compiling, disable the tests
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" && "${CROSSCOMPILING_EMULATOR}" == "" ]]; then
	BUILD_TESTING="off"
else
	BUILD_TESTING="on"
fi

# link librt to get clock_gettime on older glibc versions
if [ "$(uname)" == "Linux" ]; then
	export LDFLAGS="-lrt ${LDFLAGS}"
fi

# configure
cmake \
	${SRC_DIR} \
	${CMAKE_ARGS} \
	-DBUILD_TESTING:BOOL=${BUILD_TESTING} \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_CROSSCOMPILING_EMULATOR:STRING="${CMAKE_CROSSCOMPILING_EMULATOR}" \
	-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=true \
	-DCMAKE_OSX_ARCHITECTURES:STRING="${OSX_ARCH}" \
	-DCMAKE_POLICY_VERSION_MINIMUM:STRING=3.5 \
;

# build
cmake --build . --parallel ${CPU_COUNT} --verbose

# test
if [[ "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
	CTEST_TIMEOUT="--timeout 3600"
else
	CTEST_TIMEOUT=""
fi
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
	ctest --parallel ${CPU_COUNT} --verbose ${CTEST_TIMEOUT}
fi

# install
cmake --build . --parallel ${CPU_COUNT} --verbose --target install
