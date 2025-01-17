#!/bin/bash

if [[ -z ${ARCH} ]]; then
    echo -e "(*) ARCH not defined\n"
    exit 1
fi

if [[ -z ${TARGET_SDK} ]]; then
    echo -e "(*) TARGET_SDK not defined\n"
    exit 1
fi

if [[ -z ${SDK_PATH} ]]; then
    echo -e "(*) SDK_PATH not defined\n"
    exit 1
fi

if [[ -z ${BASEDIR} ]]; then
    echo -e "(*) BASEDIR not defined\n"
    exit 1
fi

# ENABLE COMMON FUNCTIONS
if [[ ${APPLE_TVOS_BUILD} -eq 1 ]]; then
    . ${BASEDIR}/build/tvos-common.sh
else
    . ${BASEDIR}/build/ios-common.sh
fi

# PREPARE PATHS & DEFINE ${INSTALL_PKG_CONFIG_DIR}
LIB_NAME="libass"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
BUILD_HOST=$(get_build_host)
export CFLAGS=$(get_cflags ${LIB_NAME})
export CXXFLAGS=$(get_cxxflags ${LIB_NAME})
export LDFLAGS=$(get_ldflags ${LIB_NAME})
export PKG_CONFIG_LIBDIR=${INSTALL_PKG_CONFIG_DIR}

# UPDATE BUILD FLAGS
export FREETYPE_CFLAGS="$(pkg-config --dont-define-prefix --cflags freetype2)"
export FREETYPE_LIBS="$(pkg-config --dont-define-prefix --libs --static freetype2)"
export FRIBIDI_CFLAGS="$(pkg-config --dont-define-prefix --cflags fribidi)"
export FRIBIDI_LIBS="$(pkg-config --dont-define-prefix --libs --static fribidi)"
export FONTCONFIG_CFLAGS="$(pkg-config --dont-define-prefix --cflags fontconfig)"
export FONTCONFIG_LIBS="$(pkg-config --dont-define-prefix --libs --static fontconfig)"
export HARFBUZZ_CFLAGS="$(pkg-config --dont-define-prefix --cflags harfbuzz)"
export HARFBUZZ_LIBS="$(pkg-config --dont-define-prefix --libs --static harfbuzz)"
export LIBPNG_CFLAGS="$(pkg-config --dont-define-prefix --cflags libpng)"
export LIBPNG_LIBS="$(pkg-config --dont-define-prefix --libs --static libpng)"

ARCH_OPTIONS=""
case ${ARCH} in
    x86-64 | x86-64-mac-catalyst)
        ARCH_OPTIONS="--disable-asm"
    ;;
    *)
        ARCH_OPTIONS="--enable-asm"
    ;;
esac

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURE IF REQUESTED
if [[ ${RECONF_libass} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

./configure \
    --prefix=${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME} \
    --with-pic \
    --with-sysroot=${SDK_PATH} \
    --disable-libtool-lock \
    --enable-static \
    --disable-shared \
    --disable-harfbuzz \
    --disable-fast-install \
    --disable-test \
    ${ARCH_OPTIONS} \
    --disable-profile \
    --disable-coretext \
    --host=${BUILD_HOST} || exit 1

make -j$(get_cpu_count) || exit 1

# MANUALLY COPY PKG-CONFIG FILES
cp ./*.pc ${INSTALL_PKG_CONFIG_DIR} || exit 1

make install || exit 1
