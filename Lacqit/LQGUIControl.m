//
//  LQGUIControl.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIControl.h"


@implementation LQGUIControl

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _name = [@"" retain];
        _dict = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc {
    [_name release];
    [_context release];
    [_dict release];
    [super dealloc];
}

- (NSString *)name {
    return _name; }
    
- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy]; }

- (NSString *)context {
    return _context; }
    
- (void)setContext:(NSString *)str {
    [_context release];
    _context = [str copy]; }


- (id)propertyForKey:(NSString *)key {
    return [_dict objectForKey:key]; }
    
- (void)setProperty:(id)obj forKey:(NSString *)key {
    if (obj) 
        [_dict setObject:obj forKey:key];
    else
        [_dict removeObjectForKey:key];
}


- (id)delegate {
    return _delegate; }
    
- (void)setDelegate:(id)del {
    _delegate = del; }

- (id)target {
    return _target; }
    
- (void)setTarget:(id)obj {
    _target = obj; }

- (SEL)action {
    return _action; }
    
- (void)setAction:(SEL)action {
    _action = action; }

- (NSInteger)tag {
    return _tag; }
    
- (void)setTag:(NSInteger)tag {
    _tag = tag; }


- (void)forwarderAction:(id)sender
{
    [_target performSelector:_action withObject:self];
}


- (void)setImplementationView:(NSView *)view {
    if (view != _implView) {
        _implView = view;
        [self addSubview:view];
    }
}

#pragma mark --- generic message forwarding ---

- (BOOL)_respondsToSelectorWithoutForwarding:(SEL)aSelector
{
    return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([self _respondsToSelectorWithoutForwarding:aSelector])
        return [super methodSignatureForSelector:aSelector];
    else
        return [_implView methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
 
    if ([_implView respondsToSelector:aSelector])
        [invocation invokeWithTarget:_implView];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self _respondsToSelectorWithoutForwarding:aSelector])
        return YES;
    else
        return [_implView respondsToSelector:aSelector];
}

@end
