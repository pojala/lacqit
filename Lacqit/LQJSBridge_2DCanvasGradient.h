//
//  LQJSBridge_2DCanvasGradient.h
//  Lacqit
//
//  Created by Pauli Ojala on 10.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"
@class LQJSBridge_2DCanvas;
@class LQGradient;


@interface LQJSBridge_2DCanvasGradient : LQJSBridgeObject {

    LQGradient *_grad;
    
    BOOL _isRad;
    NSPoint _p1, _p2;
    double _radius1, _radius2;
       
    cairo_pattern_t *_cairoPattern;
}

- (id)initInJSContext:(JSContextRef)context isRadial:(BOOL)isRad
                                            pointData:(double *)pointData;  // 4 elements for linear, 6 elements for radial

- (cairo_pattern_t *)cairoPattern;

@end
