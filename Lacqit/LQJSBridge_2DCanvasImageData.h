//
//  LQJSBridge_2DCanvasImageData.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"
@class LQJSBridge_2DCanvas;
@class LQJSBridge_Image;


@interface LQJSBridge_2DCanvasImageData : LQJSBridgeObject {

    LQCairoBitmap *_bitmap;
    
    id _pixelDataObj;
}

- (id)initInJSContext:(JSContextRef)context size:(NSSize)size;

- (LQCairoBitmap *)cairoBitmap;

@end
