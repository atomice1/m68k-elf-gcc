#!/bin/bash

###################################################################
#Script Name	:   build-gcc                                                                                           
#Description	:   build gcc for the Motorola 68000 toolchain   
#Date           :   samedi, 4 avril 2020                                                                          
#Args           :   Welcome to the next level!                                                                                        
#Author       	:   Jacques Belosoukinski (kentosama)                                                   
#Email         	:   kentosama@genku.net                                          
##################################################################

VERSION="15.2.0"
ARCHIVE="gcc-${VERSION}.tar.xz"
URL="https://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/${ARCHIVE}"
SHA512SUM="89047a2e07bd9da265b507b516ed3635adb17491c7f4f67cf090f0bd5b3fc7f2ee6e4cc4008beef7ca884b6b71dffe2bb652b21f01a702e17b468cca2d10b2de"
DIR="gcc-${VERSION}"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit 1
fi

# Create build folder
mkdir -p ${BUILD_DIR}/${DIR}

cd ${DOWNLOAD_DIR}

# Download gcc if is needed
if ! [ -f "${ARCHIVE}" ]; then
    wget ${URL}
fi

# Extract gcc archive if is needed
if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    SUM="$(sha512sum "${ARCHIVE}" | awk '{print $1}')"
    if [ "${SUM}" != "${SHA512SUM}" ]; then
        echo "SHA512SUM verification of ${ARCHIVE} failed!"
        echo "${SUM}"
        exit 1
    else
        tar Jxvf ${ARCHIVE} -C ${SRC_DIR}

        # Apply patch for hang in __floatsidf when a1 == 0x8000000.
        patch -t ${SRC_DIR}/${DIR}/libgcc/config/m68k/fpgnulib.c < ${ROOT_DIR}/patch/fpgnulib-hang-floatsidf-hang.patch

    fi
fi

cd ${SRC_DIR}/${DIR}

echo ${PWD}

# Download prerequisites
./contrib/download_prerequisites

cd ${BUILD_DIR}/${DIR}

# Configure before build
../../source/${DIR}/configure   --prefix=${INSTALL_DIR}             \
                                --build=${BUILD_MACH}               \
                                --host=${HOST_MACH}                 \
                                --target=${TARGET}                  \
                                --program-prefix=${PROGRAM_PREFIX}  \
                                --enable-languages=c,c++            \
                                --enable-obsolete                   \
                                --enable-lto                        \
                                --disable-threads                   \
                                --disable-libmudflap                \
                                --disable-libgomp                   \
                                --disable-nls                       \
                                --disable-werror                    \
                                --disable-libssp                    \
                                --disable-shared                    \
                                --disable-multilib                  \
                                --disable-libgcj                    \
                                --disable-libstdcxx                 \
                                --disable-gcov                      \
                                --without-headers                   \
                                --without-included-gettext          \
                                --with-cpu=${WITH_CPU}              \
                                ${WITH_NEWLIB}                      


# build and install gcc
make -j${NUM_PROC} 2<&1 | tee build.log

# Install
if [ $? -eq 0 ]; then
    make install
    make -j${NUM_PROC} all-target-libgcc
    make install-target-libgcc
fi


