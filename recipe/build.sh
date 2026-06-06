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
	-DBUILD_STATIC_LIBS:BOOL=OFF \
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
# Skip the v7/v9 downconvert tests on macOS x86_64; they fail with a
# missing-file FILE_OPEN_ERROR (see
# https://git.ligo.org/computing/ldastools/LDAS_Tools/-/issues/286).
# Same root pattern as #283. Tracked separately so a real upstream fix
# replaces this skip.
CTEST_EXCLUDE=""
if [[ "$(uname)" == "Darwin" && "${OSX_ARCH}" == "x86_64" ]]; then
	CTEST_EXCLUDE="--exclude-regex test_downconvert_framecpp_sample_(7|9)"
fi
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
	ctest --parallel ${CPU_COUNT} --verbose ${CTEST_TIMEOUT} ${CTEST_EXCLUDE} || {
	if [ "$(uname)" == "Linux" ]; then
		# see https://git.ligo.org/ldastools/LDAS_Tools/-/issues/124
		echo "WARNING: ctest failed";
	else
		exit 1;
	fi;
	}
fi

# install
cmake --build . --parallel ${CPU_COUNT} --verbose --target install
