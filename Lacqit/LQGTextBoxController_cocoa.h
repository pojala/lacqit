//
//  LQGTextFieldController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGTextBoxController_cocoa : LQGCommonUIController {

    id _textView;
    NSTextField *_labelField;
        
    NSString *_label;
    BOOL _isMultiline;
    BOOL _hasApplyButton;
    BOOL _isSecure;
    NSString *_str;
    
    id _editor;
}

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (BOOL)isMultiline;
- (void)setMultiline:(BOOL)f;

- (BOOL)hasSaveAndRevert;
- (void)setHasSaveAndRevert:(BOOL)f;

- (void)setEnabled:(BOOL)f;

- (BOOL)isSecure;
- (void)setSecure:(BOOL)f;

- (void)attachScriptEditorWithClass:(Class)cls interpreter:(id)interpreter;

@end
