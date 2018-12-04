#!/bin/bash

./configure \
    --prefix=${PREFIX} \
    --disable-warnings-as-errors \
    --with-optimization=high \
    --without-doxygen
make -j ${CPU_COUNT}
make -j ${CPU_COUNT} install
make -j ${CPU_COUNT} check
