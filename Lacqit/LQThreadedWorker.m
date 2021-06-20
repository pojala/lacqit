//
//  LQThreadedWorker.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2012.
//  Copyright 2012 Lacquer oy/ltd. All rights reserved.
//

#import "LQThreadedWorker.h"


enum {
    kThreadCond_NoRequest = 0,
    kThreadCond_HasRequest = 1,
    kThreadCond_ThreadHasStarted = 2,
    kThreadCond_ThreadHasFinished = 0x10,
};
enum {
    kThreadMsg_Proceed = 0,
    kThreadMsg_PerformSelector = 0x20,
    kThreadMsg_ExitNow = 0x100,
};


@implementation LQThreadedWorker

- (id)initWithName:(NSString *)name threadArgs:(NSDictionary *)dict
{
    _name = [name retain];

    _condLock = [[NSConditionLock alloc] initWithCondition:kThreadCond_NoRequest];
    _threadMsg = kThreadMsg_Proceed;
    
    if ( !dict) dict = [NSDictionary dictionary];
    
    dict = [self threadWillStart:dict];
    
    [NSThread detachNewThreadSelector:@selector(threadMainLoop:) toTarget:self withObject:[[dict mutableCopy] autorelease]];
    
    [_condLock lockWhenCondition:kThreadCond_ThreadHasStarted];
    [_condLock unlockWithCondition:kThreadCond_NoRequest];
    
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s, %p: '%@'", __func__, self, [self uniqueProcessName]);

    if (_condLock) {
        [self signalWorkerThreadToExit];
        [self waitForWorkerThreadToExit];
    }

    [super dealloc];
}

- (NSString *)name {
    return _name;
}

- (void)signalWorkerThreadToExit
{
    [_condLock lock];
    NSUInteger cond = [_condLock condition];
    if (cond == kThreadCond_ThreadHasFinished) {
        [_condLock unlockWithCondition:kThreadCond_ThreadHasFinished];
    } else {
        _threadMsg = kThreadMsg_ExitNow;
        [_condLock unlockWithCondition:kThreadCond_HasRequest];
    }
}

- (void)waitForWorkerThreadToExit
{
	if ( !_condLock) return;

	[_condLock lockWhenCondition:kThreadCond_ThreadHasFinished];
	[_condLock unlock];
    
	[_condLock release];
	_condLock = nil;
}

- (id)threadWillStart:(id)threadArgs
{
    return threadArgs; 
}

- (void)threadHasExited:(id)threadArgs
{
    [self waitForWorkerThreadToExit];
}

- (BOOL)isRunning
{
    return (_condLock) ? YES : NO;
}

- (BOOL)_waitUntilConditionIsNoRequestAndLock
{
    do {
        [_condLock lock];
        NSInteger cond = [_condLock condition];
        if (cond == kThreadCond_ThreadHasFinished) {
            [_condLock unlock];
            return NO; // --
        } else if (cond == kThreadCond_NoRequest) {
            break;
        } else {
            [_condLock unlock];
            usleep(500);
        }
    } while (1);
    
    return YES;
}

- (void)performSelectorOnThread:(SEL)sel withObject:(id)arg target:(id)target
{
    if ( !sel || !target) return;
    if ( !_condLock) return;
    
    if ( ![self _waitUntilConditionIsNoRequestAndLock]) return;
    
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[target methodSignatureForSelector:sel]];
    [inv setTarget:target];
    [inv setSelector:sel];
    
    if (arg) {
        [arg retain];
        [inv setArgument:&arg atIndex:2];
    }
    
    _threadMsg = kThreadMsg_PerformSelector;
    _threadMsgArg = [inv retain];
    
    [_condLock unlockWithCondition:kThreadCond_HasRequest];
}

- (void)waitForSelectorOnThreadToComplete
{
	if ( !_condLock) return;

	if ( ![self _waitUntilConditionIsNoRequestAndLock]) return;
	[_condLock unlock];
}


#pragma mark --- methods on thread ---

- (BOOL)idleOnThread:(id)threadArgs
{
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0/1000.0]];
    return YES;
}

- (void)threadMainLoop:(id)threadDict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [threadDict retain];
    
    if (_name) [[NSThread currentThread] setName:_name];
    
    //pthread_setname_np([threadName UTF8String]);
    /// ^^ if needs to compile for pre-10.6 SDK, this could be looked up dynamically
    
    [_condLock lock];
    [_condLock unlockWithCondition:kThreadCond_ThreadHasStarted];

    BOOL doIdle = YES;
    BOOL doExit = NO;
    BOOL isUnexpectedExit = NO;
    
    while ( !doExit) {
        NSInteger threadMsg = 0;
        NSInvocation *inv = nil;
        
        if ([_condLock tryLockWhenCondition:kThreadCond_HasRequest]) {
            NSInteger unlockCondition = kThreadCond_NoRequest;
            
            threadMsg = _threadMsg;
            ///NSLog(@"... child process thread msg %i", threadMsg);
            
            switch (threadMsg) {
                case kThreadMsg_ExitNow:
                    doExit = YES;
                    unlockCondition = kThreadCond_ThreadHasFinished;
                    break;
                    
                case kThreadMsg_PerformSelector:
                    inv = [_threadMsgArg autorelease];
                    _threadMsgArg = nil;
                    
                    if (inv) {
                        // perform the given selector now
                        [inv invoke];
                        // the argument was retained when -performSelector.. was called, so release it now
                        id arg = nil;
                        [inv getArgument:&arg atIndex:2];
                        [arg release];
                    }
                    break;
            }
            [_condLock unlockWithCondition:unlockCondition];
        }
        
        if ( !doExit) {
            if (doIdle && ![self idleOnThread:threadDict]) {
                doExit = YES;
                isUnexpectedExit = YES;
            }
        }
        
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    
    if (isUnexpectedExit) {
        [_condLock lock];
        [_condLock unlockWithCondition:kThreadCond_ThreadHasFinished];
        
        [self performSelectorOnMainThread:@selector(threadHasExited:) withObject:threadDict waitUntilDone:NO];        
    }
    
    [threadDict release];
    [pool drain];
}

@end
