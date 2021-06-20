/*
 *  LQAppKitUtils.m
 *  Lacqit
 *
 *  Created by Pauli Ojala on 7.12.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LQAppKitUtils.h"
#import "LQThemedInputField.h"
#import "LQNumberScrubField.h"


void LQSetTextColorForControl(NSColor *textColor, id control)
{
    if ([control respondsToSelector:@selector(setTextColor:)]) {
        [control setTextColor:textColor];
        return;  // --
    }
    
    if ([control isKindOfClass:[NSMatrix class]]) {
        for (NSCell *cell in [control cells]) {
            NSString *key;
            if ([cell respondsToSelector:@selector(setAttributedTitle:)]) {
                key = @"attributedTitle";
            } else if ([control respondsToSelector:@selector(setAttributedStringValue:)]) {
                key = @"attributedStringValue";
            }
            
            NSMutableAttributedString *attrTitle = [[[cell valueForKey:key] mutableCopy] autorelease];
            NSRange range = NSMakeRange(0, [attrTitle length]);
            [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
            [attrTitle fixAttributesInRange:range];
            [cell setValue:attrTitle forKey:key];
            [control updateCell:cell];
        }
        return;  // --
    }
    
    NSString *key = nil;
    if ([control respondsToSelector:@selector(setAttributedTitle:)]) {
        key = @"attributedTitle";
    } else if ([control respondsToSelector:@selector(setAttributedStringValue:)]) {
        key = @"attributedStringValue";
    }
    if (key) {
        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[control valueForKey:key]];
        NSRange range = NSMakeRange(0, [attrTitle length]);
        [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
        [attrTitle fixAttributesInRange:range];
        [control setValue:attrTitle forKey:key];
        [attrTitle release];
    } else {
        NSLog(@"** unable to set text color for control: %@", control);
    }
}

id LQReplaceInputFieldWithThemedField(NSTextField *field, LXInteger controlSize)
{
    NSRect frame = [field frame];
    if (controlSize != -1) {
        frame.size.height = [LQThemedInputField fieldHeightForControlSize:controlSize];
    }

    id oldField = [field retain];
    id superview = [field superview];
    [field removeFromSuperview];
    
    field = [[[LQThemedInputField alloc] initWithFrame:frame] autorelease];
    [superview addSubview:field];
    [(NSView *)field setAutoresizingMask:[(NSView *)oldField autoresizingMask]];
    [field setAction:[oldField action]];
    [field setTarget:[oldField target]];
    [field setHidden:[oldField isHidden]];
    [field setFormatter:[oldField formatter]];
    [field setTag:[oldField tag]];

    [oldField release];
    
    return field;
}

id LQReplaceInputFieldWithNumberScrubField(NSTextField *field, LXInteger controlSize)
{
    NSRect frame = [field frame];
    frame.size.height = 16;
    frame.size.width = 66;
    
    id oldField = [field retain];
    id superview = [field superview];
    [field removeFromSuperview];
    
    field = [[[LQNumberScrubField alloc] initWithFrame:frame] autorelease];
    [superview addSubview:field];
    [(NSView *)field setAutoresizingMask:[(NSView *)oldField autoresizingMask]];
    [field setAction:[oldField action]];
    [field setTarget:[oldField target]];
    [field setHidden:[oldField isHidden]];
    [field setTag:[oldField tag]];

    [oldField release];
    
    return field;
}


#pragma mark --- NSImage utils ---


#if !defined(__LAGOON__)

#import "LQLXImageAppKitUtils.h"


NSImage *NSImageFromLXPixelBuffer(LXPixelBufferRef pixbuf)
{
    if ( !pixbuf) return nil;

    LXDECLERROR(err)
    NSBitmapImageRep *rep = LXPixelBufferCopyAsNSBitmapImageRep(pixbuf, &err);
    
    if ( !rep) {
        NSLog(@"** Unable to create image from lxpixelbuffer (%i / %s)", err.errorID, err.description);
        LXErrorDestroyOnStack(err);
        return nil;
    } else {
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(LXPixelBufferGetWidth(pixbuf), LXPixelBufferGetHeight(pixbuf))];
        [image addRepresentation:[rep autorelease]];
        
        return [image autorelease];
    }
}


void LQCopyNSImageIntoCGContextWithScaling(NSImage *image, CGContextRef cgCtx, BOOL hiQ)
{
    if ( !cgCtx) return;

    if (hiQ) {
        CGContextSetInterpolationQuality(cgCtx, kCGInterpolationHigh);
    } else {
        CGContextSetInterpolationQuality(cgCtx, kCGInterpolationNone);
    }
    
    NSRect dstRect = NSMakeRect(0, 0, CGBitmapContextGetWidth(cgCtx), CGBitmapContextGetHeight(cgCtx));
    
    NSGraphicsContext *nsCtx = [NSGraphicsContext graphicsContextWithGraphicsPort:cgCtx flipped:NO];
    NSGraphicsContext *prevCtx = [[NSGraphicsContext currentContext] retain];
    [NSGraphicsContext setCurrentContext:nsCtx];
    
    [image drawInRect:dstRect fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
                              operation:NSCompositeSourceOver fraction:1.0];

    [nsCtx flushGraphics];
    [NSGraphicsContext setCurrentContext:prevCtx];
    [prevCtx release];
}


LXPixelBufferRef LXPixelBufferCreateScaledFromNSImage(NSImage *image, uint32_t w, uint32_t h)
{
    if ( !image) return nil;
    
    uint32_t imW = [image size].width;
    uint32_t imH = [image size].height;
    
    if (w < 1 || h < 1) {
        w = imW;
        h = imH;
    }
    
    int bytesPerPixel = 4;
    size_t rowBytes = LXAlignedRowBytes(w * bytesPerPixel);
    uint8_t *data = _lx_calloc(rowBytes * h, 1);
    
    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgCtx = CGBitmapContextCreate(data, w, h, 8, rowBytes, cspace, kCGImageAlphaPremultipliedLast);
    LQCopyNSImageIntoCGContextWithScaling(image, cgCtx, (w != imW || h != imH));
    
    CGContextFlush(cgCtx);
    CGContextRelease(cgCtx);
    CGColorSpaceRelease(cspace);
    
    LXDECLERROR(err)

    LXPixelBufferRef pixbuf = LXPixelBufferCreateForData(w, h, kLX_RGBA_INT8, rowBytes, data, 0, &err);
    if ( !pixbuf) {
        NSLog(@"** %s: pixbuf conversion failed (%i / %s)", __func__, err.errorID, err.description);
        LXErrorDestroyOnStack(err);
        _lx_free(data);
    }
    return pixbuf;
}


LXPixelBufferRef LXPixelBufferCreateScaledFromCGImage(CGImageRef cgImage, uint32_t w, uint32_t h)
{
    if ( !cgImage) return NULL;
    
    uint32_t imW = CGImageGetWidth(cgImage);
    uint32_t imH = CGImageGetHeight(cgImage);
    
    if (w < 1 || h < 1) {
        w = imW;
        h = imH;
    }
    
    int bytesPerPixel = 4;
    size_t rowBytes = LXAlignedRowBytes(w * bytesPerPixel);
    uint8_t *data = _lx_calloc(rowBytes * h, 1);
    
    CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgCtx = CGBitmapContextCreate(data, w, h, 8, rowBytes, cspace, kCGImageAlphaPremultipliedLast);

    CGContextSetInterpolationQuality(cgCtx, kCGInterpolationHigh);
    
    CGContextDrawImage(cgCtx, CGRectMake(0, 0, w, h), cgImage);
    
    CGContextFlush(cgCtx);
    CGContextRelease(cgCtx);
    CGColorSpaceRelease(cspace);
    
    LXDECLERROR(err)

    LXPixelBufferRef pixbuf = LXPixelBufferCreateForData(w, h, kLX_RGBA_INT8, rowBytes, data, 0, &err);
    if ( !pixbuf) {
        NSLog(@"** %s: pixbuf conversion failed (%i / %s)", __func__, err.errorID, err.description);
        LXErrorDestroyOnStack(err);
        _lx_free(data);
    }
    return pixbuf;
}


//CGContextRef LQCreateGrayscaleCGBitmapContextFromCGImageAlpha(CGImageRef cgImage)
CGImageRef LQCreateGrayscaleImageFromCGImageAlpha(CGImageRef cgImage)
{
    if ( !cgImage) return NULL;
    int w = CGImageGetWidth(cgImage);
    int h = CGImageGetHeight(cgImage);

    CGColorSpaceRef cspace = NULL;
    CGContextRef grayCtx = NULL;
    size_t dstRowBytes;
    uint8_t *dstBuf;
    
    dstRowBytes = LXAlignedRowBytes(w);
    dstBuf = _lx_malloc(dstRowBytes * h);
    cspace = CGColorSpaceCreateDeviceGray();
    grayCtx = CGBitmapContextCreate(dstBuf, w, h, 8, dstRowBytes, cspace, kCGImageAlphaNone);
    CGColorSpaceRelease(cspace);
    size_t dstStride = 1;

    if ( !grayCtx || !CGBitmapContextGetData(grayCtx)) {
        // couldn't create a grayscale CGContext, so try with RGBA
        dstRowBytes = LXAlignedRowBytes(w*4);
        dstBuf = _lx_realloc(dstBuf, dstRowBytes * h);
        cspace = CGColorSpaceCreateDeviceRGB();
        grayCtx = CGBitmapContextCreate(dstBuf, w, h, 8, dstRowBytes, cspace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(cspace);
        dstStride = 4;
    }
    if ( !grayCtx || !CGBitmapContextGetData(grayCtx)) {
        _lx_free(dstBuf);
        NSLog(@"** %s: unable to create CGContext", __func__);
        return NULL;
    }
    
    LXPixelBufferRef pixbuf = LXPixelBufferCreateScaledFromCGImage(cgImage, w, h);
    size_t srcRowBytes;
    uint8_t *srcBuf = LXPixelBufferLockPixels(pixbuf, &srcRowBytes, NULL, NULL);
    
    if ( !srcBuf) {
        NSLog(@"** %s: could not lock scaled image for source of conversion (%p)", __func__, pixbuf);
        _lx_free(dstBuf);
        LXPixelBufferRelease(pixbuf);
        return NULL; // --
    }

    
    LXInteger x, y;
    for (y = 0; y < h; y++) {
        uint8_t *src = srcBuf + srcRowBytes*y;
        uint8_t *dst = dstBuf + dstRowBytes*y;
        if (dstStride == 1) {
            for (x = 0; x < w; x++) {
                dst[0] = src[3];
                dst++;
                src += 4;
            }
        }
        else {
            for (x = 0; x < w; x++) {
                dst[0] = dst[1] = dst[2] = src[3];
                dst[3] = 255;
                dst += 4;
                src += 4;
            }
        }
    }
    
    LXPixelBufferUnlockPixels(pixbuf);
    LXPixelBufferRelease(pixbuf);
    
    CGImageRef newImage = CGBitmapContextCreateImage(grayCtx);
    CGContextRelease(grayCtx);
    _lx_free(dstBuf);
    
    return newImage;
}


#endif  // !__LAGOON__

