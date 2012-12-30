UNAME_MACHINE=$(uname -m)
case $UNAME_MACHINE in
    i[3-9]86) ARCH=x86;;
    x86_64)   ARCH=x86_64;;
    *)        echo "Unrecognized uname -m: $UNAME_MACHINE";;
esac
SRC=$PWD/src
BUILD=$PWD/build
INSTALL=$PWD/install
NPROC=$(grep "^processor[[:space:]]*:[[:space:]]*[0-9]*$" /proc/cpuinfo | wc -l)
mkdir -p $SRC
mkdir -p $BUILD
mkdir -p $INSTALL
