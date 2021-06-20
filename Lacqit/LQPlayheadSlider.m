//
//  LQPlayheadSlider.m
//  PixelMath
//
//  Created by Pauli Ojala on 8.7.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQPlayheadSlider.h"
#import "LQNSColorAdditions.h"
#import "LQGradient.h"


@implementation LQPlayheadSlider

- (void)awakeFromNib
{
    _inOutColor = [[NSColor colorWithDeviceRed:0.2 green:0.27 blue:0.9 alpha:0.38] retain];
    if ( !_bgColor) {
        _bgIsTransparent = YES;
    }
}

- (void)dealloc
{
    [_inOutColor release];
    [_bgColor release];
    [super dealloc];
}


#pragma mark --- new methods ---

- (double)inTime {
    return _inTime; }
    
- (void)setInTime:(double)time {
    _inTime = time;
    [self calcInOutRect];
    [self setNeedsDisplay:YES];
}
    
- (double)outTime {
    return _outTime; }
    
- (void)setOutTime:(double)time {
    _outTime = time;
    [self calcInOutRect];
    [self setNeedsDisplay:YES];
}

- (void)setInTimeAction:(SEL)sel {
    _inTimeAction = sel; }

- (void)setOutTimeAction:(SEL)sel {
    _outTimeAction = sel; }

- (double)frameDuration {
    return _frameLen; }
    
- (void)setFrameDuration:(double)frameLen {
    _frameLen = frameLen;
    [self setNeedsDisplay:YES];
}



#define LEFTMARGIN 5.0
#define RIGHTMARGIN 6.0

- (void)calcInOutRect
{
    double h = 14.0;

    if (_outTime == DBL_MAX && (_inTime <= [self minValue])) {
        _inOutRect = NSZeroRect;
    } else {
        NSRect bounds = [self bounds];
        double minv = [self minValue];
        double maxv = [self maxValue];
        double fullw = bounds.size.width - LEFTMARGIN - RIGHTMARGIN;
        double unit = fullw / (maxv - minv);
        
        double inTime = _inTime;
        double outTime = _outTime - _frameLen;
        
        if (inTime <= minv || !isfinite(inTime)) inTime = minv;
        if (outTime == DBL_MAX || !isfinite(outTime)) outTime = maxv;
    
        _inOutRect = NSMakeRect( LEFTMARGIN + unit * (inTime - minv) - 2.0,   0.0,
                                 unit * (outTime - inTime), h);
                                 
        if (_inOutRect.size.width < 1.0 && outTime - inTime > 0.00001)
            _inOutRect.size.width = 1.0;  // round up
    } 

    ///NSLog(@"inout rect: bounds %@, minmax %f - %f,  %f -> %f", NSStringFromRect(bounds), min, max, _inTime, _outTime);
}

- (double)viewXFromTime:(double)pos
{
    const NSRect bounds = [self bounds];
    const double min = [self minValue];
    const double max = [self maxValue];
    const double fullw = bounds.size.width - LEFTMARGIN - RIGHTMARGIN - 2.0;
    double posInView = 2.0 + bounds.origin.x + pos * (fullw / (max - min));
    
    //NSLog(@"%s: %@; %.2f (%.2f / %.2f) --> %.2f, %.2f", __func__, NSStringFromRect(bounds), pos, min, max, fullw, posInView);
    
    return posInView;
}

- (double)calcTimeFromPosition:(NSPoint)point
{
    const NSRect bounds = [self bounds];
    double min = [self minValue];
    double max = [self maxValue];
    double fullw = bounds.size.width - LEFTMARGIN - RIGHTMARGIN;
    double unit = fullw / (max - min);
    double x = point.x - LEFTMARGIN;
    return ((x / unit) + min);
}


#pragma mark --- overrides ---

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    [self calcInOutRect];
}

- (void)mouseDown:(NSEvent *)event
{
    if ( ![self isEnabled]) return;

    BOOL altDown = (([event modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    BOOL shiftDown = (([event modifierFlags] & NSShiftKeyMask) ? YES : NO);
    BOOL ctrlDown = (([event modifierFlags] & NSControlKeyMask) ? YES : NO);
    NSPoint pos = [self convertPoint:[event locationInWindow] fromView:nil];

    if (ctrlDown && _inTimeAction != NULL) {
        [self setInTime:[self calcTimeFromPosition:pos]];
        [[self target] performSelector:_inTimeAction withObject:self];
        if (!shiftDown)
            return;
    }
    else if (altDown && _outTimeAction != NULL) {
        [self setOutTime:[self calcTimeFromPosition:pos]];
        [[self target] performSelector:_outTimeAction withObject:self];
        if (!shiftDown)
            return;
    }
    
    ////[super mouseDown:event];
    // 2008.05.13 -- there seems to be a problem with using the super implementation
    // (this NSSlider's cell's trackRect apparently gets updated only during the -drawRect
    // implementation, so if we don't call that, updated view bounds won't get correctly propagated
    // to the cell, resulting in incorrect values here...) so, let's just do our own mouse tracking

    [self setDoubleValue:[self calcTimeFromPosition:pos]];
    if ([self target]) {
        [[self target] performSelector:[self action] withObject:self];
    }

    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        
        if ([event type] != NSLeftMouseDragged)
            return;
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSPoint pos = [self convertPoint:[event locationInWindow] fromView:nil];

        [self setDoubleValue:[self calcTimeFromPosition:pos]];
        if ([self target]) {
            [[self target] performSelector:[self action] withObject:self];
        }

        [pool drain];
    }
}


- (BOOL)isOpaque {
    return !_bgIsTransparent; }
    
- (void)setNeedsDisplayInRect:(NSRect)r {
    if (r.size.width > 0.0 && r.size.height > 0.0)
        [super setNeedsDisplayInRect:NSInsetRect(r, -5.0, -5.0)];
}


- (void)setBackgroundColor:(NSColor *)bgColor {
    [_bgColor release];
    _bgColor = [bgColor retain];
    
    float alpha = [_bgColor alphaComponent];
    _bgIsTransparent = (alpha < 0.999);
    
    [self setNeedsDisplay:YES];
}

- (void)setInOutColor:(NSColor *)color {
    [_inOutColor release];
    _inOutColor = [color retain];
}

- (void)setPlayheadVisible:(BOOL)f {
    _headHidden = !f;
    [self setNeedsDisplay:YES];
}


+ (LQGradient *)trackGradient
{
    static LQGradient *s_grad = nil;
    if ( !s_grad) {
        NSColor *c0 = [NSColor colorWithDeviceRed:0.02 green:0.01 blue:0.08 alpha:1.0];
        NSColor *c1 = [NSColor colorWithDeviceRed:0.13 green:0.12 blue:0.28 alpha:0.9];
        NSColor *c2 = [NSColor colorWithDeviceRed:0.23 green:0.215 blue:0.3 alpha:1.0];
        
        LQGradient *grad = [[[LQGradient alloc] init] autorelease];
        
        grad = [grad gradientByAddingColorStop:c0 atPosition:0.0];
        grad = [grad gradientByAddingColorStop:c1 atPosition:0.8];
        grad = [grad gradientByAddingColorStop:c2 atPosition:1.0];
        
        s_grad = [grad retain];
    }
    return s_grad;
}

+ (LQGradient *)disabledTrackGradient
{
    static LQGradient *s_grad = nil;
    if ( !s_grad) {
        NSColor *c0 = [NSColor colorWithDeviceRed:0.02 green:0.01 blue:0.08 alpha:0.5];
        NSColor *c1 = [NSColor colorWithDeviceRed:0.13 green:0.12 blue:0.28 alpha:0.52];
        NSColor *c2 = [NSColor colorWithDeviceRed:0.23 green:0.215 blue:0.3 alpha:0.5];
        
        LQGradient *grad = [[[LQGradient alloc] init] autorelease];
        
        grad = [grad gradientByAddingColorStop:c0 atPosition:0.0];
        grad = [grad gradientByAddingColorStop:c1 atPosition:0.8];
        grad = [grad gradientByAddingColorStop:c2 atPosition:1.0];
        
        s_grad = [grad retain];
    }
    return s_grad;
}

+ (LQGradient *)inOutBackgroundGradient
{
    static LQGradient *s_grad = nil;
    if ( !s_grad) {
        NSColor *c0 = [NSColor colorWithDeviceRed:0.15 green:0.23 blue:0.89 alpha:0.80];
        NSColor *c1 = [NSColor colorWithDeviceRed:0.2 green:0.30 blue:0.92 alpha:0.50];
        NSColor *c2 = [NSColor colorWithDeviceRed:0.2 green:0.27 blue:0.90 alpha:0.48];
        NSColor *c3 = [NSColor colorWithDeviceRed:0.9 green:0.97 blue:0.99 alpha:0.88];
        
        LQGradient *grad = [[[LQGradient alloc] init] autorelease];
        
        grad = [grad gradientByAddingColorStop:c0 atPosition:0.0];
        grad = [grad gradientByAddingColorStop:c1 atPosition:0.1];
        grad = [grad gradientByAddingColorStop:c2 atPosition:0.9];
        grad = [grad gradientByAddingColorStop:c3 atPosition:1.0];
        
        s_grad = [grad retain];
    }
    return s_grad;
}


- (void)drawRect:(NSRect)rect
{
    //[super drawRect:rect];
    //return;

    NSRect bounds = [self bounds];
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    
    NSRect bgRect = NSInsetRect(bounds, 1.5, 3.5);
    bgRect.origin.y -= 1.0;
    bgRect.origin.x += 1.0;
    bgRect.size.width -= 7.0;

    // clear the view background
    [ctx saveGraphicsState];
    {
        [ctx setCompositingOperation:(_bgIsTransparent) ? NSCompositeSourceOver : NSCompositeCopy];    
        if ( !_bgColor)
            [[[self window] backgroundColor] set];
        else
            [_bgColor set];
        
        NSRect r = NSInsetRect(bgRect, -2.0, -3.0);
        
        if (_bgIsTransparent) {
            [[NSBezierPath bezierPathWithRect:r] fill];
        } else {
            NSRectFill(r);  //bounds);
        }
    }
    [ctx restoreGraphicsState];
    

    NSBezierPath *path = nil;
    NSRect inOutArea = NSIntersectionRect(rect, _inOutRect);
    
    if (inOutArea.size.width > 0.0) {    
        inOutArea.origin.y = bgRect.origin.y - 3.0;
        inOutArea.size.height = bgRect.size.height + 6.0;
    
        path = [NSBezierPath bezierPathWithRect:inOutArea];

        //[_inOutColor set];
        //[path fill];

        LQGradient *inOutGrad = [[self class] inOutBackgroundGradient];
        [inOutGrad fillBezierPath:path angle:90];
    }

    NSColor *fillColor =   [NSColor colorWithRGBA:LXMakeRGBA(0, 0, 0, 1)];
    NSColor *strokeColor = [NSColor colorWithDeviceRed:0.82 green:0.85 blue:0.88 alpha:0.5];
    
    path = [NSBezierPath bezierPathWithRect:bgRect];
    
    //[fillColor set];
    //[path fill];
    
    LQGradient *trackGrad = ([self isEnabled]) ? [[self class] trackGradient] : [[self class] disabledTrackGradient];
    [trackGrad fillBezierPath:path angle:90];
    
    [strokeColor set];
    //[path stroke];
    
    // draw the playhead
    if ( !_headHidden) {
        const double pos = [self doubleValue];
        double posInView = [self viewXFromTime:pos];
        //NSLog(@"  ... bounds %@ -- pos %f --> %f (%i)", NSStringFromRect(bounds), pos, posInView, [self isFlipped]);
        
        NSRect playheadRect = NSMakeRect( round(posInView) + 0.5,  round(bounds.origin.y) + 0.5,   3.0, bounds.size.height - 3.0);
        
        path = [NSBezierPath bezierPathWithRect:playheadRect];

		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.5f, -1.5f)];
		[shadow setShadowBlurRadius:2.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.05f green:0.05f blue:0.07f alpha:0.4f]];
        [shadow set];
        
        [strokeColor set];
        [path fill];
        [path stroke];
    }

    //[super drawRect:rect];
}


@end
