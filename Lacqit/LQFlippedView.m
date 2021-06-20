//
//  LQFlippedView.m
//  PixelMath
//
//  Created by Pauli Ojala on 13.8.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQFlippedView.h"


@implementation LQFlippedView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)isFlipped {
	return YES; }

- (void)setDrawsBackground:(BOOL)f {
    _drawsBg = f;
    [self setNeedsDisplay:YES];
}
    
- (BOOL)drawsBackground {
    return _drawsBg; }

- (void)setBackgroundColor:(NSColor *)color {
    [_bgColor autorelease];
    _bgColor = [color retain];
}

- (NSColor *)backgroundColor {
    return _bgColor; }

- (void)setTag:(LXInteger)tag {
    _tag = tag; }
    
- (LXInteger)tag {
    return _tag; }



- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    [super resizeWithOldSuperviewSize:oldBoundsSize];
    
    if ([self bounds].size.width < 1) {
        NSLog(@"** flippedview resized to zero width (this will probably mess up some layout)");
    }
    ///if (_tag) NSLog(@"flippedview resize (tag %ld): old w %.3f, new %.3f", _tag, oldBoundsSize.width, [self bounds].size.width);
}


- (void)drawRect:(NSRect)rect
{
    if (_drawsBg) {
        NSColor *bgColor = (_bgColor) ? _bgColor : [NSColor whiteColor];
        
        [bgColor set];
        
        [[NSBezierPath bezierPathWithRect:rect] fill];
    }
}


@end
