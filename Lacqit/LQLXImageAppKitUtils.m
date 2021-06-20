/*
 *  LQLXImageAppKitUtils.m
 *  Lacqit
 *
 *  Created by Pauli Ojala on 15.4.2010.
 *  Copyright 2010 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LQLXImageAppKitUtils.h"
#import "LQAppKitUtils.h"
#import "LQLXBasicFunctions.h"


/*  NOTE:
    These implementations are only compiled here on Cocotron.
    On Mac OS X, they are included directly in Lacefx.framework.
  
    This is because I don't want to link against AppKit in the Cocotron version of Lacefx.
*/


// this is copied over from Lacefx's Mac version
NSBitmapImageRep *LXPixelBufferCopyAsNSBitmapImageRep(LXPixelBufferRef srcPixbuf, LXError *outError)
{
    if ( !srcPixbuf) return nil;
    
    LXUInteger lxPixelFormat = LXPixelBufferGetPixelFormat(srcPixbuf);
    LXPixelBufferRef tempPixbuf = NULL;
    LXPixelBufferRef pixbuf = srcPixbuf;
    
    if (lxPixelFormat != kLX_RGBA_INT8) {
        tempPixbuf = LXPixelBufferCreate(NULL, LXPixelBufferGetWidth(srcPixbuf), LXPixelBufferGetHeight(srcPixbuf), kLX_RGBA_INT8, outError);
        if ( !tempPixbuf)
            return nil;
        
        if ( !LXPixelBufferCopyPixelBufferWithPixelFormatConversion(tempPixbuf, srcPixbuf, outError))
            return nil;
        
        lxPixelFormat = kLX_RGBA_INT8;
        pixbuf = tempPixbuf;
        /*
        char msg[512];
        snprintf(msg, 512, "unsupported pixel format for conversion (%ld)", lxPixelFormat);
        LXErrorSet(outError, 1602, msg);
        return nil;
        */
    }
    
    const LXInteger w = LXPixelBufferGetWidth(pixbuf);
    const LXInteger h = LXPixelBufferGetHeight(pixbuf);

    size_t rowBytes = 0;
    uint8_t *data = LXPixelBufferLockPixels(pixbuf, &rowBytes, NULL, outError);    
    if ( !data) {
        return nil;  // this shouldn't happen in practice
    }
    
    // create an empty alloced imagerep
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                pixelsWide:w
                                pixelsHigh:h
                                bitsPerSample:8
                                samplesPerPixel:4
                                hasAlpha:YES
                                isPlanar:NO
                                colorSpaceName:NSDeviceRGBColorSpace
                                bitmapFormat:0
                                bytesPerRow:rowBytes
                                bitsPerPixel:32];
                                
    if (rep && [rep bitmapData]) {
        memcpy([rep bitmapData], data, rowBytes * h);
    } else {
        LXErrorSet(outError, 1603, "unable to create NSBitmapRep");
    }
                        
    LXPixelBufferUnlockPixels(pixbuf);
    
    LXPixelBufferRelease(tempPixbuf);
    return rep;
}


// this is native to Cocotron (the Mac version actually reads the pixel data,
// but we don't need to do that much)
LXPixelBufferRef LXPixelBufferCreateFromNSBitmapImageRep(NSBitmapImageRep *rep, LXError *outError)
{
    if ( !rep) return NULL;
    
    LXInteger w = [rep pixelsWide];
    LXInteger h = [rep pixelsHigh];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
    [image addRepresentation:rep];

    LXPixelBufferRef pixbuf = LXPixelBufferCreateScaledFromNSImage(image, w, h);
    
    [image release];
    
    return pixbuf;
}

LXPixelBufferRef LXPixelBufferCreateFromPathUsingAppKit(LXUnibuffer *unipath, LXMapPtr properties, LXError *outError)
{
    if ( !unipath) {
        NSLog(@"** %s: no path", __func__);
        return NULL;
    }
    NSString *path = NSStringFromLXUnibuffer(*unipath);
    
    NSLog(@"%s: loading path %@", __func__, path);
    
    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    if ( !image) {
        NSLog(@"** %s: unable to load path: %@", __func__, path);
        LXErrorSet(outError, 1621, "couldn't open image file");
        return NULL;
    }
    
    NSSize size = [image size];
    
    return LXPixelBufferCreateScaledFromNSImage(image, size.width, size.height);
}
