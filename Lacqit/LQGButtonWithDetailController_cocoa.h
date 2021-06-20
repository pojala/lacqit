//
//  LQGButtonWithDetailController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGButtonWithDetailController_cocoa : LQGCommonUIController {

    NSTextField *_labelField;

    NSButton *_button;
    NSTextField *_detailField;
    
    NSString *_label;
    NSString *_detailStr;
    NSString *_buttonLabel;
}

- (NSString *)detailString;
- (void)setDetailString:(NSString *)str;

- (NSString *)buttonLabel;
- (void)setButtonLabel:(NSString *)str;

@end
