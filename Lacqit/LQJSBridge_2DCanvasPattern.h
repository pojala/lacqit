//
//  LQJSBridge_2DCanvasPattern.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"
@class LQJSBridge_2DCanvas;
@class LQJSBridge_Image;


@interface LQJSBridge_2DCanvasPattern : LQJSBridgeObject {

    LQCairoBitmap       *_pattBitmap;
    cairo_pattern_t     *_cairoPattern;
    
    LQJSBridge_2DCanvas *_pattSrcCanvas;
    ///LQJSBridge_Image    *_pattSrcImage;
    
    cairo_extend_t      _extendMode;
}

- (id)initInJSContext:(JSContextRef)context patternCanvas:(LQJSBridge_2DCanvas *)pattCanvas
                                            extendMode:(cairo_extend_t)extend;

- (id)initInJSContext:(JSContextRef)context patternImage:(LQJSBridge_Image *)pattImage
                                            extendMode:(cairo_extend_t)extend;

- (cairo_pattern_t *)cairoPattern;

@end
