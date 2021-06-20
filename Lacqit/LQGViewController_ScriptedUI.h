//
//  LQGViewController_ScriptedUI.h
//  Lacqit
//
//  Created by Pauli Ojala on 13.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQGViewController.h"
#import "LacqitExport.h"


LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_Label;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_Button;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_MultiButton;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_CheckBox;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_NumberInput;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_Canvas;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_HorizontalList;
LACQIT_EXPORT_VAR NSString * const kLQGScriptedUIPresenterType_SelectorButton;


@interface LQGViewController (ScriptedUI)

+ (LQGViewController *)viewControllerFromScriptedUIDefinition:(NSDictionary *)dict;

@end
