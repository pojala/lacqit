/*
 *  LQLXImageAppKitUtils.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 15.4.2010.
 *  Copyright 2010 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LacqitExport.h"
#import <Lacefx/Lacefx.h>
#import <AppKit/AppKit.h>


#if defined(LXPLATFORM_MAC)


// on Mac OS X, these are private functions in Lacefx.framework

#import <Lacefx/LXPixelBuffer_priv.h>
/*
extern LXPixelBufferRef LXPixelBufferCreateFromNSBitmapImageRep(NSBitmapImageRep *rep, LXError *outError);

extern NSBitmapImageRep *LXPixelBufferCopyAsNSBitmapImageRep(LXPixelBufferRef pixbuf, LXError *outError);
*/

#elif defined (__COCOTRON__)

// on Cocotron, these functions are implemented here

LACQIT_EXPORT LXPixelBufferRef LXPixelBufferCreateFromNSBitmapImageRep(NSBitmapImageRep *rep, LXError *outError);

LACQIT_EXPORT NSBitmapImageRep *LXPixelBufferCopyAsNSBitmapImageRep(LXPixelBufferRef pixbuf, LXError *outError);


// this function is dynamically loaded from Lacefx if needed to load image types not supported by the Lacefx base
LACQIT_EXPORT LXPixelBufferRef LXPixelBufferCreateFromPathUsingAppKit(LXUnibuffer *unipath, LXMapPtr properties, LXError *outError);

#else

#warning "This file should not be included on Lagoon builds"

#endif



