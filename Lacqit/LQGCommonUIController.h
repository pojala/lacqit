//
//  LQGCommonUIController.h
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#if defined(__LAGOON__)
#import <Lagoon/Lagoon_All.h>
#endif

#import <Lacefx/LXBasicTypes.h>
#import "LacqitExport.h"
#import "LQModelConstants.h"
#import "LQUIConstants.h"

#if !defined(__LAGOON__)
 #import "LQGCocoaViewController.h"
/// #define LQGCOMMONUISUPERCLASS LQGCocoaViewController
#else
 #import "LQGViewController.h"
 /// #define LQGCOMMONUISUPERCLASS LQGViewController
 /// a crap hack to ensure that Interface Builder finds the proper superclass:
 #define LQGCocoaViewController LQGViewController
#endif

/*
A superclass and factory for common UI controls used by Conduit,
including the slider+numberscrub field combo, color pickers, checkboxes, etc.
(all the LQG*Controller classes are subclasses of this).

Calling the factory method with nil is same as kLQGCommonUI_GenericNSView:
it will return an LQGCommonUINSViewController that can be used to wrap a plain old NSView.
*/

// control types
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_GenericNSView;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_Checkbox;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_SliderAndField;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_NumberPairField;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_ColorPicker;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_SelectorButton;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_ButtonWithDetail;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_TextBox;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_ListItemWrapper;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_Table;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_TimecodeSetter;
LACQIT_EXPORT_VAR NSString * const kLQGCommonUI_Canvas;

// action contexts
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_ButtonClicked;
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_AddButtonClicked;
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_DeleteButtonClicked;
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_SelectionChanged;
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_MouseEvent;
LACQIT_EXPORT_VAR NSString * const kLQGActionContext_KeyEvent;

// standard button template names
LACQIT_EXPORT_VAR NSString * const kLQGTemplateName_AddButton;
LACQIT_EXPORT_VAR NSString * const kLQGTemplateName_DeleteButton;

// table column and data keys
#define                             kLQGTableKey_ColumnLabel        kLQUIKey_Label
#define                             kLQGTableKey_ColumnIdentifier   kLQUIKey_Identifier
#define                             kLQGTableKey_ColumnContentType  kLQUIKey_ContentType
LACQIT_EXPORT_VAR NSString * const kLQGTableKey_RowIndex;
LACQIT_EXPORT_VAR NSString * const kLQGTableKey_MovedObjects;
LACQIT_EXPORT_VAR NSString * const kLQGTableKey_SourceRowIndexes;
LACQIT_EXPORT_VAR NSString * const kLQGTableKey_DestinationRowIndexes;

LACQIT_EXPORT_VAR NSString * const kLQGTableContentType_EditableText;



@interface LQGCommonUIController : LQGCocoaViewController {

    NSString *_commonUICtrlType;

    NSMutableDictionary *_styleDict;
    NSDictionary *_jsBindingsDict;

    LXInteger _tag;
}

+ (id)commonUIControllerOfType:(NSString *)typeName;  // can be nil which equals kLQGCommonUI_GenericNSView

+ (id)commonUIControllerOfType:(NSString *)typeName subtype:(NSString *)subtype;

- (NSString *)commonUIControllerType;

- (NSString *)label;
- (void)setLabel:(NSString *)label;

- (LXInteger)tag;
- (void)setTag:(LXInteger)tag;

- (NSDictionary *)labelAttributes;

- (NSDictionary *)styleAttributes;
- (void)setStyleAttributes:(NSDictionary *)styleDict;
- (void)setValue:(id)val forStyleAttribute:(NSString *)attr;

- (NSDictionary *)scriptBindings;
- (void)setScriptBindings:(NSDictionary *)jsBindings;

@end
