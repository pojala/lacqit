//
//  LQJSBridge_LXSurface.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXSurface.h"
#import "LQJSBridge_LXDrawContext.h"
#import "LQJSBridge_LXTexture.h"
#import "LQJSBridge_LXTransform.h"
#import "LQJSBridge_Color.h"
#import "LQJSBridge_CurveList.h"


NSString *kLQJSLXPrimitiveType_TriangleFan = @"triangle-fan";
NSString *kLQJSLXPrimitiveType_TriangleStrip = @"triangle-strip";
NSString *kLQJSLXPrimitiveType_Quads = @"quads";
NSString *kLQJSLXPrimitiveType_Points = @"points";
NSString *kLQJSLXPrimitiveType_LineStrip = @"line-strip";
NSString *kLQJSLXPrimitiveType_LineLoop = @"line-loop";


@implementation LQJSBridge_LXSurface


- (void)_setSurface:(LXSurfaceRef)surf
{
    _surface = LXSurfaceRetain(surf);
    
    LXDrawContextRef drawCtx = LXDrawContextCreate();
    
    if ( !_jsContext) {
        NSLog(@"*** %s -- no js context (%@)", __func__, self);
    }
    
    _drawCtxBridge = [[LQJSBridge_LXDrawContext alloc] initWithLXDrawContext:drawCtx
                                                                 inJSContext:_jsContext withOwner:self];
    
    LXRefRelease(drawCtx);  // was retained by the bridge object
}

- (id)initWithLXSurface:(LXSurfaceRef)surf
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        [self _setSurface:surf];
    }
    return self;
}

+ (void)_releaseDeferredSurface:(NSValue *)value
{
    LXSurfaceRef surf = (LXSurfaceRef)[value pointerValue];
    LXSurfaceRelease(surf);
}

- (void)dealloc
{
    ///if (_wasJSConstructed) NSLog(@"%s, %p, surface %p", __func__, self, _surface);
    
    [_drawCtxBridge setOwner:nil];
    [_drawCtxBridge release];
    _drawCtxBridge = nil;
    
    ///NSLog(@"%s: texturebridge is %p -- retcount %i", __func__, _textureBridge, [_textureBridge retainCount]);

    [_textureBridge setOwner:nil];    
    [_textureBridge release];
    _textureBridge = nil;

    ///NSLog(@"%s: 2", __func__);

    /*if ( !LXPlatformCurrentThreadIsMain()) {
        [[self class] performSelectorOnMainThread:@selector(_releaseDeferredSurface:) withObject:[NSValue valueWithPointer:_surface] waitUntilDone:NO];
    } else {
        LXSurfaceRelease(_surface);
    }*/
    LXSurfaceRelease(_surface);
    _surface = NULL;

    [super dealloc];
    ///NSLog(@"%s: end", __func__);
}
/*
- (id)retain
{
    ///NSLog(@"%s / %p: retc %i", __func__, self, [self retainCount]);
    return [super retain];
}

- (void)release
{
    ///NSLog(@"%s / %p: retc %i", __func__, self, [self retainCount]);
    [super release];
}
*/
- (void)_recreateTextureBridge
{
    [_textureBridge release];
    
    _textureBridge = [[LQJSBridge_LXTexture alloc] initWithLXTexture:LXSurfaceGetTexture(_surface)
                                                           inJSContext:[self jsContextRef] withOwner:self];
}

+ (NSString *)constructorName
{
    ///return @"<LXSurface>"; // can't be constructed
    return @"Surface";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    LXDECLERROR(err);
    long w = 640, h = 480;
    
    if ([arguments count] >= 2) {
        if ( ![self parseLongFromArg:[arguments objectAtIndex:0] outValue:&w])
            return;
        
        if ( ![self parseLongFromArg:[arguments objectAtIndex:1] outValue:&h])
            return;
            
        if (w < 1 || h < 1) return;
    }
    else {
        /*if ([[self owner] respondsToSelector:@selector(preferredRenderSize)]) {
            LXSize size = [[self owner] preferredRenderSize];
            w = size.w;
            h = size.h;
        }*/
    }
    
    w = MIN(4000, w);
    h = MIN(4000, h);
    
    LXSurfaceRef newSurf = LXSurfaceCreate(NULL, w, h, kLX_RGBA_FLOAT16, 0, &err);
    if ( !newSurf) {
        NSLog(@"** JS constructor %@(): surface creation failed: %i / %s", [[self class] constructorName], err.errorID, err.description);
        LXErrorDestroyOnStack(err);
    } else {
        _wasJSConstructed = YES;
        [self _setSurface:newSurf];
        LXSurfaceRelease(newSurf);
        ///NSLog(@"Surface created by JS, self %p, lxsurf %p", self, newSurf);
    }
}




#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"width", @"height", @"drawingContext", @"texture", @"baseYAxisIsFlipped", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return NO;
}

- (LXInteger)width {
    return LXSurfaceGetWidth(_surface); }

- (LXInteger)height {
    return LXSurfaceGetHeight(_surface); }

- (BOOL)baseYAxisIsFlipped {
    return LXSurfaceNativeYAxisIsFlipped(_surface); }


- (id)drawingContext {
    if ( !_drawCtxBridge) NSLog(@"*** %s (%p): no drawctx bridge", __func__, self);
    return _drawCtxBridge; }
    
- (id)texture {
    if ( !_textureBridge)
        [self _recreateTextureBridge];
        
    return _textureBridge;
}

- (LXSurfaceRef)lxSurface {
    return _surface; }
    

#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"clear",
                                     @"drawWithinBounds",
                                     @"drawUnitQuad",
                                     @"draw2DCurveList",
                                     @"draw2DVertices",
                                     @"draw3DVertices",
                                     @"compositeUnitQuad",
                                     @"composite2DVertices",
                                     @"getOriginalProjectionTransform",
                                     nil]; 
}

- (id)lqjsCallGetOriginalProjectionTransform:(NSArray *)args context:(id)contextObj
{
    LXSurfaceRef surface = _surface;
    const LXBool isFlipped = LXSurfaceNativeYAxisIsFlipped(surface);
    const LXInteger w = LXSurfaceGetWidth(surface);
    const LXInteger h = LXSurfaceGetHeight(surface);
            
    LXTransform3DRef trs = LXTransform3DCreateIdentity();
    LXTransform3DConcatExactPixelsTransformForSurfaceSize(trs, w, h, isFlipped);
        
    id trsBridge = [[LQJSBridge_LXTransform alloc] initWithLXTransform3D:trs inJSContext:[self jsContextRef] withOwner:nil];
    LXTransform3DRelease(trs);
    
    return [trsBridge autorelease];
}

// three ways to call clear():
//    surface.clear()
//    surface.clear(color)
//    surface.clear(color, x, y, w, h)

- (id)lqjsCallClear:(NSArray *)args context:(id)contextObj
{
    int argCount = [args count];
    BOOL didClear = NO;
    
    if (argCount >= 5) {
        id col = [args objectAtIndex:0];
        double x = [[args objectAtIndex:1] doubleValue];
        double y = [[args objectAtIndex:2] doubleValue];
        double w = [[args objectAtIndex:3] doubleValue];
        double h = [[args objectAtIndex:4] doubleValue];
        
        if ( !isfinite(x)) x = 0.0;
        if ( !isfinite(y)) y = 0.0;
        if ( !isfinite(w)) w = 0.0;
        if ( !isfinite(h)) h = 0.0;
        
        if (w <= 0.0 || h <= 0.0)
            return nil;
        
        LXRGBA rgba = LXBlackOpaqueRGBA;
        if ([col respondsToSelector:@selector(rgba_sRGB)]) {
            rgba = [(LQJSBridge_Color *)col rgba_sRGB];
        }
        
        LXSurfaceClearRegionWithRGBA(_surface, LXMakeRect(x, y, w, h), rgba);
        didClear = YES;
    }
    
    if ( !didClear && argCount == 1) {
        id col = [args objectAtIndex:0];
        
        if ([col respondsToSelector:@selector(rgba_sRGB)]) {
            LXSurfaceClearRegionWithRGBA(_surface, LXSurfaceGetBounds(_surface), [(LQJSBridge_Color *)col rgba_sRGB]);
            didClear = YES;
        }
    }
    
    if ( !didClear) {
        LXSurfaceClear(_surface);
    }
    return nil;
}


static LXInteger primitiveTypeFromString(NSString *jsPrimitiveType)
{
    LXInteger primitiveType = -1;
    
    if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_TriangleFan]) {
        primitiveType = kLXTriangleFan;
    } else if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_TriangleStrip]) {
        primitiveType = kLXTriangleStrip;
    } else if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_Quads]) {
        primitiveType = kLXQuads;
    } else if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_Points]) {
        primitiveType = kLXPoints;
    } else if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_LineStrip]) {
        primitiveType = kLXLineStrip;
    } else if ([jsPrimitiveType isEqualToString:kLQJSLXPrimitiveType_LineLoop]) {
        primitiveType = kLXLineLoop;
    }
    return primitiveType;
}

- (void)_drawPrimitivesUsingRenderStyle:(LXUInteger)primitiveType
                vertices:(void *)vertices count:(LXUInteger)vertexCount type:(LXUInteger)vertexType
{
    LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];
    LXUInteger renderStyle = [_drawCtxBridge lqxRenderStyle];

    if (renderStyle == kLQXSurfaceRenderStyle_OSC) {
        // for OSC style, first draw a shadow offset by (1, 1), then the actual curve
        LXTransform3DRef origTrs = LXTransform3DRetain(LXDrawContextGetModelViewTransform(drawCtx));
        LXTransform3DRef tempTrs = LXTransform3DCopy(origTrs);
        
        LXTransform3DTranslate(tempTrs, 1, 1, 0);
        LXDrawContextSetModelViewTransform(drawCtx, tempTrs);
        
        LXRGBA origColor = LXDrawContextGetShaderParameter(drawCtx, 0);
        LXRGBA tempColor = LXMakeRGBA(0, 0, 0, 0.3);
        LXDrawContextSetShaderParameter(drawCtx, 0, tempColor);
        
        LXSurfaceDrawPrimitive(_surface, primitiveType,
                                vertices, vertexCount, vertexType,
                                drawCtx);

        LXDrawContextSetModelViewTransform(drawCtx, origTrs);
        LXDrawContextSetShaderParameter(drawCtx, 0, origColor);
        
        LXSurfaceDrawPrimitive(_surface, primitiveType,
                                vertices, vertexCount, vertexType,
                                drawCtx);
    
        LXTransform3DRelease(tempTrs);
        LXTransform3DRelease(origTrs);
    }
    else {
        LXSurfaceDrawPrimitive(_surface, primitiveType,
                                vertices, vertexCount, vertexType,
                                drawCtx);
    }
}

// surface.draw2DCurveList("line-loop", clist);

- (id)lqjsCallDraw2DCurveList:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    
    LXInteger primitiveType = primitiveTypeFromString([[args objectAtIndex:0] description]);    
    if (primitiveType == -1) {
        NSLog(@"** invalid primitive type passed to JS call draw2DCurveList (%@)", [[args objectAtIndex:0] description]);
        return nil;
    }
    
    id jsClist = [args objectAtIndex:1];
    if ( ![jsClist respondsToSelector:@selector(curveList)]) {
        NSLog(@"** invalid curve list object passed to JS call (%@)", [jsClist class]);
        return nil;
    }
    
    LQCurveList *clist = [jsClist curveList];
    LXInteger segCount = [clist numberOfSegments];
    
    if (segCount > 4096) {
        NSLog(@"** %s: sanity limit exceeded (%ld)", __func__, segCount);
        return nil;
    }
    if (segCount < 1)
        return nil;
            
    LXInteger vertArrayCount = 2 + segCount * 16;
    LXVertexXYZW *clistVertices = _lx_malloc(vertArrayCount * sizeof(LXVertexXYZW));
    LXInteger clistVCount = 0;
    [clist getXYZWVertices:clistVertices arraySize:vertArrayCount maxSamplesPerSegment:16 outVertexCount:&clistVCount];
    
    if (clistVCount < 1) {
        NSLog(@"** %s: failed to get vertices", __func__);
    } else {
        [self _drawPrimitivesUsingRenderStyle:primitiveType
                vertices:clistVertices count:clistVCount type:kLXVertex_XYZW];
    }
    
    _lx_free(clistVertices);
    return nil;
}

- (id)lqjsCallDrawWithinBounds:(NSArray *)args context:(id)contextObj
{
    LXVertexXYUV vertices[4];
    LXSurfaceGetQuadVerticesXYUV(_surface, vertices);

    //LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];    
    //LXSurfaceDrawPrimitive(_surface, kLXQuads, vertices, 4, kLXVertex_XYUV, drawCtx);

    [self _drawPrimitivesUsingRenderStyle:kLXQuads
                vertices:vertices count:4 type:kLXVertex_XYUV];
    
    return nil;
}

- (id)lqjsCallDrawUnitQuad:(NSArray *)args context:(id)contextObj
{
    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, LXUnitRect, LXUnitRect);

    //LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];
    //LXSurfaceDrawPrimitive(_surface, kLXQuads, vertices, 4, kLXVertex_XYUV, drawCtx);
    
    [self _drawPrimitivesUsingRenderStyle:kLXQuads
                vertices:vertices count:4 type:kLXVertex_XYUV];
    
    return nil;
}

- (id)lqjsCallCompositeUnitQuad:(NSArray *)args context:(id)contextObj
{
    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, LXUnitRect, LXUnitRect);

    LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];

    LXUInteger prevFlags = LXDrawContextGetFlags(drawCtx);
    LXDrawContextSetFlags(drawCtx, prevFlags | kLXDrawFlag_UseFixedFunctionBlending_SourceIsPremult);
    
    LXSurfaceDrawPrimitive(_surface, kLXQuads, vertices, 4, kLXVertex_XYUV, drawCtx);
    
    LXDrawContextSetFlags(drawCtx, prevFlags);
    return nil;
}

// calling draw3DVertices() could look like this:
//
//     surface.draw3DVertices("triangle-fan", [ { "x": 0.3, "y": 0.3, "u": 0.0, "v": 0.0 },
//                                              { "x": 0.3, "y": 0.5, "u": 1.0, "v": 0.0 },
//                                              { "x": 0.6, "y": 0.5, "u": 1.0, "v": 1.0 },
//                                              { "x": 0.6, "y": 0.3, "u": 0.0, "v": 1.0 }
//                                            ] );

- (void)_drawXYUVWithArgs:(NSArray *)args drawFlags:(LXUInteger)drawFlags
{
    if ([args count] < 2) return;
    
    LXUInteger primitiveType = primitiveTypeFromString([[args objectAtIndex:0] description]);    
    if (primitiveType == -1) {
        NSLog(@"** invalid primitive type passed to JS call drawVertices (%@)", [[args objectAtIndex:0] description]);
        return;
    }
    
    NSArray *jsVertices = [args objectAtIndex:1];
    if ( ![jsVertices respondsToSelector:@selector(count)]) {
        NSLog(@"** invalid object passed to JS call drawVertices (%@)", [jsVertices class]);
        return;
    }
    
    LXInteger vertexCount = [jsVertices count];
    if (vertexCount < 2) {
        NSLog(@"too few vertices from JS call (%ld)", vertexCount);
        return;
    }
    if (vertexCount > 30000) {
        NSLog(@"** %s: sanity limit exceeded (%ld vertices)", __func__, vertexCount);
        return;
    }
    
    LXVertexXYUV vertices[vertexCount];
    
    LXInteger i;
    for (i = 0; i < vertexCount; i++) {
        id jsv = [jsVertices objectAtIndex:i];
        id xv = [jsv valueForKey:@"x"];
        id yv = [jsv valueForKey:@"y"];
        id uv = [jsv valueForKey:@"u"];
        id vv = [jsv valueForKey:@"v"];
        
        ///NSLog(@"vertex %i: object is %@ (class %@);\n   x: %@,  u: %@", i, jsv, [jsv class],  [jsv valueForKey:@"x"], [jsv valueForKey:@"u"]);
        
        double x = (xv) ? [xv doubleValue] : 0.0;
        double y = (yv) ? [yv doubleValue] : 0.0;
        double u = (uv) ? [uv doubleValue] : 0.0;
        double v = (vv) ? [vv doubleValue] : 0.0;
        
        if ( !isfinite(x)) x = 0.0;
        if ( !isfinite(y)) y = 0.0;
        if ( !isfinite(u)) u = 0.0;
        if ( !isfinite(v)) v = 0.0;
        
        LXSetVertex4((LXVertexXYZW *)(vertices + i),   x, y, u, v);
    }
    
    LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];
    
    LXUInteger prevFlags;
    if (drawFlags != 0) {
        prevFlags = LXDrawContextGetFlags(drawCtx);
        LXDrawContextSetFlags(drawCtx, prevFlags | drawFlags);
    }
    
    /*LXSurfaceDrawPrimitive(_surface,
                            primitiveType,
                            vertices,
                            vertexCount,
                            kLXVertex_XYUV,
                            drawCtx);
    */
    [self _drawPrimitivesUsingRenderStyle:primitiveType
                vertices:vertices count:vertexCount type:kLXVertex_XYUV];
                            
    if (drawFlags != 0) {
        LXDrawContextSetFlags(drawCtx, prevFlags);
    }
}

- (id)lqjsCallDraw2DVertices:(NSArray *)args context:(id)contextObj
{
    [self _drawXYUVWithArgs:args drawFlags:0];
    return nil;
}

- (id)lqjsCallComposite2DVertices:(NSArray *)args context:(id)contextObj
{
    [self _drawXYUVWithArgs:args drawFlags:kLXDrawFlag_UseFixedFunctionBlending_SourceIsPremult];
    return nil;
}


- (void)_drawXYZWUVWithArgs:(NSArray *)args drawFlags:(LXUInteger)drawFlags
{
    if ([args count] < 2) return;
    
    LXUInteger primitiveType = primitiveTypeFromString([[args objectAtIndex:0] description]);    
    if (primitiveType == -1) {
        NSLog(@"** invalid primitive type passed to JS call drawVertices (%@)", [[args objectAtIndex:0] description]);
        return;
    }
    
    NSArray *jsVertices = [args objectAtIndex:1];
    if ( ![jsVertices respondsToSelector:@selector(count)]) {
        NSLog(@"** invalid object passed to JS call drawVertices (%@)", [jsVertices class]);
        return;
    }
    
    LXInteger vertexCount = [jsVertices count];
    if (vertexCount < 2) {
        NSLog(@"too few vertices from JS call (%ld)", vertexCount);
        return;
    }
    if (vertexCount > 30000) {
        NSLog(@"** %s: sanity limit exceeded (%ld vertices)", __func__, vertexCount);
        return;
    }
    
    LXFloat *vertices = _lx_malloc(vertexCount * 6 * sizeof(LXFloat));
    
    LXInteger i;
    for (i = 0; i < vertexCount; i++) {
        id jsv = [jsVertices objectAtIndex:i];
        id xv = [jsv valueForKey:@"x"];
        id yv = [jsv valueForKey:@"y"];
        id zv = [jsv valueForKey:@"z"];
        id wv = [jsv valueForKey:@"w"];
        id uv = [jsv valueForKey:@"u"];
        id vv = [jsv valueForKey:@"v"];
        
        ///NSLog(@"vertex %i: object is %@ (class %@);\n   x: %@,  u: %@", i, jsv, [jsv class],  [jsv valueForKey:@"x"], [jsv valueForKey:@"u"]);
        
        double x = (xv) ? [xv doubleValue] : 0.0;
        double y = (yv) ? [yv doubleValue] : 0.0;
        double z = (zv) ? [zv doubleValue] : 0.0;
        double w = (wv) ? [wv doubleValue] : 0.0;
        double u = (uv) ? [uv doubleValue] : 0.0;
        double v = (vv) ? [vv doubleValue] : 0.0;
        
        if ( !isfinite(x)) x = 0.0;
        if ( !isfinite(y)) y = 0.0;
        if ( !isfinite(z)) z = 0.0;
        if ( !isfinite(w)) w = 0.0;
        if ( !isfinite(u)) u = 0.0;
        if ( !isfinite(v)) v = 0.0;
        
        LXFloat *vert = vertices + i*6;
        vert[0] = x;
        vert[1] = y;
        vert[2] = z;
        vert[3] = w;
        vert[4] = u;
        vert[5] = v;
    }
    
    LXDrawContextRef drawCtx = [_drawCtxBridge lxDrawContext];
    
    LXUInteger prevFlags;
    if (drawFlags != 0) {
        prevFlags = LXDrawContextGetFlags(drawCtx);
        LXDrawContextSetFlags(drawCtx, prevFlags | drawFlags);
    }
    
    [self _drawPrimitivesUsingRenderStyle:primitiveType
                vertices:vertices count:vertexCount type:kLXVertex_XYZWUV];
                            
    if (drawFlags != 0) {
        LXDrawContextSetFlags(drawCtx, prevFlags);
    }
    
    _lx_free(vertices);
}

- (id)lqjsCallDraw3DVertices:(NSArray *)args context:(id)contextObj
{
    [self _drawXYZWUVWithArgs:args drawFlags:0];
    return nil;
}


@end
