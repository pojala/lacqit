//
//  LQJSEventRoster.h
//  Lacqit
//
//  Created by Pauli Ojala on 26.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LacqJS/LacqJS.h>


@interface LQJSEventRoster : NSObject {

    id _delegate;
    
    NSMutableDictionary *_eventObserversDict;
}

- (id)init;

- (id)delegate;
- (void)setDelegate:(id)del;

// event names are not case-sensitive and implicitly converted to lowercase (e.g. "loadfailed")

- (BOOL)addObserver:(id)observer forEventName:(NSString *)eventName jsCallback:(id)callback;

- (void)removeObserver:(id)observer forEventName:(NSString *)eventName;
- (void)removeObserver:(id)observer;

- (void)notifyObserversOfEventNamed:(NSString *)eventName;

@end


@interface NSObject (LQJSEventRosterDelegate)
- (BOOL)shouldDispatchEventNamed:(NSString *)eventName toObserver:(id)obs;
- (void)didDispatchEventNamed:(NSString *)eventName toObserver:(id)obs error:(NSError *)error;

// values passed to the callback function: this object and arguments
- (id)jsCallbackThisForEventNamed:(NSString *)eventName observer:(id)obs argumentsPtr:(NSArray **)outParams;

@end