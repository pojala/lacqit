//
//  LQPerformer.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#if !defined(__LAGOON__)
#import <Cocoa/Cocoa.h>
#endif
#import "LQPerformer.h"
#import "LQTimeFunctions.h"


@interface LQPerformerTask : NSObject {
    SEL _action;
    id _arg;
    NSString *_ctx;
    NSTimeInterval _delay;
    NSTimeInterval _initTime;
}

- (id)initWithAction:(SEL)action argument:(id)arg context:(NSString *)ctx delay:(NSTimeInterval)delay;
- (double)creationTime;
- (double)delay;
- (NSString *)context;
- (void)performOn:(id)target;

@end



@interface LQPerformer (PrivateImpl)

- (void)_startTimerWithInfo:(id)userInfo;
- (void)_stopTimer;

@end



@implementation LQPerformer

- (id)init
{
    NSLog(@"*** %s: ERROR: wrong initializer", __func__);
    [self release];
    return nil;
}

- (id)initWithOwner:(id)owner
{
    self = [super init];
    _owner = owner;
    _tasks = [[NSMutableArray arrayWithCapacity:32] retain];
    return self;
}

- (void)dealloc
{
    [self _stopTimer];
    [_tasks release];
    [super dealloc];
}

- (id)owner {
    return _owner; }
    
- (void)performSelector:(SEL)action withObject:(id)arg
        inContext:(NSString *)ctx
        afterDelay:(NSTimeInterval)time
{
    [_tasks addObject:[[[LQPerformerTask alloc] initWithAction:action argument:arg context:ctx delay:time] autorelease]];
    
    //NSLog(@"lqperform: ctx %@, owner %@", ctx, _owner);
    
    if ( !_timer)
        [self _startTimerWithInfo:nil];
}

- (void)cancelTasksForContext:(NSString *)ctx
{
    NSMutableArray *killList = [NSMutableArray arrayWithCapacity:16];
    
    NSEnumerator *taskEnum = [_tasks objectEnumerator];
    LQPerformerTask *task;
    while (task = [taskEnum nextObject]) {
        if ([ctx isEqualToString:[task context]]) {
            [killList addObject:task];
            ///NSLog(@"cancelled task %@ in context %@", task, ctx);
        }
    }
    
    [_tasks removeObjectsInArray:killList];
    
    if ([_tasks count] < 1)
        [self _stopTimer];
}



- (void)_timerFired:(NSTimer *)timer
{
    id userInfo = [timer userInfo];
    id val;
    
    double timeNow = LQReferenceTimeGetCurrent();
    
    NSMutableArray *killList = nil;
    
    NSEnumerator *taskEnum = [_tasks objectEnumerator];
    LQPerformerTask *task;
    while (task = [taskEnum nextObject]) {
        if (timeNow >= [task creationTime] + [task delay]) {
            [task performOn:_owner];
            
            if ( !killList) killList = [NSMutableArray arrayWithCapacity:16];
            [killList addObject:task];
        }
    }
    
    //NSLog(@"%s (%p), %i, %@, %f, %p", __func__, self, [_tasks count], killList, timeNow, [NSThread currentThread]);
    [_tasks removeObjectsInArray:killList];
    
    if ([_tasks count] < 1)
        [self _stopTimer];
}

- (void)_stopTimer
{
    [_timer invalidate];
    [_timer release];
    _timer = nil;
}

- (void)_startTimerWithInfo:(id)userInfo
{
    if (_timer)
        [self _stopTimer];

    _timer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                             target:self
                             selector:@selector(_timerFired:)
                             userInfo:userInfo
                             repeats:YES] retain];
                             
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
        
#if !defined(__LAGOON__)
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSEventTrackingRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSModalPanelRunLoopMode];
#endif

        _startTime = LQReferenceTimeGetCurrent();
}


- (void)abort {
    [self _stopTimer]; }


@end



// ---------------------------------------------------

@implementation LQPerformerTask

- (id)initWithAction:(SEL)action argument:(id)arg context:(NSString *)ctx delay:(NSTimeInterval)delay {
    self = [super init];
    _action = action;
    _arg = arg;
    _ctx = [ctx copy];
    _delay = delay;
    _initTime = LQReferenceTimeGetCurrent();
    return self;
}

- (void)dealloc {
    [_ctx release];
    [super dealloc];
}

- (NSString *)context {
    return _ctx; }
    
- (double)creationTime {
    return _initTime; }
    
- (double)delay {
    return _delay; }

- (void)performOn:(id)target {
    [target performSelector:_action withObject:_arg];
}

@end


