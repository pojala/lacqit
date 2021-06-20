//
//  LQGCheckboxController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGCheckboxController_cocoa : LQGCommonUIController {

    NSButton *_button;
    
    NSString *_label;
    
    BOOL _boolValue;
}

- (BOOL)boolValue;
- (void)setBoolValue:(BOOL)f;

- (double)doubleValue;

@end
