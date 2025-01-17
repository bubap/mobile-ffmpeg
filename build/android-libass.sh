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
LIB_NAME="libass"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
BUILD_HOST=$(get_build_host)
export CFLAGS=$(get_cflags ${LIB_NAME})
export CXXFLAGS=$(get_cxxflags ${LIB_NAME})
export LDFLAGS=$(get_ldflags ${LIB_NAME})
export PKG_CONFIG_LIBDIR="${INSTALL_PKG_CONFIG_DIR}"

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

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# RECONFIGURE IF REQUESTED
if [[ ${RECONF_libass} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

ASM_FLAGS=""
case ${ARCH} in
    x86)

        # please note that asm is disabled
        # because enabling asm for x86 causes text relocations in libavfilter.so
        ASM_FLAGS="	--disable-asm"
    ;;
    *)
        ASM_FLAGS="	--enable-asm"
    ;;
esac

./configure \
    --prefix=${BASEDIR}/prebuilt/android-$(get_target_build)/${LIB_NAME} \
    --with-pic \
    --with-sysroot=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${TOOLCHAIN}/sysroot \
    --disable-libtool-lock \
    --enable-static \
    --disable-shared \
    --disable-harfbuzz \
    --disable-fast-install \
    --disable-test \
    --disable-profile \
    --disable-coretext \
    ${ASM_FLAGS} \
    --host=${BUILD_HOST} || exit 1

make -j$(get_cpu_count) || exit 1

# MANUALLY COPY PKG-CONFIG FILES
cp ./*.pc ${INSTALL_PKG_CONFIG_DIR} || exit 1

make install || exit 1
