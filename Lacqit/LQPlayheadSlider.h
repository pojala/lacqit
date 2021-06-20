//
//  LQPlayheadSlider.h
//  PixelMath
//
//  Created by Pauli Ojala on 8.7.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQPlayheadSlider : NSSlider {

    SEL     _inTimeAction;
    SEL     _outTimeAction;
    
    double  _inTime;
    double  _outTime;
    double  _frameLen;
    
    NSRect  _inOutRect;         // visual area to be marked as selected
    NSColor *_inOutColor;
    
    BOOL _headHidden;
    
    NSColor *_bgColor;
    BOOL _bgIsTransparent;
}

- (void)setBackgroundColor:(NSColor *)bgColor;
- (void)setInOutColor:(NSColor *)color;

- (void)setPlayheadVisible:(BOOL)f;

- (double)inTime;
- (void)setInTime:(double)time;
- (double)outTime;
- (void)setOutTime:(double)time;

// the convention for "outTime" is:  time of the last frame + duration of 1 frame.
// to properly support this notion, the playhead needs to know the frame duration.
- (double)frameDuration;
- (void)setFrameDuration:(double)frameLen;


- (void)setInTimeAction:(SEL)sel;
- (void)setOutTimeAction:(SEL)sel;

- (void)calcInOutRect;
- (double)calcTimeFromPosition:(NSPoint)point;

@end
