//
//  LQScroller.m
//  Lacqit
//
//  Created by Pauli Ojala on 25.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQThemedScroller.h"
#import "LQNSBezierPathAdditions.h"


@implementation LQThemedScroller

- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    if (tint != _interfaceTint) {
        _interfaceTint = tint;
        [self setNeedsDisplay:YES];
    }
}

- (LQInterfaceTint)interfaceTint {
    return _interfaceTint; }


- (void)_drawWithFloaterTheme
{
    NSRect bounds = [self bounds];
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
        
    // fill bg
    if (0) {
        NSColor *bgColor = [NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        
        [ctx saveGraphicsState];    
        
        [ctx setCompositingOperation:NSCompositeCopy];
        [bgColor set];
        [[NSBezierPath bezierPathWithRect:bounds] fill];
        
        [ctx restoreGraphicsState];
    }
    
    NSRect knobRect = [self rectForPart:NSScrollerKnob];    
    NSRect knobSlotRect = [self rectForPart:NSScrollerKnobSlot];
    NSRect incLineRect = [self rectForPart:NSScrollerIncrementLine];
    NSRect decLineRect = [self rectForPart:NSScrollerDecrementLine];
    
    NSBezierPath *path;
    
    /*
    path = [NSBezierPath bezierPathWithRect:knobSlotRect];
    [[NSColor blueColor] set];
    [path fill];

    path = [NSBezierPath bezierPathWithRect:knobRect];
    [[NSColor whiteColor] set];
    [path fill];

    path = [NSBezierPath bezierPathWithRect:incLineRect];
    [[NSColor redColor] set];
    [path fill];

    path = [NSBezierPath bezierPathWithRect:decLineRect];
    [[NSColor yellowColor] set];
    [path fill];
    */
    
    path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(knobRect, 0.5, 1.5) rounding:6.0];
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.5)];
    [shadow setShadowBlurRadius:2.0];
    [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.02f alpha:0.9f]];
    [shadow set];
    
    [[NSColor colorWithDeviceRed:0.10 green:0.08 blue:0.13 alpha:1.0] set];
    [path fill];
    
    [[NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.68] set];
    [path stroke];
    
    
    NSRect arrowRect = NSInsetRect(incLineRect, 3, 4);
    arrowRect.origin.y -= 1.0;
    
    path = [NSBezierPath bezierPath];
    [path moveToPoint:arrowRect.origin];
    [path lineToPoint:NSMakePoint(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y)];
    [path lineToPoint:NSMakePoint(arrowRect.origin.x + arrowRect.size.width*0.5, arrowRect.origin.y + arrowRect.size.height)];
    [path fill];
    
    decLineRect.size.height = incLineRect.size.height;
    arrowRect = NSInsetRect(decLineRect, 3, 4);
    arrowRect.origin.y -= 1.0;
        
    path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(arrowRect.origin.x, arrowRect.origin.y + arrowRect.size.height)];
    [path lineToPoint:NSMakePoint(arrowRect.origin.x + arrowRect.size.width, arrowRect.origin.y + arrowRect.size.height)];
    [path lineToPoint:NSMakePoint(arrowRect.origin.x + arrowRect.size.width*0.5, arrowRect.origin.y)];
    [path fill];
    
    [ctx restoreGraphicsState];
}

- (void)drawRect:(NSRect)rect
{
    if (_interfaceTint == kLQFloaterTint) {
        [self _drawWithFloaterTheme];
    } else {
        [super drawRect:rect];
    }
}

@end
