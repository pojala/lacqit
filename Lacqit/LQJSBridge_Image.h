//
//  LQJSBridge_Image.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>
#import "LQJSPatchMarshalling.h"
@class LQCairoBitmap;


@interface LQJSBridge_Image : LQJSBridgeObject  <LQJSPatchMarshalling> {

    LXPixelBufferRef _pixbuf;
    
    LQCairoBitmap *_cairoBitmap;  // created from the pixbuf only on request
}

- (id)initWithLXPixelBuffer:(LXPixelBufferRef)pixbuf
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXPixelBufferRef)lxPixelBuffer;

- (LQCairoBitmap *)cairoBitmap;

@end
