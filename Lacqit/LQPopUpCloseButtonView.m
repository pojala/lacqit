//
//  LQPopUpCloseButtonView.m
//  Lacqit
//
//  Created by Pauli Ojala on 19.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQPopUpCloseButtonView.h"
#import "LQPopUpWindow.h"


@implementation LQPopUpCloseButtonView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)setTarget:(id)target {
    _target = target; }
    
- (void)setAction:(SEL)action {
    _action = action; }
    
- (id)target {
    return _target; }
    
- (SEL)action {
    return _action; }
    

- (void)mouseDown:(NSEvent *)event
{
    _hilite = YES;
    [self setNeedsDisplay:YES];
    
	NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    NSRect bounds = [self bounds];
    BOOL isFlipped = [self isFlipped];
    
    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ( !event || [event type] == NSLeftMouseUp) {
            break;
        }
        curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
        
        _hilite = (NSMouseInRect(curPoint, bounds, isFlipped)) ? YES : NO;
            
		[self setNeedsDisplay:YES];
	}
    
    if (_hilite) {
        if (_target && _action) {
            [_target performSelector:_action withObject:self];
        }
    }
    _hilite = NO;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path; 
    NSRect bounds = [self bounds];
    LXUInteger tint = [(id)[self window] popUpControlTint];
    NSColor *c;

    NSRect circleBounds = NSInsetRect(bounds, 1, 1);
    
    path = [NSBezierPath bezierPathWithOvalInRect:circleBounds];
    
    c = (_hilite) ? [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.95]
                           : [NSColor colorWithDeviceRed:0.02 green:0.015 blue:0.08 alpha:0.82];
    [c set];
    [path fill];

    NSRect crossBounds = NSInsetRect(bounds, 4.5, 4.5);
    
    path = [NSBezierPath bezierPath];
    [path moveToPoint:crossBounds.origin];
    [path lineToPoint:NSMakePoint(crossBounds.origin.x + crossBounds.size.width, crossBounds.origin.y + crossBounds.size.height)];

    [path moveToPoint:NSMakePoint(crossBounds.origin.x + crossBounds.size.width, crossBounds.origin.y)];
    [path lineToPoint:NSMakePoint(crossBounds.origin.x, crossBounds.origin.y + crossBounds.size.height)];
    
    c = (_hilite) ? [NSColor colorWithDeviceRed:0.9 green:0.905 blue:0.92 alpha:0.55]
                           : [NSColor colorWithDeviceRed:0.9 green:0.905 blue:0.92 alpha:0.95];
    [c set];
    
    [path setLineWidth:2.0];
    [path stroke];
    
    /*
    if (tint == kLQPopUpDarkBorderlessTint || tint == kLQPopUpDarkTint) {
        [[NSColor blackColor] set];
        NSRectFill(rect);
    }
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    NSColor *lightC =   (tint >= kLQPopUpMediumTint) ? [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.865 alpha:0.35]
                                                    : [NSColor colorWithDeviceRed:0.65 green:0.65 blue:0.665 alpha:0.3];
    NSColor *darkC =    [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.06 alpha:0.88];
    
    [path setLineWidth:0.7];
    
    y += 0.5;
    
    while (y < h) {
        [path moveToPoint:NSMakePoint(bounds.origin.x, y)];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
        
        [darkC set];
        [path stroke];
        [path removeAllPoints];
        
        y += 1.0;
        [path moveToPoint:NSMakePoint(bounds.origin.x, y)];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
        
        [lightC set];
        [path stroke];
        [path removeAllPoints];
        
        y += 2.0;
    }
    */
}

@end
