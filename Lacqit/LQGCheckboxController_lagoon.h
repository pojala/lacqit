//
//  LQGCheckboxController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGCheckboxController_lagoon : LQGCommonUIController {

    LGNativeWidget *_checkboxWidget;
    
    NSString *_label;
    BOOL _boolValue;
}

- (BOOL)boolValue;
- (void)setBoolValue:(BOOL)f;

- (double)doubleValue;


- (void)_newBoolValueForCheckbox:(BOOL)f;

@end
