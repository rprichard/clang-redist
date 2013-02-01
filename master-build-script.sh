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

# This part is interactive -- it uses sudo.

# All of the scripts are run in a top-level directory, so that if an end-user's
# machine attempts to access an embedded build/install path, it is likely to
# fail instantly.

TOPDIR=/clang-redist-${DIST_VERSION}-${ARCH}-${PLATFORM}
sudo rm -fr $TOPDIR
sudo mkdir $TOPDIR
sudo chown $(id -un) $TOPDIR
sudo chgrp $(id -gn) $TOPDIR
cd $TOPDIR

# The rest of the script is non-interactive.

main() {
    $SCRIPT_SRC/get-packages.sh
    $SCRIPT_SRC/build-clang.sh
    if [ $PLATFORM = linux ]; then
        $SCRIPT_SRC/build-gcc46.sh
        $SCRIPT_SRC/build-gcc47.sh
        $SCRIPT_SRC/extract-gcc-libs.sh 4.6.3
        $SCRIPT_SRC/extract-gcc-libs.sh 4.7.2
    fi
    package clang-3.2-${DIST_VERSION}-${ARCH}-${PLATFORM}
    if [ $PLATFORM = linux ]; then
        package gcc-libs-4.6.3-${DIST_VERSION}-${ARCH}-${PLATFORM}
        package gcc-libs-4.7.2-${DIST_VERSION}-${ARCH}-${PLATFORM}
    fi
    cd /
    tar cfj $HOME/$(basename $TOPDIR).tar.bz2 $(basename $TOPDIR)
}

main >build.log 2>&1
