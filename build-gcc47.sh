#!/bin/bash
#
# Build GCC.  We need libstdc++ and some object/library files that shipped as
# part of GCC.  Unfortunately, we apparently have to build all of GCC to get
# them.

echo "===== build-gcc47.sh"
set -e -x
date
TOP=$PWD
SCRIPT_SRC=$(cd $(dirname $0) && /bin/pwd)
. $SCRIPT_SRC/include.sh

VERSION_GCC=4.7.2
PREFIX=$INSTALL/gcc-${VERSION_GCC}-${ARCH}-${PLATFORM}

# Extract GCC and its dependencies.
cd $SRC
rm -fr gcc-${VERSION_GCC}
tar xfj $TOP/gcc-${VERSION_GCC}.tar.bz2
cd $SRC/gcc-${VERSION_GCC}
tar xfj $TOP/gmp-5.0.5.tar.bz2
mv gmp-5.0.5 gmp
tar xfj $TOP/mpfr-3.1.0.tar.bz2
mv mpfr-3.1.0 mpfr
tar xfz $TOP/mpc-0.9.tar.gz
mv mpc-0.9 mpc

# Configure and build GCC.
cd $BUILD
rm -fr gcc-${VERSION_GCC}
mkdir $BUILD/gcc-${VERSION_GCC}
cd $BUILD/gcc-${VERSION_GCC}
$SRC/gcc-${VERSION_GCC}/configure \
    --prefix $PREFIX \
    --enable-languages=c,c++ \
    --enable-__cxa_atexit \
    --disable-multilib \
    --with-mpfr-include=$SRC/gcc-${VERSION_GCC}/mpfr/src \
    --with-mpfr-lib=$BUILD/gcc-${VERSION_GCC}/mpfr/src/.libs \
    > ../gcc-${VERSION_GCC}-configure-log 2>&1
make -j$NPROC > ../gcc-${VERSION_GCC}-build-log 2>&1
make install > ../gcc-${VERSION_GCC}-install-log 2>&1
date
