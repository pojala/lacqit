//
//  LQIndicatorView.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQIndicatorView.h"
#import "LQGradient.h"
#import "LQTimeFunctions.h"


@implementation LQIndicatorView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _baseColor = [[NSColor colorWithDeviceRed:0.32 green:0.04 blue:0.13 alpha:1.0] retain];
        _hiliteColor = [[NSColor colorWithDeviceRed:1.0 green:0.1 blue:0.15 alpha:1.0] retain];
        _pulseShineColor = [[NSColor colorWithDeviceRed:1.0 green:0.3 blue:0.48 alpha:1.0] retain];
        
        _hilite = NO;
    }
    return self;
}

- (void)dealloc {
    [_baseColor release];
    [_hiliteColor release];
    [_pulseShineColor release];
    [_baseGrad release];
    [_hiliteGrad release];
    
    [_animTimer release];
    _animTimer = nil;
            
    [super dealloc];
}


- (void)_recreateGradients
{
#if !defined(__LAGOON__)
    [_baseGrad release];
    [_hiliteGrad release];
    
    NSColor *shadowColor = [NSColor colorWithDeviceRed:0.025 green:0.0 blue:0.05 alpha:1.0];
    LQGradient *baseGrad = [LQGradient gradientWithBeginningColor:_baseColor endingColor:shadowColor];
    baseGrad = [baseGrad gradientByAddingColorStop:_baseColor atPosition:0.7];
    [baseGrad setGradientType:kLQRadialGradient];
    
    _baseGrad = [baseGrad retain];

    shadowColor = [_baseColor blendedColorWithFraction:0.3 + (_pulseFraction*0.6) ofColor:_hiliteColor];
    NSColor *hiliteColor = (_pulseFraction > 0.0) ? [_hiliteColor blendedColorWithFraction:_pulseFraction ofColor:_pulseShineColor]
                                                  : _hiliteColor;
    
    LQGradient *hiliteGrad = [LQGradient gradientWithBeginningColor:hiliteColor endingColor:shadowColor];
    hiliteGrad = [hiliteGrad gradientByAddingColorStop:hiliteColor atPosition:0.2];
    [hiliteGrad setGradientType:kLQRadialGradient];
    
    _hiliteGrad = [hiliteGrad retain];
#endif
}

- (void)setBaseColor:(NSColor *)color {
    [_baseColor autorelease];
    _baseColor = [color retain];
    
    [self _recreateGradients];
}

- (void)setHighlightColor:(NSColor *)color {
    [_hiliteColor autorelease];
    _hiliteColor = [color retain];
    
    [self _recreateGradients];
}

- (void)setPulseHighlightColor:(NSColor *)color {
    [_pulseShineColor autorelease];
    _pulseShineColor = [color retain];
    
    [self _recreateGradients];
}

- (void)animTimerFired:(NSTimer *)timer
{
    double t0 = LQReferenceTimeGetCurrent();
    double delta = t0 - _startTime;
    
    const double phaseLen = 5.0;
    
    double phase = fmod(delta, phaseLen) / phaseLen;
    if (phase > 0.5) {
        phase = 1.0 - phase;
    }
    phase *= 2.0;
    phase = pow(phase, 2.2);
    
    _pulseFraction = phase;
    [self setNeedsDisplay:YES];
}

- (void)_recreateAnimTimerIfNeeded
{
    BOOL doAnim = (_hilite && _pulsating && ![self isHidden]);
    if ( !doAnim) {
        if (_animTimer) {
            [_animTimer invalidate];
            [_animTimer release];
            _animTimer = nil;
            _pulseFraction = 0.0;
        }
    } else {
        if ( !_animTimer) {
            _pulseFraction = 0.0;
            _startTime = LQReferenceTimeGetCurrent();
            _animTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 10.0)
                             target:self
                             selector:@selector(animTimerFired:)
                             userInfo:nil
                             repeats:YES] retain];
        }
    }
    [self setNeedsDisplay:YES];
}

- (void)setHidden:(BOOL)f {
    [super setHidden:f];
    [self _recreateAnimTimerIfNeeded];
}

- (void)setHighlighted:(BOOL)f {
    _hilite = f;
    [self _recreateAnimTimerIfNeeded];
}
    
- (BOOL)isHighlighted {
    return _hilite; }

- (void)setPulsating:(BOOL)f {
    _pulsating = f;
    [self _recreateAnimTimerIfNeeded];
}
    
- (BOOL)isPulsating {
    return _pulsating; }


- (void)drawRect:(NSRect)rect
{
// TODO: needs implementation on Lagoon
#if !defined(__LAGOON__)
    if ( !_baseGrad || _pulseFraction > 0.0)
        [self _recreateGradients];

    NSRect bounds = [self bounds];
    bounds.size.width = bounds.size.height;
    bounds = NSInsetRect(bounds, 1.5, 1.5);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:bounds];
    
    // draw background
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
    
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowBlurRadius:(_hilite) ? 1.0 : 0.0];
    [shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
    [shadow setShadowColor:[NSColor colorWithDeviceRed:1.0 green:((_hilite) ? 0.75 : 0.95) blue:0.99 alpha:(_hilite) ? 0.95 : 0.55]];
    [shadow set];

    [_baseColor set];
    [path setLineWidth:1.0];

    [path fill];
    
    [ctx restoreGraphicsState];
    
    
    // draw content
    LQGradient *activeGrad = (_hilite) ? _hiliteGrad : _baseGrad;
    
    [ctx saveGraphicsState];
    NSRect innerRect = NSInsetRect(bounds, 1.1, 1.1);
    innerRect.origin.y -= 0.5;
    [[NSBezierPath bezierPathWithOvalInRect:innerRect] addClip];
    
    NSRect gradientRect = NSInsetRect(bounds, -2, -2);
    gradientRect.origin.y += bounds.size.height * 0.15;
    gradientRect.origin.x -= bounds.size.height * 0.05;

    shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowBlurRadius:1.0];
    [shadow setShadowOffset:NSMakeSize(0.0, 2.0)];
    [shadow setShadowColor:[NSColor colorWithDeviceRed:0 green:0 blue:0.3 alpha:0.8]];
    [shadow set];
    
    [activeGrad radialFillBezierPath:[NSBezierPath bezierPathWithOvalInRect:gradientRect]];
    
    [ctx restoreGraphicsState];
#endif
}


@end
