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
LIB_NAME="leptonica"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
BUILD_HOST=$(get_build_host)
export CFLAGS="$(get_cflags ${LIB_NAME})"
export CXXFLAGS="$(get_cxxflags ${LIB_NAME})"
export CPPFLAGS="-I${BASEDIR}/prebuilt/$(get_target_build_directory)/giflib/include"
export LDFLAGS="$(get_ldflags ${LIB_NAME}) -L${BASEDIR}/prebuilt/$(get_target_build_directory)/giflib/lib -lgif"
export PKG_CONFIG_LIBDIR="${INSTALL_PKG_CONFIG_DIR}"

export LIBPNG_CFLAGS="$(pkg-config --dont-define-prefix --cflags libpng)"
export LIBPNG_LIBS="$(pkg-config --dont-define-prefix --libs --static libpng)"

export LIBWEBP_CFLAGS="$(pkg-config --dont-define-prefix --cflags libwebp)"
export LIBWEBP_LIBS="$(pkg-config --dont-define-prefix --libs --static libwebp)"

export LIBTIFF_CFLAGS="$(pkg-config --dont-define-prefix --cflags libtiff-4)"
export LIBTIFF_LIBS="$(pkg-config --dont-define-prefix --libs --static libtiff-4)"

export ZLIB_CFLAGS="$(pkg-config --dont-define-prefix --cflags zlib)"
export ZLIB_LIBS="$(pkg-config --dont-define-prefix --libs --static zlib)"

export JPEG_CFLAGS="$(pkg-config --dont-define-prefix --cflags libjpeg)"
export JPEG_LIBS="$(pkg-config --dont-define-prefix --libs --static libjpeg)"

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURE IF REQUESTED
if [[ ${RECONF_leptonica} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

./configure \
    --prefix=${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME} \
    --with-pic \
    --with-zlib \
    --with-libpng \
    --with-jpeg \
    --with-giflib \
    --with-libtiff \
    --with-libwebp \
    --enable-static \
    --disable-shared \
    --disable-fast-install \
    --disable-programs \
    --host=${BUILD_HOST} || exit 1

make -j$(get_cpu_count) || exit 1

# MANUALLY COPY PKG-CONFIG FILES
cp lept.pc ${INSTALL_PKG_CONFIG_DIR} || exit 1

make install || exit 1
