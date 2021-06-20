//
//  LQJSEventRoster.m
//  Lacqit
//
//  Created by Pauli Ojala on 26.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSEventRoster.h"
#import <Lacefx/LXBasicTypes.h>


@implementation LQJSEventRoster

- (id)init
{
    self = [super init];
    _eventObserversDict = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc
{
    [_eventObserversDict release];
    [super dealloc];
}

- (id)delegate {
    return _delegate; }
    
- (void)setDelegate:(id)del {
    _delegate = del; }
    
    
- (LXInteger)_indexOfObserver:(id)obs inArray:(id)obsArray
{
    LXInteger n = [obsArray count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        id o = [obsArray objectAtIndex:i];
        if ([o objectForKey:@"observer"] == obs)
            return i;
    }
    return NSNotFound;
}

- (BOOL)addObserver:(id)observer forEventName:(NSString *)eventName jsCallback:(id)callback
{
    if ( !observer || !eventName) return NO;
    
    eventName = [eventName lowercaseString];
    
    NSMutableArray *obsArray = [_eventObserversDict objectForKey:eventName];
    if ( !obsArray) {
        obsArray = [[NSMutableArray alloc] init];
        [_eventObserversDict setObject:obsArray forKey:eventName];
    }
    
    id dict = [NSDictionary dictionaryWithObjectsAndKeys:observer, @"observer", callback, @"jsCallback", nil];
        
    LXInteger index = [self _indexOfObserver:observer inArray:obsArray];
    if (index == NSNotFound) {
        [obsArray addObject:dict];
    } else {
        [obsArray replaceObjectAtIndex:index withObject:dict];
    }
    return YES;
}

- (void)removeObserver:(id)observer forEventName:(NSString *)eventName
{
    eventName = [eventName lowercaseString];
    
    NSMutableArray *obsArray = [_eventObserversDict objectForKey:eventName];

    LXInteger index = [self _indexOfObserver:observer inArray:obsArray];
    if (index != NSNotFound) {
        NSLog(@"... removing observer: %@", [obsArray objectAtIndex:index]);
        [obsArray removeObjectAtIndex:index];
    }
}

- (void)removeObserver:(id)observer
{
    NSEnumerator *keyEnum = [_eventObserversDict keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        [self removeObserver:observer forEventName:key];
    }
}

- (void)notifyObserversOfEventNamed:(NSString *)eventName
{
    eventName = [eventName lowercaseString];
    
    NSMutableArray *obsArray = [_eventObserversDict objectForKey:eventName];
    LXUInteger n = [obsArray count];
    if (n < 1) return;    
    
    LXUInteger i;
    for (i = 0; i < n; i++) {
        id o = [obsArray objectAtIndex:i];
        id obs = [o objectForKey:@"observer"];
        id callback = [o objectForKey:@"jsCallback"];
        
        BOOL ok = YES;
        if ([_delegate respondsToSelector:@selector(shouldDispatchEventNamed:toObserver:)]) {
            ok = [_delegate shouldDispatchEventNamed:eventName toObserver:obs];
        }
        if (ok) {
            id this = nil;
            NSArray *args = [NSArray array];
            
            if ([_delegate respondsToSelector:@selector(jsCallbackThisForEventNamed:observer:argumentsPtr:)]) {
                this = [_delegate jsCallbackThisForEventNamed:eventName observer:obs argumentsPtr:&args];
            }
            
            NSError *error = nil;
            [callback callWithThis:this parameters:args error:&error];
            
            if ([_delegate respondsToSelector:@selector(didDispatchEventNamed:toObserver:error:)]) {
                [_delegate didDispatchEventNamed:eventName toObserver:obs error:error];
            }
        }
    }
}

@end
