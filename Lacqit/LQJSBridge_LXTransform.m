//
//  LQJSBridge_LXTransform.m
//  Lacqit
//
//  Created by Pauli Ojala on 10.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXTransform.h"


@implementation LQJSBridge_LXTransform

- (id)initInJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [super initInJSContext:context withOwner:owner];
    if (self) {
        _trs = LXTransform3DCreateIdentity();
    }
    return self;
}

- (id)initWithLXTransform3D:(LXTransform3DRef)lxTrs
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        if (lxTrs) {
            LXTransform3DRelease(_trs);
            _trs = LXTransform3DCopy(lxTrs);
        }
    }
    return self;
}            

- (void)dealloc
{
    LXTransform3DRelease(_trs);
    _trs = NULL;
    
    [super dealloc];
}

- (LXTransform3DRef)lxTransform3D {
    return _trs; }

- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj = [[[self class] alloc] initWithLXTransform3D:_trs
                                            inJSContext:dstContext
                                            withOwner:nil];                                                
    return [newObj autorelease];
}

+ (NSString *)constructorName
{
    return @"Transform3D";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] >= 1) {
        id arg = [arguments objectAtIndex:0];
        
        if ([arg respondsToSelector:@selector(lxTransform3D)]) {
            LXTransform3DRelease(_trs);
            _trs = LXTransform3DCopy([arg lxTransform3D]);
        }
    }
}




#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects:@"matrixArray", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return YES;
}

- (NSArray *)matrixArray
{
    LXInteger i;
    LX4x4Matrix mat;
    memset(&mat, 0, sizeof(LX4x4Matrix));
    
    LXTransform3DGetMatrix(_trs, &mat);
    /*
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:16];
    for (i = 0; i < 16; i++) {
        LXFloat f = ((LXFloat *)(&mat))[i];
        
        [arr addObject:[NSNumber numberWithDouble:f]];
    }
    return arr;
    */
    ///double t0 = LQReferenceTimeGetCurrent();
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    id jsArr = [interp emptyProtectedJSArray];
    [jsArr setProtected:NO];
    
    for (i = 0; i < 16; i++) {
        LXFloat f = ((LXFloat *)(&mat))[i];
        [jsArr addObject:[NSNumber numberWithDouble:f]];
    }
    ///double t1 = LQReferenceTimeGetCurrent();
    ///NSLog(@"...matrix array created in %.3f ms", 1000*(t1-t0));
    
    return jsArr;
}

- (BOOL)_getMatrix:(LX4x4Matrix *)mat fromInputArray:(id)arr
{
    if ([arr respondsToSelector:@selector(propertyForKey:)]) {
        id func = [arr propertyForKey:@"getValues"];
        if (func && [func respondsToSelector:@selector(isFunction)] && [func isFunction]) {
            NSError *error = nil;
            id result = [func callWithThis:arr parameters:nil error:&error];
            if (error) {
                NSLog(@"*** %s: Map.getValues() failed, error: %@", __func__, error);
                return NO;
            } else {
                ///NSLog(@"got result: %@", [result class]);
                arr = result;
            }
        }
    }
    if ( ![arr isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    LXInteger count = MIN(16, [arr count]);
    LXInteger i;
    for (i = 0; i < count; i++) {
        id obj = [arr objectAtIndex:i];
        if ([obj respondsToSelector:@selector(doubleValue)]) {
            LXFloat f = [obj doubleValue];
        
            ((LXFloat *)mat)[i] = f;
            ///NSLog(@".... %02i: %.3f", i, f);
        } else {
            NSLog(@"** matrixArray: object at index %ld is invalid: %@", i, [obj class]);
        }
    }
    return YES;
}

- (void)setMatrixArray:(id)arr
{
    LX4x4Matrix mat = *LXIdentity4x4Matrix;
    
    if ( ![self _getMatrix:&mat fromInputArray:arr]) {
        NSLog(@"** property matrixArray: can't set object of type '%@'", [arr class]);
    } else {
        LXTransform3DSetMatrix(_trs, &mat);
    }
}


#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"translate",
                                     @"scale",
                                     @"rotate",
                                     
                                     @"transpose",
                                     @"invert",
                                     
                                     @"perspective",
                                     @"lookAt",
                                     @"oneToOnePixels",
                                     
                                     @"concat",
                                     
                                     @"copy",
                                     nil]; 
}

- (id)lqjsCallCopy:(NSArray *)args context:(id)contextObj
{
    // the init method will copy the transform
    ///JSContextRef jsCtx = [self jsContextRefFromJSCallContextObj:contextObj];
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    
    id newObj = [[[self class] alloc] initWithLXTransform3D:_trs inJSContext:[interp jsContextRef] withOwner:nil];
    return [newObj autorelease];
}

- (BOOL)_getVectorFromArgs:(NSArray *)args offset:(int)offset outX:(double *)x outY:(double *)y outZ:(double *)z
{
    LXInteger argCount = [args count];
    if (argCount >= 1+offset) {
        *x = [[args objectAtIndex:0+offset] doubleValue];
    }
    if (argCount >= 2+offset) {
        *y = [[args objectAtIndex:1+offset] doubleValue];
    }
    if (argCount >= 3+offset) {
        *z = [[args objectAtIndex:2+offset] doubleValue];
    }
    if ( !isfinite(*x) || !isfinite(*y) || !isfinite(*z)) return NO;
    else return YES;
}

- (id)lqjsCallTranslate:(NSArray *)args context:(id)contextObj
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    if ( ![self _getVectorFromArgs:args offset:0 outX:&x outY:&y outZ:&z]) return nil;
    
    LXTransform3DTranslate(_trs, x, y, z);
    return self;
}

- (id)lqjsCallScale:(NSArray *)args context:(id)contextObj
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    if ( ![self _getVectorFromArgs:args offset:0 outX:&x outY:&y outZ:&z]) return nil;
    
    LXTransform3DScale(_trs, x, y, z);
    return self;
}

- (id)lqjsCallRotate:(NSArray *)args context:(id)contextObj
{
    double x = 0.0;
    double y = 0.0;
    double z = 0.0;
    if ( ![self _getVectorFromArgs:args offset:1 outX:&x outY:&y outZ:&z]) return nil;
    
    double angleInRadians = 0.0;
    if ([args count] >= 1) {
        angleInRadians = [[args objectAtIndex:0] doubleValue];
    }
    if ( !isfinite(angleInRadians)) return nil;
    
    if (angleInRadians != 0.0) {
        LXTransform3DRotate(_trs, angleInRadians, x, y, z);
    }
    return self;
}

- (id)lqjsCallTranspose:(NSArray *)args context:(id)contextObj
{
    LX4x4Matrix mat;
    
    LXTransform3DGetMatrix(_trs, &mat);
    LX4x4MatrixTranspose(&mat, &mat);
    
    LXTransform3DSetMatrix(_trs, &mat);
    return self;
}

- (id)lqjsCallInvert:(NSArray *)args context:(id)contextObj
{
    BOOL ok = LXTransform3DInvert(_trs);

    return [NSNumber numberWithBool:ok];
}

- (id)lqjsCallPerspective:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 4) return nil;
    double fovY =  [[args objectAtIndex:0] doubleValue];
    double asp =   [[args objectAtIndex:1] doubleValue];
    double zNear = [[args objectAtIndex:2] doubleValue];
    double zFar =  [[args objectAtIndex:3] doubleValue];
    
    LXTransform3DConcatPerspective(_trs, fovY, asp, zNear, zFar);
    return self;
}

- (id)lqjsCallLookAt:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 9) return nil;
    double eyeX = [[args objectAtIndex:0] doubleValue];
    double eyeY = [[args objectAtIndex:1] doubleValue];
    double eyeZ = [[args objectAtIndex:2] doubleValue];
    double centerX = [[args objectAtIndex:3] doubleValue];
    double centerY = [[args objectAtIndex:4] doubleValue];
    double centerZ = [[args objectAtIndex:5] doubleValue];
    double upX = [[args objectAtIndex:6] doubleValue];
    double upY = [[args objectAtIndex:7] doubleValue];
    double upZ = [[args objectAtIndex:8] doubleValue];

    LXTransform3DConcatLookAt(_trs,  eyeX, eyeY, eyeZ,  centerX, centerY, centerZ,  upX, upY, upZ);
    return self;
}

- (id)lqjsCallOneToOnePixels:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    double w =  [[args objectAtIndex:0] doubleValue];
    double h =  [[args objectAtIndex:1] doubleValue];
    BOOL flip = NO;
    if ([args count] >= 3 && [[args objectAtIndex:2] respondsToSelector:@selector(boolValue)])
        flip = [[args objectAtIndex:2] boolValue];
    
    LXTransform3DConcatExactPixelsTransformForSurfaceSize(_trs, w, h, flip);
    return self;
}

- (id)lqjsCallConcat:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    id obj = [args objectAtIndex:0];
    
    LXTransform3DRef trs = NULL;
    
    if ([obj respondsToSelector:@selector(lxTransform3D)]) {
        trs = LXTransform3DRetain([obj lxTransform3D]);
    }
    else {
        LX4x4Matrix mat = *LXIdentity4x4Matrix;
    
        if ( ![self _getMatrix:&mat fromInputArray:obj]) {
            NSLog(@"** concat(): can't set object of type '%@'", [obj class]);
            return nil;
        }
        
        trs = LXTransform3DCreateWithMatrix(&mat);
    }

    LXTransform3DConcat(_trs, trs);
    
    LXTransform3DRelease(trs);
    return self;
}

@end
