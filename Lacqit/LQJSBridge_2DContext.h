//
//  LQJSBridge_2DContext.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"
@class LQJSBridge_2DCanvas;


@interface LQJSBridge_2DContext : LQJSBridgeObject {

    LQJSBridge_2DCanvas *_canvas;

    cairo_t *_cr;
    
    // JS-visible properties
    double _globalAlpha;
    id _globalCompOp;
    LXInteger _globalCompOpCairo;
    
    id _strokeStyle;
    id _fillStyle;
    
    double _lineWidth;
    id _lineCap;
    id _lineJoin;
    double _miterLimit;
    
    NSFont *_font;
    LXInteger _textAlign;
    LXInteger _textBaseline;
    
    id _shadowColor;
    double _shadowBlur;
    NSPoint _shadowOffset;
    
    NSMutableArray *_stack;
    
    ///NSMutableArray *_createdBridgeObjs;
}

- (id)initInJSContext:(JSContextRef)context withOwnerCanvas:(LQJSBridge_2DCanvas *)canvas;

- (void)finishContext;


- (void)_applyStrokeStyle:(cairo_t *)cr;
- (void)_applyFillStyle:(cairo_t *)cr;

@end
