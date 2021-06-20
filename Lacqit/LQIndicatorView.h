//
//  LQIndicatorView.h
//  Lacqit
//
//  Created by Pauli Ojala on 5.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
@class LQGradient;


@interface LQIndicatorView : NSView {

    NSColor *_baseColor;
    NSColor *_hiliteColor;
    NSColor *_pulseShineColor;
    
    LQGradient *_baseGrad;
    LQGradient *_hiliteGrad;
    
    BOOL _hilite;
    BOOL _pulsating;
    
    NSTimer *_animTimer;
    double _pulseFraction;
    double _startTime;
}

- (void)setBaseColor:(NSColor *)color;
- (void)setHighlightColor:(NSColor *)color;
- (void)setPulseHighlightColor:(NSColor *)color;

- (void)setHighlighted:(BOOL)f;
- (BOOL)isHighlighted;

- (void)setPulsating:(BOOL)f;
- (BOOL)isPulsating;

@end
