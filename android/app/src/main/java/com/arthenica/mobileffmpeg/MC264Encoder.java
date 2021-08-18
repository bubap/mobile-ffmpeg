/*
 * Copyright (C) 2019 The FFmpegMC264encoder library By YongTae Kim.
 * This library is based on The Android Open Source Project & FFmpeg.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.arthenica.mobileffmpeg;

import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaCodecList;
import android.media.MediaFormat;
import android.os.Build;
import android.util.Log;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Arrays;

public class MC264Encoder {
    public native void onH264MediaCodecEncodedFrame2(ByteBuffer data, int size, long presentationTimeUs, int b_keyframe);

    private static final String TAG = "MC264Encoder";

    private MediaCodec encoder;
    private boolean encoderDone = false;
    private boolean released = false;

    ByteBuffer[] encoderInputBuffers; // = encoder.getInputBuffers();
    ByteBuffer[] encoderOutputBuffers; // = encoder.getOutputBuffers();

    // size of a frame, in pixels
    private int mStride = -1;
    private int mWidth = -1;
    private int mHeight = -1;
    private int mBitRate = -1;
    private float mFrameRate = -1;
    private int mGOP = -1;
    private int mEncoderColorFormat = -1;
    private long mFrameIndex = 0;
    private long mEncodedIndex = 1;

    private ByteBuffer mH264Keyframe;
    private int mH264MetaSize = 0;                   // Size of SPS + PPS data

    public MC264Encoder() {
        try {
            encoder = MediaCodec.createEncoderByType("video/avc");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void reset() {
        Log.d(TAG, "reset() : Enter...");

        if (encoder != null) {
            encoder.stop();
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                encoder.reset();
            }
            mStride = -1;
        }
    }

    public void release() {
        Log.d(TAG, "release() : Enter...");

        if( released ) return;

        if (encoder != null) {
            encoder.stop();
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                encoder.reset();
            }
        }
        mStride = -1;
        released = true;
    }

    public void setParameter(int width, int height, int bitrate, float framerate, int gop, int colorformat) {
        Log.d(TAG, "setParameter() : Enter ... "
                + "w=" + width
                + ", h=" + height
                + ", bitrate=" + bitrate
                + ", framerate=" + framerate
                + ", gop=" + gop
                + ", colorformat=" + colorformat);

        released = false;

        mWidth = width;
        mHeight = height;
        mBitRate = bitrate;
        mFrameRate = framerate;
        mGOP = gop;

        MediaCodecInfo codecInfo = selectCodec("video/avc");
        mEncoderColorFormat = selectColorFormat(codecInfo, "video/avc");
        Log.d(TAG, "mEncoderColorFormat - after selectColorFormat() = " + mEncoderColorFormat);   //21 on LG Q6 (OK)

        MediaFormat mediaFormat = MediaFormat.createVideoFormat("video/avc", mWidth, mHeight);
        mediaFormat.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, mWidth * mHeight * 3 / 2);
        mediaFormat.setInteger(MediaFormat.KEY_BIT_RATE, mBitRate);
        mediaFormat.setFloat  (MediaFormat.KEY_FRAME_RATE, mFrameRate);
        mediaFormat.setInteger(MediaFormat.KEY_COLOR_FORMAT, mEncoderColorFormat);
        mediaFormat.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1 /*sec*/);    //KEY_I_FRAME_INTERVAL is not for GOP
        mediaFormat.setInteger(MediaFormat.KEY_INTRA_REFRESH_PERIOD, mGOP /*frames*/); //for low-delay and good error-resilience : Maybe this is for GOP
        mediaFormat.setInteger(MediaFormat.KEY_LATENCY, mGOP /*frames*/);               //What is this for?
        mediaFormat.setInteger(MediaFormat.KEY_PRIORITY, 0);                    //0- real time, 1 - non-reaal time (beast effort)
        if( mStride > 0 ) {
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                mediaFormat.setInteger(MediaFormat.KEY_STRIDE, mStride );   //No effect on LG-Q6 although KEY_STRIDE requires API 23 and LG-Q6 is API 25.

            //and do more for my LG-Q6
            mediaFormat.setInteger(MediaFormat.KEY_WIDTH, mStride );
        }

        encoder.configure(mediaFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        encoder.start();  //moved into setParameter();

        encoderInputBuffers = encoder.getInputBuffers();
        encoderOutputBuffers = encoder.getOutputBuffers();
    }

    private void setStride( int stride ) {
        mStride = stride;
        Log.d(TAG, "set encoder stride = " + stride );
        encoder.stop();
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
            encoder.reset();
        setParameter( mWidth, mHeight, mBitRate, mFrameRate, mGOP, -1);
    }

    private ByteBuffer encodedDataOld = null;
    private long curPTS_Old = 0;

    public void putYUVFrameData(byte[] iframeData, int stride, long pts) {
        byte[] frameData = iframeData;

        if( mStride <= 0 )
            setStride( stride );

        final int TIMEOUT_USEC = 8000;
        final int TIMEOUT_USEC2 = 10000;
        MediaCodec.BufferInfo info = new MediaCodec.BufferInfo();

        if( mEncoderColorFormat == MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar ) {
            //for SAMSUNG Galaxy Note-10
            frameData = convertYUV420SemiPlanarToYUV420Planar(iframeData, stride);
        }

        int inputBufIndex = encoder.dequeueInputBuffer(TIMEOUT_USEC);
        if (inputBufIndex >= 0) {
            long ptsUsec = computePresentationTime(pts);

            ByteBuffer inputBuf;
            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                /*ByteBuffer*/ inputBuf = encoder.getInputBuffer(inputBufIndex);
            } else {
                /*ByteBuffer*/ inputBuf = encoderInputBuffers[inputBufIndex];
            }

            inputBuf.clear();
            inputBuf.put(frameData);
            encoder.queueInputBuffer(inputBufIndex, 0, frameData.length, ptsUsec, 0);
            Log.d(TAG, "submitted frame to enc (length=" + frameData.length + ")");
        } else {
            // either all in use, or we timed out during initial setup
            Log.d(TAG, "input buffer not available. drop input frame...");
        }

        /*
         * Check encoder output. Take out encoded data if it is.
         */
        if (!encoderDone) {
            int encoderStatus = encoder.dequeueOutputBuffer(info, TIMEOUT_USEC2);
            if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                // no output available yet
                Log.d(TAG, "no output from encoder available");

                if( encodedDataOld != null ) {
                    long curPTS = curPTS_Old + (1000000 / (long) mFrameRate);
                }

            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
                // not expected for an encoder
                Log.d(TAG, "encoder output buffers changed");
            } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                // not expected for an encoder
                MediaFormat newFormat = encoder.getOutputFormat();
                Log.d(TAG, "encoder output format changed: " + newFormat);

                encodedDataOld = null;
            } else if (encoderStatus < 0) {
                Log.e(TAG, "unexpected result from encoder.dequeueOutputBuffer: " + encoderStatus);
            } else { // encoderStatus >= 0

                ByteBuffer encodedData;
                if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    /*ByteBuffer*/ encodedData = encoder.getOutputBuffer(encoderStatus);
                } else {
                    /*ByteBuffer*/ encodedData = encoderOutputBuffers[encoderStatus];
                }
                if (encodedData == null) {
                    Log.e(TAG, "encoderOutputBuffer " + encoderStatus + " was null");
                }
                // It's usually necessary to adjust the ByteBuffer values to match BufferInfo.
                encodedData.position(info.offset);
                encodedData.limit(info.offset + info.size);

                if ( /*listener*/true) {
                    if ((info.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                        Log.d(TAG, "info.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 1 ...");
                        //save this metadata and use it in passing every key_frame
                        captureH264MetaData(encodedData, info);

                    } else if ((info.flags & MediaCodec.BUFFER_FLAG_PARTIAL_FRAME) != 0) {
                        Log.d(TAG, "info.flags & MediaCodec.BUFFER_FLAG_PARTIAL_FRAME == 1 ...");
                    } else if ((info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        Log.d(TAG, "info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM == 1 ...");
                    } else {
                        int b_keyframe = info.flags & MediaCodec.BUFFER_FLAG_KEY_FRAME;

                        Log.d(TAG, "info.presentationTimeUs = " + info.presentationTimeUs + " b_keyframe = " + b_keyframe);

                        //for MediaProjection
                        long curPTS = 0;

                        if (b_keyframe == 1) {
                            packageH264Keyframe(encodedData, info);
                            onH264MediaCodecEncodedFrame2(mH264Keyframe, mH264MetaSize + info.size, info.presentationTimeUs /*mEncodedIndex++*/, /*b_keyframe*/1);
                        } else {
                            onH264MediaCodecEncodedFrame2(encodedData, info.size, info.presentationTimeUs /*mEncodedIndex++*/, /*b_keyframe*/0);

                            encodedDataOld = encodedData;
                        }
                    }
                }

                encoderDone = (info.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0;
                encoder.releaseOutputBuffer(encoderStatus, false);
            } //last else
        } //if (!encoderDone)
    }

    private byte[] convertYUV420SemiPlanarToYUV420Planar(byte[] iframeData, int stride) {

        byte[] newFrameData = new byte[iframeData.length];

        //YUV420 planar         : [Y1Y2......][Cb1Cb2......][Cr1Cr2.......]
        //YUV420 semi planar    : [Y1Y2......][Cb1Cr1Cb2Cr2......]              == iframeData
        //YUV422 interleaved    : Y1U1Y2V1 Y3U2Y4V2 ... ...

        byte[] Y = Arrays.copyOf(iframeData, stride*mHeight);
        byte[] U = new byte[stride*mHeight/2];
        byte[] V = new byte[stride*mHeight/2];
        int pos = 0;
        for( int i=0; i<stride*mHeight/2; i+=2 ) {  //stride/2 안하는 대신 i=+2
            int upos = i;
            int vpos = i+1;
            U[pos] = iframeData[ stride*mHeight + upos ];
            V[pos] = iframeData[ stride*mHeight + vpos ];
            pos++;
        }

        for (int i = 0; i < stride*mHeight; i++)
        {
            newFrameData[i] = Y[i];
        }

        for (int i = 0; i < stride/2*mHeight/2; i++)
        {
            newFrameData[stride*mHeight + i] = U[i];
            newFrameData[stride*mHeight + stride/2*mHeight/2 + i] = V[i];
        }

        return newFrameData;
    }

    private void captureH264MetaData(ByteBuffer encodedData, MediaCodec.BufferInfo bufferInfo) {
        mH264MetaSize = bufferInfo.size;
        mH264Keyframe = ByteBuffer.allocateDirect(encodedData.capacity());  //Don't use ByteBuffer.allocate(...) to access in JNI using (*genv)->GetDirectBufferAddress(genv, data);
        mH264Keyframe.put(encodedData);
    }

    private void packageH264Keyframe(ByteBuffer encodedData, MediaCodec.BufferInfo bufferInfo) {
        // BufferOverflow : --> startcode missing <--
        mH264Keyframe.position(mH264MetaSize);
        mH264Keyframe.put(encodedData);
    }

    /**
     * Returns the first codec capable of encoding the specified MIME type, or null if no
     * match was found.
     */
    private static MediaCodecInfo selectCodec(String mimeType) {
        int numCodecs = MediaCodecList.getCodecCount();
        for (int i = 0; i < numCodecs; i++) {
            MediaCodecInfo codecInfo = MediaCodecList.getCodecInfoAt(i);
            if (!codecInfo.isEncoder()) {
                continue;
            }
            String[] types = codecInfo.getSupportedTypes();
            for (int j = 0; j < types.length; j++) {
                if (types[j].equalsIgnoreCase(mimeType)) {
                    return codecInfo;
                }
            }
        }
        return null;
    }

    /**
     * Returns a color format that is supported by the codec and by this test code.  If no
     * match is found, this throws a test failure -- the set of formats known to the test
     * should be expanded for new platforms.
     */
    private static int selectColorFormat(MediaCodecInfo codecInfo, String mimeType) {
        MediaCodecInfo.CodecCapabilities capabilities = codecInfo.getCapabilitiesForType(mimeType);
        for (int i = 0; i < capabilities.colorFormats.length; i++) {
            int colorFormat = capabilities.colorFormats[i];
            if (isRecognizedFormat(colorFormat)) {
                return colorFormat;
            }
        }
        Log.e(TAG, "couldn't find a good color format for " + codecInfo.getName() + " / " + mimeType);
        return 0;   // not reached
    }

    /**
     * Returns true if this is a color format that this test code understands (i.e. we know how
     * to read and generate frames in this format).
     */
    private static boolean isRecognizedFormat(int colorFormat) {
        switch (colorFormat) {
            // these are the formats we know how to handle for this test
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Planar:
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420PackedPlanar:
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420SemiPlanar:
            case MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420PackedSemiPlanar:
            case MediaCodecInfo.CodecCapabilities.COLOR_TI_FormatYUV420PackedSemiPlanar:
                return true;
            default:
                return false;
        }
    }

    /**
     * Generates the presentation time for frame N, in microseconds.
     */
    private long computePresentationTime(long frameIndex) {
        return 132 + frameIndex * 1000000 / (long) mFrameRate;    //for old style sync mc264.c : pkt->pts = (int64_t)( (double)presentationTimeUs / (double)(1000000/(double)myCtx->fps) );
        //return  frameIndex * 1000000 / (long) mFrameRate;          //for new style sync mc264.c : pkt->pts = av_rescale_q( presentationTimeUs, bq, cq ) / (90000/(int)myCtx->fps);
    }

}
