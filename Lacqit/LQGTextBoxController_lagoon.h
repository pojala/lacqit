//
//  LQGTextBoxController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 17.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGTextBoxController_lagoon : LQGCommonUIController {

    LGNativeWidget *_vboxWidget;
    
    GtkWidget *_textViewWidget;
    
    BOOL _isMultiline;
    BOOL _hasApplyButton;
    NSString *_str;
}

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (BOOL)isMultiline;
- (void)setMultiline:(BOOL)f;

- (BOOL)hasSaveAndRevert;
- (void)setHasSaveAndRevert:(BOOL)f;


- (void)_newStringValueForTextView:(NSString *)str;

@end
