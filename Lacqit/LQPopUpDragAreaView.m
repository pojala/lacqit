//
//  LQPopUpDragAreaView.m
//  ConduitLive2
//
//  Created by Pauli Ojala on 30.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQPopUpDragAreaView.h"
#import "LQPopUpWindow.h"


@implementation LQPopUpDragAreaView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    [_title release];
    _title = [title copy];
    [self setNeedsDisplay:YES];
}

- (NSString *)title {
    return _title; }


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES; }

- (void)mouseDown:(NSEvent *)event
{
    [(LQPopUpWindow *)[self window] doWindowDrag];
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    double h = bounds.size.height;
    double y = bounds.origin.y;
    double x = bounds.origin.x;
    
    LXUInteger tint = [(id)[self window] popUpControlTint];
    
    if (tint == kLQPopUpDarkBorderlessTint || tint == kLQPopUpDarkTint) {
        [[NSColor blackColor] set];
        NSRectFill(rect);
    }
    
    NSString *title = [self title];
    NSSize titleSize = NSZeroSize;
    if (title && [title length] > 0) {
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowBlurRadius:1.0];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.9]];
    
        NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize], NSFontAttributeName,
                                                [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.95], NSForegroundColorAttributeName,
                                                shadow, NSShadowAttributeName,
                                                nil];
        
        titleSize = [title sizeWithAttributes:titleAttrs];
        
        [title drawAtPoint:NSMakePoint(round(bounds.origin.x + 4.0), round(bounds.origin.y + 1.0)) withAttributes:titleAttrs];

        x += titleSize.width + 9;
    }
    
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    NSColor *lightC =   (tint >= kLQPopUpMediumTint) ? [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.865 alpha:0.29]
                                                    : [NSColor colorWithDeviceRed:0.65 green:0.65 blue:0.665 alpha:0.23];
    NSColor *darkC =    [NSColor colorWithDeviceRed:0.02 green:0.01 blue:0.06 alpha:0.7];
    
    [path setLineWidth:0.7];
    
    y += 2.5;
    
    while (y < h-1.5) {
        [path moveToPoint:NSMakePoint(x, y)];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
        
        [darkC set];
        [path stroke];
        [path removeAllPoints];
        
        y += 1.0;
        [path moveToPoint:NSMakePoint(x, y)];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
        
        [lightC set];
        [path stroke];
        [path removeAllPoints];
        
        y += 2.0;
    }
}

@end
