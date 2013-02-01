#!/bin/bash

echo "===== build-clang.sh"
set -e -x
date
TOP=$PWD
SCRIPT_SRC=$(cd $(dirname $0) && /bin/pwd)
. $SCRIPT_SRC/include.sh

VERSION_CLANG=3.2
PREFIX=$INSTALL/clang-${VERSION_CLANG}-${DIST_VERSION}-${ARCH}-${PLATFORM}

# Extract Clang.
cd $SRC
rm -fr clang-${VERSION_CLANG}
tar xfz $TOP/llvm-${VERSION_CLANG}.src.tar.gz
mv llvm-${VERSION_CLANG}.src clang-${VERSION_CLANG}
cd $SRC/clang-${VERSION_CLANG}/tools
tar xfz $TOP/clang-${VERSION_CLANG}.src.tar.gz
mv clang-${VERSION_CLANG}.src clang
cd $SRC/clang-${VERSION_CLANG}/projects
tar xfz $TOP/compiler-rt-${VERSION_CLANG}.src.tar.gz
mv compiler-rt-${VERSION_CLANG}.src compiler-rt

# Patch LLVM.
cd $SRC/clang-${VERSION_CLANG}
patch -p0 < $SCRIPT_SRC/clang-relocation.patch

EXTRA_OPTIONS=
if [ $PLATFORM = darwin ]; then
    EXTRA_OPTIONS="--enable-libcpp $EXTRA_OPTIONS"
fi

# Configure and build LLVM.
cd $BUILD
rm -fr clang-${VERSION_CLANG}
mkdir $BUILD/clang-${VERSION_CLANG}
cd $BUILD/clang-${VERSION_CLANG}
$SRC/clang-${VERSION_CLANG}/configure \
    --prefix=$PREFIX \
    --disable-assertions \
    --enable-optimized \
    --enable-shared \
    $EXTRA_OPTIONS \
    > ../clang-${VERSION_CLANG}-configure-log 2>&1
make -j$NPROC > ../clang-${VERSION_CLANG}-build-log 2>&1
make install > ../clang-${VERSION_CLANG}-install-log 2>&1

if [ $PLATFORM = linux ]; then
    # Clang is configured to build and link against a libLLVM shared object.  The
    # binaries find the shared object using an RPATH, which includes
    # $ORIGIN/../lib, which is good, but it also includes an absolute path to the
    # build directory, which is at best useless.  Clean up the RPATH entries.
    $SCRIPT_SRC/update-rpath-entries.py \
        --use-origin $PREFIX --discard $BUILD --reject / -- $PREFIX
fi

# Run Clang tests in the build directory.
cd $BUILD/clang-${VERSION_CLANG}/test
make check-all > ../../clang-${VERSION_CLANG}-test-log 2>&1

date
