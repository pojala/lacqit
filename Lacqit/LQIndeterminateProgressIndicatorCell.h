//
//  LQIndeterminateProgressIndicatorCell.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.11.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"


@interface LQIndeterminateProgressIndicatorCell : NSCell {

	double _doubleValue;
	NSTimeInterval _animationDelay;
	BOOL _displayedWhenStopped;
	BOOL _spinning;
	NSTimer *_timer;
	NSControl *_control;
    LQInterfaceTint _lqTint;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

- (NSControl *)parentControl;
- (void)setParentControl:(NSControl *)c;

- (double)doubleValue;
- (void)setDoubleValue:(double)value;

- (NSTimeInterval)animationDelay;
- (void)setAnimationDelay:(NSTimeInterval)value;

- (BOOL)isDisplayedWhenStopped;
- (void)setDisplayedWhenStopped:(BOOL)value;

- (BOOL)isSpinning;
- (void)setSpinning:(BOOL)value;

- (void)animate:(NSTimer *)aTimer;

@end
