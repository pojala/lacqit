//
//  LQJSBridge_Fcurve.m
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_Fcurve.h"


@implementation LQJSBridge_Fcurve

+ (Class)curveClass {
    return [LQFcurve class]; }


- (LQFcurve *)fcurve {
    return (LQFcurve *)_curveList;  }


+ (NSString *)constructorName
{
    return @"Fcurve";
}

// this is called from -awakeFromConstructor and -init
- (void)_setCurve:(id)clist
{
    if ( ![clist isKindOfClass:[LQFcurve class]]) {
        NSLog(@"*** %s: can't set non-fcurve", __func__);
    } else {
        [_curveList autorelease];
        _curveList = [clist copy];
    }
}

#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"length", @"duration", @"minValue", @"maxValue", @"name", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return NO;
}

- (double)duration
{
    return [[self fcurve] duration];
}

- (double)minValue
{
    double v = 0.0;
    [[self fcurve] getMinValue:&v maxValue:NULL];
    return v;
}

- (double)maxValue
{
    double v = 0.0;
    [[self fcurve] getMinValue:NULL maxValue:&v];
    return v;
}

- (NSString *)name
{
    return [[self fcurve] name];
}


#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames  // if the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"appendCurveToPoint",
                                     @"insertCurve",
                                     @"copy",
                                     
                                     nil];
}

// copy / appendCurve / insertCurve are implemented in superclass




@end
