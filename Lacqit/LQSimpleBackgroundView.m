//
//  LQSimpleBackgroundView.m
//  Lacqit
//
//  Created by Pauli Ojala on 27.12.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQSimpleBackgroundView.h"


@implementation LQSimpleBackgroundView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    [self setBackgroundColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    return self;
}


- (void)setBackgroundColor:(NSColor *)c
{
    [_c autorelease];
    _c = [c retain];
    
    BOOL isTransparent = NO;
    @try {
        isTransparent = ([_c alphaComponent] <= 0.00001);
    } @catch (id exc) {
    
    }
    _compOp = (isTransparent) ? NSCompositeClear : NSCompositeSourceOver;
    
    [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor {
    return _c; }

- (void)setBottomBorderColor:(NSColor *)c
{
    [_bottomBorderC autorelease];
    _bottomBorderC = [c retain];
}

- (NSColor *)bottomBorderColor {
    return _bottomBorderC; }


#pragma mark --- drawing ---

- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    NSCompositingOperation compOp = [ctx compositingOperation];
    
    [ctx setCompositingOperation:_compOp];
    
    [_c set];
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:bounds];
    [path fill];
    
    [ctx setCompositingOperation:compOp];
    
    if (_bottomBorderC) {
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(bounds.origin.x, bounds.origin.y + 0.5)];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + 0.5)];
        
        NSColor *lineC = _bottomBorderC;
        
        [lineC set];
        [path setLineWidth:0.9];
        [path stroke];
    }
}

@end
