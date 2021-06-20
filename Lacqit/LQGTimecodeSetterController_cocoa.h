//
//  LQGTimecodeSetterController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 20.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


// the "clear" button action sets the value to DBL_MAX


@interface LQGTimecodeSetterController_cocoa : LQGCommonUIController {

    IBOutlet NSTextField *_labelField;
    IBOutlet NSTextField *_timeField;
    
    IBOutlet NSButton *_setButton;
    IBOutlet NSButton *_clearButton;
    
    NSString *_label;
    double _value;
}

- (id)init;

- (IBAction)setTimeAction:(id)sender;
- (IBAction)setTimeAtCurrentTimeAction:(id)sender;
- (IBAction)clearTimeAction:(id)sender;

@end
