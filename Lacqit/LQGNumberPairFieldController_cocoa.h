//
//  LQGNumberPairFieldController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 11.2.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
@class LQNumberScrubField;


@interface LQGNumberPairFieldController_cocoa : LQGCommonUIController {

    IBOutlet NSTextField *_nameLabel;
    IBOutlet LQNumberScrubField *_scrubField1;
    IBOutlet LQNumberScrubField *_scrubField2;
    
    NSString *_label;
    double _xValue;
    double _yValue;
    BOOL _labelHidden;
    NSString *_nformat;
}

- (id)init;

- (void)setLabelFont:(NSFont *)font;

- (double)xValue;
- (void)setXValue:(double)d;

- (double)yValue;
- (void)setYValue:(double)d;

- (double)increment;
- (void)setIncrement:(double)f;

- (void)setEnabled:(BOOL)f;

@end
