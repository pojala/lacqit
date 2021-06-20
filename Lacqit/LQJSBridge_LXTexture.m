//
//  LQJSBridge_LXTexture.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXTexture.h"


@implementation LQJSBridge_LXTexture

- (id)initWithLXTexture:(LXTextureRef)texture
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _texture = texture;
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"%s / %p: 1", __func__, self);

    [super dealloc];
    ///NSLog(@"%s: end", __func__);
}
/*
- (void)release
{
    ///NSLog(@"%s / %p: retc %i", __func__, self, [self retainCount]);
    [super release];
}
*/


- (LXTextureRef)lxTexture {
    return _texture; }
    

+ (NSString *)constructorName
{
    return @"<LXTexture>"; // can't be constructed
}


#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"width", @"height", @"samplingMode", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return ([propertyName isEqualToString:@"samplingMode"]) ? YES : NO;
}

- (LXInteger)width {
    return LXTextureGetWidth(_texture); }

- (LXInteger)height {
    return LXTextureGetHeight(_texture); }

- (NSString *)samplingMode
{
    LXInteger s = LXTextureGetSampling(_texture);
    switch (s) {
        case kLXNearestSampling:    return @"nearest";
        
        default:
        case kLXLinearSampling:     return @"linear";
    }
}

- (void)setSamplingMode:(NSString *)str
{
    LXInteger s = -1;
    if ([str isEqualToString:@"nearest"])
        s = kLXNearestSampling;
    else if ([str isEqualToString:@"linear"])
        s = kLXLinearSampling;
        
    if (s != -1)
        LXTextureSetSampling(_texture, s);
}


#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray array];
}

@end
