Pod::Spec.new do |s|
    s.name              = "mobile-ffmpeg-bubap"
    s.version           = "0.0.2"
    s.summary           = "Mobile FFmpeg Full Static Framework"
    s.description       = <<-DESC
    Includes FFmpeg v4.4-dev-416 with fontconfig v2.13.92, freetype v2.10.2, fribidi v1.0.9, gmp v6.2.0, gnutls v3.6.13, kvazaar v2.0.0, lame v3.100, libaom v1.0.0-errata1-avif-110, libass v0.14.0, libilbc v2.0.2, libtheora v1.1.1, libvorbis v1.3.7, libvpx v1.8.2, libwebp v1.1.0, libxml2 v2.9.10, opencore-amr v0.1.5, opus v1.3.1, shine v3.1.1, snappy v1.1.8, soxr v0.1.3, speex v1.2.0, twolame v0.4, vo-amrwbenc v0.1.3 and wavpack v5.3.0 libraries enabled.
    DESC

    s.homepage          = "https://github.com/bubap/mobile-ffmpeg"

    s.author            = { "Daeseong Kim" => "scvgoe@bubagump.net" }
    s.license           = { :type => "LGPL-3.0", :file => "ios-framework/mobileffmpeg.framework/LICENSE" }

    s.platform          = :ios
    s.requires_arc      = true
    s.libraries         = 'z', 'bz2', 'c++', 'iconv'

    s.source            = { :http => "https://github.com/bubap/mobile-ffmpeg/releases/download/v0.0.2-bubap/ios-framework.zip" }

    s.ios.deployment_target = '12.1'
    s.ios.frameworks    = 'AudioToolbox','AVFoundation','CoreMedia','VideoToolbox'
    s.ios.vendored_frameworks = 'ios-framework/chromaprint.framework', 'ios-framework/expat.framework', 'ios-framework/fontconfig.framework', 'ios-framework/freetype.framework', 'ios-framework/fribidi.framework', 'ios-framework/giflib.framework', 'ios-framework/gmp.framework', 'ios-framework/gnutls.framework', 'ios-framework/jpeg.framework', 'ios-framework/kvazaar.framework', 'ios-framework/lame.framework', 'ios-framework/leptonica.framework', 'ios-framework/libaom.framework', 'ios-framework/libass.framework', 'ios-framework/libavcodec.framework', 'ios-framework/libavdevice.framework', 'ios-framework/libavfilter.framework', 'ios-framework/libavformat.framework', 'ios-framework/libavutil.framework', 'ios-framework/libhogweed.framework', 'ios-framework/libilbc.framework', 'ios-framework/libnettle.framework', 'ios-framework/libogg.framework', 'ios-framework/libopencore-amrnb.framework', 'ios-framework/libpng.framework', 'ios-framework/libsndfile.framework', 'ios-framework/libswresample.framework', 'ios-framework/libswscale.framework', 'ios-framework/libtheora.framework', 'ios-framework/libtheoradec.framework', 'ios-framework/libtheoraenc.framework', 'ios-framework/libvorbis.framework', 'ios-framework/libvorbisenc.framework', 'ios-framework/libvorbisfile.framework', 'ios-framework/libvpx.framework', 'ios-framework/libwebp.framework', 'ios-framework/libwebpdemux.framework', 'ios-framework/libwebpmux.framework', 'ios-framework/libxml2.framework', 'ios-framework/mobileffmpeg.framework', 'ios-framework/openh264.framework', 'ios-framework/opus.framework', 'ios-framework/sdl.framework', 'ios-framework/shine.framework', 'ios-framework/snappy.framework', 'ios-framework/soxr.framework', 'ios-framework/speex.framework', 'ios-framework/tesseract.framework', 'ios-framework/tiff.framework', 'ios-framework/twolame.framework', 'ios-framework/vo-amrwbenc.framework', 'ios-framework/wavpack.framework'

end
