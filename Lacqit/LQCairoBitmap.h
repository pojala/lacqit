//
//  LQCairoFrame.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQBitmap.h"
#import <Cairo/cairo.h>
#import <Lacefx/Lacefx.h>


// unlike Quartz, Cairo's ARGB pixel layout is endian-dependent, so from our Mac-centric view it becomes 'BGRA' on x86.
// these are endian-independent pixel formats that match CAIRO_FORMAT_ARGB32.
#ifndef __BIG_ENDIAN__
 #define CAIROARGB_LXSTYLEPXFORMAT  kLX_BGRA_INT8
 #define CAIROARGB_QTSTYLEPXFORMAT  kLQQTPixelFormat_BGRA_int8
#else
 #define CAIROARGB_LXSTYLEPXFORMAT  kLX_ARGB_INT8
 #define CAIROARGB_QTSTYLEPXFORMAT  kLQQTPixelFormat_ARGB_int8
#endif


#ifdef __APPLE__
/* setting this flag makes LQCairoBitmap use a CGContext backing instead of a Cairo buffer.
   however the results don't seem completely reliable as of Cairo 1.6.4 on Leopard (at least text gets rendered upside down?).
   testing with Conduit's JS canvas node suggests that the Quartz backend isn't much faster than
   Cairo's own routines ayway, so there's probably not much point to it...? */
#define CAIROBMP_USEQUARTZ 0
#endif


LACQIT_EXPORT cairo_matrix_t LQCairoMatrixFromNSAffineTransform(NSAffineTransform *trs);


@interface LQCairoBitmap : LQBitmap {

    cairo_surface_t     *_cairoSurf;
    
    #if defined(CAIROBMP_USEQUARTZ) && CAIROBMP_USEQUARTZ
    CGContextRef        _cgContext;
    #endif
    
    cairo_t             *_lockedCairoCtx;
    int                 _lockCount;
}

- (id)initWithSize:(NSSize)size;

- (id)initWithLXPixelBuffer:(LXPixelBufferRef)lxPixbuf;  // copies the pixel data (converting to Cairo's ARGB format as necessary)

- (cairo_surface_t *)cairoSurface;

- (cairo_t *)lockCairoContext;  // is recursive (lock calls can be nested)
- (void)unlockCairoContext;

- (cairo_t *)lockAndSaveCairoContext;  // convenience method: calls -lockCairoContext, then cairo_save()
- (void)unlockAndRestoreCairoContext;

@end


@interface LQBitmap (LQBitmapCairoAdditions)

- (void)copyIntoCairoSurface:(cairo_surface_t *)cairoSurf;

@end
