//
//  EDUIDiscTriangle.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUIDiscTriangle.h"
#import "LQNSColorAdditions.h"

#if !defined(__LAGOON__)
#import "EDUIDiscTriangleCell.h"
#endif


@implementation EDUIDiscTriangle

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)setColor:(NSColor *)color {
    [_color autorelease];
    _color = [color retain];
}

- (NSColor *)color {
    return _color; }


#if !defined(__LAGOON__)

+ (Class)cellClass {
    return [EDUIDiscTriangleCell class]; }

- (void)setOpened:(BOOL)flag {
    [(EDUIDiscTriangleCell *)[self cell] setOpened:flag]; }

- (BOOL)isOpened {
    return [(EDUIDiscTriangleCell *)[self cell] isOpened]; }

#else

- (void)setOpened:(BOOL)flag {
    _isOpen = flag; }

- (BOOL)isOpened {
    return _isOpen; }
    
#endif


- (void)mouseDown:(NSEvent *)event
{
	[self setOpened:([self isOpened]) ? NO : YES];
    
    #if !defined(__LAGOON__)
    [[[self cell] target] performSelector:[[self cell] action] withObject:self];
    #else
    [[self target] performSelector:[self action] withObject:self];
    #endif
}

- (void)drawRect:(NSRect)rect
{
	BOOL isOpened = [self isOpened];
    NSRect bounds = [self bounds];
    NSBezierPath *path = [NSBezierPath bezierPath];

    bounds.origin.x += 1.0;
    bounds.origin.y += 2.0;
    bounds.size.width -= 3.0;
    bounds.size.height -= 3.0;

	if ( !isOpened) {
		[path moveToPoint:bounds.origin];
		[path lineToPoint:NSMakePoint(bounds.origin.x, bounds.origin.y + bounds.size.height)];
		[path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width - 3.0, bounds.origin.y + bounds.size.height*0.5)];
	}
	else {
		bounds.origin.y -= 0.5;
		[path moveToPoint:NSMakePoint(bounds.origin.x + bounds.size.width*0.5, bounds.origin.y + 3.0)];
		[path lineToPoint:NSMakePoint(bounds.origin.x, bounds.origin.y + bounds.size.height)];
		[path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height)];
	}
	[path closePath];
	
    NSColor *c = (_color) ? _color : [NSColor blackColor];
    NSShadow *shadow = nil;
    
    LXRGBA rgba = [c rgba];
    double lum = 0.3*rgba.r + 0.6*rgba.g + 0.1*rgba.b;
        
    if (lum > 0.9) {
        shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow setShadowBlurRadius:1];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:0 green:0 blue:0 alpha:0.8]];
    }
    
    if (shadow) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [shadow set];
    }
    
    [c set];
    [path fill];
    
    if (shadow) {
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}


@end
