/*
 *  LQAppKitUtils.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 7.12.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import "LacqitExport.h"
#import "LQNumberScrubField.h"


// -- conversions --

LACQIT_EXPORT NSImage *NSImageFromLXPixelBuffer(LXPixelBufferRef pixbuf);

// uses Quartz to draw the image into a bitmap context.
// for no scaling, pass 0 for width and height.
// Quartz will perform its own choice of colorspace conversions;
// if you need a precise copy of the pixel data, you should use the private ...FromNSBitmapImageRep_ function in Lacefx instead.
LACQIT_EXPORT LXPixelBufferRef LXPixelBufferCreateScaledFromNSImage(NSImage *image, uint32_t w, uint32_t h);

// same operation as above, but for CGImage
LACQIT_EXPORT LXPixelBufferRef LXPixelBufferCreateScaledFromCGImage(CGImageRef cgImage, uint32_t w, uint32_t h);

// -- cg images --

// extracts the alpha channel as a greyscale image
LACQIT_EXPORT CGImageRef LQCreateGrayscaleImageFromCGImageAlpha(CGImageRef cgImage);

// -- views --

LACQIT_EXPORT void LQSetTextColorForControl(NSColor *textColor, id control);

LACQIT_EXPORT id LQReplaceInputFieldWithThemedField(NSTextField *field, LXInteger controlSize);  // pass -1 for controlSize to keep the field height the same

LACQIT_EXPORT id LQReplaceInputFieldWithNumberScrubField(NSTextField *field, LXInteger controlSize);  // pass -1 for controlSize to keep the field height the same
