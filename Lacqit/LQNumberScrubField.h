//
//  LQNumberScrubField.h
//  PixelMath
//
//  Created by Pauli Ojala on 10.9.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
@class LQGradient;


#ifdef __LAGOON__
#import <Lagoon/Lagoon_All.h>
@interface LQNumberScrubField : NSControl {
#else
@interface LQNumberScrubField : NSTextField {
#endif
	
	NSTextField *_editor;

    //id          _delegate;
#if !defined(__LAGOON__)
	id			_target;
	SEL			_action;
#endif

    NSView      *_nextKeyView;

	double		_value;
	double		_scrubRatio;	// a value of 600 means that a 600-pixel x movement => 1.0 change in value
    double      _increment;
    BOOL        _enabled;
    
    NSColor     *_baseC;
    NSImage     *_baseCImage;
    LXUInteger  _interfaceTint;
}

+ (void)setDefaultBackgroundGradient:(LQGradient *)grad;
+ (void)setDefaultInterfaceTint:(LQInterfaceTint)tint;
+ (void)setScrubEnabled:(BOOL)flag;
    
- (double)increment;
- (void)setIncrement:(double)f;

- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter;

- (NSTextField *)valueEditor;
- (void)startTabbing;
- (void)endTabbing;

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end


@interface NSObject (LQNumberScrubFieldDelegate)

- (void)startTabbingBetweenScrubFields;
- (void)endTabbingBetweenScrubFields;

- (void)fieldStartsScrub:(LQNumberScrubField *)field;

@end

