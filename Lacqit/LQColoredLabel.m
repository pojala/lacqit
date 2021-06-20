//
//  LQColoredLabel.m
//  Lacqit
//
//  Created by Pauli Ojala on 7.10.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQColoredLabel.h"
#import "LQNSBezierPathAdditions.h"
#import "LQNSColorAdditions.h"
#import "LQGradient.h"


@implementation LQColoredLabel

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
    [_bgColor release];
    [_bgGrad release];
    [super dealloc];
}

- (void)_updateGradient
{
    [_bgGrad release];
    _bgGrad = nil;

    LXRGBA rgba = (_bgColor) ? [_bgColor rgba] : LXMakeRGBA(1, 0, 0.5, 1);
    
    LXRGBA hiliteRGBA = LXMakeRGBA(rgba.r * 0.87, rgba.g * 0.85, rgba.b * 0.88, rgba.a);
    
    _bgGrad = [[LQGradient gradientWithBeginningColor:[NSColor colorWithRGBA:rgba] endingColor:[NSColor colorWithRGBA:hiliteRGBA]] retain];
}

- (void)setBaseColor:(NSColor *)color
{
    [_bgColor autorelease];
    _bgColor = [color retain];
    
    [self _updateGradient];
}

- (BOOL)isOpaque {
    return NO; }

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    bounds = NSInsetRect(bounds, 1, 2);
    bounds.origin.y -= 2.0;
        
    NSString *label = [self stringValue];
    NSFont *font = [NSFont boldSystemFontOfSize:11.0];
    NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                (font) ? font : [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                                                [NSColor whiteColor], NSForegroundColorAttributeName,
                                                                nil];
    
    NSSize labelSize = (label) ? [label sizeWithAttributes:labelAttrs]
                               : NSZeroSize;
                               
    
    if ( !_bgGrad) [self _updateGradient];
    
    double rounding = bounds.size.height * 0.5;
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:bounds rounding:rounding];
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor colorWithRGBA:LXMakeRGBA(0.03, 0, 0.1, 0.6)]];
    [shadow setShadowOffset:NSMakeSize(0, -1)];
    [shadow setShadowBlurRadius:2.0];
    
    [[NSGraphicsContext currentContext] saveGraphicsState];
    //[shadow set];
    NSAffineTransform *trs = [NSAffineTransform transform];
    [trs translateXBy:0.0 yBy:1.0];
    [trs concat];

    [[NSColor colorWithRGBA:LXMakeRGBA(0, 0, 0, 0.5)] set];
    [path fill];
    
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
    [_bgGrad fillBezierPath:path angle:90.0];
    
    
    if (labelSize.width > 0) {
        [shadow setShadowOffset:NSMakeSize(0, -1)];
        [shadow set];
        NSPoint p = NSMakePoint(round(bounds.origin.x + bounds.size.width*0.5 - labelSize.width*0.5),
                                round(bounds.origin.y + bounds.size.height*0.5 - labelSize.height*0.5));
        
        [label drawAtPoint:p withAttributes:labelAttrs];
    }
}

@end
