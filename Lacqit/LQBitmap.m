//
//  LQBitmap.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBitmap.h"

#ifdef __WIN32__
#import <Lacefx/LXPlatform_d3d.h>

#else

extern LXSuccess LXTextureWillModifyData(LXTextureRef r, uint8_t *buffer, size_t rowBytes, LXUInteger storageHint);
extern LXSuccess LXTextureRefreshWithData(LXTextureRef r, uint8_t *buffer, size_t rowBytes, LXUInteger storageHint);

#endif


#if defined(__APPLE__)
#include <libkern/OSAtomic.h>
static volatile int64_t s_createCount = 0;
static volatile int64_t s_liveCount = 0;
static volatile int64_t s_liveMemBytesEstimate = 0;
// write to same log as LXSurface
extern LXLogFuncPtr g_lxSurfaceLogFuncCb;
extern void *g_lxSurfaceLogFuncCbUserData;
#endif



int LQBytesPerPixelForQTPixelFormat(unsigned int pf)
{
	switch (pf) {
        case kLQQTPixelFormat_RGBA_int8:
        case kLQQTPixelFormat_BGRA_int8:
        case MAKEFOURCC_QTSTYLE('A', 'R', 'G', 'B'):
		case 32:		return 4;
        
		case 24:		return 3;
        
        case kLQQTPixelFormat_ARGB_int16:   return 8;
        case kLQQTPixelFormat_RGB_int16:    return 6;
        
        case MAKEFOURCC_QTSTYLE('y', 'u', 'y', 'v'):
        case MAKEFOURCC_QTSTYLE('y', 'u', 'v', '2'):
        case MAKEFOURCC_QTSTYLE('2', 'V', 'U', 'Y'):
		case kLQQTPixelFormat_YCbCr422_int8:            return 2; 
        
        case kLQQTPixelFormat_YCbCr444Render_int8:      return 4;
        case kLQQTPixelFormat_YCbCr444Render_float32:   return 16;
        
        case kLQQTPixelFormat_RGBA_float16:      return 8;
		case kLQQTPixelFormat_RGBA_float32:      return 16;        
        
		default:		NSLog(@"** %s: unknown pixel format (%ui)", __func__, pf);
						return 4;
	}
}

size_t LQWidenRowBytes(size_t rowBytes)
{
    // widen rowBytes out to a integer multiple of 16 bytes
    rowBytes = (rowBytes + 15) & ~15;

    // make sure we are not an even power of 2 wide.
    // will loop a few times for rowBytes <= 16.
    // (this is for PPC cache aligment I think, perhaps not needed on Intel?)
    while (0 == (rowBytes & (rowBytes - 1)))
        rowBytes += 16;
        
    return rowBytes;
}

NSString *NSStringFromQTPixelFormat(LQQTStylePixelFormat pf)
{
    if (pf < 256) {
        return [NSString stringWithFormat:@"'%i (byte-sized pixel format)'", (int)pf];
    } else {
        // QuickTime-style pixel format fourCCs use big-endian layout convention on all platforms (i.e. '2vuy' looks like "yuv2" in memory on x86)
        char c1 = (pf >> 24) & 0xff;
        char c2 = (pf >> 16) & 0xff;
        char c3 = (pf >> 8)  & 0xff;
        char c4 = (pf >> 0)  & 0xff;
        c1 = (c1 > 31) ? c1 : '_';
        c2 = (c2 > 31) ? c2 : '_';
        c3 = (c3 > 31) ? c3 : '_';
        c4 = (c4 > 31) ? c4 : '_';
        return [NSString stringWithFormat:@"'%c%c%c%c'", c1, c2, c3, c4];
    }
}

NSString *LQFourCCToString(int32_t pf)
{
    if (pf < 256) {
        return [NSString stringWithFormat:@"%i", pf];
    } else {
        char c[5];
        memset(c, 0, 5);
        c[0] = (pf >> 24) & 0xff;
        c[1] = (pf >> 16) & 0xff;
        c[2] = (pf >> 8)  & 0xff;
        c[3] = (pf >> 0)  & 0xff;
        int i;
        for (i = 0; i < 4; i++) {
            if (c[i] < 32)
                c[i] = ' ';
        }
        return [NSString stringWithUTF8String:c];
    }
}

int32_t LQFourCCToInt(NSString *str)
{
    if ([str length] < 4) {
        int32_t v = [str intValue];
        return (v > 0 && v < 256) ? v : 0;
    }
    char c[5];
    memset(c, 0, 5);
    [str getCString:c maxLength:4 encoding:NSUTF8StringEncoding];
    int32_t v;
    v = (c[0] << 24) | (c[1] << 16) | (c[2] << 8) | c[3];
    return v;
}


void _lq_warn_unsupported(NSString *str, const char *origFuncName)
{
    NSLog(@"** %s: %@ (break on %s in Lacqit to debug)", origFuncName, str, __func__);
}

LXUInteger LXPixelFormatFromQTPixelFormat(uint32_t lqPF)
{
    switch (lqPF) {
        case kLQQTPixelFormat_ARGB_int8:        return kLX_ARGB_INT8;
        case kLQQTPixelFormat_RGBA_int8:        return kLX_RGBA_INT8;
        case kLQQTPixelFormat_BGRA_int8:        return kLX_BGRA_INT8;
        case kLQQTPixelFormat_RGBA_float16:     return kLX_RGBA_FLOAT16;
        case kLQQTPixelFormat_RGBA_float32:     return kLX_RGBA_FLOAT32;
        case kLQQTPixelFormat_YCbCr422_int8:    return kLX_YCbCr422_INT8;
        default:   _lq_warn_unsupported([NSString stringWithFormat:@"unsupported pixel format: %@ (0x%x)", NSStringFromQTPixelFormat(lqPF), lqPF], __func__);
    }
    return 0;
}

uint32_t LQQTPixelFormatFromLXPixelFormat(LXUInteger lxPF)
{
    switch (lxPF) {
        case kLX_ARGB_INT8:         return kLQQTPixelFormat_ARGB_int8;
        case kLX_RGBA_INT8:         return kLQQTPixelFormat_RGBA_int8;
        case kLX_BGRA_INT8:         return kLQQTPixelFormat_BGRA_int8;
        case kLX_RGBA_FLOAT16:      return kLQQTPixelFormat_RGBA_float16;
        case kLX_RGBA_FLOAT32:      return kLQQTPixelFormat_RGBA_float32;
        case kLX_YCbCr422_INT8:     return kLQQTPixelFormat_YCbCr422_int8;
        default:   _lq_warn_unsupported([NSString stringWithFormat:@"unsupported pixel format: %u", (unsigned)lxPF], __func__);
    }
    return 0;
}


LXPixelBufferRef LXPixelBufferCreateFromLQBitmap(LQBitmap *bitmap)
{
    if ( !bitmap) return NULL;
    
    LXUInteger lxPF = LXPixelFormatFromQTPixelFormat([bitmap pixelFormat]);
    if (lxPF == 0) {
        NSLog(@"** %s: invalid pixel format (%@)", __func__, NSStringFromQTPixelFormat([bitmap pixelFormat]));
        return NULL;
    }    
    
    LXDECLERROR(err);
    
    const LXInteger w = [bitmap size].width;
    const LXInteger h = [bitmap size].height;
    
    LXPixelBufferRef pixbuf = LXPixelBufferCreate(NULL, w, h, lxPF, &err);
    if ( !pixbuf) {
        NSLog(@"** %s: failed (%i / %s)", __func__, err.errorID, err.description);
        LXErrorDestroyOnStack(err);
        return NULL;
    }
    
    size_t dstRowBytes = 0;
    uint8_t *dstBuf = LXPixelBufferLockPixels(pixbuf, &dstRowBytes, NULL, NULL);
    if ( !dstBuf) return NULL;
    
    size_t srcRowBytes = [bitmap bufferRowBytes];
    uint8_t *srcBuf = [bitmap buffer];
    
    const size_t rb = MIN(dstRowBytes, srcRowBytes);
    LXInteger y;
    for (y = 0; y < h; y++) {
        memcpy(dstBuf + dstRowBytes*y,  srcBuf + srcRowBytes*y,  rb);
    }
    
    LXPixelBufferUnlockPixels(pixbuf);
    
    return pixbuf;
}



@implementation LQBitmap

+ (NSString *)lacTypeID {
    return @"Bitmap"; }


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (id %ld, refTime %.3f, sourceTime %.3f; %ld * %ld, pxf %@)>",
                        [self class], self,
                        (long)[self sampleID],
                        [self sampleReferenceTime],
                        [self sampleSourceTime],
                        (long)_w, (long)_h, 
                        NSStringFromQTPixelFormat(_pixelFormat)
                    ];
}


// private storage hint flags
enum {
    kLXStorageHint_PostponeTextureUpdates = 1 << 29,
};


+ (LXUInteger)defaultStorageHintForLXTexture
{
    return (kLXStorageHint_ClientStorage | kLXStorageHint_PreferDMAToCaching | kLXStorageHint_PostponeTextureUpdates);
//    return (kLXStorageHint_ClientStorage);
//    return 0;
}


- (void)propagatePropertiesFromSample:(id)sample
{
    [super propagatePropertiesFromSample:sample];

    if ([sample respondsToSelector:@selector(pixelAspectRatio)]) {
        [self setPixelAspectRatio:[sample pixelAspectRatio]];
        [self setSourceName:[sample sourceName]];
        [self setTag:[sample tag]];
    }
}


- (void)_setupDefaults
{
	_scale = NSMakeSize(1.0, 1.0);
	_par = 1.0;
    
    _lxTextureStorageHint = [[self class] defaultStorageHintForLXTexture];
}

- (id)initAsAliasOfLQBitmap:(LQBitmap *)bitmap retain:(BOOL)doRetain
{
    if ( !bitmap) {
        [self release];
        return nil;
    }
    self = [super init];
    
    _aliasedOriginal = bitmap;
    _aliasedIsRetained = doRetain;
    if (doRetain) {
        [_aliasedOriginal retain];
    }
    
    _w = [bitmap width];
    _h = [bitmap height];
    _pixelFormat = [bitmap pixelFormat];
    
    [self _setupDefaults];
    [self propagatePropertiesFromSample:bitmap];
    
    return self;
}

// all the other data-creating initializers end up calling this one
- (id)initWithOwnedBuffer:(uint8_t *)buffer size:(NSSize)size pixelFormat:(LQQTStylePixelFormat)pxf rowBytes:(size_t)rowBytes
{
	self = [super init];

    if (rowBytes == 0 || buffer == NULL) {
        [self release];
        return nil;
    }
	_rowBytes = rowBytes;
	_pixelFormat = pxf;
	_frameBuf = buffer;

    if (size.width < 1 || size.height < 1) {
        NSLog(@"** %s: zero size (buffer %p)", __func__, buffer);
        [self release];
        return nil;
    }

	_w = size.width;
	_h = size.height;
    
#if defined(__APPLE__)
    int64_t numTotal = OSAtomicIncrement64(&s_createCount);
    int64_t numLive = OSAtomicIncrement64(&s_liveCount);
    int64_t numLiveBytes = OSAtomicAdd64(_rowBytes * _h, &s_liveMemBytesEstimate);
    if (g_lxSurfaceLogFuncCb) {
        char text[512];
        snprintf(text, 512, "%s: %p (%s) = %ld*%ld, total %ld, live %ld, estimated live bytes %ld (%ld MB)", __func__, self, NSStringFromClass([self class]).UTF8String, _w, _h, (long)numTotal, (long)numLive, (long)numLiveBytes, (long)numLiveBytes/(1024*1024));
        g_lxSurfaceLogFuncCb(text, g_lxSurfaceLogFuncCbUserData);
    }
#endif
    
    [self _setupDefaults];
    
	return self;
}


- (id)initWithSize:(NSSize)size pixelFormat:(LQQTStylePixelFormat)pxf
{
    int w = size.width;
    int h = size.height;
    size_t rowBytes = LQWidenRowBytes(w * LQBytesPerPixelForQTPixelFormat(pxf));
    uint8_t *frameBuf = _lx_malloc(rowBytes * h);
    
    self = [self initWithOwnedBuffer:frameBuf size:size pixelFormat:pxf rowBytes:rowBytes];
    return self;
}

- (BOOL)copyFromLQBitmap:(LQBitmap *)otherFrame
{
    if (_aliasedOriginal) {
        NSLog(@"*** %@: can't copy data into aliased bitmap (source is %@)", self, otherFrame);
        return NO;
    }

    if ( !otherFrame) return NO;
	LXInteger w = [otherFrame width];
	LXInteger h = [otherFrame height];
    LQQTStylePixelFormat pixelFormat = [otherFrame pixelFormat];
    size_t srcRowBytes = [otherFrame bufferRowBytes];
    size_t dstRowBytes = _rowBytes;
    
    if (w != _w || h != _h || pixelFormat != _pixelFormat) return NO;
    
    uint8_t *srcBuf = [otherFrame buffer];
    
    [self willModifyFrameBuffer];
    
    if (srcRowBytes == dstRowBytes) {
        memcpy(_frameBuf, srcBuf, srcRowBytes * h);
    } else {
        LXInteger i;
        for (i = 0; i < h; i++) {
            memcpy(_frameBuf + dstRowBytes*i,  srcBuf + srcRowBytes*i,  MIN(srcRowBytes, dstRowBytes));
        }
    }
    [self propagatePropertiesFromSample:otherFrame];
    return YES;
}

- (id)initWithContentsOfLQBitmap:(LQBitmap *)otherFrame tightRowPacking:(BOOL)tightRow
{
    if ( !otherFrame) {
        [self release];
        return nil;
    }
	LXInteger w = [otherFrame width];
	LXInteger h = [otherFrame height];
    LQQTStylePixelFormat pixelFormat = [otherFrame pixelFormat];
	size_t rowBytes = (tightRow) ? (w * LQBytesPerPixelForQTPixelFormat(pixelFormat)) : [otherFrame bufferRowBytes];
	
	size_t bufSize = rowBytes * h;
	uint8_t *frameBuf = _lx_malloc(bufSize);
    
    self = [self initWithOwnedBuffer:frameBuf size:[otherFrame size] pixelFormat:pixelFormat rowBytes:rowBytes];

    if (self) {
        uint8_t *srcBuf = [otherFrame buffer];
        size_t srcRowBytes = [otherFrame bufferRowBytes];

        if ( !tightRow)
            memcpy(_frameBuf, srcBuf, bufSize);
        else {
            LXInteger i;
            for (i = 0; i < h; i++)
                memcpy(_frameBuf + rowBytes*i,  srcBuf + srcRowBytes*i,  MIN(srcRowBytes, rowBytes));
        }
	
        [self propagatePropertiesFromSample:otherFrame];
    }
	
	return self;
}

- (id)initWithContentsOfLQBitmap:(LQBitmap *)frame {
	self = [self initWithContentsOfLQBitmap:frame tightRowPacking:NO];
	return self;
}


- (id)initWithImageNamed:(NSString *)name
{
#ifdef __LAGOON__
    NSLog(@"*** %s: unimplemented", __func__);
    // TODO: on Lagoon, should read GdkPixbuf data from given LGImage
    return nil;

#else
    NSBitmapImageRep *rep;
    rep = (NSBitmapImageRep *)[[NSImage imageNamed:name] bestRepresentationForDevice:nil];
    if ( !rep || ![rep isKindOfClass:[NSBitmapImageRep class]]) {
        [self release];
        return nil;
    } else
        return [self initWithBitmapImageRep:rep];
#endif
}


- (void)dealloc
{
#if defined(__APPLE__)
    int64_t numLive = OSAtomicDecrement64(&s_liveCount);
    int64_t numLiveBytes = OSAtomicAdd64(-(int)(_rowBytes * _h), &s_liveMemBytesEstimate);
    if (g_lxSurfaceLogFuncCb) {
        char text[512];
        snprintf(text, 512, "%s: %p (%s) = %ld*%ld, live now %ld, estimated live bytes %ld (%ld MB)", __func__, self, NSStringFromClass([self class]).UTF8String, _w, _h, (long)numLive, (long)numLiveBytes, (long)numLiveBytes/(1024*1024));
        g_lxSurfaceLogFuncCb(text, g_lxSurfaceLogFuncCbUserData);
        if (_ownedLXPixbuf) {
            snprintf(text, 512, "%s: %p -- note: owns an lxpixbuf, so live bytes was counted there too", __func__, self);
            g_lxSurfaceLogFuncCb(text, g_lxSurfaceLogFuncCbUserData);
        }
    }
#endif

    if (_infoDelegate) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }

    if (_aliasedIsRetained) {
        [_aliasedOriginal release];
    }
    _aliasedOriginal = nil;

    LXTextureRelease(_lxTex);
    _lxTex = NULL;

    LXPixelBufferRelease(_lxPixbufWrap);
    _lxPixbufWrap = NULL;

    if (_ownedLXPixbuf) {
        LXPixelBufferRelease(_ownedLXPixbuf);
        _ownedLXPixbuf = NULL;
    } else {
        _lx_free(_frameBuf);
        _frameBuf = NULL;
    }
	
	[_sourceName release];
	_sourceName = nil;
	
    //if (_texID > 0) {
    //    [PixMathMultipassRender deferDeleteOfGLTextureID:_texID];
    //    _texID = 0;
    //}
    
	[super dealloc];
}


#pragma mark --- basic accessors ---

- (LXInteger)width {
    return _w; }
    
- (LXInteger)height {
    return _h; }

- (NSSize)size {
	return NSMakeSize(_w, _h); }

- (BOOL)matchesSize:(NSSize)size {
    return (_w == (LXInteger)size.width && _h == (LXInteger)size.height) ? YES : NO; }

- (NSSize)imageDataSize {
    return NSMakeSize(_w, _h); }
    
- (LQQTStylePixelFormat)pixelFormat {
	return _pixelFormat; }

- (size_t)bufferRowBytes {
	return (_aliasedOriginal) ? [_aliasedOriginal bufferRowBytes] : _rowBytes;
}
	
- (uint8_t *)buffer {
    return (_aliasedOriginal) ? [_aliasedOriginal buffer] : _frameBuf;
}

- (BOOL)isAlias {
    return (_aliasedOriginal) ? YES : NO; }

- (NSSize)scaleFromOriginal {
	return _scale; }

- (double)pixelAspectRatio {
	return _par; }
	
- (void)setPixelAspectRatio:(double)par {
	_par = par; }

- (NSString *)sourceName {
	return _sourceName; }
	
- (void)setSourceName:(NSString *)name {
	[_sourceName release];
	_sourceName = [name retain];
}

- (LXInteger)tag {
	return _tag; }

- (void)setTag:(LXInteger)tag {
	_tag = tag; }

- (double)displayAspectRatio {
    return ((double)_w / _h) * ((_par > 0.0) ? _par : 1.0);
}


- (void)_privateBitmapUpdateNotif:(NSNotification *)notif
{
    ///NSLog(@"...update notif");
    [_infoDelegate lqBitmapDidUpdate:self];
}

- (void)setInfoDelegate:(id)del {
    _infoDelegate = del;
    
    if (_infoDelegate) {
        // listen to our own private notifications.
        // the idea here is to coalesce the -didModifyFrameBuffer calls into a single call to our info delegate.
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_privateBitmapUpdateNotif:)
                                                    name:@"LQBitmapDidUpdateNotification" object:self];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}
    
- (id)infoDelegate {
    return _infoDelegate; }


- (void)clear
{
    memset(_frameBuf, 0, _rowBytes * _h);
}
    


#pragma mark --- LXTexture ---

- (void)setStorageHintForLXTexture:(LXUInteger)storageHint
{
    _lxTextureStorageHint = storageHint;
}

- (LXUInteger)storageHintForLXTexture
{
    if (_aliasedOriginal) {
        return [_aliasedOriginal storageHintForLXTexture];
    }

    if (_lxTextureStorageHint == 0) {
        _lxTextureStorageHint = [[self class] defaultStorageHintForLXTexture];
    }
    return _lxTextureStorageHint;
}

- (LXUInteger)storageHintForLXPixelBuffer
{
    if (_aliasedOriginal) {
        return [_aliasedOriginal storageHintForLXPixelBuffer];
    }

    return (kLXStorageHint_ClientStorage | kLXStorageHint_PreferDMAToCaching);
//    return (kLXStorageHint_ClientStorage);
//    return 0;
}


- (void)willModifyFrameBuffer
{
    if (_aliasedOriginal) {
        [_aliasedOriginal willModifyFrameBuffer];
        return;
    }

    if (_lxTex) {
        LXTextureWillModifyData(_lxTex, _frameBuf, _rowBytes, [self storageHintForLXTexture]);
        _texIsDirty = YES;
    }
}

- (void)_enqueueRetainedNotif:(NSNotification *)notif
{
    [[NSNotificationQueue defaultQueue]
                        enqueueNotification:[notif autorelease]
                        postingStyle:NSPostWhenIdle
                        coalesceMask:(NSNotificationCoalescingOnName | NSNotificationCoalescingOnSender)
                        forModes:
#if defined(__LAGOON__)
                        [NSArray arrayWithObjects:NSDefaultRunLoopMode, nil]
#else
                        [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil]
#endif
                        ];
}

- (void)_reallyRefreshTexture
{
    LXTextureRefreshWithData(_lxTex, _frameBuf, _rowBytes, [self storageHintForLXTexture]);
    _texIsDirty = NO;
}

- (void)didModifyFrameBuffer
{
    BOOL doTexUpdate = NO;
    // 2011.05.07 -- changed this to default to NO.
    // refreshing the texture on every modification caused flashing in conduit canvas2D rendering.
    // hopefully this doesn't cause horrors.
    
    if (_aliasedOriginal) {
        [_aliasedOriginal didModifyFrameBuffer];
        doTexUpdate = NO;
    }
    if ( !_aliasedOriginal && _infoDelegate && [_infoDelegate respondsToSelector:@selector(lqBitmapShouldRefreshTexture:)]) {
        doTexUpdate = [_infoDelegate lqBitmapShouldRefreshTexture:self];
    }
    if (doTexUpdate && _lxTex) {
        [self _reallyRefreshTexture];
    }
    
    if (_infoDelegate && [_infoDelegate respondsToSelector:@selector(lqBitmapDidUpdate:)]) {
        // post a coalesced update notification on the main thread
        ///NSLog(@"... will post update notif ...");
        
        NSNotification *notif = [[NSNotification notificationWithName:@"LQBitmapDidUpdateNotification"
                                                            object:self
                                                            userInfo:nil] retain];
        if (LXPlatformCurrentThreadIsMain()) {
            [self _enqueueRetainedNotif:notif];
        } else {
            [self performSelectorOnMainThread:@selector(_enqueueRetainedNotif:)
                            withObject:notif
                            waitUntilDone:NO
                            modes:
#if defined(__LAGOON__)
                        [NSArray arrayWithObjects:NSDefaultRunLoopMode, nil]
#else
                        [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil]
#endif
                            ];
        }
        
        //[_infoDelegate lqBitmapDidUpdate:self];
    }
}

- (LXTextureRef)lxTexture
{
    if (_aliasedOriginal) {
        return [_aliasedOriginal lxTexture];
    }

    if ( !_lxTex) {
        LXError err;
        memset(&err, 0, sizeof(LXError));
        
        LXUInteger lxPF = LXPixelFormatFromQTPixelFormat(_pixelFormat);
        if (lxPF == 0) {
            NSLog(@"** %s: invalid pixel format (%i)", __func__, _pixelFormat);
            return NULL;
        }
        
        ///NSLog(@"%s (%i, %i;  first pixels are %i - %i - %i - %i)", __func__, _w, _h,  _frameBuf[0], _frameBuf[1], _frameBuf[2], _frameBuf[3]);
        
        _lxTex = LXTextureCreateWithData(_w, _h, (LXPixelFormat)lxPF,
                                     (uint8_t *)_frameBuf, _rowBytes,
                                     [self storageHintForLXTexture],
                                     &err);
                                     
        if ( !_lxTex) {
            NSLog(@"** %s: lxTex create failed, %i (%s / %s)", __func__, err.errorID, err.location, err.description);
            return NULL;
        }
        
        LXTextureSetSampling(_lxTex, kLXLinearSampling);
    }
    else {
        if (_texIsDirty) {
            [self _reallyRefreshTexture];
        }
    }
    return _lxTex;
}

- (void)invalidateLXTexture
{
    LXTextureRelease(_lxTex);
    _lxTex = NULL;
}

/*
#pragma mark --- reading pixels ---

- (void)readFloatRGBAPixels:(float *)pixelsArray inRegion:(LXRect)region
{
    const LXUInteger pxf = LXPixelFormatFromQTPixelFormat(_pixelFormat);
    if (pxf == 0) {
        NSLog(@"** %s: unable to proceed, unknown pixel format", __func__);
        return;
    }

    const LXInteger w = _w;
    const LXInteger h = _h;
    const LXInteger rowBytes = _rowBytes;
    const LXInteger bytesPerPixel = _bytesPerPixel;
    
    const LXInteger maxX = MIN(w - 1, region.x + region.w - 1);
    const LXInteger maxY = MIN(h - 1, region.y + region.h - 1);
    
    float *dst = pixelsArray;
    
    LXInteger x, y;
    for (y = region.y; y <= maxY; y++) {
        uint8_t *src = _frameBuf + y*rowBytes + (int)region.x*bytesPerPixel;
        
        for (x = region.x; x <= maxX; x++) {
            float r, g, b, a;
            
            switch (pxf) {
                case kLX_RGBA_FLOAT32:
                    r = ((float *)src)[0];
                    g = ((float *)src)[1];
                    b = ((float *)src)[2];
                    a = ((float *)src)[3];
                    break;                    

                case kLX_RGBA_FLOAT16: {
                    
                    break;
                }

                case kLX_ARGB_INT8:
                    break;
                    
                case kLX_RGBA_INT8:
                    break;
                    
                case kLX_BGRA_INT8:
                    break;
                    

                case kLX_YCbCr422_INT8:
                    break;
            }
        
            src += bytesPerPixel;
            dst += 4;
        }
    }
}
*/



#pragma mark --- drawing utils ---

- (void)drawInLXSurface:(LXSurfaceRef)lxSurface inRect:(LXRect)rect
{
    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, rect, LXUnitRect);
    
    LXSurfaceDrawTexturedQuad(lxSurface, (void *)vertices, kLXVertex_XYUV,
                                  [self lxTexture], NULL);
}

- (void)drawInLXSurface:(LXSurfaceRef)lxSurface atPoint:(LXPoint)p
{
    LXRect r;
    r.w = [self width];
    r.h = [self height];
    r.x = p.x;
    r.y = p.y;
    
    [self drawInLXSurface:lxSurface inRect:r];
}

- (void)drawInLXSurface:(LXSurfaceRef)lxSurface atCenterPoint:(LXPoint)p
{
    LXRect r;
    r.w = [self width];
    r.h = [self height];
    r.x = p.x - r.w*0.5;
    r.y = p.y - r.h*0.5;
    
    [self drawInLXSurface:lxSurface inRect:r];
}


#pragma mark --- LXPixelBuffer access ---

- (LXPixelBufferRef)lxPixelBuffer
{
    if (_aliasedOriginal) {
        return [_aliasedOriginal lxPixelBuffer];
    }

    if (_ownedLXPixbuf) {
        return _ownedLXPixbuf;
    }
    else {
        if ( !_lxPixbufWrap) {
            LXUInteger lxPF = LXPixelFormatFromQTPixelFormat(_pixelFormat);
            if (lxPF == 0) {
                NSLog(@"** %s: invalid pixel format (%ui)", __func__, _pixelFormat);
                return NULL;
            }    
            LXDECLERROR(err);
            
            _lxPixbufWrap = LXPixelBufferCreateForData(_w, _h,
                                                        lxPF,
                                                        _rowBytes,
                                                        (uint8_t *)_frameBuf,
                                                        [self storageHintForLXPixelBuffer],
                                                        &err);
            if ( !_lxPixbufWrap) {
                NSLog(@"** unable to create pixbuf (err %i, %s)", err.errorID, err.description);
                LXErrorDestroyOnStack(err);
            }
        }
        return _lxPixbufWrap;
    }
}


#pragma mark --- wrapping an LQBitmap on an LXPixelBufferRef ---

// this method will take possession of the buffer
- (id)initWithOwnedLXPixelBuffer:(LXPixelBufferRef)pixbuf
{
    if ( !pixbuf) {
        [self release];
        return nil;
    }
    
    uint32_t qtPxFormat = LQQTPixelFormatFromLXPixelFormat(LXPixelBufferGetPixelFormat(pixbuf));
    if (qtPxFormat == 0) {
        NSLog(@"** %s: invalid pixel format (%ld)", __func__, (long)LXPixelBufferGetPixelFormat(pixbuf));
        [self release];
        return nil;
    }
    
    size_t rowBytes = 0;
    uint8_t *buffer = (uint8_t *) LXPixelBufferLockPixels(pixbuf, &rowBytes, NULL, NULL);
    
    self = [self initWithOwnedBuffer:buffer size:NSSizeFromLXSize(LXPixelBufferGetSize(pixbuf))
                                            pixelFormat:qtPxFormat
                                            rowBytes:rowBytes];
    
    // by unlocking the pixel buffer here and still keeping its pointer around,
    // we're relying on Lacefx's internal implementation to not change the pointer.
    // this unfortunate fact is commented in LXPixelBuffer.c.
    LXPixelBufferUnlockPixels(pixbuf);
    
    if (self) {
        _ownedLXPixbuf = pixbuf;  // not retained -- the assumption is that we take ownership from the caller
        return self;
    } else {
        [self release];
        return nil;
    }
}



#pragma mark --- conversion from NSImage ---

#if !defined(__LAGOON__)

#import "LQLXImageAppKitUtils.h"


- (id)initWithBitmapImageRep:(NSBitmapImageRep *)rep
{
    if ( !rep) {
        [self release];
        return nil;
    }

    LXDECLERROR(err);
    LXPixelBufferRef pixbuf = LXPixelBufferCreateFromNSBitmapImageRep(rep, &err);
    if ( !pixbuf) {
        NSLog(@"** %s: failed, error %i / %s", __func__, err.errorID, err.description);
        [self release];
        return nil;
    }
    else {
        return [self initWithOwnedLXPixelBuffer:pixbuf];
    }
}

// the following conversion junk isn't necessary anymore, the LXPixelBuffer version does a better job anyway
/*
    BOOL straightAlpha = NO;
    BOOL alphaFirst = NO;
    if ([rep respondsToSelector:@selector(bitmapFormat)]) {
        // the -bitmapFormat message was introduced in 10.4, so we need to check before using it
        NSBitmapFormat bitmapFormat = [rep bitmapFormat];
        
        alphaFirst = (bitmapFormat & NSAlphaFirstBitmapFormat) ? YES : NO;
        straightAlpha = (bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) ? YES : NO;
    }
    int bps = [rep bitsPerSample];
    int bytesPerPixel = [rep bitsPerPixel] / 8;
    int spp = [rep bitsPerPixel] / bps;
    int rowBytes = [rep bytesPerRow];
    int w = [rep pixelsWide];
    int h = [rep pixelsHigh];

    int dstBytesPerPixel = (bps == 8) ? 4 : 16;
    int dstRowBytes = ((w * dstBytesPerPixel) + 15) & ~15;  // 16-byte alignment
    
    // new buffer for data
    uint8_t *dstBuf = _lx_malloc(dstRowBytes * h);
    BOOL success = NO;
    {
        // get NSImage pixel data
        uint8_t *imageBuf = [rep bitmapData];
        
        int i, j;
        
        if (bps == 8) {
            for (i = 0; i < h; i++) {
                uint8_t *srcData = imageBuf + i*rowBytes;
                uint8_t *texData = dstBuf + i*dstRowBytes;
            
                for (j = 0; j < w; j++) {
                    register unsigned char r, g, b, a;
                    if (spp < 3) {
                        r = g = b = srcData[j];
                        a = 255;
                    }
                    else if (spp == 3) {
                        r = srcData[0];
                        g = srcData[1];
                        b = srcData[2];
                        a = 255;
                    }
                    else {
                        if (alphaFirst)  {
                            a = srcData[0];
                            r = srcData[1];
                            g = srcData[2];
                            b = srcData[3];
                        }
                        else {
                            r = srcData[0];
                            g = srcData[1];
                            b = srcData[2];
                            a = srcData[3];
                        }
                    }
                    
                    if (straightAlpha) {  // premultiply
                        r = (int)r*a >> 8;
                        g = (int)g*a >> 8;
                        b = (int)b*a >> 8;
                    }
                    
                    texData[0] = r;
                    texData[1] = g;
                    texData[2] = b;
                    texData[3] = a;
                    texData += 4;
                    srcData += bytesPerPixel;
                }
            }
            success = YES;
        }
        else if (bps == 32) {
            // source data is float
            
            for (i = 0; i < h; i++) {
                float *texData = (float *)(dstBuf + i*dstRowBytes);
            
                for (j = 0; j < w; j++) {
                    float r, g, b, a;
                    float *pf = (float *)&(imageBuf[j*bytesPerPixel]);
                    
                    if (spp < 3) {
                        r = g = b = pf[0];
                        a = 1.0f;
                    }
                    else if (spp == 3) {
                        r = pf[0];
                        g = pf[1];
                        b = pf[2];
                        a = 1.0f;
                    }
                    else {
                        // assume RGBA order for EXR images
                        r = pf[0];
                        g = pf[1];
                        b = pf[2];
                        a = pf[3];
                    }
                    
                    texData[0] = r;
                    texData[1] = g;
                    texData[2] = b;
                    texData[3] = a;
                    texData += 4;
                }
                
                imageBuf += rowBytes;
            }
            success = YES;
        }
        else {
            NSLog(@"** unknown bits per sample: %i", bps);
        }
    }
        
    if (success) {
        [self initWithOwnedBuffer:dstBuf size:NSMakeSize(w, h)
                pixelFormat:((bps == 8) ? kLQQTPixelFormat_RGBA_int8 : kLQQTPixelFormat_RGBA_float32)
                rowBytes:dstRowBytes];
                
        return self;
    }
    else {
        _lx_free(dstBuf);
        
        [self autorelease];
        return nil;
    }
}
*/


#endif // __LAGOON__

@end
