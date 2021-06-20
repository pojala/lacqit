//
//  LQGCommonUIController.m
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"

#import "LQGCommonUINSViewController.h"

#if !defined(__LAGOON__)
 #import "LQGCheckboxController_cocoa.h"
 #import "LQGSliderAndFieldController_cocoa.h"
 #import "LQGNumberPairFieldController_cocoa.h"
 #import "LQGColorPickerController_cocoa.h"
 #import "LQGSelectorButtonController_cocoa.h"
 #import "LQGButtonWithDetailController_cocoa.h"
 #import "LQGTextBoxController_cocoa.h"
 #import "LQGListItemWrapperController_cocoa.h" 
 #import "LQGTableController_cocoa.h" 
 #import "LQGTimecodeSetterController_cocoa.h"
 #define CLS_CHECKBOX           LQGCheckboxController_cocoa
 #define CLS_SLIDERANDFIELD     LQGSliderAndFieldController_cocoa
 #define CLS_NUMBERPAIRFIELD    LQGNumberPairFieldController_cocoa
 #define CLS_COLORPICKER        LQGColorPickerController_cocoa
 #define CLS_SELECTORBUTTON     LQGSelectorButtonController_cocoa
 #define CLS_BUTTONWITHDETAIL   LQGButtonWithDetailController_cocoa
 #define CLS_TEXTBOX            LQGTextBoxController_cocoa
 #define CLS_LISTITEMWRAPPER    LQGListItemWrapperController_cocoa
 #define CLS_TABLE              LQGTableController_cocoa
 #define CLS_TIMECODESETTER     LQGTimecodeSetterController_cocoa
#else
 #import "LQGCheckboxController_lagoon.h"
 #import "LQGSliderAndFieldController_lagoon.h"
 #import "LQGColorPickerController_lagoon.h"
 #import "LQGSelectorButtonController_lagoon.h"
 #import "LQGButtonWithDetailController_lagoon.h"
 #import "LQGTextBoxController_lagoon.h"
 #import "LQGListItemWrapperController_lagoon.h" 
 #define CLS_CHECKBOX           LQGCheckboxController_lagoon
 #define CLS_SLIDERANDFIELD     LQGSliderAndFieldController_lagoon
 #define CLS_NUMBERPAIRFIELD    Nil  // TODO: implement numberPairField
 #define CLS_COLORPICKER        LQGColorPickerController_lagoon
 #define CLS_SELECTORBUTTON     LQGSelectorButtonController_lagoon
 #define CLS_BUTTONWITHDETAIL   LQGButtonWithDetailController_lagoon
 #define CLS_TEXTBOX            LQGTextBoxController_lagoon
 #define CLS_LISTITEMWRAPPER    LQGListItemWrapperController_lagoon
 #define CLS_TABLE              Nil  // TODO: implement table
 #define CLS_TIMECODESETTER     Nil  // TODO: implement timecodeSetter
#endif

// shared implementation
 #import "LQGCanvasController_cocoa.h"
 #define CLS_CANVAS             LQGCanvasController_cocoa


NSString * const kLQGCommonUI_GenericNSView = @"LQGCommonUI_GenericNSView";
NSString * const kLQGCommonUI_Checkbox = @"LQGCommonUI_Checkbox";
NSString * const kLQGCommonUI_SliderAndField = @"LQGCommonUI_SliderAndField";
NSString * const kLQGCommonUI_NumberPairField = @"LQGCommonUI_NumberPairField";
NSString * const kLQGCommonUI_ColorPicker = @"LQGCommonUI_ColorPicker";
NSString * const kLQGCommonUI_SelectorButton = @"LQGCommonUI_SelectorButton";
NSString * const kLQGCommonUI_ButtonWithDetail = @"LQGCommonUI_ButtonWithDetail";
NSString * const kLQGCommonUI_TextBox = @"LQGCommonUI_TextBox";
NSString * const kLQGCommonUI_ListItemWrapper = @"LQGCommonUI_ListItemWrapper";
NSString * const kLQGCommonUI_Table = @"LQGCommonUI_Table";
NSString * const kLQGCommonUI_TimecodeSetter = @"LQGCommonUI_TimecodeSetter";
NSString * const kLQGCommonUI_Canvas = @"LQGCommonUI_Canvas";


NSString * const kLQGActionContext_ButtonClicked = @"buttonClicked";
NSString * const kLQGActionContext_AddButtonClicked = @"addButtonClicked";
NSString * const kLQGActionContext_DeleteButtonClicked = @"deleteButtonClicked";
NSString * const kLQGActionContext_SelectionChanged = @"selectionChanged";
NSString * const kLQGActionContext_MouseEvent = @"mouseEvent";
NSString * const kLQGActionContext_KeyEvent = @"keyEvent";

NSString * const kLQGTemplateName_AddButton = @"addButton";
NSString * const kLQGTemplateName_DeleteButton = @"deleteButton";

// table column/data info keys
//NSString * const kLQGTableKey_ColumnLabel = @"label";
//NSString * const kLQGTableKey_ColumnIdentifier = @"identifier";
//NSString * const kLQGTableKey_ColumnContentType = @"contentType";
NSString * const kLQGTableKey_RowIndex = @"rowIndex";
NSString * const kLQGTableKey_MovedObjects = @"movedObjects";
NSString * const kLQGTableKey_SourceRowIndexes = @"sourceRows";
NSString * const kLQGTableKey_DestinationRowIndexes = @"destinationRows";
NSString * const kLQGTableContentType_EditableText = @"editableText";



@implementation LQGCommonUIController

- (void)_setCommonUIControllerType:(NSString *)type {
    [_commonUICtrlType release];
    _commonUICtrlType = [type copy];
}

+ (id)commonUIControllerOfType:(NSString *)typeName subtype:(NSString *)subtype
{
    id obj = nil;
    
#if !defined(__LAGOON__)
    if ([typeName isEqualToString:kLQGCommonUI_SliderAndField] && [subtype isEqualToString:@"smallFullWidthSlider"]) {
        obj = [[[CLS_SLIDERANDFIELD class] alloc] initWithSmallFullWidthSlider];
    }
#endif

    if (obj) {
        [obj _setCommonUIControllerType:typeName];
        return obj;
    } else {
        return [self commonUIControllerOfType:typeName];
    }
}


+ (id)commonUIControllerOfType:(NSString *)typeName
{
    Class cls = Nil;

    if (typeName == nil || [typeName isEqualToString:kLQGCommonUI_GenericNSView]) {
        cls = [LQGCommonUINSViewController class];
    }
    else if ([typeName isEqualToString:kLQGCommonUI_Checkbox]) {
        cls = [CLS_CHECKBOX class];
    } else if ([typeName isEqualToString:kLQGCommonUI_SliderAndField]) {
        cls = [CLS_SLIDERANDFIELD class];
    } else if ([typeName isEqualToString:kLQGCommonUI_NumberPairField]) {
        cls = [CLS_NUMBERPAIRFIELD class];
    } else if ([typeName isEqualToString:kLQGCommonUI_ColorPicker]) {
        cls = [CLS_COLORPICKER class];
    } else if ([typeName isEqualToString:kLQGCommonUI_SelectorButton]) {
        cls = [CLS_SELECTORBUTTON class];
    } else if ([typeName isEqualToString:kLQGCommonUI_ButtonWithDetail]) {
        cls = [CLS_BUTTONWITHDETAIL class];
    } else if ([typeName isEqualToString:kLQGCommonUI_TextBox]) {
        cls = [CLS_TEXTBOX class];
    } else if ([typeName isEqualToString:kLQGCommonUI_ListItemWrapper]) {
        cls = [CLS_LISTITEMWRAPPER class];
    } else if ([typeName isEqualToString:kLQGCommonUI_Table]) {
        cls = [CLS_TABLE class];
    }  else if ([typeName isEqualToString:kLQGCommonUI_TimecodeSetter]) {
        cls = [CLS_TIMECODESETTER class];
    } else if ([typeName isEqualToString:kLQGCommonUI_Canvas]) {
        cls = [CLS_CANVAS class];
    } 
    else {
        NSLog(@"*** %s: unknown type: '%@'", __func__, typeName);
        return nil;
    }
    
    if (cls == Nil) {
        NSLog(@"*** %s: no class available for type: '%@'", __func__, typeName);
        return nil;
    }
    
    id obj = [[[cls alloc] init] autorelease];
    [obj _setCommonUIControllerType:typeName];
    
    return obj;
}

- (id)initWithResourceName:(NSString *)resName bundle:(NSBundle *)bundle
{
    self = [super initWithResourceName:resName bundle:bundle];
    if (self) {
        _styleDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)init
{
    self = [self initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];    
    return self;
}


- (void)dealloc
{
    [_commonUICtrlType release];
    [_styleDict release];
    [_jsBindingsDict release];
    [super dealloc];
}

- (NSString *)commonUIControllerType {
    return _commonUICtrlType; }

- (NSDictionary *)styleAttributes {
    return _styleDict; }
    
- (void)setStyleAttributes:(NSDictionary *)styleDict {
    [_styleDict removeAllObjects];
    [_styleDict addEntriesFromDictionary:styleDict];
}

- (void)setValue:(id)val forStyleAttribute:(NSString *)attr {
    if (val)
        [_styleDict setObject:val forKey:attr];
    else
        [_styleDict removeObjectForKey:attr];
}

- (NSDictionary *)scriptBindings {
    return _jsBindingsDict; }
    
- (void)setScriptBindings:(NSDictionary *)jsBindings {
    [_jsBindingsDict autorelease];
    _jsBindingsDict = [jsBindings copy];
}



// label methods should be implemented by subclass
- (NSString *)label {
    return nil; }
    
- (void)setLabel:(NSString *)label
{
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag; }


- (NSDictionary *)labelAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize], NSFontAttributeName,
                        nil];
}

@end
