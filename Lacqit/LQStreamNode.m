//
//  LQStreamNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamNode.h"
#import "LQStreamNode_priv.h"

#ifdef __WIN32__
#import <windows.h>
#endif


NSString *kLQStreamThreadProperty_PollsPerSecond = @"pollsPerSecond";
NSString *kLQStreamThreadProperty_StreamStartReferenceTime = @"streamStartRefTime";
NSString *kLQStreamThreadProperty_WantsFullyRegularRenderSchedule = @"wantsFullyRegularRenderSchedule";


@implementation LQStreamNode

+ (NSString *)packageIdentifier
{
    return [NSString stringWithFormat:@"fi.lacquer.lqstream.%@", NSStringFromClass(self)];
}

+ (BOOL)canBecomePrimaryPresenter
{
    return NO;
}

#pragma mark --- special eval control ---

- (BOOL)wantsEvalIfNotConnectedToPresenter
{
    return NO;
}



// subclasses can override to implement custom fetching / conversion of input arguments
- (NSArray *)scriptEvalArgumentsForOutputIndex:(LXInteger)index
                                    inputLists:(LACArrayListPtr *)inputLists
                                    context:(NSDictionary *)context
{
    LXInteger inpCount = [_inputs count];
    if (inpCount < 1)
        return [NSArray array];
        
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:inpCount];
    LXInteger i;
    for (i = 0; i < inpCount; i++) {
        LACArrayListPtr list = inputLists[i];
        NSArray *a = LACArrayListAsNSArray(list);
        [arr addObject:(a) ? a : [NSArray array]];
    }
    
    [arr addObject:context];
    return arr;
}

- (id)runOnRenderScriptForOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    id result = nil;
    NSError *error = nil;
    id myJSObj = [self jsBridgeInPatchContext];
    
    if (myJSObj) {
        /*
        NSArray *inputNames = nil;
        NSArray *inputVals = [self scriptEvalInputValuesForIndex:index inputLists:inputLists context:context inputNamesPtr:&inputNames];
        
        id inputNamesJSArray = nil;
        if ([inputNames count] > 0) {  // copy into a real JS array (for use of indexOf(), etc.)
            inputNamesJSArray = [[[self owner] jsInterpreter] emptyJSArray];
            [inputNamesJSArray addObjectsFromArray:inputNames];
        }
        
        NSArray *params = (inputVals) ? [NSArray arrayWithObjects:inputVals, (inputNamesJSArray) ? inputNamesJSArray : [NSArray array], nil]
                                      : [NSArray array];
        */
        ///NSLog(@"... %@: inputnames: %@", self, inputNames);
    
        NSString *funcName = @"onRender";
        id func = [myJSObj propertyForKey:funcName];

        if (func && [func respondsToSelector:@selector(isFunction)] && [func isFunction]) {
            NSArray *params = [self scriptEvalArgumentsForOutputIndex:index inputLists:inputLists context:context];
            
            [[self owner] willEnterJSMethodNamed:funcName onNode:self];
        
            result = [func callWithThis:myJSObj parameters:params error:&error];
            
            if (error) {
                ///[self _logRuntimeJSError:error withinFunctionNamed:funcName];
                [[self owner] _logJSError:error type:2];
                result = nil;
            } else {
                //if (result) LXPrintf(".. node %s eval: js result is '%s'\n", [[self name] UTF8String], [[result description] UTF8String]);
            }
            
            [[self owner] didExitJSMethod];
        }
    }
    return result;
}



#pragma mark --- eval utilities ---

- (BOOL)canEvalWithContext:(NSDictionary *)context
{
    if ([[context objectForKey:kLQStreamPatchCtxKey_RenderFailures] count] > 0)
        return NO;
    else
        return YES;
}

- (double)currentTimeInStreamFromEvalContext:(NSDictionary *)context
{
    id timeVal = [context objectForKey:kLQStreamPatchCtxKey_RequestedTimeConstrainedToProjectBase];
    if ( !timeVal) {
        timeVal = [context objectForKey:kLQStreamPatchCtxKey_RequestedTime];
    }
    const BOOL isSingleFrameRequest = (timeVal) ? YES : NO;

    double timeInStream;
    
    if (isSingleFrameRequest) {
        timeInStream = [timeVal doubleValue];
    } else {
        double startTime = [[self owner] streamStartReferenceTime];
        
        double t0 = [[self owner] latestEvalReferenceTime];
        if (t0 <= 0.0) {
            t0 = LQReferenceTimeGetCurrent();
        }
        timeInStream = (startTime > 0.0) ? (t0 - startTime) : 0.0;
    }
    return timeInStream;
}


#pragma mark --- overrides ---

+ (BOOL)usesTransientState {
    return YES; }


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    //LQPrintf("eval stream node: %s\n", [[self name] UTF8String]);
    
    return LACEmptyArrayList;
}

- (LXUInteger)typeOfInputAtIndex:(LXInteger)index
{
    return kLQStreamNodeConnectionType_Image;  ///kLACNodeDefaultConnectionType;
}

- (LXUInteger)typeOfOutputAtIndex:(LXInteger)index
{
    return kLQStreamNodeConnectionType_Image;
}



#pragma mark --- stream control ---

// subclasses should implement if they do preroll on a thread;
// this base implementation just calls the delegate method immediately
- (void)prerollAsyncWithDelegate:(id)del
{
    _prerollDelegate = del;
    [_prerollDelegate streamNodeFinishedPreroll:self];
    _prerollDelegate = nil;
}

- (void)playNow
{
}

- (void)postrollAsync
{
}

- (void)waitForPostrollToFinish
{
}


- (double)sampleScheduleKnownReferenceTime
{
    return _knownSampleTime;
}

- (double)sampleScheduleTimeInterval
{
    return _knownSampleInterval;
}

- (LXUInteger)streamState
{
    [_attrLock lock];
    LXUInteger state = _nodeStreamState;
    [_attrLock unlock];
    return state;
}

- (void)setStreamState:(LXUInteger)state
{
    [_attrLock lock];
    _nodeStreamState = state;
    [_attrLock unlock];
}

- (void)recursivelySetStreamState:(LXUInteger)state
{
    [_attrLock lock];
    _nodeStreamState = state;
    [_attrLock unlock];
    
    NSEnumerator *inpEnum = [_inputs objectEnumerator];
    id inp;
    while (inp = [inpEnum nextObject]) {
        id node = [[inp connectedOutput] owner];
        if (node && [node respondsToSelector:@selector(recursivelySetStreamState:)])
            [node recursivelySetStreamState:state];
    }
}


- (void)invalidateCaches
{
    // subclasses should clean their cached objects here
}


#pragma mark --- worker thread ---

#define DEFAULT_THREAD_POLL_RATE  120.0

- (NSDictionary *)parametersForWorkerThread
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:DEFAULT_THREAD_POLL_RATE], kLQStreamThreadProperty_PollsPerSecond,
                                    nil];
}

- (void)_setThreadMsg:(LXInteger)msg dict:(NSDictionary *)dict
{
    _threadMsg = msg;
    
    if (_threadMsgDict)
        [_threadMsgDict autorelease];
    _threadMsgDict = [dict retain];
}

- (void)startWorkerThread
{
	if (_condLock) { // already running
        [self signalWorkerThreadToExit];

        NSLog(@"%s (%@): thread was already running (this probably indicates an invalid stop previously, maybe due to overlapping play/stop calls)", __func__, self);
    }
		
    _condLock = [[NSConditionLock alloc] initWithCondition:kThreadCond_NoRequest];
    
//#if defined(__COCOTRON__) || (defined(__APPLE__) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5))
    if ([_condLock respondsToSelector:@selector(setName:)])
        [(NSXMLNode *)_condLock setName:[self name]];  // XMLNode provides suitable -setName definition to eliminate warning about multiple methods with same name
//#endif

    ///NSLog(@"%s: %@", __func__, self);
    
    [self _setThreadMsg:kThreadMsg_Proceed dict:nil];
    
    [NSThread detachNewThreadSelector:@selector(_workerThreadMainLoop:)
                        toTarget:self
                        withObject:[[self parametersForWorkerThread] retain]
                        ];
}

- (void)signalWorkerThreadToExit
{
	if ( !_condLock)  // not running
		return;
    
    //NSLog(@"%s: %@", __func__, self);
    
    // ask thread to exit
    //[_condLock lockWhenCondition:kThreadCond_NoRequest];
    [_condLock lock];
    
    [self _setThreadMsg:kThreadMsg_ExitNow dict:nil];
    
    [_condLock unlockWithCondition:kThreadCond_HasRequest];
    
    //NSLog(@"%s: %@  -- finished --", __func__, self);
}

- (void)waitForWorkerThreadToExit
{
	if ( !_condLock)  // not running
		return;

    //NSLog(@"%s: %@", __func__, self);
    
	[_condLock lockWhenCondition:kThreadCond_ThreadHasFinished];
	[_condLock unlock];

    //NSLog(@"%s: %@ -- finished ---", __func__, self);
    
	[_condLock release];
	_condLock = nil;    
}

- (void)stopWorkerThread
{
    [self signalWorkerThreadToExit];
    [self waitForWorkerThreadToExit];
	
    // wait for thread to finish
	///usleep(1000);    
}

// this asks the thread to call its "poll" method now, instead of waiting the regular polling interval
- (void)signalWorkerThreadWithDict:(NSDictionary *)dict
{
    ///NSLog(@"%s: %@", __func__, self);

    //[_condLock lockWhenCondition:kThreadCond_NoRequest];
    [_condLock lock];
    
    [self _setThreadMsg:kThreadMsg_Proceed dict:dict];
    
    [_condLock unlockWithCondition:kThreadCond_HasRequest];
    
    ///NSLog(@"%s: %@  -- finished -- sampleinterval is %f", __func__, self, _knownSampleInterval);
}


#pragma mark --- in thread ---

- (void)didEnterWorkerThread:(id)threadParamsDict
{
}

- (BOOL)handleMessageInWorkerThreadMainLoop:(id)threadParamsDict
{
    // subclasses can override to handle special messages
    return NO;
}

- (void)pollOnWorkerThread:(id)threadParamsDict
{
    double t0 = LQReferenceTimeGetCurrent();
    double streamStartTime = [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
    //LQPrintf("node %p | poll time: %f\n", self, t0-streamStartTime);
}

- (void)willExitWorkerThread:(id)threadParamsDict
{
}


// this method is the main loop for a persistent worker thread
- (void)_workerThreadMainLoop:(id)threadParamsDict
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LXPoolRef lxPool = LXPoolCreateForThread();
    LXInteger n = 0;
    NSString *threadName = [NSString stringWithFormat:@"fi.lacquer.LQStreamNode: '%@'", [self name]];

    //NSLog(@"entered worker thread for node %@: thread %p; thread params dict: %@", self, [NSThread currentThread], threadParamsDict);
    //NSLog(@"entered worker thread for node %@: thread %p", self, [NSThread currentThread]);

#ifdef __WIN32__
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
#endif

#if defined(__APPLE__) && defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED)
    pthread_setname_np([threadName UTF8String]);
#endif

    if ([[NSThread currentThread] respondsToSelector:@selector(setName:)]) {
        [[NSThread currentThread] setName:threadName];
    }
    

    id val = nil;
    const double pollsPerSec = ((val = [threadParamsDict objectForKey:kLQStreamThreadProperty_PollsPerSecond]) != nil) ? [val doubleValue] : 30.0;
    const double pollWaitInterval = 1.0 / pollsPerSec;
    
    [self didEnterWorkerThread:threadParamsDict];

    double lastPollTime = LQReferenceTimeGetCurrent();
    double nextPollTime = (_initialWaitOnCondLock < 0.0001) ? (lastPollTime + pollWaitInterval)
                                                            : (lastPollTime + _initialWaitOnCondLock);

    double streamStartTime = 0.0;  // this is expected to be given in a thread message

    while (1) {        
        ///NSLog(@"...thread %p (%s): looping...", [NSThread currentThread], [threadName UTF8String]);

        // NSDate's reference time may not agree with LQReferenceTime, so compute the difference
        double timeNow = LQReferenceTimeGetCurrent();
        double diff = nextPollTime - timeNow;
        ///NSLog(@"thread %p (%s): going to wait %.3f ms for lock", [NSThread currentThread], [threadName UTF8String], 1000*diff);        
        NSDate *lockWaitDate = [NSDate dateWithTimeIntervalSinceNow:diff];
        
    
        if ([_condLock lockWhenCondition:kThreadCond_HasRequest beforeDate:lockWaitDate]) {
            NSDictionary *msgDict = nil;
            ///NSLog(@"    ##  thread %p (%s): got condlock -- msg is 0x%x\n", [NSThread currentThread], [threadName UTF8String], _threadMsg);
        
            if (_threadMsg == kThreadMsg_ExitNow) {
                [self willExitWorkerThread:threadParamsDict];

                [_condLock unlockWithCondition:kThreadCond_ThreadHasFinished];
                goto exitThread;
            }
            else if ([self handleMessageInWorkerThreadMainLoop:threadParamsDict]) {
                // was handled by subclass - the method implementation must take care of the unlocking!
            }
            else {
                msgDict = [_threadMsgDict autorelease];
                _threadMsgDict = nil;
                [_condLock unlockWithCondition:kThreadCond_NoRequest];
            }
            
            // this is a separately signaled poll
            lastPollTime = LQReferenceTimeGetCurrent();
            
            if (_initialWaitOnCondLock > 0.0) {
                // this is the first poll we're doing.
                // if there's a known sample time+rate specified, we should time the polling to
                // happen just before a known sample is expected
                if (_knownSampleTime > 0.0 && _knownSampleInterval > 0.0) {
                    nextPollTime = _knownSampleTime;
                    while (nextPollTime < lastPollTime)
                        nextPollTime += _knownSampleInterval;
                        
                    ///nextPollTime -= (0.5 / 1000.0);  // 0.5 msec in advance
                } else {
                    nextPollTime = lastPollTime + pollWaitInterval;
                }
                
                _initialWaitOnCondLock = 0.0;
            } else {
                if ((nextPollTime - lastPollTime) < (1.0 / 1000.0)) {
                    nextPollTime += pollWaitInterval;
                }
            }
            
            // msgDict contains the thread message passed for this poll.
            // it may contain a new reference time, or other requests
            if ((val = [msgDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime])) {
                id newThreadParamsDict = [NSMutableDictionary dictionaryWithDictionary:threadParamsDict];
                [newThreadParamsDict setObject:val forKey:kLQStreamThreadProperty_StreamStartReferenceTime];
                
                [threadParamsDict release];
                threadParamsDict = [newThreadParamsDict retain];
                //streamStartTime = [val doubleValue];
                ///NSLog(@"workthread %@ -- got stream start ref time: %f", threadName, streamStartTime);
            }
            if ((val = [msgDict objectForKey:@"invocationToPerformOnThread"])) {
                if ( ![val respondsToSelector:@selector(invoke)] || ![val target]) {
                    NSLog(@"** %@: can't invoke this request on thread: %@ (target is %@)", threadName, val, ([val respondsToSelector:@selector(target)]) ? [val target] : nil);
                } else {
                    [val setArgument:threadParamsDict atIndex:2];
                    [val invoke];
                }
            }
        }
        else {
///            NSLog(@"   thread %p (%@): didn't get lock (waited %.3f ms)", [NSThread currentThread], threadName, 1000*diff);
        
            // did not get lock, so this is just a scheduled poll
            lastPollTime = nextPollTime;
            nextPollTime = lastPollTime + pollWaitInterval;
        }
        
        [self pollOnWorkerThread:threadParamsDict];
        
        LXPoolPurge(lxPool);
        
        double t0 = LQReferenceTimeGetCurrent();
        while ((nextPollTime - t0) < (1.0 / 1000.0)) {
            nextPollTime += pollWaitInterval;
        }

		n++;
		if (n == 4) {  // clean up the thread's top-level autorelease pool every once in a while
            LXPoolPurge(lxPool);
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];
			n = 0;
		}
        
        usleep(1);
    }

exitThread:
    LXPoolRelease(lxPool);
    [pool drain];
    [threadParamsDict release];
    return;
}

@end
