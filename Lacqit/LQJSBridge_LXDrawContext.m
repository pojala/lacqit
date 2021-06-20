//
//  LQJSBridge_LXDrawContext.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXDrawContext.h"
#import "LQJSBridge_LXSurface.h"
#import "LQJSBridge_LXTexture.h"
#import "LQJSBridge_LXTransform.h"
#import "LQJSBridge_LXShader.h"
#import "LQJSBridge_Color.h"



@implementation LQJSBridge_LXDrawContext

- (id)initWithLXDrawContext:(LXDrawContextRef)ctx
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _drawCtx = ctx;
        LXRefRetain(_drawCtx);
    }
    return self;
}

- (void)dealloc
{
    LXRefRelease(_drawCtx);
    _drawCtx = NULL;
 
    [_texArray release];
    _texArray = nil;
    
    [_mvTrsBridge setOwner:nil];
    [_mvTrsBridge release];
    _mvTrsBridge = nil;
          
    [_projTrsBridge setOwner:nil];
    [_projTrsBridge release];
    _projTrsBridge = nil;
          
    [_shaderBridge setOwner:nil];
    [_shaderBridge release];
    _shaderBridge = nil;
          
    [super dealloc];
}

- (LXDrawContextRef)lxDrawContext {
    return _drawCtx; }


+ (NSString *)constructorName
{
    return @"<LXSurfaceDrawingContext>"; // can't be constructed
}


#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"textureArray",
                                      @"projectionTransform", @"modelViewTransform",
                                      @"shader", 
                                      @"useFragmentAntialiasing",  
                                      @"renderStyle",
                                      nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return YES;
}

- (BOOL)useFragmentAntialiasing {
    return (LXDrawContextGetFlags(_drawCtx) & kLXDrawFlag_UseHardwareFragmentAntialiasing) ? YES : NO; }
    
- (void)setUseFragmentAntialiasing:(BOOL)f {
    LXUInteger flags = LXDrawContextGetFlags(_drawCtx);
    LXDrawContextSetFlags(_drawCtx, (f) ? (flags | kLXDrawFlag_UseHardwareFragmentAntialiasing)
                                        : (flags & ~kLXDrawFlag_UseHardwareFragmentAntialiasing));
}

- (NSString *)renderStyle {
    return (_renderStyle == kLQXSurfaceRenderStyle_OSC) ? @"onScreenControls" : @"default"; 
}

- (void)setRenderStyle:(NSString *)str {
    if ([str isEqualToString:@"onScreenControls"]) {
        [self setUseFragmentAntialiasing:YES];
        _renderStyle = kLQXSurfaceRenderStyle_OSC;
    } else
        _renderStyle = kLQXSurfaceRenderStyle_None;
}

- (LXUInteger)lqxRenderStyle {
    return _renderStyle; }


- (NSArray *)textureArray {
    return (_texArray) ? _texArray : [NSArray array];
}

- (void)setTextureArray:(NSArray *)texArray
{
    if ( ![texArray isKindOfClass:[NSArray class]]) {
        return;
    }

    LXTextureRef lxTextures[8];
    memset(lxTextures, 0, sizeof(LXTextureRef)*8);
    
    NSMutableArray *confirmedTexArr = [NSMutableArray arrayWithCapacity:8];
    int texCount = 0;
    
    NSEnumerator *texEnum = [texArray objectEnumerator];
    id tex;
    while ((tex = [texEnum nextObject]) && texCount < 8) {
        if ([tex respondsToSelector:@selector(lxTexture)]) {
            lxTextures[texCount] = [tex lxTexture];
            
            texCount++;
            [confirmedTexArr addObject:tex];
        }
    }
    
    ///NSLog(@"%s: texcount is %i", __func__, texCount);
    
    LXTextureArrayRef lxTexArray = LXTextureArrayCreateWithTexturesAndCount(lxTextures, texCount);
    
    LXDrawContextSetTextureArray(_drawCtx, lxTexArray);
    
    LXRefRelease(lxTexArray);
    
    [_texArray release];
    _texArray = [confirmedTexArr retain];
}

- (LQJSBridge_LXTransform *)projectionTransform
{
    if ( !_projTrsBridge) {
        // create a projection to match the surface's default setup
        LXSurfaceRef surface = ([_owner respondsToSelector:@selector(lxSurface)]) ? [_owner lxSurface] : NULL;
        const LXBool isFlipped = LXSurfaceNativeYAxisIsFlipped(surface);
        const LXInteger w = (surface) ? LXSurfaceGetWidth(surface) : 640;
        const LXInteger h = (surface) ? LXSurfaceGetHeight(surface) : 480;
            
        LXTransform3DRef trs = LXTransform3DCreateIdentity();
        LXTransform3DConcatExactPixelsTransformForSurfaceSize(trs, w, h, isFlipped);
        
        _projTrsBridge = [[LQJSBridge_LXTransform alloc] initWithLXTransform3D:trs inJSContext:[self jsContextRef] withOwner:self];
        LXTransform3DRelease(trs);
    }
    return _projTrsBridge; 
}

- (void)setProjectionTransform:(id)trs
{
    if ([trs respondsToSelector:@selector(lxTransform3D)]) {
        LXTransform3DRef lxTrs = [trs lxTransform3D];
        
        LXDrawContextSetProjectionTransform(_drawCtx, lxTrs);
        
        [_projTrsBridge release];
        _projTrsBridge = [[LQJSBridge_LXTransform alloc] initWithLXTransform3D:lxTrs inJSContext:[self jsContextRef] withOwner:self];
    }
}


- (LQJSBridge_LXTransform *)modelViewTransform
{
    if ( !_mvTrsBridge) {
        LXTransform3DRef trs = LXTransform3DCreateIdentity();
        
        _mvTrsBridge = [[LQJSBridge_LXTransform alloc] initWithLXTransform3D:trs inJSContext:[self jsContextRef] withOwner:self];
        LXTransform3DRelease(trs);
    }
    return _mvTrsBridge;
}

- (void)setModelViewTransform:(id)trs
{
    if ([trs respondsToSelector:@selector(lxTransform3D)]) {
        LXTransform3DRef lxTrs = [trs lxTransform3D];
        
        LXDrawContextSetModelViewTransform(_drawCtx, lxTrs);
        
        [_mvTrsBridge release];
        _mvTrsBridge = [[LQJSBridge_LXTransform alloc] initWithLXTransform3D:lxTrs inJSContext:[self jsContextRef] withOwner:self];
    }
    /*
    if ([trs isKindOfClass:[LQJSBridge_LXTransform class]]) {
        [_mvTrsBridge autorelease];
        _mvTrsBridge = [(LQJSBridge_LXTransform *)trs retain];
        
        if ( ![_mvTrsBridge owner]) {
            [_mvTrsBridge setOwner:self];
        }
        
        LXTransform3DRef lxTrs = [_mvTrsBridge lxTransform3D];
        
        LXDrawContextSetModelViewTransform(_drawCtx, lxTrs);
    }
    */
}

- (LQJSBridge_LXShader *)shader {
    return _shaderBridge; }
    
- (void)setShader:(id)shader {
    if ([shader isKindOfClass:[LQJSBridge_LXShader class]]) {
        [_shaderBridge autorelease];
        _shaderBridge = [(LQJSBridge_LXShader *)shader retain];
        
        if ( ![_shaderBridge owner]) {
            [_shaderBridge setOwner:self];
        }
        
        LXDrawContextSetShader(_drawCtx, [_shaderBridge lxShader]);
    }
}



#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"setShaderParam",
                nil]; 
}

// example:  drawCtx.setShaderParam(0, [ 1.0, 0.5, 0.2, 1.0 ]);

- (id)lqjsCallSetShaderParam:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    
    LXInteger index = lround([[args objectAtIndex:0] doubleValue]);
    
    if (index < 0 || index > 64) return nil;
    
    id value = [args objectAtIndex:1];
    LXRGBA rgba = LXBlackOpaqueRGBA;
    BOOL gotValue = NO;
    
    if ([value isKindOfClass:[NSArray class]]) {
        LXInteger count = MIN(4, [value count]);
        LXInteger i;
        for (i = 0; i < count; i++) {
            id val = [value objectAtIndex:i];
            ((LXFloat *)(&rgba))[i] = ([val respondsToSelector:@selector(doubleValue)]) ? [val doubleValue] : 0.0;
        }
        gotValue = YES;
    }
    else if ([value respondsToSelector:@selector(rgba_sRGB)]) {
        rgba = [value rgba_sRGB];
        gotValue = YES;
    }
    else if ([value respondsToSelector:@selector(doubleValue)]) {
        rgba.r = rgba.g = rgba.b = [value doubleValue];
        rgba.a = 1.0;
        gotValue = YES;
    }
    
    if (gotValue) {
        LXDrawContextSetShaderParameter(_drawCtx, index, rgba);
    }
    
    return nil;
}

// replaced with shader property
/*
+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"setShaderFromARBFragmentProgram",
                nil]; 
}

- (id)lqjsCallSetShaderFromARBFragmentProgram:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    NSString *progStr = [[args objectAtIndex:0] description];
    
    const char *ss = [progStr UTF8String];
    LXDECLERROR(err);
    LXShaderRef newShader = LXShaderCreateWithString(ss, (ss) ? strlen(ss) : 0, kLXShaderFormat_OpenGLARBfp, 0, &err);
    
    if ( !newShader) {
        NSLog(@"** failed to set shader from JS call: error %i (%s)", err.errorID, err.description);
    } else {
        LXDrawContextSetShader(_drawCtx, newShader);
        
        LXShaderRelease(newShader);
    }
    
    return nil;
}
*/

@end
