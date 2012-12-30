#!/bin/bash

if [ "$1" = "" ]; then
    echo "Pass a version number to this script."
    exit 1
fi

echo "===== extract-gcc-libs.sh"
set -e -x
SCRIPT_SRC=$(cd $(dirname $0) && /bin/pwd)
. $SCRIPT_SRC/include.sh

VERSION_GCC=$1
PREFIX_GCC=$INSTALL/gcc-${VERSION_GCC}-${ARCH}-linux
PREFIX_GCC_LIBS=${INSTALL}/gcc-libs-${VERSION_GCC}-${ARCH}-linux

rm -fr ${PREFIX_GCC_LIBS}
mkdir ${PREFIX_GCC_LIBS}

# Deliberately omit the bin and libexec directories -- they contain GCC
# binaries.

# Copy the include directory, which has libstdc++ headers.
cp -r ${PREFIX_GCC}/include ${PREFIX_GCC_LIBS}

# Copy the lib directory.  It has many things in it, most notably the libstdc++
# and libgcc libraries.
cp -r ${PREFIX_GCC}/lib ${PREFIX_GCC_LIBS}

# Remove la files.  They have absolute paths in them that would need
# relocating.
rm ${PREFIX_GCC_LIBS}/lib/*.la

# Remove this Python script.  It uses an absolute path to find a Python script
# in the share directory.  The path would need relocating.
rm ${PREFIX_GCC_LIBS}/lib/libstdc++.so.*gdb.py

# Remove fixed-up headers.  They come from the host system and are not
# applicable to other distributions.
rm -r ${PREFIX_GCC_LIBS}/lib/gcc/*/*/finclude
rm -r ${PREFIX_GCC_LIBS}/lib/gcc/*/*/include-fixed
rm -r ${PREFIX_GCC_LIBS}/lib/gcc/*/*/install-tools

# Strip symbols from libraries.  This is guesswork.  GNU strip defaults to
# --strip-all, which is OK for dynamic executables because it does not strip
# the dynamic sections.  It is *not* OK for static libraries.  I don't know
# about shared libraries.  There are also --strip-debug and --strip-unneeded
# options.  There is not a clear consensus on the Internet regarding which
# option is appropriate in which contexts.  There is a large size reduction
# with --strip-debug (28MiB to 15MiB), and --strip-unneeded is slightly
# smaller.  I'm going to use --strip-debug in the hope that it is safer.
find ${PREFIX_GCC_LIBS} \
    -type f '(' -name '*.so' -o -name '*.so.*' -o -name '*.a' ')' | \
    xargs strip --strip-debug
