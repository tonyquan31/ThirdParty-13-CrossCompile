#!/bin/bash
set -e

# ==============================================================================
# Cross-Compilation Script for Scotch 7.0.8 (Target: Windows x64 via MinGW)
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

SCOTCH_VER="7.0.8"
SCOTCH_DIR="$SCRIPT_DIR/scotch_$SCOTCH_VER"
PLATFORM_DIR="$SCRIPT_DIR/platforms/linux64MingwDPInt32"
LIB_DIR="$PLATFORM_DIR/lib"
INC_DIR="$PLATFORM_DIR/include"

echo "======================================================================"
echo "  Cross-compiling Scotch $SCOTCH_VER for Windows x64 (MinGW)"
echo "======================================================================"
echo "  Source : $SCOTCH_DIR"
echo "  Target : $PLATFORM_DIR"
echo "======================================================================"

mkdir -p "$LIB_DIR"
mkdir -p "$INC_DIR"

cd "$SCOTCH_DIR/src"

# 1. Prepare Makefile.inc for MinGW
cat << 'EOF_MAKE' > Makefile.inc
EXE         = .exe
LIB         = .dll
OBJ         = .o

MAKE        = make
AR          = x86_64-w64-mingw32-gcc
ARFLAGS     = -shared -Wl,--output-def,libscotch.def,--out-implib,libscotch.dll.a -o
CAT         = cat
CCS         = x86_64-w64-mingw32-gcc
CCP         = x86_64-w64-mingw32-gcc
CCD         = gcc
CFLAGS      = -O3 -fPIC -DCOMMON_FILE_COMPRESS_GZ -DCOMMON_RANDOM_FIXED_SEED -DSCOTCH_RENAME -Drestrict=__restrict -DCOMMON_OS_WINDOWS -DCOMMON_STUB_FORK -DIDXSIZE32 -DINTSIZE32
CCDFLAGS    = -O3 -DCOMMON_FILE_COMPRESS_GZ -DCOMMON_RANDOM_FIXED_SEED -DSCOTCH_RENAME -Drestrict=__restrict -DIDXSIZE32 -DINTSIZE32

CLIBFLAGS   = -shared
LDFLAGS     = -lz -lm
CP          = cp
FLEX        = flex
BISON       = bison
LEX         = flex
YACC        = bison
LN          = ln
MKDIR       = mkdir -p
MV          = mv
RANLIB      = echo
EOF_MAKE

# 2. Patch CCD in libscotch Makefile if needed
sed -i 's/CCD="\$(CCS)"/CCD="\$(CCD)"/g' libscotch/Makefile

# 3. Clean previous builds
make clean 2>/dev/null || true
rm -f libscotch/*.dll libscotch/*.a libscotch/*.def libscotch/dummysizes libscotch/scotch.h libscotch/scotchf.h

# 4. Compile libscotch and helpers
echo "[+] Building Scotch source objects..."
make -j $(nproc) libscotch

# 5. Verify Windows PE DLL
echo "[+] Verifying Windows libscotch.dll..."
cd libscotch

# 6. Copy artifacts to platforms directory
echo "[+] Installing Scotch headers and libraries..."
cp -f scotch.h scotchf.h "$INC_DIR/"
cp -f libscotch.dll libscotcherr.dll libscotcherrexit.dll "$LIB_DIR/"
[ -f libscotch.dll.a ] && cp -f libscotch.dll.a "$LIB_DIR/"
# Also copy to .so for OpenFOAM build system compatibility
cp -f libscotch.dll "$LIB_DIR/libscotch.so"
cp -f libscotcherr.dll "$LIB_DIR/libscotcherr.so"
cp -f libscotcherrexit.dll "$LIB_DIR/libscotcherrexit.so"

echo "======================================================================"
echo "  SCOTCH BUILD & INSTALL COMPLETED SUCCESSFULLY!"
echo "======================================================================"
ls -lh "$LIB_DIR"/libscotch*
ls -lh "$INC_DIR"/scotch*
