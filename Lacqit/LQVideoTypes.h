/*
 *  LQVideoTypes.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 4.5.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

#ifndef _LQVIDEOTYPES_H_
#define _LQVIDEOTYPES_H_

#include <Lacefx/LXBasicTypes.h>


// --- pixel and frame format types ---

// QuickTime-style pixel format fourCCs use big-endian layout convention on all platforms (i.e. '2vuy' looks like "yuv2" in memory on x86)
#ifndef MAKEFOURCC_QTSTYLE
#define MAKEFOURCC_QTSTYLE(a_, b_, c_, d_)  \
    (uint32_t)(  ((uint8_t)(a_) << 24) | ((uint8_t)(b_) << 16) | ((uint8_t)(c_) << 8) | ((uint8_t)(d_))  )
#endif


typedef uint32_t LQQTStylePixelFormat;

enum {
    kLQQTPixelFormat_RGBA_int8    = MAKEFOURCC_QTSTYLE('R', 'G', 'B', 'A'),     // 'RGBA'
    kLQQTPixelFormat_ARGB_int8    = 32,                                         // 0x20
    kLQQTPixelFormat_BGRA_int8    = MAKEFOURCC_QTSTYLE('B', 'G', 'R', 'A'),     // 'BGRA'

    // 16-bit RGB pixels (standard formats used by QT applications. *** NOTE: big-endian components! ***)
    kLQQTPixelFormat_ARGB_int16     = MAKEFOURCC_QTSTYLE('b', '6', '4', 'a'),   // 'b64a'
    kLQQTPixelFormat_RGB_int16      = MAKEFOURCC_QTSTYLE('b', '4', '8', 'r'),   // 'b48r'
    
    // 8-bit YCbCr
    kLQQTPixelFormat_YCbCr422_int8 = MAKEFOURCC_QTSTYLE('2', 'v', 'u', 'y'),    // '2vuy'

    // YCbCr 4:4:4 render formats (these are supported by many codecs);
    // more info on the float version:  http://developer.apple.com/technotes/tn2008/tn2201.html
    //
    kLQQTPixelFormat_YCbCr444Render_int8     = MAKEFOURCC_QTSTYLE('r', '4', '0', '8'),    // 'r408' -- component order is A, Y, Cb, Cr (big-endian)
    kLQQTPixelFormat_YCbCr444Render_float32  = MAKEFOURCC_QTSTYLE('r', '4', 'f', 'l'),    // 'r4fl' -- component order is A, Y, Cb, Cr

    // custom formats to match Lacefx's float RGBA formats
    kLQQTPixelFormat_RGBA_float16    = MAKEFOURCC_QTSTYLE('h', 'f', '6', '4'),  // 'hf64' - not standard
    kLQQTPixelFormat_RGBA_float32    = MAKEFOURCC_QTSTYLE('f', '1', '2', '8'),  // 'f128' - not standard
};

enum {
	kLQProgressiveFrame = 0,
	kLQInterlacedBlendFrames,
	kLQInterlacedEvenFrame,
	kLQInterlacedOddFrame
};
typedef LXUInteger LQVideoFieldProcessingMode;

enum {
	kLQQuicktimeMedia = 0x10,
    kLQAVIMedia = 0x20,
    kLQMPEG2Media = 0x50,
    kLQMPEG4Media = 0x60,
    kLQOggMedia = 0x140,
    kLQWebMMedia = 0x150,
	kLQImageSequenceMedia = 0x1000,
};
typedef LXUInteger LQVideoMediaType;


typedef struct _LQBitmapCrop {
    int left;
    int right;
    int top;
    int bottom;
} LQBitmapCrop;


LXINLINE LQBitmapCrop LQMakeBitmapCrop(int l, int r, int t, int b) {
    LQBitmapCrop crop;
    crop.left = l;
    crop.right = r;
    crop.top = t;
    crop.bottom = b;
    return crop;
}


enum {
    kLQPARMode_Square = 0,
    kLQPARMode_4_3,
    kLQPARMode_16_9
};
typedef LXUInteger LQVideoPixelAspectMode;  // TODO: add other common PARs like 1440*1080 HD


// pixel aspect ratios for SD video.
// authoritative reference on the derivation of these seemingly odd values:  http://lurkertech.com/lg/pixelaspect

#define kPAR_NTSC_4_3    (10. / 11.)
#define kPAR_NTSC_16_9   ((10. / 11.) * (4. /3.))
#define kPAR_PAL_4_3     (59. / 54.)
#define kPAR_PAL_16_9    ((59. / 54.) * (4. /3.))


// --- color types ---

// common colorspace definitions are here:
#import <Lacefx/LXImageFunctions.h>


// --- time types ---

// a "fip" is 1/600 seconds -- useful for representing all the common frame rates,
// except of course the junky NTSC drop frame formats.

#define kLQFipsPerSec 600
#define kLQFipsToSecs (1.0 / 600.0)

#define kLQFrameRate_NTSC_24_DropFrame  (24 * (1000.0/1001.0))
#define kLQFrameRate_NTSC_30_DropFrame  (30 * (1000.0/1001.0))
#define kLQFrameRate_NTSC_60_DropFrame  (60 * (1000.0/1001.0))


typedef struct _LQPlaybackRange {
    double startTime;
    double duration;
    LXInteger startTimeInFips;
    LXInteger durationInFips;
} LQPlaybackRange;



#endif
