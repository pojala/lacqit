//
//  LQCairoFrame.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQCairoBitmap.h"

#if (USEQUARTZ)
#import <Cairo/CairoQuartz.h>
#endif


cairo_matrix_t LQCairoMatrixFromNSAffineTransform(NSAffineTransform *transform)
{
    cairo_matrix_t cmat;
    if ( !transform) {
        cairo_matrix_init_identity(&cmat);
    } else {
        NSAffineTransformStruct nsMat = [transform transformStruct];
        cmat.xx = nsMat.m11;
        cmat.yx = nsMat.m12;
        cmat.xy = nsMat.m21;
        cmat.yy = nsMat.m22;
        cmat.x0 = nsMat.tX;
        cmat.y0 = nsMat.tY;
    }
    return cmat;
}


@interface LQBitmap (PrivateToSubclasses)
- (id)initWithOwnedBuffer:(unsigned char *)buffer size:(NSSize)size pixelFormat:(LQQTStylePixelFormat)pxf rowBytes:(size_t)rowBytes;
@end


@implementation LQCairoBitmap

+ (LXUInteger)defaultStorageHintForLXTexture
{
    return (kLXStorageHint_ClientStorage | kLXStorageHint_PreferDMAToCaching);
//    return (kLXStorageHint_ClientStorage);
//    return 0;
}


- (id)initWithSize:(NSSize)size
{
    // unlike Quartz, Cairo's ARGB pixel layout is endian-dependent, so it's BGRA on Intel
    unsigned int pxFormat = CAIROARGB_QTSTYLEPXFORMAT;
        
    #if (CAIROBMP_USEQUARTZ)
    pxFormat = kLQQTPixelFormat_ARGB_int8;
    #endif

    self = [super initWithSize:size pixelFormat:pxFormat];
    
    if (self) {
        #if (CAIROBMP_USEQUARTZ)
        CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
        _cgContext = CGBitmapContextCreate( _frameBuf, _w, _h, 8, _rowBytes, cspace, kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(cspace);    
        
        _cairoSurf = cairo_quartz_surface_create_for_cg_context (_cgContext, _w, _h);
        
        #else
        _cairoSurf = cairo_image_surface_create_for_data (_frameBuf, CAIRO_FORMAT_ARGB32,
                                                          _w, _h, _rowBytes);
        #endif
        
        if ( !_cairoSurf || cairo_surface_status(_cairoSurf) != CAIRO_STATUS_SUCCESS) {
            NSLog(@"** %s: failed to create Cairo surface for memory buffer (error %i; size %ld * %ld, rb %ld)",  __func__,
                                            (int)cairo_surface_status(_cairoSurf),
                                            (long)_w, (long)_h, (long)_rowBytes);
            [self release];
            return nil;
        }
    }
    return self;
}

// this is called by the -initWithContentsOfLQBitmap: copy constructor
- (id)initWithOwnedBuffer:(unsigned char *)buffer size:(NSSize)size pixelFormat:(LQQTStylePixelFormat)pxf rowBytes:(size_t)rowBytes
{
    if (pxf != CAIROARGB_QTSTYLEPXFORMAT) {
        NSLog(@"** %s: unsupported pixel format (%i)", __func__, pxf);
        [self autorelease];
        return nil;
    }
    
    self = [super initWithOwnedBuffer:buffer size:size pixelFormat:pxf rowBytes:rowBytes];
    
    if (self) {
        _cairoSurf = cairo_image_surface_create_for_data (_frameBuf, CAIRO_FORMAT_ARGB32,
                                                          _w, _h, _rowBytes);
                                                          
        if ( !_cairoSurf || cairo_surface_status(_cairoSurf) != CAIRO_STATUS_SUCCESS) {
            NSLog(@"** %s: failed to create Cairo surface for memory buffer (error %i; size %ld * %ld, rb %ld)",  __func__,
                                            (int)cairo_surface_status(_cairoSurf),
                                            (long)_w, (long)_h, (long)_rowBytes);
            [self release];
            return nil;
        }
    }
    return self;
}


- (id)initWithLXPixelBuffer:(LXPixelBufferRef)lxPixbuf
{
    int w = LXPixelBufferGetWidth(lxPixbuf);
    int h = LXPixelBufferGetHeight(lxPixbuf);
    unsigned int pxFormat = LXPixelBufferGetPixelFormat(lxPixbuf);
    
    if ( !lxPixbuf || w < 1 || h < 1 || pxFormat == 0) {
        [self autorelease];
        return nil;
    }
    
    self = [super initWithSize:NSMakeSize(w, h) pixelFormat:CAIROARGB_QTSTYLEPXFORMAT];
    
    if (self) {
        LXDECLERROR(err);
        LXSuccess didConvert = LXPixelBufferGetDataWithPixelFormatConversion(lxPixbuf,
                                            _frameBuf, _w, _h, _rowBytes,
                                            CAIROARGB_LXSTYLEPXFORMAT,
                                            NULL, &err);
        if ( !didConvert) {
            NSLog(@"*** %s: failed to convert data, can't proceed (%i * %i); error %i / '%s'", __func__, w, h, err.errorID, err.description);
            LXErrorDestroyOnStack(err);
            [self autorelease];
            return nil;
        }
        else {
            ///NSLog(@"%s: successful with conversion %i -> %i (%i * %i)", __func__, pxFormat, CAIROARGB_LXSTYLEPXFORMAT, w, h);

            _cairoSurf = cairo_image_surface_create_for_data (_frameBuf, CAIRO_FORMAT_ARGB32,
                                                              _w, _h, _rowBytes);
        
            if ( !_cairoSurf || cairo_surface_status(_cairoSurf) != CAIRO_STATUS_SUCCESS) {
                NSLog(@"** %s: failed to create Cairo surface for memory buffer (error %i; size %ld * %ld, rb %ld)",
                                            __func__,
                                            (int)cairo_surface_status(_cairoSurf),
                                            (long)_w, (long)_h, (long)_rowBytes);
                [self autorelease];
                return nil;
            }
        }
    }
    return self;
}


- (void)dealloc
{
#if (CAIROBMP_USEQUARTZ)
    CGContextRelease(_cgContext);
    _cgContext = NULL;    
#endif

    cairo_surface_destroy(_cairoSurf);
    _cairoSurf = NULL;
    
    [super dealloc];
}

- (cairo_surface_t *)cairoSurface
{
    return _cairoSurf;
}

- (cairo_t *)lockCairoContext
{
    [self willModifyFrameBuffer];

    if ( !_lockedCairoCtx) {
        _lockedCairoCtx = cairo_create(_cairoSurf);
    }
    _lockCount++;
    return _lockedCairoCtx;
}

#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();

- (void)didModifyFrameBuffer
{
    //DTIME(t0)
    cairo_surface_flush(_cairoSurf);
    //DTIME(t1)
    
    [super didModifyFrameBuffer];
    
    //DTIME(t2)
    ///NSLog(@"cairo didmodifyframebuffer: %.3f ms, %.3f ms", 1000*(t1-t0), 1000*(t2-t1));
}

- (void)unlockCairoContext
{
    _lockCount--;
    if (_lockCount < 1 && _lockedCairoCtx) {
        cairo_destroy(_lockedCairoCtx);
        _lockedCairoCtx = NULL;
    }
    
    ///NSLog(@"%s (%i, %i;  first pixels are %i - %i - %i - %i)", __func__, _w, _h,  _frameBuf[0], _frameBuf[1], _frameBuf[2], _frameBuf[3]);
}

- (cairo_t *)lockAndSaveCairoContext
{
    cairo_t *cr = [self lockCairoContext];
    cairo_save(cr);
    return cr;
}

- (void)unlockAndRestoreCairoContext
{
    cairo_restore(_lockedCairoCtx);
    [self unlockCairoContext];
}

@end



@implementation LQBitmap (LQBitmapCairoAdditions)

- (void)copyIntoCairoSurface:(cairo_surface_t *)cairoSurf
{
    if ( !cairoSurf) return;
    
    LXInteger w = [self width];
    LXInteger h = [self height];
    
    uint8_t *dstBuf = cairo_image_surface_get_data(cairoSurf);
    size_t dstRowBytes = cairo_image_surface_get_stride(cairoSurf);
    int dstFormat = cairo_image_surface_get_format(cairoSurf);
    
    if (dstFormat != CAIRO_FORMAT_ARGB32) {
        NSLog(@"*** %s: unsupported target format (only RGB supported currently), %i", __func__, dstFormat);
        return;
    }
    
    uint8_t *srcBuf = [self buffer];
    size_t srcRowBytes = [self bufferRowBytes];
    uint32_t pxFormat = [self pixelFormat];
    
    cairo_surface_flush(cairoSurf);

    // on x86, Cairo uses BGRA layout
    
    if (pxFormat == CAIROARGB_QTSTYLEPXFORMAT) {
        LXPxCopy_RGBA_int8(w, h, srcBuf, srcRowBytes, dstBuf, dstRowBytes);
    }
    else if (pxFormat == kLQQTPixelFormat_RGBA_int8) {
        #if !defined(__BIG_ENDIAN__)
        LXPxConvert_RGBA_to_reverse_BGRA_int8(w, h, srcBuf, srcRowBytes, dstBuf, dstRowBytes);
        #else
        LXPxConvert_RGBA_to_ARGB_int8(w, h, srcBuf, srcRowBytes, dstBuf, dstRowBytes);
        #endif
    }
    else if (pxFormat == kLQQTPixelFormat_ARGB_int8) {
        // this function works for ARGB->BGRA 
        LXPxConvert_RGBA_to_reverse_int8(w, h, srcBuf, srcRowBytes, dstBuf, dstRowBytes);
    }
    else {
        NSLog(@"** %s: unsupported source format (%@)", __func__, NSStringFromQTPixelFormat(pxFormat));
    }
    
    cairo_surface_mark_dirty(cairoSurf);

}

@end

