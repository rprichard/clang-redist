#!/bin/bash

echo "===== master-build-script.sh"
set -e -x
date
SCRIPT_SRC=$(cd $(dirname $0) && /bin/pwd)
. $SCRIPT_SRC/include.sh

package() {
    # xz tarballs do not work on OpenSUSE 11.2, so use bz2.
    cd install
    rm -f $1.tar.bz2
    tar cfj $1.tar.bz2 $1
    cd ..
}

$SCRIPT_SRC/get-packages.sh
$SCRIPT_SRC/build-clang.sh
if [ $PLATFORM = linux ]; then
    $SCRIPT_SRC/build-gcc46.sh
    $SCRIPT_SRC/build-gcc47.sh
    $SCRIPT_SRC/extract-gcc-libs.sh 4.6.3
    $SCRIPT_SRC/extract-gcc-libs.sh 4.7.2
fi
package clang-3.2-${ARCH}-${PLATFORM}
if [ $PLATFORM = linux ]; then
    package gcc-libs-4.6.3-${ARCH}-${PLATFORM}
    package gcc-libs-4.7.2-${ARCH}-${PLATFORM}
fi
