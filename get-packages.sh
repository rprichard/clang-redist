#!/bin/bash
#
# Usage:
# ./get-packages.sh
#
# This script can optionally download packages from a cache.  Use this syntax:
#    DIST_CACHE_URL=<cache-url> ./get-packages
# The script will first attempt to download each package from
# <cache-url>/<basename-of-archive> before trying the official site.

echo "===== get-packages.sh"
date
SCRIPT_SRC=$(cd $(dirname $0) && /bin/pwd)
. $SCRIPT_SRC/include.sh

GNU_URL=http://mirrors.kernel.org/gnu

get() {
    URL=$1
    FILENAME=$(basename $URL)
    if [ ! -f $FILENAME ]; then
        if [ "$DIST_CACHE_URL" != "" ]; then
            wget $DIST_CACHE_URL/$FILENAME
        fi
    fi
    if [ ! -f $FILENAME ]; then
        wget $URL
    fi
}

# GCC 4.6.3 is the newest 4.6 compiler to-date, and 4.7.2 is the newest 4.7
# compiler to-date.  The gcc/gmp/mpfr/mpc package versions are the same ones
# used in Ubuntu 12.04 and 12.10.
#
# xz tarballs do not work on OpenSUSE 11.2, so use the bz2 packages for
# gmp-5.0.5 and mpfr-3.1.0.
get $GNU_URL/gcc/gcc-4.6.3/gcc-core-4.6.3.tar.bz2
get $GNU_URL/gcc/gcc-4.6.3/gcc-g++-4.6.3.tar.bz2
get $GNU_URL/gcc/gcc-4.7.2/gcc-4.7.2.tar.bz2
get $GNU_URL/gmp/gmp-5.0.2.tar.bz2
get $GNU_URL/gmp/gmp-5.0.5.tar.bz2
get $GNU_URL/mpfr/mpfr-3.1.0.tar.bz2
get http://www.multiprecision.org/mpc/download/mpc-0.9.tar.gz
get http://llvm.org/releases/3.2/llvm-3.2.src.tar.gz
get http://llvm.org/releases/3.2/clang-3.2.src.tar.gz
get http://llvm.org/releases/3.2/compiler-rt-3.2.src.tar.gz

set -e
echo "Checking SHA256 checksums of downloaded files..."
sha256sum -c $SCRIPT_SRC/sha256sums.txt

date
