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

# build somehow overrides cmake's standard -DCMAKE_CXX_STANDARD=14, probably due to
# https://git.ligo.org/computing/ldastools/LDAS_Tools/-/blob/master/framecpp/CMakeLists.txt#L57
# need to use C++14, because the code still uses std::binary_function, which got removed in C++17
export CMAKE_CXX_STANDARD="14"

# configure
cmake \
	${SRC_DIR} \
	${CMAKE_ARGS} \
	-DBUILD_TESTING:BOOL=${BUILD_TESTING} \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_CROSSCOMPILING_EMULATOR:STRING="${CMAKE_CROSSCOMPILING_EMULATOR}" \
	-DCMAKE_CXX_STANDARD=14 \
	-DCMAKE_DISABLE_FIND_PACKAGE_Doxygen=true \
	-DCMAKE_OSX_ARCHITECTURES:STRING="${OSX_ARCH}" \
;

# build
cmake --build . --parallel ${CPU_COUNT} --verbose

# test
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
	ctest --parallel ${CPU_COUNT} --verbose
fi

# install
cmake --build . --parallel ${CPU_COUNT} --verbose --target install
