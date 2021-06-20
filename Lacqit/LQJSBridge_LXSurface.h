//
//  LQJSBridge_LXSurface.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LXSurface : LQJSBridgeObject {

    LXSurfaceRef _surface;  // not retained
    BOOL _wasJSConstructed;
    
    id _drawCtxBridge;
    id _textureBridge;
}

- (id)initWithLXSurface:(LXSurfaceRef)surf
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXSurfaceRef)lxSurface;

- (id)drawingContext;

@end
