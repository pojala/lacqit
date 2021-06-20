//
//  LQLXSurface.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import "LQStreamBuffer.h"

/*
This class is used for buffers in LQStreamPatch.
The idea is that these objects are thin wrappers that all return -lxTexture.
*/

@interface LQLXSurface : LQStreamBuffer {

    LXSurfaceRef _surface;
    
    LXPixelBufferRef _assocPixbuf;
    
    BOOL _isRetained;
    BOOL __resBool1_lxs;
    BOOL __resBool2_lxs;
    BOOL __resBool3_lxs;
}

- (id)initWithLXSurface:(LXSurfaceRef)surface retain:(BOOL)doRetain;

- (LXSurfaceRef)lxSurface;
- (LXTextureRef)lxTexture;

- (NSSize)imageDataSize;

- (LXPixelBufferRef)associatedLXPixelBuffer;
- (void)setAssociatedLXPixelBuffer:(LXPixelBufferRef)pixbuf;

@end
