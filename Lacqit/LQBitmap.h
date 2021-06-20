//
//  LQBitmap.h
//  Lacqit
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXPlatform.h>
#import "LacqitExport.h"
#import "LQStreamBuffer.h"
#import "LQUIFrameworkHeader.h"
#import "LQVideoTypes.h"
#import "LQLXBasicFunctions.h"

@class LQBitmap;


LACQIT_EXPORT size_t LQWidenRowBytes(size_t rowBytes);
LACQIT_EXPORT int LQBytesPerPixelForQTPixelFormat(LQQTStylePixelFormat pf);
LACQIT_EXPORT NSString *NSStringFromQTPixelFormat(LQQTStylePixelFormat pf);
LACQIT_EXPORT LXUInteger LXPixelFormatFromQTPixelFormat(LQQTStylePixelFormat pf);
LACQIT_EXPORT uint32_t LQQTPixelFormatFromLXPixelFormat(LXUInteger pf);

// these are meant to be used in APIs where strings and fourCC ints need to be roundtripped.
// the int is interpreted as big-endian: this matches what QT does.
LACQIT_EXPORT NSString *LQFourCCToString(int32_t pf);
LACQIT_EXPORT int32_t LQFourCCToInt(NSString *str);

// provides a breakpoint for warnings about unsupported formats
LACQIT_EXPORT void _lq_warn_unsupported(NSString *str, const char *origFuncName);

// copies the pixel data without conversion
LACQIT_EXPORT LXPixelBufferRef LXPixelBufferCreateFromLQBitmap(LQBitmap *bitmap);


@interface LQBitmap : LQStreamBuffer {

    LXInteger           _w, _h;
    uint32_t            _pixelFormat;
	size_t				_rowBytes;
    LXUInteger          _bytesPerPixel;
    
    uint8_t             *_frameBuf;
	
	double				_par;
	NSSize				_scale;
	NSString			*_sourceName;
	LXInteger			_tag;	

    LXTextureRef        _lxTex;
    LXUInteger          _lxTextureStorageHint;
    BOOL                _texIsDirty;
    BOOL                __resBool0; //_wantsDelayedTextureUpdate;
    BOOL                __resBool1;
    BOOL                __resBool2;
        
    LXPixelBufferRef    _lxPixbufWrap;
    
    LXPixelBufferRef    _ownedLXPixbuf;
    
    LQBitmap            *_aliasedOriginal;
    BOOL                _aliasedIsRetained;
    
    id                  _infoDelegate;
    
    void                *__resPtr1;
    void                *__resPtr2;
}

- (id)initWithSize:(NSSize)size pixelFormat:(LQQTStylePixelFormat)pixelFormat;

- (id)initWithContentsOfLQBitmap:(LQBitmap *)frame;

// this method will own the pixel buffer, so it should not be shared with any other objects.
// pixbuf is _not_ retained by this call.
- (id)initWithOwnedLXPixelBuffer:(LXPixelBufferRef)pixbuf;

// this method creates an alias that refers to the data and texture of the original bitmap.
- (id)initAsAliasOfLQBitmap:(LQBitmap *)bitmap retain:(BOOL)doRetain;

// converting from Cocoa types and named images
- (id)initWithImageNamed:(NSString *)name;
#if !defined(__LAGOON__)
- (id)initWithBitmapImageRep:(NSBitmapImageRep *)rep;
#endif


- (LXInteger)width;
- (LXInteger)height;
- (NSSize)size;
- (BOOL)matchesSize:(NSSize)size;

- (NSSize)imageDataSize;  // same as -size; exists for disambiguation

- (LQQTStylePixelFormat)pixelFormat;

- (double)displayAspectRatio;

- (double)pixelAspectRatio;
- (NSString *)sourceName;
- (LXInteger)tag;

- (void)setPixelAspectRatio:(double)par;
- (void)setSourceName:(NSString *)name;
- (void)setTag:(LXInteger)tag;

- (BOOL)isAlias;

- (void)willModifyFrameBuffer;
- (void)didModifyFrameBuffer;

- (size_t)bufferRowBytes;
- (uint8_t *)buffer;

// copies the data and properties from another bitmap; size and pixel format must match
- (BOOL)copyFromLQBitmap:(LQBitmap *)otherFrame;

// clears with zero; does not call -willModify/didModifyFrameBuffer, so the caller should do that it if necessary
- (void)clear;

- (LXTextureRef)lxTexture;
- (void)drawInLXSurface:(LXSurfaceRef)lxSurface inRect:(LXRect)rect;
- (void)drawInLXSurface:(LXSurfaceRef)lxSurface atPoint:(LXPoint)p;
- (void)drawInLXSurface:(LXSurfaceRef)lxSurface atCenterPoint:(LXPoint)p;

- (void)invalidateLXTexture;

/// reading pixels (-- removed, use LXPixelBuffer calls instead)
///- (void)readFloatRGBAPixels:(float *)pixelsArray inRegion:(LXRect)region;


- (LXUInteger)storageHintForLXTexture;
- (void)setStorageHintForLXTexture:(LXUInteger)storageHint;

// a wrapped-on pixel buffer
- (LXPixelBufferRef)lxPixelBuffer;


// subclasses can override
- (LXUInteger)storageHintForLXPixelBuffer;

// for direct notifications
- (void)setInfoDelegate:(id)del;
- (id)infoDelegate;

@end


@interface NSObject (LQBitmapDirectNotification)

// this is called for every update
- (BOOL)lqBitmapShouldRefreshTexture:(LQBitmap *)bitmap;

// this is called a single time at the end of the event loop,
// so it's suitable for heavy display updates
- (void)lqBitmapDidUpdate:(LQBitmap *)bitmap;

@end

