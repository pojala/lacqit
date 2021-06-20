//
//  LQJSBridge_Color.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_Color.h"
#import "LQNSColorAdditions.h"
#import "LQNSValueAdditions.h"


@implementation LQJSBridge_Color

- (id)initInJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [super initInJSContext:context withOwner:owner];
    if (self) {
        _red = _green = _blue = 0.0;
        _alpha = 1.0;
    }
    return self;
}


- (id)initWithHTMLFormattedString:(NSString *)str
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        NSColor *color = [NSColor colorWithHTMLFormattedSRGBString:str];
        
        ///NSLog(@"html color str %@ --> color %@", str, color);
        
        if (color) {
            LXRGBA rgba = [color rgba_sRGB];
            _red = rgba.r;
            _green = rgba.g;
            _blue = rgba.b;
            _alpha = rgba.a;
        }
    }
    return self;
}

- (void)dealloc
{
    ///NSLog(@"color bridge dealloc: %p, jsobj %p, owner %@, my color: %@", self, _jsObject, _owner, [self htmlFormattedString]);
    [super dealloc];
}

- (id)copyAsPatchObject {
    return [[NSValue valueWithRGBA:LXMakeRGBA(_red, _green, _blue, _alpha)] retain];
}

- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj = [[[self class] alloc] initWithHTMLFormattedString:[self htmlFormattedSRGBString]
                                            inJSContext:dstContext
                                            withOwner:nil];
    return [newObj autorelease];
}


+ (NSString *)constructorName
{
    return @"Color";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] >= 4) {
        double r = 0, g = 0, b = 0, a = 1;
        @try {
            r = [[arguments objectAtIndex:0] doubleValue];
            g = [[arguments objectAtIndex:1] doubleValue];
            b = [[arguments objectAtIndex:2] doubleValue];
            a = [[arguments objectAtIndex:3] doubleValue];
        } @catch (id exception) {
        }
        
        _red = MIN(1.0, MAX(0.0, r));
        _green = MIN(1.0, MAX(0.0, g));
        _blue = MIN(1.0, MAX(0.0, b));
        _alpha = MIN(1.0, MAX(0.0, a));
    }
    else if ([arguments count] == 1) {
        id arg = [arguments objectAtIndex:0];
        
        if ([arg respondsToSelector:@selector(rgba_sRGB)]) {
            LXRGBA rgba = [arg rgba_sRGB];
            _red = rgba.r;
            _green = rgba.g;
            _blue = rgba.b;
            _alpha = rgba.a;
        } else if ([arg respondsToSelector:@selector(rgba)]) {
            LXRGBA rgba = [arg rgba];
            _red = rgba.r;
            _green = rgba.g;
            _blue = rgba.b;
            _alpha = rgba.a;
        } else {
            NSString *str = [arg description];
            NSColor *color = [NSColor colorWithHTMLFormattedSRGBString:str];
        
            if (color) {
                LXRGBA rgba = [color rgba_sRGB];
                _red = rgba.r;
                _green = rgba.g;
                _blue = rgba.b;
                _alpha = rgba.a;
            }
        }
    }
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"red", @"green", @"blue", @"alpha", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return YES;
}

- (double)red {
    return _red; }

- (double)green {
    return _green; }

- (double)blue {
    return _blue; }

- (double)alpha {
    return _alpha; }

- (void)setRed:(double)r {
    _red = r; }

- (void)setGreen:(double)g {
    _green = g; }

- (void)setBlue:(double)b {
    _blue = b; }

- (void)setAlpha:(double)a {
    _alpha = a; }

- (void)getRed:(double *)pR green:(double *)pG blue:(double *)pB alpha:(double *)pA
{
    if (pR) *pR = _red;
    if (pG) *pG = _green;
    if (pB) *pB = _blue;
    if (pA) *pA = _alpha;
}

- (LXRGBA)rgba {
    return LXMakeRGBA(_red, _green, _blue, _alpha); }
    
- (void)setRGBA:(LXRGBA)rgba {
    _red = rgba.r;
    _green = rgba.g;
    _blue = rgba.b;
    _alpha = rgba.a;
}

- (LXRGBA)rgba_sRGB {
    return LXMakeRGBA(_red, _green, _blue, _alpha); }
    
- (void)setRGBA_sRGB:(LXRGBA)rgba {
    _red = rgba.r;
    _green = rgba.g;
    _blue = rgba.b;
    _alpha = rgba.a;
}

+ (NSArray *)objectFunctionNames  // if the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"toString",
                nil]; 
}

- (NSColor *)nsColor
{
    return [NSColor colorWithRGBA_sRGB:LXMakeRGBA(_red, _green, _blue, _alpha)];
}

- (NSString *)htmlFormattedString
{
    return [[self nsColor] htmlFormattedSRGBString];
}

- (NSString *)htmlFormattedSRGBString
{
    return [[self nsColor] htmlFormattedSRGBString];
}

- (id)lqjsCallToString:(NSArray *)args context:(id)contextObj
{
    return [[self nsColor] htmlFormattedSRGBString];
}

@end
