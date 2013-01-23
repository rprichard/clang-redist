UNAME_MACHINE=$(uname -m)
UNAME_SYSTEM=$(uname -s)
case $UNAME_MACHINE in
    i[3-9]86) ARCH=x86;;
    x86_64)   ARCH=x86_64;;
    *)        echo "Unrecognized uname -m: $UNAME_MACHINE";;
esac
case $UNAME_SYSTEM in
    Linux)  PLATFORM=linux;;
    Darwin) PLATFORM=darwin;;
    *)      echo "Unrecognized uname -s: $UNAME_SYSTEM";;
esac

SRC=$PWD/src
BUILD=$PWD/build
INSTALL=$PWD/install
if [ $PLATFORM = linux ]; then
    NPROC=$(grep "^processor[[:space:]]*:[[:space:]]*[0-9]*$" /proc/cpuinfo | wc -l)
elif [ $PLATFORM = darwin ]; then
    NPROC=$(sysctl -n hw.ncpu)
fi
mkdir -p $SRC
mkdir -p $BUILD
mkdir -p $INSTALL
