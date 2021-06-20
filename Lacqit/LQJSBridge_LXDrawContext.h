//
//  LQJSBridge_LXDrawContext.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>

@class LQJSBridge_LXTransform;
@class LQJSBridge_LXShader;


enum {
    kLQXSurfaceRenderStyle_None = 0,
    kLQXSurfaceRenderStyle_OSC = 1
};


@interface LQJSBridge_LXDrawContext : LQJSBridgeObject {

    LXDrawContextRef _drawCtx;  // retained
    
    NSArray *_texArray;
    
    LQJSBridge_LXTransform *_mvTrsBridge;
    LQJSBridge_LXTransform *_projTrsBridge;
    LQJSBridge_LXShader *_shaderBridge;
    
    LXUInteger _renderStyle;
}

- (id)initWithLXDrawContext:(LXDrawContextRef)ctx
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXDrawContextRef)lxDrawContext;

- (NSArray *)textureArray;

- (LXUInteger)lqxRenderStyle;

@end
