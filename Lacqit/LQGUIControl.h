//
//  LQGUIControl.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
#import "LQAppKitUtils.h"

/*
Cocoa view wrappers with utilities for setting name, creating in a particular context (e.g. kLQUIContext_Floater), etc.

These are used by Conduit nodes with custom views, but can of course be used for any other purpose as needed.

The LQGUIControl superclass implements method forwarding to the actual implementation view.
*/

@interface LQGUIControl : NSView {

    NSString *_name;
    NSString *_context;
    NSInteger _tag;
    
    id _implView;
    
    NSMutableDictionary *_dict;
    id _delegate;
    
    SEL _action;
    id _target;    
}

- (NSString *)name;
- (void)setName:(NSString *)name;

- (NSString *)context;
- (void)setContext:(NSString *)context;

- (id)propertyForKey:(NSString *)key;
- (void)setProperty:(id)obj forKey:(NSString *)key;

- (id)target;
- (void)setTarget:(id)target;

- (SEL)action;
- (void)setAction:(SEL)action;

- (id)delegate;
- (void)setDelegate:(id)del;

- (NSInteger)tag;
- (void)setTag:(NSInteger)tag;

- (void)setImplementationView:(NSView *)view;

- (void)forwarderAction:(id)sender;

@end
