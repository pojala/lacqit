//
//  LQJSBridge_2DCanvasGradient.m
//  Lacqit
//
//  Created by Pauli Ojala on 10.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_2DCanvasGradient.h"
#import "LQJSBridge_Color.h"
#import "LQGradient.h"
#import "LQNSColorAdditions.h"


@implementation LQJSBridge_2DCanvasGradient

- (id)initInJSContext:(JSContextRef)context isRadial:(BOOL)isRad
                                            pointData:(double *)pointData
{
    self = [super initInJSContext:context withOwner:nil];
    if (self) {
        ///_grad = [[LQGradient alloc] init];
        _isRad = isRad;
        
        _p1 = NSMakePoint(pointData[0], pointData[1]);
        _p2 = NSMakePoint(pointData[2], pointData[3]);
        
        if (_isRad) {
            _radius1 = pointData[4];
            _radius2 = pointData[5];
        }
    }
    return self;
}

- (void)_setGradient:(LQGradient *)grad {
    [_grad release];
    _grad = [grad retain];
}

- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    double pointData[6] = { _p1.x, _p1.y,  _p2.x, _p2.y,  _radius1, _radius2 };
    
    id newObj = [[[self class] alloc] initInJSContext:dstContext isRadial:_isRad pointData:pointData]; 
    [newObj _setGradient:_grad];
    
    ///NSLog(@"copied %@", self);
    
    return [newObj autorelease];
}


- (void)dealloc
{
    if (_cairoPattern) {
        cairo_pattern_destroy(_cairoPattern);
        _cairoPattern = NULL;
    }

    [_grad release];
    _grad = nil;
    
    [super dealloc];
}


- (void)_createCairoPattern
{
    if ( !_grad) return;
    
    if (_isRad) {
        _cairoPattern = [_grad createRadialCairoPatternFromPoint:_p1 toPoint:_p2 radius1:_radius1 radius2:_radius2];
    } else {
        _cairoPattern = [_grad createLinearCairoPatternFromPoint:_p1 toPoint:_p2];
    }
    
    ///NSLog(@"created cairoPattern %p, status %i (colorstops %i)", _cairoPattern, cairo_pattern_status(_cairoPattern), [_grad numberOfColorStops]);
}

- (cairo_pattern_t *)cairoPattern
{
    if ( !_cairoPattern)
        [self _createCairoPattern];
        
    return _cairoPattern;
}

+ (NSString *)constructorName
{
    return @"<Canvas2DGradient>"; // can't be constructed
}

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"addColorStop", nil];
}

- (id)lqjsCallAddColorStop:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        NSLog(@"** %s: invalid args (count %lu: %@)", __func__, (long)[args count], args);
        return nil;
    }

    double offset = [[args objectAtIndex:0] doubleValue];
    id colorObj = [args objectAtIndex:1];
    
    if (offset < 0.0 || offset > 1.0 || !isfinite(offset)) return nil;
    
    NSColor *c = nil;
    
    if ([colorObj isKindOfClass:[NSString class]]) {
        c = [NSColor colorWithHTMLFormattedSRGBString:(NSString *)colorObj];
    }
    else if ([colorObj respondsToSelector:@selector(rgba_sRGB)]) {
        LXRGBA rgba = [colorObj rgba_sRGB];
        c = [NSColor colorWithRGBA_sRGB:rgba];
    }
    
    if (c) {
        ///NSLog(@"adding JS gradient colorStop at offset %.4f, color %@ (%p), from %@", offset, c, _grad, colorObj);
    
        LQGradient *newGrad = [(_grad ? _grad : [[[LQGradient alloc] init] autorelease]) gradientByAddingColorStop:c atPosition:offset];
        [_grad release];
        _grad = [newGrad retain];
    }
    return nil;
}


@end
