#!/bin/bash

if [[ -z ${ANDROID_NDK_ROOT} ]]; then
    echo -e "(*) ANDROID_NDK_ROOT not defined\n"
    exit 1
fi

if [[ -z ${ARCH} ]]; then
    echo -e "(*) ARCH not defined\n"
    exit 1
fi

if [[ -z ${API} ]]; then
    echo -e "(*) API not defined\n"
    exit 1
fi

if [[ -z ${BASEDIR} ]]; then
    echo -e "(*) BASEDIR not defined\n"
    exit 1
fi

# ENABLE COMMON FUNCTIONS
. ${BASEDIR}/build/android-common.sh

# PREPARE PATHS & DEFINE ${INSTALL_PKG_CONFIG_DIR}
LIB_NAME="fontconfig"
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

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURE IF REQUESTED
if [[ ${RECONF_fontconfig} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

./configure \
    --prefix=${BASEDIR}/prebuilt/android-$(get_target_build)/${LIB_NAME} \
    --with-pic \
    --with-libiconv-prefix=${BASEDIR}/prebuilt/android-$(get_target_build)/libiconv \
    --with-expat=${BASEDIR}/prebuilt/android-$(get_target_build)/expat \
    --without-libintl-prefix \
    --enable-static \
    --disable-shared \
    --disable-fast-install \
    --disable-rpath \
    --disable-libxml2 \
    --disable-docs \
    --host=${BUILD_HOST} || exit 1

make -j$(get_cpu_count) || exit 1

# CREATE PACKAGE CONFIG MANUALLY
create_fontconfig_package_config "2.13.92"

make install || exit 1
