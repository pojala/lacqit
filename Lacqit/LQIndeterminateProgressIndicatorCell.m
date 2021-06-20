//
//  LQIndeterminateProgressIndicatorCell.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.11.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//


#import "LQIndeterminateProgressIndicatorCell.h"


#define convertAngle(a) (fmod((90.0-(a)), 360.0))

#define kDeg2Rad 0.017453292519943295


@implementation LQIndeterminateProgressIndicatorCell

- (id)init
{
    if (self = [super initImageCell:nil]) {
        [self setAnimationDelay:5.0/60.0];
        [self setDisplayedWhenStopped:YES];
        [self setDoubleValue:0.0];
    }
    return self;
}

- (void)dealloc
{
    [_timer release];
    [super dealloc];
}

- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    _lqTint = tint;
}

- (LQInterfaceTint)interfaceTint
{
    return _lqTint;
}

- (NSControl *)parentControl {
    return _control;
}

- (void)setParentControl:(NSControl *)c {
    _control = c;
    //[_control autorelease];
    //_control = [c retain];
}

- (double)doubleValue
{
    return _doubleValue;
}

- (void)setDoubleValue:(double)value
{
    if (_doubleValue != value) {
        _doubleValue = MIN(1.0, MAX(0.0, value));
    }
}

- (NSTimeInterval)animationDelay
{
    return _animationDelay;
}

- (void)setAnimationDelay:(NSTimeInterval)value
{
    if (_animationDelay != value) {
        _animationDelay = value;
    }
}

- (BOOL)isDisplayedWhenStopped
{
    return _displayedWhenStopped;
}

- (void)setDisplayedWhenStopped:(BOOL)value
{
    if (_displayedWhenStopped != value) {
        _displayedWhenStopped = value;
    }
}

- (BOOL)isSpinning
{
    return _spinning;
}

- (void)setSpinning:(BOOL)value
{
    if (_spinning != value) {
        _spinning = value;

        if (value) {
            if (_timer == nil) {
                _timer = [[NSTimer scheduledTimerWithTimeInterval:_animationDelay target:self selector:@selector(animate:) userInfo:NULL repeats:YES] retain];
            } else {
                [_timer fire];
            }
        }
        else {
            [_timer invalidate];
            [_timer release];
            _timer = nil;
        }
        
        if ( !_spinning) [_control setNeedsDisplay:YES];
    }
}

- (void)animate:(NSTimer *)aTimer
{
    double value = fmod(([self doubleValue] + (5.0/60.0)), 1.0);
    
    [self setDoubleValue:value];

    [_control setNeedsDisplay:YES];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    // cell has no border
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if ([self isSpinning] || [self isDisplayedWhenStopped]) {
        float flipFactor = ([controlView isFlipped] ? 1.0 : -1.0);
        int step = round([self doubleValue]/(5.0/60.0));
        float cellSize = MIN(cellFrame.size.width, cellFrame.size.height);
        NSPoint center = cellFrame.origin;
        center.x += cellSize/2.0;
        center.y += cellFrame.size.height/2.0;
        float outerRadius;
        float innerRadius;
        float strokeWidth = cellSize*0.08;
        if (cellSize >= 32.0) {
            outerRadius = cellSize*0.38;
            innerRadius = cellSize*0.23;
        } else {
            outerRadius = cellSize*0.48;
            innerRadius = cellSize*0.27;
        }
        float a; // angle
        NSPoint inner;
        NSPoint outer;
        
        [NSBezierPath setDefaultLineCapStyle:NSRoundLineCapStyle];
        [NSBezierPath setDefaultLineWidth:strokeWidth];
        
        if ([self isSpinning]) {
            a = (270+(step* 30))*kDeg2Rad;
        } else {
            a = 270*kDeg2Rad;
        }
        a = flipFactor*a;
        int i;

        for (i = 0; i < 12; i++) {
            BOOL isWhite = (_lqTint == kLQFloaterTint);
            double alpha = (isWhite) ? 0.95 : 1.0;
            if (i == 0) {
                [[NSColor colorWithCalibratedWhite:(isWhite ? 1.0 : 0.0) alpha:alpha] set];
            }
            else {
                [[NSColor colorWithCalibratedWhite:(isWhite) ? MIN(sqrt(i)*0.44, 0.8) : 1.0 - MIN(sqrt(i)*0.5, 0.8)
                                            alpha:alpha] set];
            }
            
            outer = NSMakePoint(center.x+cos(a)*outerRadius, center.y+sin(a)*outerRadius);
            inner = NSMakePoint(center.x+cos(a)*innerRadius, center.y+sin(a)*innerRadius);
            [NSBezierPath strokeLineFromPoint:inner toPoint:outer];
            a -= flipFactor*30*kDeg2Rad;
        }
    }
}

- (void)setObjectValue:(id)value
{
    if ([value respondsToSelector:@selector(boolValue)]) {
        [self setSpinning:[value boolValue]];
    } else {
        [self setSpinning:NO];
    }
}

@end
