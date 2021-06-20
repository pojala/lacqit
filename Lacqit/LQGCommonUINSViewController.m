//
//  LQGCommonUINSViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUINSViewController.h"
#import "LQSegmentedControl.h"


@implementation LQGCommonUINSViewController

- (void)dealloc
{
    [_subviewCtrls release];
    [super dealloc];
}


// this is an action method for buttons wrapped in a view controller.
- (void)delegatingButtonAction:(id)sender
{
    [[sender window] makeFirstResponder:nil];  // end editing
    
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:nil];
}

// this is an action method for buttons wrapped in a view controller.
- (void)delegatingSegmentedControlAction:(id)sender
{
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        [info setObject:[NSNumber numberWithBool:YES] forKey:@"isMultiButton"];
        
        LXUInteger trackMode = [(LQSegmentedControl *)sender trackingMode];
        NSString *trackModeStr;
        switch (trackMode) {
            default:
            case kLQSegmentSwitchTrackingSelectOne:  trackModeStr = @"one";  break;
            case kLQSegmentSwitchTrackingSelectAny:  trackModeStr = @"any";  break;
            case kLQSegmentSwitchTrackingMomentary:  trackModeStr = @"none";  break;
        }
        [info setObject:trackModeStr forKey:@"selectable"];
        
        LXInteger selSeg = [sender selectedSegment];
        [info setObject:[NSNumber numberWithInt:selSeg] forKey:@"selected"];
        
        if (trackMode == kLQSegmentSwitchTrackingSelectAny) {
            LXInteger n = [sender segmentCount];
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:n];
            LXInteger i;
            for (i = 0; i < n; i++) {
                [arr addObject:[NSNumber numberWithBool:[sender isSelectedForSegment:i]]];
            }
            [info setObject:arr forKey:@"selections"];
        }
    
        [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:info];
    }
}


/* on Mac, LQGCocoaViewController is a superclass of this class, 
   so we don't need to implement any of the view-handling methods here.
*/

- (id)forwardControl {
    return _control; }
    
- (void)setForwardControl:(id)control {
    _control = control; }

    
- (NSArray *)subviewControllers {
    return _subviewCtrls; }

- (void)setSubviewControllers:(NSArray *)arr {
    [_subviewCtrls release];
    _subviewCtrls = [arr retain];
}



// these are provided as a convenience
- (NSString *)stringValue
{
    if ([[self forwardControl] respondsToSelector:@selector(stringValue)]) {
        return [(id)[self forwardControl] stringValue];
    }
    else if ([[self view] respondsToSelector:@selector(stringValue)]) {
        return [(id)[self view] stringValue];
    }
    
    return nil;
}

- (void)setStringValue:(NSString *)str
{
    if ([[self forwardControl] respondsToSelector:@selector(setStringValue:)]) {
        [(id)[self forwardControl] setStringValue:str];
    }
    else if ([[self view] respondsToSelector:@selector(setStringValue:)]) {
        [(id)[self view] setStringValue:str];
    }
}

- (NSString *)label {
    if ([_control respondsToSelector:@selector(label)])
        return [_control label];
    return nil;
}
    
- (void)setLabel:(NSString *)label
{
    if ([_control respondsToSelector:@selector(setLabel:)])
        return [_control setLabel:label];
}



#pragma mark --- generic message forwarding ---

- (BOOL)_respondsToSelectorWithoutForwarding:(SEL)aSelector
{
    return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ( !_control || [self _respondsToSelectorWithoutForwarding:aSelector])
        return [super methodSignatureForSelector:aSelector];
    else
        return [_control methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
 
    if ([_control respondsToSelector:aSelector])
        [invocation invokeWithTarget:_control];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self _respondsToSelectorWithoutForwarding:aSelector])
        return YES;
    else
        return [_control respondsToSelector:aSelector];
}




#if (__LAGOON__)
- (NSView *)view {
    return _view; }

- (void)setView:(NSView *)view {
    [_view autorelease];
    _view = [view retain];
}

// TODO: must implement wrapping of the NSView into a Gtk+ widget
// before this class can work on Lagoon

#endif


@end
