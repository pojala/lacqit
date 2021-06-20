//
//  LQThreadedWorker.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2012.
//  Copyright 2012 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacqit/LQTimeFunctions.h>


@interface LQThreadedWorker : NSObject {

    NSString        *_name;

	NSConditionLock *_condLock;
    NSInteger       _threadMsg;
    id              _threadMsgArg;
}

- (id)initWithName:(NSString *)name threadArgs:(NSDictionary *)threadArgs;

- (NSString *)name;

- (BOOL)isRunning;

- (void)signalWorkerThreadToExit;
- (void)waitForWorkerThreadToExit;

- (void)performSelectorOnThread:(SEL)sel withObject:(id)arg target:(id)target;

- (void)waitForSelectorOnThreadToComplete;


// for subclasses
- (BOOL)idleOnThread:(id)threadArgs;

- (id)threadWillStart:(id)threadArgs;
- (void)threadHasExited:(id)threadArgs;

@end
