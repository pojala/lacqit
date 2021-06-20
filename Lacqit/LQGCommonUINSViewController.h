//
//  LQGCommonUINSViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


// on OS X, this class already inherits from LQGCocoaViewController.
// thus we need to provide an additional level of implementation on Lagoon only.


@interface LQGCommonUINSViewController : LQGCommonUIController {

    // _view is declared in LQGCommonUIController
    
    // when set, unknown selectors are forwarded to this object
    id _control;
    
    // used for horizontal lists created from script
    NSArray *_subviewCtrls;
}


- (NSString *)stringValue;
- (void)setStringValue:(NSString *)str;

- (id)forwardControl;
- (void)setForwardControl:(id)control;

- (NSArray *)subviewControllers;
- (void)setSubviewControllers:(NSArray *)arr;

#if (__LAGOON__)
- (NSView *)view;
- (void)setView:(NSView *)view;
#endif


// this can be set as the action for wrapped Cocoa buttons (sends "kLQGActionContext_ButtonClicked" to the view controller delegate)
- (void)delegatingButtonAction:(id)sender;
- (void)delegatingSegmentedControlAction:(id)sender;

@end
