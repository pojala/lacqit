//
//  LQJSBridge_LXAccumulator.m
//  Lacqit
//
//  Created by Pauli Ojala on 21.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXAccumulator.h"
#import "LQJSBridge_LXTexture.h"
#import "LQJSBridge_LXSurface.h"
#import "LQStreamPatch.h"


@implementation LQJSBridge_LXAccumulator

- (id)initWithLXAccumulator:(LXAccumulatorRef)acc
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _acc = LXAccumulatorRetain(acc);
    }
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@", __func__, self);
    LXAccumulatorRelease(_acc);
    [super dealloc];
}


- (LXAccumulatorRef)lxAccumulator {
    return _acc; }


+ (NSString *)constructorName {
    return @"TextureAccumulator";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    LXDECLERROR(err);
    LXSize accSize;
    
    if ([arguments count] >= 2) {
        long w = 0, h = 0;
        if ( ![self parseLongFromArg:[arguments objectAtIndex:0] outValue:&w])
            return;
        
        if ( ![self parseLongFromArg:[arguments objectAtIndex:1] outValue:&h])
            return;
            
        if (w < 1 || h < 1) return;
        
        accSize = LXMakeSize(w, h);
    }
    else {
        if ([[self owner] respondsToSelector:@selector(preferredRenderSize)]) {
            accSize = [[self owner] preferredRenderSize];
        } else {
            accSize = LXMakeSize(640, 360);
        }
    }
    
    LXAccumulatorRef newAcc = LXAccumulatorCreateWithSize(NULL, accSize, 0, &err);
    if ( !newAcc) {
        NSLog(@"** JS constructor %@(): lxAcc creation failed: %i / %s", [[self class] constructorName], err.errorID, err.description);
        LXErrorDestroyOnStack(err);
    } else {
        ///NSLog(@"JS accumulator constructed (%@)", self);
        _acc = newAcc;
    }
}



+ (NSArray *)objectPropertyNames {
    return [NSArray arrayWithObjects:@"width", @"height", @"numberOfSamples", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName {
    return ([propertyName isEqualToString:@"numberOfSamples"]) ? YES : NO;
}

- (LXInteger)width {
    return LXAccumulatorGetSize(_acc).w; }
    
- (LXInteger)height {
    return LXAccumulatorGetSize(_acc).h; }

- (LXInteger)numberOfSamples {
    return LXAccumulatorGetNumberOfSamples(_acc); }
    
- (void)setNumberOfSamples:(LXInteger)numSamples {
    LXAccumulatorSetNumberOfSamples(_acc, numSamples); }


+ (NSArray *)objectFunctionNames {
    return [NSArray arrayWithObjects:@"start", @"finishIntoSurface", @"addTexture", nil];
}

- (id)lqjsCallStart:(NSArray *)args context:(id)contextObj
{
    if ( !_acc) return nil;

    LXDECLERROR(err)
    if ( !LXAccumulatorStartAccumulation(_acc, &err)) {
        NSLog(@"** JS accumulator start(): error %i / %s", err.errorID, err.description);
        LXErrorDestroyOnStack(err);
    }
    return self;
}

- (id)lqjsCallFinishIntoSurface:(NSArray *)args context:(id)contextObj
{
    if ( !_acc) return nil;
    if ([args count] < 1) return nil;
    
    LXSurfaceRef dstSurf = NULL;
    id surfObj = [args objectAtIndex:0];
    
    if ([surfObj respondsToSelector:@selector(lxSurface)]) {
        dstSurf = [surfObj lxSurface];
    }
    
    LXSurfaceRef resultSurf = LXAccumulatorFinishAccumulation(_acc);
    
    if (resultSurf && dstSurf) {
        LXTextureRef resTex = LXSurfaceGetTexture(resultSurf);
        LXInteger prevSampling = -1;
        if ( !LXSurfaceMatchesSize(resultSurf, LXTextureGetSize(resTex)) && LXTextureGetSampling(resTex) != kLXLinearSampling) {
            prevSampling = LXTextureGetSampling(resTex);
            LXTextureSetSampling(resTex, kLXLinearSampling);
        }
        
        LXSurfaceCopyTexture(dstSurf, resTex, NULL);
        
        if (prevSampling != -1) {
            LXTextureSetSampling(resTex, prevSampling);
        }
    }
    
    LXSurfaceRelease(resultSurf);
    return nil;
}

// accumulator.addTexture(texture[, optionalOpacity])
- (id)lqjsCallAddTexture:(NSArray *)args context:(id)contextObj
{
    if ( !_acc) return nil;

    if ([args count] < 1) return self;
    
    LXTextureRef tex = NULL;
    id texObj = [args objectAtIndex:0];
    
    if ([texObj respondsToSelector:@selector(lxSurface)]) {
        tex = LXSurfaceGetTexture([texObj lxSurface]);
    }
    else if ([texObj respondsToSelector:@selector(lxTexture)]) {
        tex = [texObj lxTexture];
    }
    else {
        NSLog(@"** JS accumulator addTexture(): object does't provide a texture (%@)", [texObj class]);
        return self;
    }
    
    ///NSLog(@"..addTexture(): tex is %p", tex);
    
    if ([args count] > 1) {
        double op = 1.0;
        if ([[args objectAtIndex:1] respondsToSelector:@selector(doubleValue)]) {
            op = [[args objectAtIndex:1] doubleValue];
        }
        
        LXAccumulatorAccumulateTextureWithOpacity(_acc, tex, op);
    }
    else {
        LXAccumulatorAccumulateTexture(_acc, tex);
    }
    
    return self;
}

@end

