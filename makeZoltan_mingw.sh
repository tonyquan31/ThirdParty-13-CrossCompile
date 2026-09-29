#!/bin/bash
set -e

# ==============================================================================
# Cross-Compilation Script for Zoltan 3.90 (Target: Windows x64 via MinGW)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -z "$WM_PROJECT_DIR" ] || [ "$WM_COMPILER" != "Mingw" ]; then
    echo "[+] Sourcing OpenFOAM MinGW environment..."
    OF_DIR="$(cd "$SCRIPT_DIR/../OpenFOAM-13" 2>/dev/null && pwd)"
    if [ ! -f "$OF_DIR/etc/bashrc" ]; then
        OF_DIR="/home/kodama/OpenFOAM-v13/OpenFOAM-13"
    fi
    cd "$OF_DIR"
    export WM_COMPILER=Mingw
    export WM_ARCH=linux64
    export WM_MPLIB=MSMPI
    export WM_OSTYPE=MSwindows
    source etc/bashrc
    cd "$SCRIPT_DIR"
fi

ZOLTAN_VER="3.90"
ZOLTAN_DIR="$SCRIPT_DIR/Zoltan-$ZOLTAN_VER"
PLATFORM_DIR="$SCRIPT_DIR/platforms/linux64MingwDPInt32"

echo "======================================================================"
echo "  Cross-compiling Zoltan $ZOLTAN_VER for Windows x64 (MinGW)"
echo "======================================================================"

mkdir -p "$PLATFORM_DIR"
cd "$ZOLTAN_DIR"

rm -rf build-mingw
mkdir -p build-mingw
cd build-mingw

echo "[+] Configuring Zoltan for MinGW..."
../configure \
    --host=x86_64-w64-mingw32 \
    --prefix="$PLATFORM_DIR" \
    --disable-mpi \
    --disable-zoltan-cppdriver \
    --with-ccflags="-fPIC -O3" \
    --with-cxxflags="-fPIC -O3" \
    CC=x86_64-w64-mingw32-gcc \
    CXX=x86_64-w64-mingw32-g++ \
    AR=x86_64-w64-mingw32-ar \
    RANLIB=x86_64-w64-mingw32-ranlib

echo "[+] Building Zoltan..."
make -j $(nproc)

echo "[+] Installing Zoltan..."
cd src && make install

echo "======================================================================"
echo "  ZOLTAN BUILD & INSTALL COMPLETED SUCCESSFULLY!"
echo "======================================================================"
ls -lh "$PLATFORM_DIR/lib"/libzoltan*
ls -lh "$PLATFORM_DIR/include"/zoltan*
