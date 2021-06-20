//
//  LQGSliderAndFieldController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 16.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
@class LQNumberScrubField;


@interface LQGSliderAndFieldController_cocoa : LQGCommonUIController {

    IBOutlet NSTextField *_nameLabel;
    IBOutlet NSSlider *_slider;
    IBOutlet LQNumberScrubField *_scrubField;
 
    NSString *_label;
    double _value;
    double _prevValue;
    BOOL _labelHidden;   
    
    BOOL _hasSmallFullWidthSlider;
}

- (id)init;
- (id)initWithSmallFullWidthSlider;

- (void)setLabelFont:(NSFont *)font;

- (double)doubleValue;
- (void)setDoubleValue:(double)d;

- (void)setSliderMin:(double)smin max:(double)smax;

- (double)increment;
- (void)setIncrement:(double)f;  // sets the entry field's increment; needs to be called after -loadView

- (void)setEnabled:(BOOL)f;

- (void)setLabelEditable:(BOOL)f;

@end
