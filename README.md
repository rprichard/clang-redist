clang-redist-linux
==================

This project creates redistributable packages containing Clang, Clang
libraries, and GCC libraries (e.g. libstdc++) for Linux x86 and x86-64.  The
packages provide a C++11 toolchain that runs on most currently supported Linux
distributions, and they provide the Clang libraries needed for the SourceWeb
indexer.

The scripts should be run on Ubuntu 10.04, x86 and x86-64, which uses
libstdc++-4.4.3.  The resulting packages should run on any Linux distributions
using libstdc++-4.4.3 or newer, which includes almost every currently supported
distribution:

 - Debian 6.0.
 - Ubuntu 10.04 and up.
 - Fedora 16 and up.
 - OpenSUSE 12.1 and up.
 - CentOS 6.0.

The packages will not work on CentOS 5.0, which uses libstdc++-4.2.

Note that at run-time, the binaries produced by this package may need a
libstdc++ newer than the one on the host system.  Either use `LD_LIBRARY_PATH`
to point at the packaged libstdc++, or compile with `-Wl,-R<path>` to embed an
RPATH into the binary.

Build process
-------------

All of the scripts in this directory should be run in the
`/clang-redist-linux-DATE` top-level directory, so that if an end-user's
machine attempts to access an embedded build/install path, it is likely to fail
instantly.

    DATE=$(date +%Y%m%d)
    sudo mkdir /clang-redist-linux-$DATE
    sudo chown $(id -un).$(id -gn) /clang-redist-linux-$DATE
    cd /clang-redist-linux-$DATE

Run the `master-build-script.sh`, piping both stdout and stderr to `build.log`.

    <path-to-clang-redist>/master-build-script.sh >build.log 2>&1

Package the entire directory into a tarball.

    cd /
    tar cfJ $HOME/clang-redist-linux-$DATE.tar.xz \
        clang-redist-linux-$DATE

Move the tarballs to permanent storage somewhere.  The tarballs in the install
directory have no version string associating them with this project, so put
them in a directory named with the `DATE`.

Tag the revision of this project used to produce the `DATE` binaries.

Compatibility note: library versions
------------------------------------

| Distribution           | libc version    | libstdc++ version
| ---------------------- | --------------- | -----------------
| CentOS 6.0 [1][2]      | 2.12            | 4.4.4
| CentOS 6.3 [3][4]      | 2.12            | 4.4.6
| Debian 6.0 [5]         | 2.11.3          | 4.4.5
| OpenSUSE 11.2 [6]      | 2.10.1          | 4.4.1
| Ubuntu 10.04 Lucid [7] | 2.11.1          | 4.4.3

[1]: http://vault.centos.org/6.0/os/i386/Packages/
[2]: http://vault.centos.org/6.0/os/x86_64/Packages/
[3]: http://mirror.centos.org/centos/6.3/os/i386/Packages/
[4]: http://mirror.centos.org/centos/6.3/os/x86_64/Packages/
[5]: http://www.debian.org/distrib/packages#search_packages
[6]: http://ftp5.gwdg.de/pub/opensuse/discontinued/distribution/11.2/repo/oss/suse/
[7]: http://packages.ubuntu.com/
