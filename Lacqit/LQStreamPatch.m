//
//  LQStreamPatch.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamPatch.h"
#import <Lacefx/LXRandomGen.h>
#import <Lacefx/LXPlatform.h>
#import "LQStreamNode_priv.h"
#import "LQXSurfacePool.h"
#import "LQLXSurface.h"
#import "LQNSValueAdditions.h"
#import "LQLXBasicFunctions.h"
#import "LQBufferingStreamNode.h"

#import "LQJSBridge_StreamPatch.h"
#import "LQJSBridge_MutableByteBuffer.h"
#import "LQJSBridge_Color.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQJSBridge_CurveList.h"
#import "LQJSBridge_LXTransform.h"
#import "LQJSBridge_LXShader.h"
#import "LQJSBridge_LXAccumulator.h"
#import "LQJSBridge_LXSurface.h"
#import "LQJSBridge_JSON.h"
#import "LQJSBridge_System.h"
#import "LQJSBridge_Image.h"


NSString * const kLQStreamPatchCtxKey_RequestedTime = @"requestedTimeInStream";
NSString * const kLQStreamPatchCtxKey_RequestedTimeConstrainedToProjectBase = @"requestedTimeConstrainedToProjectBase";
NSString * const kLQStreamPatchCtxKey_RequestedTimeFrameIncrement = @"requestedTimeFrameIncrement";
NSString * const kLQStreamPatchCtxKey_RenderFailures = @"renderFailures";



NSString *NSStringFromLQStreamState(LQStreamState state)
{
    switch (state) {
        case kLQStreamState_Idle:        return @"idle";
        case kLQStreamState_Waiting:     return @"waiting";
        case kLQStreamState_Prerolled:   return @"prerolled";
        case kLQStreamState_Paused:      return @"paused";
        case kLQStreamState_Active:      return @"active";
    }
    return [NSString stringWithFormat:@"* invalid stream state: %ld *", (long)state];
}


@interface LACMutablePatch (PrivateImpl)
- (void)_notifyAboutModifiedNodes:(NSSet *)nodeSet contextInfo:(NSDictionary *)ctx;
- (void)_recreateJSSandbox;
@end

@interface LQStreamPatch (PrivateSurfaceManagement)
- (void)_cleanupSurfacesRequestedFromPoolWithinEval;
@end

@interface LQStreamPatch (PrivateTimers)
- (void)_invalidateJSTimer:(NSTimer *)timer;
@end



#define ENTERLOCK   [_streamLock lock];
#define EXITLOCK    [_streamLock unlock];
#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();




@implementation LQStreamPatch

+ (void)initialize
{
    if (self == [LQStreamPatch class]) {
        LXRdSeed();
    }
}

static id g_jsCreationDelegate = nil;

+ (void)setJSCreationDelegate:(id)del {
    g_jsCreationDelegate = del;
}

- (void)_setInitialPatchState
{
    if ( !LXPlatformHWSupportsFilteringForFloatTextures()) {  // added 2011.01.13
        [self setPrefersRenderSpeedToPrecision:YES];
    }
    if ( !_infoLock) {
        _infoLock = [[NSLock alloc] init];
    }
}

- (id)initWithSurfacePool:(LQXSurfacePool *)surfacePool
{
    return [self initWithSurfacePool:surfacePool shareJSContainer:nil];
}

- (id)initWithSurfacePool:(LQXSurfacePool *)surfacePool
         shareJSContainer:(LQJSContainer *)shareJSContainer
{
    self = [super init];
    if (self) {
        _streamLock = [[NSRecursiveLock alloc] init];
        if ([_streamLock respondsToSelector:@selector(setName:)]) {
            [(NSImage *)_streamLock setName:[NSString stringWithFormat:@"owned by streamPatch %p", self]];
        }
        
        if ( !surfacePool) {
            surfacePool = [[[LQXSurfacePool alloc] init] autorelease];
            [surfacePool setName:[NSString stringWithFormat:@"owned by %@ '%@'", [self class], [self name]]];
        }
        
        _surfacePool = [surfacePool retain];

        [self _setInitialPatchState];
        
        _sharedJSContainer = (shareJSContainer != nil);
        if (_sharedJSContainer) {
            _jsSandbox = [shareJSContainer retain];
        } else {
            [self _recreateJSSandbox];
        }
    }
    return self;
}

- (id)init
{
    return [self initWithSurfacePool:nil];
}

- (void)_clearAllJSTimers
{
    NSEnumerator *timerEnum = [_jsIntervalTimers objectEnumerator];
    id timer;
    while (timer = [timerEnum nextObject]) {
        [self _invalidateJSTimer:timer];
    }    
}

- (void)containingProjectWillBeReleased:(id)proj
{
    if (_sharedJSContainer) {
        [_jsSandbox release], _jsSandbox = nil;
    } else {
        [self _clearAllJSTimers];
        [_jsSandbox clearAllState];
    }

    [self _cleanupSurfacesRequestedFromPoolWithinEval];
    
    [_surfacePool purgePool];
}

- (void)dealloc
{
    ///NSLog(@"%s: %@ (jsSandbox %@; retc %i)", __func__, self, _jsSandbox, [_jsSandbox retainCount]);

    [self _clearAllJSTimers];
    [_jsIntervalTimers release];
    _jsIntervalTimers = nil;

    [self _cleanupSurfacesRequestedFromPoolWithinEval];
    [_surfacesFromPoolWithinEval release];

    [_streamLock release];
    [_surfacePool release];
    
    if (_sharedJSContainer) {
        [_jsSandbox release], _jsSandbox = nil;
    } else {
        [_jsObj_stream release];
        [_jsObj_app release];
        [_jsObj_sysBridge release];
        
        // HACK -- silly workaround for the case where there are bridge objects
        // in the Cocoa autorelease pool that still contain JS object references to our context:
        // delaying the release of the interpreter environment hopefully allows those objects
        // to be released first...
        [_jsSandbox clearAllState];
        [_jsSandbox performSelector:@selector(release)
                         withObject:nil
                         afterDelay:1.0];
        _jsSandbox = nil;
    }
    
    [super dealloc];
}


#pragma mark --- overrides ---

static LXRdStatePtr s_rdState = NULL;
static LXMutex s_rdStateMutex;

- (LXInteger)_availableNodeTagWith:(LXInteger)tag
{
    // 32-bit range really should suffice (4 billion nodes in a single tree?). leaving some values above and below range
    // in case they need to be appointed to some special nodes (something like Conduit Live's AuxOut single instance?)
    const NSInteger tag_min = 0x1000;
    const NSInteger tag_max = INT_MAX - 0xfff;
    
    if ( !s_rdState) {
        s_rdState = LXRdStateCreateSeeded();
        LXMutexInit(&s_rdStateMutex);
    }

    LXMutexLock(&s_rdStateMutex);
    
    if (tag < tag_min || tag > tag_max)
        tag = LXRdUniform_s_i32(s_rdState, tag_min, tag_max); 

    NSInteger n = [_nodes count];
    NSInteger i = n;
    NSInteger attempts = 1;
    while (i > 0) {
        i--;
        LACNode *node = [_nodes objectAtIndex:i];
        if ([node tag] == tag) {
            tag = LXRdUniform_s_i32(s_rdState, tag_min, tag_max);
            attempts++;
            i = n;
            if (attempts > 10000) // something's wrong
                break;
        }
    }
    
    LXMutexUnlock(&s_rdStateMutex);
    
    return tag;
}

- (void)_willAddNode:(id)node  // private method in LACMutablePatch
{
    [node setTag:[self _availableNodeTagWith:[node tag]]];
}

- (void)addNode:(id)node
{
    [super addNode:node];
    if ([node owner] == self) {
        if ( !_primaryPresenter && [[node class] respondsToSelector:@selector(canBecomePrimaryPresenter)] && [[node class] canBecomePrimaryPresenter]) {
            _primaryPresenter = node;
            
            [self _notifyAboutModifiedNodes:[NSSet setWithObject:node] contextInfo:nil];
        }
    }
}

- (void)deleteNode:(id)node
{
    if (node == _primaryPresenter) {
        _primaryPresenter = nil;
    }
    if ([node respondsToSelector:@selector(wantsJSBridgeInPatchContext)] && [[node class] wantsJSBridgeInPatchContext]) {
        NSString *tagVarName = [self _tagHashForNode:node];
        ///NSLog(@"..clearing out js object for '%@' (%@)", tagVarName, [[self streamJSThis] valueForKey:tagVarName]);
        [[self streamJSThis] setValue:nil forKey:tagVarName];
    }
    [super deleteNode:node];
}

- (NSString *)_tagHashForNode:(id)node
{
    LXInteger tag = [node tag];
    NSAssert2(tag != 0, @"node has zero tag: patch %@, node %@", self, node);
    return [NSString stringWithFormat:@"node_%ld", (long)tag];
}


#pragma mark --- stream ---

- (LQXSurfacePool *)surfacePool {
    return _surfacePool; }


- (BOOL)lockStreamBeforeIntervalSinceNow:(double)intv
{
    //NSLog(@"%s", __func__);
    BOOL didLock = [_streamLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:intv]];
    if (didLock) {
#ifdef __APPLE__
        NSString *threadName = [[NSThread currentThread] name];
        if ([threadName length] < 1) {
            long threadId = (long)pthread_mach_thread_np(pthread_self());
            threadName = [NSString stringWithFormat:@"thread:%x", (int)threadId];
        }
        //NSLog(@"... did lock, thread is '%@'", threadName);
        [self setLockHolderName:[NSString stringWithFormat:@"(thread %@)", threadName]];
#endif
    }
    return didLock;
}

- (void)unlockStream {
    EXITLOCK
    //[self setLockHolderName:nil];
    //NSLog(@"%s", __func__);
}

- (NSString *)lockHolderName {
    [_infoLock lock];
    NSString *name = [_lockHolderName retain];
    [_infoLock unlock];
    return [name autorelease];
}

- (void)setLockHolderName:(NSString *)str {
    [_infoLock lock];
    [_lockHolderName release];
    _lockHolderName = [str copy];
    [_infoLock unlock];
}


#define DEFAULTLOCKTIMEOUT 1.5

- (BOOL)enterUIAction {
    return [_streamLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:DEFAULTLOCKTIMEOUT]];
}

- (void)exitUIAction {
    EXITLOCK
}


- (void)_collectNodesFromInput:(LACInput *)inp intoArray:(NSMutableArray *)arr
{
    id node = [[inp connectedOutput] owner];
    
    if (node) {
        NSEnumerator *inpEnum = [[node inputs] objectEnumerator];
        id theInp;
        while (theInp = [inpEnum nextObject]) {
            [self _collectNodesFromInput:theInp intoArray:arr];
        }

        if ( ![arr containsObject:node]) [arr addObject:node];
    }
}

- (NSArray *)collectSortedNodesFromNode:(id)node
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:32];
    
    NSEnumerator *inpEnum = [[node inputs] objectEnumerator];
    LACInput *inp;
    while (inp = [inpEnum nextObject]) {
        [self _collectNodesFromInput:inp intoArray:arr];
    }
    
    if ( ![arr containsObject:node]) [arr addObject:node];
    
    [arr sortUsingSelector:@selector(compareSortLevelTo:)];
    return arr;
}

- (NSArray *)nodesWithPrimaryPresenterConnection
{
    return (_primaryPresenter) ? [self collectSortedNodesFromNode:_primaryPresenter] : _nodes;
}

// an util for finding the first movie source
- (id)findFirstPresentableNodeOfClass:(Class)cls
{
    NSArray *activeNodes = [self nodesWithPrimaryPresenterConnection];
    NSEnumerator *nodeEnum = [activeNodes objectEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if ([node isKindOfClass:cls])
            return node;
    }
    return nil;
}


enum {
    kLQStreamPrerollDefault = 0,
    kLQStreamPrerollPlayWhenReady = 1,
    kLQStreamPrerollFailed = 0x100
};


- (void)streamNode:(LQStreamNode *)node prerollFailedWithError:(NSError *)err
{
    _prerollWaitState = kLQStreamPrerollFailed;
}

- (void)streamNodeFinishedPreroll:(LQStreamNode *)node
{
    ENTERLOCK

    [_prerollWaitList removeObject:node];
    
    ///NSLog(@"%s (%@): waitlist count %i, state %i, node that finished is %@; waitlist: %@", __func__, self, [_prerollWaitList count], _prerollWaitState, node, _prerollWaitList);
    
    if ([_prerollWaitList count] < 1) {
        [_prerollWaitList release];
        _prerollWaitList = nil;
        
        _streamState = kLQStreamState_Prerolled;
        
        LXUInteger waitState = _prerollWaitState;
        _prerollWaitState = 0;
        
        switch (waitState) {
            case kLQStreamPrerollPlayWhenReady:
                [self play];
                break;
            case kLQStreamPrerollFailed:
                [self stop];
                break;
        }
    }
    
    EXITLOCK
}

- (void)prerollAndPlay
{
    ENTERLOCK
    if (_streamState != kLQStreamState_Idle) {
        NSLog(@"*** %s: can't proceed, stream is not ready (%@)", __func__, NSStringFromLQStreamState(_streamState));
        EXITLOCK
        return;
    }

    ///NSLog(@"---- %s ---- ", __func__);
    _prerollWaitState = kLQStreamPrerollPlayWhenReady;
    [self preroll];
    
    EXITLOCK
}

- (void)_publishPrimaryPresentersOutputsInPatchAndSort
{
    // publish the primary presenter's connected outputs
    // so that nodes can be sorted correctly based on their distance from the presenter
    if (_primaryPresenter) {
        LXInteger inpCount = [[_primaryPresenter inputs] count];
        LXInteger i;
        for (i = 0; i < inpCount; i++) {
            id presInp = [[_primaryPresenter inputs] objectAtIndex:i];
            /*LACOutput *renderOutput = [presInp connectedOutput];
            [self setOutputBinding:renderOutput forKey:[NSString stringWithFormat:@"__streamPrimaryPresenter.%i__", (int)i]];
            */
            [self setOutputBinding:presInp forKey:[NSString stringWithFormat:@"__streamPrimaryPresenter.%i__", (int)i]];
        }
    }

    [self sortNodesRecursivelyFromPublishedOutputs];
}


- (void)preroll
{
    ENTERLOCK
    if (_streamState != kLQStreamState_Idle) {
        NSLog(@"*** %s: can't proceed, stream is not ready (%@)", __func__, NSStringFromLQStreamState(_streamState));
        EXITLOCK
        return;
    }

    _streamState = kLQStreamState_Waiting;
    //NSLog(@"---- preroll entered (%p, stream now waiting)", self);

    if (_prerollWaitList)
        [_prerollWaitList release];
    _prerollWaitList = [[NSMutableArray arrayWithCapacity:32] retain];

    [self _publishPrimaryPresentersOutputsInPatchAndSort];

    
    // disable all
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    id node;    
    while (node = [nodeEnum nextObject]) {
        [node setStreamState:kLQStreamState_Idle];
    }
    
    // now collect the active nodes
    NSMutableArray *activeNodes = [NSMutableArray array];
    if (_primaryPresenter)
        [activeNodes addObjectsFromArray:[self collectSortedNodesFromNode:_primaryPresenter]];
        
    NSEnumerator *keysEnum = [[[[[self publishedOutputInterface] allKeys] copy] autorelease] objectEnumerator];
    NSString *key;
    while (key = [keysEnum nextObject]) {
        id node = [[self objectForOutputBinding:key] owner];
        if (node && ![activeNodes containsObject:node]) {
            NSArray *nodes = [self collectSortedNodesFromNode:node];
            ///NSLog(@"... preroll: adding active nodes for published output node '%@', node count %i", [node name], [nodes count]);
            NSEnumerator *nenum = [nodes objectEnumerator];
            id anode;
            while (anode = [nenum nextObject]) {
                if ( ![activeNodes containsObject:anode])
                    [activeNodes addObject:anode];
            }
        }
    }
    [activeNodes sortUsingSelector:@selector(compareSortLevelTo:)];
    
    
    _activeStreamNodes = [activeNodes retain];

    [_prerollWaitList addObjectsFromArray:activeNodes];

    nodeEnum = [activeNodes objectEnumerator];
    while (node = [nodeEnum nextObject]) {
        [node setStreamState:kLQStreamState_Waiting];
        //NSLog(@"going to preroll node: %@", node);
        
        [node prerollAsyncWithDelegate:self];
    }
    //NSLog(@"---- preroll done, will wait for completion (%p, streamstate %@, waitlist count %i: %@) ---- ", self, NSStringFromLQStreamState(_streamState), (int)∫[_prerollWaitList count], _prerollWaitList);
    EXITLOCK
}

- (void)play
{
    ENTERLOCK
    if (_streamState == kLQStreamState_Active) {
        EXITLOCK
        return;
    }
    if (_streamState != kLQStreamState_Prerolled) {
        NSLog(@"*** %s: can't proceed, stream is not prerolled (%@)", __func__, NSStringFromLQStreamState(_streamState));
        EXITLOCK
        return;
    }

    ///NSLog(@"---- %s: syncmode is: %@ ---- ", __func__, (_syncMode == kLQStreamIsJamSynced) ? @"jam sync" : @"free run");
    
    if (_prerollWaitList) {
        NSLog(@"** %s: still waiting for preroll to finish (%@, listcount %ld)", __func__, self, (long)[_prerollWaitList count]);
        EXITLOCK
        return;
    }

    // activate nodes and do one evaluation now
    NSEnumerator *nodeEnum = [_activeStreamNodes objectEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        [node setStreamState:kLQStreamState_Active];
    }

    _streamState = kLQStreamState_Active;

    _streamStartTime = LQReferenceTimeGetCurrent();
    _streamStartTime_wallClock_nsDate = [[NSDate date] timeIntervalSinceReferenceDate];
    
    // send play message to all active nodes
    [_activeStreamNodes makeObjectsPerformSelector:@selector(playNow)];

    // eval now
    LACOutput *renderOutput = [[_primaryPresenter primeInput] connectedOutput];
    NSDictionary *evalCtx = nil;
    #pragma unused (evalCtx)
    LACArrayListPtr resultList = [self evaluateOutput:renderOutput withContext:evalCtx];
    LACArrayListRelease(resultList);

    
    ///NSLog(@"---- play (%p, stream now active)", self);

    // setup JS state
    //id jsThis = [_jsSandbox jsConstructedThis];
    //id timeVal = [NSNumber numberWithDouble:_streamStartTime];
    //[jsThis setValue:timeVal forKey:@"startRefTime"];
    //[jsThis setValue:timeVal forKey:@"currentRefTime"];
    
    /*
    nodeEnum = [_activeStreamNodes objectEnumerator];
    while (node = [nodeEnum nextObject]) {
        ////NSLog(@"--- going to play: %@", node);
        [node playNow];
    }*/
    EXITLOCK
}

- (void)_stopNow
{
    ///NSLog(@"####### %s - getting lock #######", __func__);
    ENTERLOCK
    if (_streamState == kLQStreamState_Idle) {
        EXITLOCK
        return;
    }
    else if (_streamState != kLQStreamState_Active && _streamState != kLQStreamState_Prerolled) {
        NSLog(@"*** %s: can't proceed, stream state is not valid (%@)", __func__, NSStringFromLQStreamState(_streamState));
        if (_streamState == kLQStreamState_Waiting) {
            NSLog(@" ... preroll wait list is: %@", _prerollWaitList);
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"stop", @"methodName", nil];
            if ([_prerollWaitList count] > 0) [userInfo setObject:[[_prerollWaitList copy] autorelease] forKey:@"prerollWaitList"];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LQStreamPatchIsStuckNotification"
                                            object:self
											userInfo:userInfo];
            
        }
        EXITLOCK
        return;
    }

    ///NSLog(@"####### %s - with lock #######", __func__);
    
    _streamState = kLQStreamState_Waiting;
    ///NSLog(@"---- stop started (%p, stream now waiting)", self);
    EXITLOCK
    
    LXInteger nodeCount = [_nodes count];
    LXInteger i;
    for (i = 0; i < nodeCount; i++) {
        id node = [_nodes objectAtIndex:i];
        [node setStreamState:kLQStreamState_Idle];
        [node postrollAsync];
    }
    
    ///NSLog(@"---- postrolled, now waiting for finish (%p)", self);

    _streamStartTime = 0.0;
    _streamStartTime_wallClock_nsDate = 0.0;
    
    // clear output bindings used during playback
    NSEnumerator *keysEnum = [[[[[self publishedOutputInterface] allKeys] copy] autorelease] objectEnumerator];
    NSString *key;
    while (key = [keysEnum nextObject]) {
        if ([key hasPrefix:@"__streamPrimaryPresenter"]) {
            [self setOutputBinding:nil forKey:key];
        }
    }


    for (i = 0; i < nodeCount; i++) {
        id node = [_nodes objectAtIndex:i];
        [node waitForPostrollToFinish];
        ///NSLog(@"   --- postroll done, %i / %i:  node '%@'", i, nodeCount, [node name]);
    }
    
    ENTERLOCK
    _streamState = kLQStreamState_Idle;
    
    ///NSLog(@"---- stop finished (%p, stream now idle)", self);
    
    [_activeStreamNodes release];
    _activeStreamNodes = nil;
    EXITLOCK
}

- (void)_tryStop
{
    double maxWaitTime = 1.5;  // seconds
    double iterTime = 0.05;
    LXInteger i;
    for (i = 0; i*iterTime < maxWaitTime; i++) {
        ENTERLOCK
        LXUInteger state = _streamState;
        EXITLOCK
        
        if (state == kLQStreamState_Waiting) {
            NSLog(@"stop stream: still waiting for nodes...");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:iterTime]];
        } else {
            break;
        }
    }
    [self _stopNow];
}

- (void)stop
{
    [self _tryStop];
}

- (void)rewind
{
    ENTERLOCK
    if (_streamState != kLQStreamState_Active) {
        NSLog(@"*** %s: can't proceed, stream is not active (%@)", __func__, NSStringFromLQStreamState(_streamState));
        EXITLOCK
        return;
    }
    
    _streamStartTime = LQReferenceTimeGetCurrent();
    _streamStartTime_wallClock_nsDate = [[NSDate date] timeIntervalSinceReferenceDate];
    
    NSEnumerator *nodeEnum = [_activeStreamNodes objectEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if ([node respondsToSelector:@selector(rewind)]) {
            [node rewind];
        }
    }    
    EXITLOCK
}

- (void)windToTimeInStream:(double)t
{
    ENTERLOCK
    if (_streamState != kLQStreamState_Active) {
        ///NSLog(@"*** %s: can't proceed, stream is not active (%@)", __func__, NSStringFromLQStreamState(_streamState));
        EXITLOCK
        return;
    }
    
    _streamStartTime = LQReferenceTimeGetCurrent() - t;
    _streamStartTime_wallClock_nsDate = [[NSDate date] timeIntervalSinceReferenceDate] - t;
    
    NSEnumerator *nodeEnum = [_activeStreamNodes objectEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if ([node respondsToSelector:@selector(windToTimeInStream:)]) {
            [node windToTimeInStream:t];
        }
    }    
    EXITLOCK
}

- (double)inTimeInStream {
    return _inTime; }

- (void)setInTimeInStream:(double)t {
    _inTime = t;
}

- (double)streamStartReferenceTime {
    return _streamStartTime;
}

- (NSDate *)streamStartTimeAsWallClockDate {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:_streamStartTime_wallClock_nsDate];
}

- (double)latestEvalReferenceTime {
    return _latestEvalTime;
}

- (LXUInteger)streamState {
    return _streamState;
}


- (id)primaryPresenter {
    return _primaryPresenter; }

- (void)setPrimaryPresenter:(id)node {
    if ( ![_nodes containsObject:node]) {
        NSLog(@"** %s (%@): node is not in this patch (%@)", __func__, self, node);
    } else {
        _primaryPresenter = node;
    }
}

- (LQStreamPatchSyncMode)streamSyncMode {
    return _syncMode; }
    
- (void)setStreamSyncMode:(LQStreamPatchSyncMode)syncMode {
    _syncMode = syncMode;
}

- (BOOL)isFixedTimeline {
    return _isTimeline; }
    
- (void)setIsFixedTimeline:(BOOL)f {
    _isTimeline = f;
    
    if (f) {
        [self setStreamSyncMode:kLQStreamIsJamSynced];
    }
}


- (LXSize)preferredRenderSize {
    return _preferredRenderSize; }
    
- (void)setPreferredRenderSize:(LXSize)size {
    if (size.w < 0.0 || size.h < 0.0 || !isfinite(size.w) || !isfinite(size.h))
        size = LXZeroSize;
        
    if (size.w != _preferredRenderSize.w || size.h != _preferredRenderSize.h) {
        _preferredRenderSize = size;

        [_nodes makeObjectsPerformSelector:@selector(invalidateCaches)];   
    }
}

- (BOOL)prefersRenderSpeedToPrecision {
    return _prefersRenderSpeedToPrecision; }

- (void)setPrefersRenderSpeedToPrecision:(BOOL)f {
    if (f != _prefersRenderSpeedToPrecision) {
        _prefersRenderSpeedToPrecision = f;
        
        [_surfacePool setLXPixelFormat:(_prefersRenderSpeedToPrecision) ? kLX_RGBA_INT8 : 0];
        
        [_nodes makeObjectsPerformSelector:@selector(invalidateCaches)];
    }
}

- (BOOL)prefersRenderWithoutVSync {
    return _prefersRenderNoVSync; }
    
- (void)setPrefersRenderWithoutVSync:(BOOL)f {
    if (f != _prefersRenderNoVSync) {
        _prefersRenderNoVSync = f;
    }
}



- (BOOL)isEvalLoggingEnabled {
    return _enableEvalLog; }
    
- (void)setEvalLoggingEnabled:(BOOL)f {
    _enableEvalLog = f; }


- (NSString *)validateNodeName:(NSString *)prefix integerSuffix:(LXInteger)num
{
    NSString *name;
    NSRange range;
    // first look for an ending number
    if ((range = [prefix rangeOfString:@" " options:NSBackwardsSearch]).location != NSNotFound && range.location > 0) {
        NSString *ending = [prefix substringFromIndex:range.location+1];
        NSCharacterSet *invDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        
        // if the ending contains only digits (e.g. "foo 2"), we'll strip it off
        if ([ending rangeOfCharacterFromSet:invDigits].location == NSNotFound) {
            prefix = [prefix substringToIndex:range.location];
        }
    }
    
    name = (num > 0) ? [NSString stringWithFormat:@"%@ %ld", prefix, (long)num] : prefix;
    
    if ([self nodeNamed:name] != nil) {
        name = [self validateNodeName:prefix integerSuffix:(num > 0) ? num+1 : 2];  // after "foo", we want the next node name to be "foo 2"
    }
    return name;
}



#pragma mark --- JavaScript ---

- (LQJSInterpreter *)jsInterpreter
{
    if ( !_jsSandbox && !_sharedJSContainer)
        [self _recreateJSSandbox];
        
    return [_jsSandbox interpreter];
}

- (id)streamJSThis {
    if ( !_jsSandbox && !_sharedJSContainer)
        [self _recreateJSSandbox];
        
    return [_jsSandbox jsConstructedThis];
}


- (void)_logJSError:(NSError *)error type:(LXInteger)errorType
{
    NSString *logStr;
    switch (errorType) {
        case 0:
            logStr = [NSString stringWithFormat:@"%@", [error localizedDescription]];
            break;
        case 3: {
            NSString *desc = [error localizedDescription];
            NSRange range;
            if ((range = [desc rangeOfString:@"(on line" options:NSCaseInsensitiveSearch]).location != NSNotFound) {
                desc = [desc substringToIndex:range.location];
            }
            logStr = [NSString stringWithFormat:@"%@", desc];
            break;
        }
        case 1: 
            logStr = [NSString stringWithFormat:@"Compile error:  %@", [error localizedDescription]];
            break;
        case 2: {
            NSString *desc = [error localizedDescription];
            if (_jsActiveNode) {
                desc = [desc stringByAppendingFormat:@" (node id: %@, function: %@)", [_jsActiveNode name], _jsActiveNodeFuncName];
            }
            logStr = [NSString stringWithFormat:@"Runtime error:  %@", desc];
            break;
        }
    }
    
    NSLog(@"JavaScript error / %@", logStr);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kLQPatchJSTraceNotification
                                                object:self
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        logStr, kLQPatchTraceStringKey,
                                                                        [NSNumber numberWithBool:YES], kLQPatchTraceIsErrorKey,
                                                                        nil]];
}

- (id)executeScript:(NSString *)script
{
    if ([script length] < 1) return nil;
    
    if ( !_jsSandbox && !_sharedJSContainer)
        [self _recreateJSSandbox];

    id result = nil;
    NSError *error = nil;
    id interp = [_jsSandbox interpreter];
    id myJSObj = [self streamJSThis];
    
    if (myJSObj) {
        result = [interp evaluateScript:script thisValue:myJSObj error:&error];
        if (error) {
            ///NSLog(@"** %@: failed to execute JS func (%@)", self, error);
            [self _logJSError:error type:3];
        }
        /*
        id newFunc = [interp compileScript:script functionName:@"_tempStreamExecFunc" parameterNames:[NSArray array] error:&error];
        if (error) {
            NSLog(@"** failed to compile script for patch (error %@)", [self name], error);
            [self _logJSError:error type:1];
        } else {
            result = [newFunc callWithThis:myJSObj parameters:[NSArray array] error:&error];
            
            if (error) {
                NSLog(@"** %@: failed to execute JS func (%@)", self, error);
                [self _logJSError:error type:2];
            } else {
                ///LQPrintf("js exec result is: '%s'\n", [[result description] UTF8String]);
            }
        }
        */
    }
    return result;
}

- (id)jsSingleton_app {
    return _jsObj_app; }

- (id)jsSingleton_stream {
    return _jsObj_stream; }



- (id)jsifyAndRetainEvalResultObject:(id)obj
{
    BOOL isValue = [obj isKindOfClass:[NSValue class]];
    id ret = obj;
    
    if ([obj isKindOfClass:[NSNumber class]]) {
        [ret retain];
    }
    else if ([obj isKindOfClass:[NSData class]]) {
        ret = [[LQJSBridge_ByteBuffer alloc] initWithData:obj inJSContext:[[self jsInterpreter] jsContextRef] withOwner:self];
    }
    else if (isValue && 0 == strcmp([obj objCType], @encode(LXRGBA))) {
        LXRGBA rgba = [obj rgbaValue];
        ret = [[[self jsInterpreter] emptyProtectedJSObject] retain];
        [ret setValue:[NSNumber numberWithDouble:rgba.r] forKey:@"r"];
        [ret setValue:[NSNumber numberWithDouble:rgba.g] forKey:@"g"];
        [ret setValue:[NSNumber numberWithDouble:rgba.b] forKey:@"b"];
        [ret setValue:[NSNumber numberWithDouble:rgba.a] forKey:@"a"];
    }
    else if (isValue && 0 == strcmp([obj objCType], @encode(NSPoint))) {
        NSPoint p = [obj pointValue];
        ret = [[[self jsInterpreter] emptyProtectedJSObject] retain];
        [ret setValue:[NSNumber numberWithDouble:p.x] forKey:@"x"];
        [ret setValue:[NSNumber numberWithDouble:p.y] forKey:@"y"];
    }
    else if (isValue) {
        // don't let unknown NSValues through
        ret = [[[self jsInterpreter] emptyProtectedJSObject] retain];
    }
    else {
        [ret retain];
    }
    
    return ret;
}

- (id)createJSMapObjectFromEvalInputList:(LACArrayListPtr)inputList
{
    NSError *error = nil;
    /*
    id interp = [self jsInterpreter];
    id map = [[interp globalVariableForKey:@"Map"] constructWithParameters: [NSArray array]
                                                                    //[NSArray arrayWithObject:[NSNumber numberWithBool:YES]]
                                                                     error:&error];
    */
    id map = nil;
    if ( ![_jsSandbox constructGlobalVariable:@"Map" withParameters:nil resultPtr:&map]) {
        NSLog(@"*** %s: unable to construct 'Map'", __func__);
        return [[NSArray array] retain];
    }
    [map setProtected:YES];
    [map retain];

    LXInteger count = LACArrayListCount(inputList);        
    count = MIN(count, 1024);  // -- sanity check --
    
    LXInteger i;
    for (i = 0; i < count; i++) {
        id obj = LACArrayListObjectAt(inputList, i);
        id key = LACArrayListIndexNameAt(inputList, i);
        
        if ([key length] < 1)
            key = [NSNumber numberWithLong:i];
        
        ///NSLog(@"Map.put() -- %i: %@ / %@ (count %i)", i, key, [obj class], [obj respondsToSelector:@selector(count)] ? [obj count] : -1);
        ///NSLog(@" ... object is: %@", obj);
        
        if (obj) {
            obj = [self jsifyAndRetainEvalResultObject:obj];
        
            error = nil;
            [map callMethod:@"put" withParameters:[NSArray arrayWithObjects:key, obj, nil] error:&error];
            if (error) {
                NSLog(@"*** %s: Map.put() failed: %@ - %@ (count %ld)", __func__, key, [obj class], [obj respondsToSelector:@selector(count)] ? (long)[obj count] : -1);
            }
            
            if ([obj respondsToSelector:@selector(setProtected:)]) [obj setProtected:NO];
            [obj release];
        }
    }
    return map;
}


// cleanup function for JS-created timers
- (void)_invalidateJSTimer:(NSTimer *)timer
{
    if ( ![timer respondsToSelector:@selector(invalidate)]) return;
    
    ///NSLog(@"%s: %@", __func__, timer);
    
    if ( !LXPlatformCurrentThreadIsMain()) {
        ///[self performSelectorOnMainThread:@selector(_invalidateJSTimer:) withObject:timer waitUntilDone:NO];
        [self performAsyncSelectorOnMainThread:@selector(_invalidateJSTimer:) target:self argumentObject:timer withinStreamLock:YES];
    } else {
        [[[timer userInfo] objectForKey:@"jsFunction"] setProtected:NO];
        [timer invalidate];
    }
}

// callback for JS-created timers
- (void)jsCreatedTimerFired:(NSTimer *)timer
{
    if ( ![self lockStreamBeforeIntervalSinceNow:0.2]) {
        NSLog(@"*** JS timer callback: unable to lock stream (%p)", timer);
        return;
    }
    [self setLockHolderName:@"jsTimerFired"];

    NSError *error = nil;
    id func = [[timer userInfo] objectForKey:@"jsFunction"];
    
    //DTIME(t0)
    [func callWithParameters:[NSArray array] error:&error];
    //DTIME(t1)

    if (error) {
        NSLog(@"*** JS timer error during firing: %@", error);
    }
    
    if ([timer timeInterval] <= 0.0) {  // this is a one-shot timer, so remove it from our array
        [self _invalidateJSTimer:timer];
        
        LXInteger index = [_jsIntervalTimers indexOfObject:timer];
        if (index == NSNotFound) {
            NSLog(@"** JS setTimeout() was not in timers array for patch (%p)", timer);
        } else {
            ///NSLog(@"removing one-shot timer (was: %@)", [_jsIntervalTimers objectAtIndex:index]);
            [_jsIntervalTimers replaceObjectAtIndex:index withObject:[NSNull null]];
        }
    }
    
    //NSLog(@"js timer fired (call took %.3f ms)", 1000*(t1-t0));
    [self unlockStream];
}


- (LXInteger)_firstFreeJSTimerIndex
{
    LXInteger n = [_jsIntervalTimers count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        if ([[_jsIntervalTimers objectAtIndex:i] isKindOfClass:[NSNull class]])
            break;
    }
    return i;
}

- (void)addTimerToCommonRunLoopModes:(NSTimer *)timer
{
    #if !defined(__LAGOON__)
    // these runloop modes only exist in Cocoa (Lagoon doesn't have them currently)
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
    #endif
}

- (void)_scheduleTimerWithRetainedInfo:(NSDictionary *)info
{
    const double interval = [[info objectForKey:@"interval"] doubleValue];
    BOOL doRepeat = [[info objectForKey:@"repeats"] doubleValue];
    id userInfo = [info objectForKey:@"userInfo"];
    LXInteger indexForTimer = [[info objectForKey:@"indexForTimer"] longValue];
    [info autorelease];
    
    ///NSLog(@"... scheduling timer on main thread (tag %i)", indexForTimer+1);
    
    id timer = [NSTimer scheduledTimerWithTimeInterval:interval
                             target:self
                             selector:@selector(jsCreatedTimerFired:)
                             userInfo:userInfo
                             repeats:doRepeat];                     
    [self addTimerToCommonRunLoopModes:timer];
    
    if (indexForTimer < [_jsIntervalTimers count])
        [_jsIntervalTimers replaceObjectAtIndex:indexForTimer withObject:timer];
    else
        [_jsIntervalTimers addObject:timer];
}

- (LXInteger)_reallyStartJSTimerWithInterval:(double)interval repeats:(BOOL)doRepeat function:(id)func
{
    LQJSInterpreter *jsInterpreter = [_jsSandbox interpreter];
    
    // this is important: the function may contain closure values that must be protected in our main context
    func = [jsInterpreter recontextualizeObject:func];

    if ( !_jsIntervalTimers)  _jsIntervalTimers = [[NSMutableArray alloc] init];
    
    // integer tag for this timer. this is the value returned to JS from this call.
    LXInteger indexForTimer = [self _firstFreeJSTimerIndex];
    LXInteger timerTag = indexForTimer + 1;

    ///NSLog(@"will start JS timer: interval %.3f ms (delegate %@); repeats %i; proposed tag %i", interval*1000.0, _jsInterceptionDelegate, doRepeat, timerTag);
            
    // allow the delegate to intercept this call; it can start its own timer and reserve this tag if it wants
    if ([_jsInterceptionDelegate respondsToSelector:@selector(shouldSetJSTimerWithTag:repeats:function:interval:reserveThisTag:)]) {
        BOOL doReserveTag = NO;
        if ( ![_jsInterceptionDelegate shouldSetJSTimerWithTag:timerTag repeats:doRepeat function:func interval:interval reserveThisTag:&doReserveTag]) {
            // delegate doesn't want us to set this timer, but it may want us to reserve the tag anyway
            ///NSLog(@".... delegate prevented timer (%@, res %i)", _jsInterceptionDelegate, doReserveTag);
            
            if ( !doReserveTag) {
                return 0;
            } else {
                // to reserve the tag, insert a dummy into the interval ID array. ugh.
                id dummy = @"__reservedByDelegate";
                if (indexForTimer < [_jsIntervalTimers count])
                    [_jsIntervalTimers replaceObjectAtIndex:indexForTimer withObject:dummy];
                else
                    [_jsIntervalTimers addObject:dummy];
                    
                return timerTag;
            }
        }
    }
    
    if (_jsActiveNode) {
        if ( ![_jsActiveNode patchShouldCreateJSTimerWithTag:timerTag repeats:doRepeat]) {
            return 0;
        }
    }
        
    /*[jsInterpreter setGlobalVariable:func forKey:@"__tempFunc"];    
    id ofunc = [jsInterpreter globalVariableForKey:@"__tempFunc"];
    NSLog(@"... func %p (%p); ofunc %p (%p); mine %p", func, [func jsContextRef], ofunc, [ofunc jsContextRef], [jsInterpreter jsContextRef]);
    func = ofunc;
    */

    // copy the function now
    /*
    NSString *funcStr = [func description]; //[@"__temp = " stringByAppendingString:[func description]];
    NSError *error = nil;
    //func = [jsInterpreter evaluateScript:funcStr error:&error];
    func = [jsInterpreter compileAnonymousFormattedFunction:funcStr error:&error];
    if (error || !func || ![func isFunction]) {
        NSLog(@"** setInterval: unable to compile function (%p, error: %@):\n   %@", func, error, funcStr);
        return 0;
    }
    */
    
    ///JSContextRef ctx = [func jsContextRef];
    ///NSLog(@"%s: interval %.4f; func %p:   %@  -- ctx is %p, main ctx %p", __func__, intervalMs, func, func, ctx, [jsInterpreter jsContextRef]);
    
    [func setProtected:YES];    
    id userInfo = [NSDictionary dictionaryWithObjectsAndKeys:func, @"jsFunction", nil];

    id timer = nil;
    if (LXPlatformCurrentThreadIsMain()) {
        //NSLog(@"added timer on main thread (intv %.3f, func: %@)", interval, func);
    
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                             target:self
                             selector:@selector(jsCreatedTimerFired:)
                             userInfo:userInfo
                             repeats:doRepeat];                     
        [self addTimerToCommonRunLoopModes:timer];
    } else {
        ///NSLog(@"...delaying start of timer from secondary thread (tag %i)", timerTag);
        
        // for non-main thread, insert a dummy in place of the timer, and send an async message to start the timer
        timer = @"__asyncTimerStartPending";
        
        [self performAsyncSelectorOnMainThread:@selector(_scheduleTimerWithRetainedInfo:) target:self
        ///[self performSelectorOnMainThread:@selector(_scheduleTimerWithRetainedInfo:)
                    argumentObject:[[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:interval], @"interval",
                                                                            [NSNumber numberWithBool:doRepeat], @"repeats",
                                                                            userInfo, @"userInfo",
                                                                            [NSNumber numberWithLong:indexForTimer], @"indexForTimer",
                                                                            nil] retain]
        ///            waitUntilDone:NO];
                    withinStreamLock:YES];
    }

    if (indexForTimer < [_jsIntervalTimers count])
        [_jsIntervalTimers replaceObjectAtIndex:indexForTimer withObject:timer];
    else
        [_jsIntervalTimers addObject:timer];
    
    ///NSLog(@" .... timer started, tag is %ld, %@", timerTag, timer);
    
    if ([_jsInterceptionDelegate respondsToSelector:@selector(didSetJSTimerWithTag:repeats:)]) {
        [_jsInterceptionDelegate didSetJSTimerWithTag:timerTag repeats:doRepeat];
    }
    
    return timerTag;
}

- (id)jsSetInterval:(NSArray *)args
{
    if ([args count] < 2) return nil;
    id func = [args objectAtIndex:0];
    if ( ![func respondsToSelector:@selector(isFunction)] || ![func isFunction]) {
        NSLog(@"** setInterval(): invalid function argument (%@)", [func class]);
        return nil;
    }
    id intv = [args objectAtIndex:1];
    if ( ![intv respondsToSelector:@selector(doubleValue)]) {
        NSLog(@"** setInterval(): invalid delay argument (%@)", [intv class]);
        return nil;
    }
    
    double intervalMs = [intv doubleValue];
    if (intervalMs <= 0.0)
        return nil;
        
    LXInteger timerTag = [self _reallyStartJSTimerWithInterval:intervalMs / 1000.0 repeats:YES function:func];
    /*
    LXInteger timerTag = 0;
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:intervalMs / 1000.0], @"interval",
                                                                    [NSNumber numberWithBool:YES], @"repeats",
                                                                    func, @"jsFunction",
                                                                    nil];
    if (LXPlatformCurrentThreadIsMain()) {
        timerTag = [self _reallyStartJSTimerWithRetainedInfo:[info retain]]; ///Interval:intervalMs / 1000.0 repeats:YES function:func];
    } else {
        _jsPendingTimerTag = -1;  // ugh, ugly
        
        DTIME(t0)
        [self performSelectorOnMainThread:@selector(_reallyStartJSTimerWithRetainedInfo:) withObject:[info retain] waitUntilDone:YES];
        DTIME(t1)
        
        timerTag = (_jsPendingTimerTag > 0) ? _jsPendingTimerTag : 0;
        _jsPendingTimerTag = 0;
        NSLog(@"... non-main thread setInterval() call: tag is %i, took %.3f ms", timerTag, 1000*(t1-t0));
    }
    */
    return (timerTag > 0) ? [NSNumber numberWithLong:timerTag] : nil;
}

- (id)jsSetTimeout:(NSArray *)args
{
    if ([args count] < 2) return nil;
    id func = [args objectAtIndex:0];
    if ( ![func respondsToSelector:@selector(isFunction)] || ![func isFunction]) {
        NSLog(@"** setTimeout(): invalid function argument (%@)", [func class]);
        return nil;
    }
    id intv = [args objectAtIndex:1];
    if ( ![intv respondsToSelector:@selector(doubleValue)]) {
        NSLog(@"** setTimeout(): invalid delay argument (%@)", [intv class]);
        return nil;
    }
    
    double intervalMs = [intv doubleValue];
    if (intervalMs <= 0.0)
        return nil;
        
    LXInteger timerTag = [self _reallyStartJSTimerWithInterval:intervalMs / 1000.0 repeats:NO function:func];

    return (timerTag > 0) ? [NSNumber numberWithLong:timerTag] : nil;
}


- (void)_reallyClearJSTimerWithTag:(LXInteger)timerTag allowDelegation:(BOOL)doDelegate
{
    LXInteger indexForTimer = timerTag - 1;

    if (doDelegate && [_jsInterceptionDelegate respondsToSelector:@selector(shouldClearJSTimerWithTag:)]) {
        if ( ![_jsInterceptionDelegate shouldClearJSTimerWithTag:timerTag])
            return;
    }
    
    NSTimer *timer = ([_jsIntervalTimers count] > indexForTimer) ? [_jsIntervalTimers objectAtIndex:indexForTimer] : nil;
    if (timer) {
        [self _invalidateJSTimer:timer];
        [_jsIntervalTimers replaceObjectAtIndex:indexForTimer withObject:[NSNull null]];
        
        if (doDelegate && [_jsInterceptionDelegate respondsToSelector:@selector(didClearJSTimerWithTag:)]) {
            [_jsInterceptionDelegate didClearJSTimerWithTag:timerTag];
        }
    }
}

- (id)jsClearInterval:(NSArray *)args
{
    if ([args count] < 1) return nil;
    id timerTag = [args objectAtIndex:0];
    if ( ![timerTag respondsToSelector:@selector(longValue)]) return nil;
    if ([timerTag longValue] <= 0) return nil;
    
    [self _reallyClearJSTimerWithTag:[timerTag longValue] allowDelegation:YES];
    return nil;
}

- (id)jsClearTimeout:(NSArray *)args
{
    if ([args count] < 1) return nil;
    id timerTag = [args objectAtIndex:0];
    if ( ![timerTag respondsToSelector:@selector(longValue)]) return nil;
    if ([timerTag longValue] <= 0) return nil;
    
    ///NSLog(@"clearing timeOut with tag %@", timerTag);
    
    [self _reallyClearJSTimerWithTag:[timerTag longValue] allowDelegation:YES];
    return nil;
}

- (void)clearJSTimerWithTag:(LXInteger)timerTag
{
    [self _reallyClearJSTimerWithTag:timerTag allowDelegation:NO];
}

- (void)setJSCallInterceptionDelegate:(id)obj {
    _jsInterceptionDelegate = obj;
}

- (void)setJSCreationDelegate:(id)obj {
    _jsCreationDelegate = obj;
}


// subclasses could override, I guess
- (NSString *)jsSandboxConstructorScript
{
    return @"";
}

- (void)_recreateJSSandbox
{
    //NSLog(@"%s, %@", __func__, self);

    // see comments in -dealloc for explanation of this hack
    [_jsSandbox clearAllState];
    [_jsSandbox performSelector:@selector(release)
                    withObject:nil
                    afterDelay:1.0];

    
    DTIME(t0)
    _jsSandbox = [[LQJSContainer alloc] initWithName:[self name]];

    //NSLog(@"  .. sandbox created");
    
    LQJSInterpreter *jsInterpreter = [_jsSandbox interpreter];
    
    DTIME(t1)
    [jsInterpreter loadBridgeClass:[LQJSBridge_Color class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_MutableByteBuffer class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_Image class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_2DCanvas class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_CurveList class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_LXTransform class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_LXShader class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_LXAccumulator class]];
    [jsInterpreter loadBridgeClass:[LQJSBridge_LXSurface class]];
    
    DTIME(t2)
    [_jsSandbox setConstructorScript:[self jsSandboxConstructorScript]];
    [_jsSandbox construct];

    
    // add standard setInterval/clearInterval funcs
    [jsInterpreter addFunction:@"setInterval" target:self selector:@selector(jsSetInterval:)];
    [jsInterpreter addFunction:@"clearInterval" target:self selector:@selector(jsClearInterval:)];
    [jsInterpreter addFunction:@"setTimeout" target:self selector:@selector(jsSetTimeout:)];
    [jsInterpreter addFunction:@"clearTimeout" target:self selector:@selector(jsClearTimeout:)];
    
    // make JSON object available in the context
    id jsonBridge = [[LQJSBridge_JSON alloc] initInJSInterpreter:[_jsSandbox interpreter] withOwner:nil];
    [jsInterpreter setGlobalVariable:[jsonBridge autorelease]
                              forKey:@"JSON"
                             options:kLQJSKitPropertyAttributeReadOnly];

    // sys object
    _jsObj_sysBridge = [[LQJSBridge_System alloc] initInJSInterpreter:[_jsSandbox interpreter] withOwner:self];
    [jsInterpreter setGlobalVariable:_jsObj_sysBridge
                              forKey:@"sys"
                             options:kLQJSKitPropertyAttributeReadOnly];
                             
    _jsObj_stream = [[LQJSBridge_StreamPatch alloc] initWithStreamPatch:self];
    [jsInterpreter setGlobalVariable:_jsObj_stream
                            forKey:@"stream"
                            options:kLQJSKitPropertyAttributeReadOnly];

    // create an empty 'app' singleton object, and keep a reference to it.
    // in CL2, the project will fill this object with stuff relating to the app (e.g. plugin bridges).
    _jsObj_app = [[jsInterpreter emptyProtectedJSObject] retain];
    
    [jsInterpreter setGlobalVariable:_jsObj_app
                            forKey:@"app"
                            options:kLQJSKitPropertyAttributeReadOnly];
    
    NSAssert([jsInterpreter globalVariableForKey:@"stream"], @"stream JS object is missing");                        
    NSAssert([jsInterpreter globalVariableForKey:@"app"], @"app JS object is missing");


    // useful classes implemented in pure JS
    NSError *error = nil;
    NSString *scriptPath = [[NSBundle bundleForClass:[LQStreamPatch class]] pathForResource:@"Base" ofType:@"js"];
    NSString *baseJSScript = [NSString stringWithContentsOfFile:scriptPath
                                            encoding:NSUTF8StringEncoding error:&error];
    if (baseJSScript) {
        DTIME(et1)
        [jsInterpreter evaluateScript:baseJSScript error:&error];
        DTIME(et2)
        //NSLog(@"... loaded 'Base' script in %.3f ms", 1000*(et2-et1));
        if (error) {
            NSLog(@"** failed to eval init script 'Base': error %@", error);
        }
    } else {
        NSLog(@"*** couldn't open Base.js: %@ (path: %@, bundle: %@)", error, scriptPath, [NSBundle bundleForClass:[LQStreamPatch class]]);
    }

    scriptPath = [[NSBundle bundleForClass:[LQStreamPatch class]] pathForResource:@"Map" ofType:@"js"];
    NSString *mapJSScript = [NSString stringWithContentsOfFile:scriptPath
                                            encoding:NSUTF8StringEncoding error:&error];
    if (mapJSScript) {
        DTIME(et1)
        [jsInterpreter evaluateScript:mapJSScript error:&error];
        DTIME(et2)
        //NSLog(@"... loaded 'Map' script in %.3f ms", 1000*(et2-et1));
        if (error) {
            NSLog(@"** failed to eval init script for object 'Map': error %@", error);
        }
    } else {
        NSLog(@"*** couldn't open Map.js: %@ (path: %@, bundle: %@)", error, scriptPath, [NSBundle bundleForClass:[LQStreamPatch class]]);
    }

    /*
    // test script
    NSString *testScr = @"aFunc = function(a) { return a * 3 };"
                         "a = aFunc(7);"
                        ; 
    DTIME(t3)
    NSError *error = nil;
    id result = [[_jsSandbox interpreter] evaluateScript:testScr thisValue:[_jsSandbox jsConstructedThis] error:&error];
    if (error || !result) {
        NSLog(@"** js exec failed: %@", error);
    } else {
        DTIME(t4)
        NSLog(@"did run JS eval test: result is '%@'\n times: js init %.3f ms - loadBridges %.3f ms - construct %.3f ms - eval %.3f ms", result,
                                                                1000*(t1-t0), 1000*(t2-t1), 1000*(t3-t1), 1000*(t4-t3));
    }
    */
    
    if ([_jsCreationDelegate respondsToSelector:@selector(patchDidCreateJSInterpreter:)]) {
        [_jsCreationDelegate patchDidCreateJSInterpreter:self];
    }
    else if (g_jsCreationDelegate) {
        // this weird global delegate is used for keyed unarchiving, where the stream patch will be created at some point during the unarch process,
        // and we can't wait to call the delegate because the unarchiving may create objects that expect to have specific JS classes already loaded
        [g_jsCreationDelegate patchDidCreateJSInterpreter:self];
    }
}

- (void)willEnterJSMethodNamed:(NSString *)funcName onNode:(id)node
{
    _jsActiveNode = node;
    _jsActiveNodeFuncName = funcName;
    ///NSLog(@"%s -- %@, %@", __func__, node, funcName);
}

- (void)didExitJSMethod
{
    ///NSLog(@"%s", __func__);
    _jsActiveNode = nil;
    _jsActiveNodeFuncName = nil;
}

/*
- (BOOL)runMethodNamed:(NSString *)funcName onNode:(id)node resultPtr:(id *)outResult
{
    return [self runMethodNamed:funcName onNode:node parameters:nil resultPtr:outResult];
}
*/
- (BOOL)runMethodNamed:(NSString *)funcName onNode:(id)node parameters:(NSArray *)params resultPtr:(id *)outResult
{
    if ([funcName length] < 1) return NO;
    
    BOOL retVal = NO;
    id result = nil;
    NSError *error = nil;
    
    id nodeJSProxy = [node jsBridgeInPatchContext];
    if (nodeJSProxy) {
        id func = [nodeJSProxy propertyForKey:funcName];

        if (func && [func respondsToSelector:@selector(isFunction)] && [func isFunction]) {
            [self willEnterJSMethodNamed:funcName onNode:node];
        
            result = [func callWithThis:nodeJSProxy parameters:params error:&error];            
            if (error)
                [self _logJSError:error type:2];
            else
                retVal = YES;
            
            [self didExitJSMethod];
        }
    }
    if (outResult) *outResult = result;
    return retVal;
}


#pragma mark --- JS sys bridge delegate ---

- (void)_postTraceNotifWithRetainedInfo:(NSDictionary *)info
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLQPatchJSTraceNotification
                                                object:self
                                                userInfo:info];
    [info release];
}

- (void)jsSystemCallForBridge:(id)bridgeObj printTraceString:(NSString *)str
{
    NSDictionary *info = [[NSDictionary dictionaryWithObjectsAndKeys:(str) ? str : @"", kLQPatchTraceStringKey,
                                                                    nil] retain];
    if (LXPlatformCurrentThreadIsMain()) {
        [self _postTraceNotifWithRetainedInfo:info];
    } else {
        [self performAsyncSelectorOnMainThread:@selector(_postTraceNotifWithRetainedInfo:) target:self argumentObject:info withinStreamLock:NO];
    }
}

- (void)_showAlertWithRetainedString:(NSString *)str
{
    NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Script says:"];
        [alert setInformativeText:(str) ? str : @"(Null)"];
        [alert runModal];
    [alert release];

    [str release];
}

- (void)jsSystemCallForBridge:(id)bridgeObj showAlertWithString:(NSString *)str
{
    [str retain];
    if (LXPlatformCurrentThreadIsMain()) {
        [self _showAlertWithRetainedString:str];
    } else {
        [self performAsyncSelectorOnMainThread:@selector(_showAlertWithRetainedString:) target:self argumentObject:str withinStreamLock:NO];
    }
}

- (NSData *)jsSystemCallForBridge:(id)bridgeObj shouldLoadDataFromPath:(NSString *)path error:(NSError **)outError
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fm attributesOfItemAtPath:path error:NULL];
    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
    
    // check for file size, because we don't want the user to load enormous files into memory inside Conduit
    if (fileSize) {
        uint64_t size = [fileSize unsignedLongLongValue];
        const uint64_t maxSize = 1024*1024 * 32;
        if (size > maxSize) {
            if (outError) {
                *outError = [NSError errorWithDomain:@"LQPatchErrorDomain" code:132000
                                            userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        @"File is too large to be loaded into memory", NSLocalizedDescriptionKey,
                                                                        nil]];
            }
            return nil;
        }
    }
    
    return [NSData dataWithContentsOfFile:path options:0 error:outError];
}


#pragma mark --- evaluation ---

// override of private method in LACPatch: log info about stream buffer objects
- (void)_logExtraInfoAboutEvalResultObject:(id)obj inDictionary:(NSMutableDictionary *)dict
{
    if ([obj isKindOfClass:[NSValue class]] && 0 == strcmp([obj objCType], @encode(LXRGBA))) {
        [dict setObject:@"Color" forKey:@"type"];
        [dict setObject:obj forKey:@"rgbaValue"];
        [dict setObject:NSStringFromLXRGBA([obj rgbaValue]) forKey:@"stringValue"];
    }
    else if ([obj isKindOfClass:[NSValue class]] && 0 == strcmp([obj objCType], @encode(NSPoint))) {
        [dict setObject:@"Point" forKey:@"type"];
        [dict setObject:obj forKey:@"pointValue"];
        [dict setObject:NSStringFromPoint([obj pointValue]) forKey:@"stringValue"];
    }
    else if ([obj respondsToSelector:@selector(imageDataSize)]) {
        [dict setObject:[NSValue valueWithSize:[obj imageDataSize]] forKey:@"imageDataSize"];
    }
}

- (void)_postEvalResultsNotifWithRetainedLog:(NSDictionary *)evalLog
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kLQPatchEvalLogNotification
                                                object:self
                                                userInfo:evalLog];
    [evalLog release];
}

- (LACArrayListPtr)evaluateNode:(LACNode *)node forOutputAtIndex:(LXInteger)outputIndex
                                                withContext:(NSDictionary *)evalCtx
{
    if ( !_jsSandbox && !_sharedJSContainer) {
        [self _recreateJSSandbox];
    }
    
    _latestEvalTime = LQReferenceTimeGetCurrent();

    LACArrayListPtr result = [super evaluateNode:node forOutputAtIndex:outputIndex withContext:evalCtx];
    return result;
}

- (void)willEvaluateForPresenter:(id)presenter withContext:(NSDictionary *)context
{
    DTIME(t0)
    // set up eval logging
    if (_enableEvalLog) {
        _evalLog = [[NSMutableDictionary alloc] init];
    }

    // set up JS state for "timeline" mode
    id timeVal = [context objectForKey:kLQStreamPatchCtxKey_RequestedTimeConstrainedToProjectBase];
    if ( !timeVal) {
        timeVal = [context objectForKey:kLQStreamPatchCtxKey_RequestedTime];
    }
    [_jsObj_stream setActiveTimelineMode:(timeVal) ? YES : NO
                       timeInStream:(timeVal) ? [timeVal doubleValue] : (LQReferenceTimeGetCurrent() - _streamStartTime)];
    
    DTIME(t1)

    // check for nodes that want to be evaled even without a presenter connection
    NSArray *presentableNodes = nil;
    
    double tPresGet = 0.0;
    double tPresEval = 0.0;
    NSMutableArray *presented = [NSMutableArray array];
    
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LQStreamNode *node;
    while (node = [nodeEnum nextObject]) {
        DTIME(tAA)
        if ([node wantsEvalIfNotConnectedToPresenter]) {
            if ( !presentableNodes) {
                DTIME(tA)
                presentableNodes = [self nodesWithPrimaryPresenterConnection];
                tPresGet = LQReferenceTimeGetCurrent() - tA;
            }
                
            if ( ![presentableNodes containsObject:node]) {
                //DTIME(tA)
                NSDictionary *evalCtxForNode = context;  // give the node a chance to modify the eval context if it wants
                if ([node respondsToSelector:@selector(willEvalOutsidePresenterUsingContext:)])
                    evalCtxForNode = [node willEvalOutsidePresenterUsingContext:context];
                    
                //DTIME(tB)
            
                LACArrayListPtr result = [self evaluateNode:node forOutputAtIndex:([[node outputs] count] > 0) ? 0 : -1 withContext:evalCtxForNode];
                
                LACArrayListRelease(result);
                /*
                DTIME(tC)
                double d = tC - tA;
                tPresEval += d;
                [presented addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1000*d], @"timeSpent",
                                                                                [NSNumber numberWithDouble:1000*(tB-tA)], @"timeSpentOnPreEval",
                                                                                [NSNumber numberWithDouble:1000*(tA-tAA)], @"timeSpentOnNodeWantsEvalMethodCall",
                                                                                node, @"node", nil]];*/
            }
        }
    }
    DTIME(t2)
    
    /*if ((t2-t0) > 10.0/1000.0) {
        NSLog(@"long time spent on willEval: js %.3f ms, presentables %.3f ms; pres get %.3f ms; pres eval %.3f ms", 1000*(t1-t0), 1000*(t2-t1), 1000*tPresGet, 1000*tPresEval);
        NSLog(@"nodes: %@", presented);
    }*/
}

- (void)_performAsyncWithInfo:(id)info
{
    SEL sel = [[info objectForKey:@"selectorPtr"] pointerValue];
    id target = [info objectForKey:@"targetObj"];
    id arg = [info objectForKey:@"argObj"];
    BOOL doLock = [[info objectForKey:@"enterStreamLock"] boolValue];
    NSAssert(sel, @"no selector");
    
    if (doLock) {
        if ( ![self lockStreamBeforeIntervalSinceNow:2.0]) {
            NSLog(@"*** %s: unable to lock stream (selector: %@)", __func__, NSStringFromSelector(sel));
            return;
        }
        [self setLockHolderName:@"performAsync"];
    }    
    [target performSelector:sel withObject:arg];
    
    if (doLock) {
        [self unlockStream];
    }
}

- (void)performAsyncSelectorOnMainThread:(SEL)sel target:(id)target argumentObject:(id)arg withinStreamLock:(BOOL)enterStreamLock
{
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            target, @"targetObj",
                                            [NSValue valueWithPointer:sel],             @"selectorPtr",
                                            [NSNumber numberWithBool:enterStreamLock],  @"enterStreamLock",
                                            nil];
    if (arg)
        [info setObject:arg forKey:@"argObj"];

    [self performSelectorOnMainThread:@selector(_performAsyncWithInfo:)
                            withObject:info
                            waitUntilDone:NO
                            modes:
#if defined(__LAGOON__)
                                [NSArray arrayWithObjects:NSDefaultRunLoopMode, nil]
#else
                                [NSArray arrayWithObjects:NSDefaultRunLoopMode, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil]
#endif
                        ];
}

- (void)didEvaluateForPresenter:(id)presenter
{
    // notify of eval results if logging is enabled
    if (_enableEvalLog) {
        NSDictionary *log = [_evalLog copy];
        [_evalLog release];
        _evalLog = nil;
    
        if (LXPlatformCurrentThreadIsMain()) {
            [self _postEvalResultsNotifWithRetainedLog:log];
        } else {
            [self performAsyncSelectorOnMainThread:@selector(_postEvalResultsNotifWithRetainedLog:) target:self argumentObject:log withinStreamLock:NO];
        }
    }
}

- (LACArrayListPtr)evaluateSingleFrameOnPrimaryPresenterAtTime:(double)timeInStream withContext:(NSDictionary *)context
{
    if ( ![self primaryPresenter]) {
        NSLog(@"*** can't render single frame on patch, no presenter");
        return nil;
    }
    
    // clean up any lingering buffers
    if ( !_surfacesFromPoolWithinEval) {
        _surfacesFromPoolWithinEval = [[NSMutableArray alloc] initWithCapacity:32];
    } else {
        [self _cleanupSurfacesRequestedFromPoolWithinEval];
    }

    NSMutableSet *failures = [NSMutableSet set];
    NSMutableDictionary *evalCtx = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithDouble:timeInStream], kLQStreamPatchCtxKey_RequestedTime,
                                            failures, kLQStreamPatchCtxKey_RenderFailures,
                                            nil];

    if (context)
        [evalCtx addEntriesFromDictionary:context];

    if ([[self publishedOutputInterface] count] < 1) {
        [self _publishPrimaryPresentersOutputsInPatchAndSort];
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    LACNode *presenter = [self primaryPresenter];
    
    [self willEvaluateForPresenter:presenter withContext:evalCtx];

    LACArrayListPtr result = [self evaluateNode:presenter forOutputAtIndex:-1 withContext:evalCtx];
    
    [self didEvaluateForPresenter:presenter];

    ///NSLog(@"%s: list is %@ -- first obj %@ -- retcount %ld", __func__, LACArrayListDescribe(result), obj, [obj retainCount]);
    
    [pool drain];
    [_jsSandbox cleanupAfterRenderIteration];
    
    if ([failures count] > 0) {
        NSLog(@"*** could not eval time %.3f: render failures: %@", timeInStream, failures);
    }
            
    return result;
}


- (void)streamNode:(id)node didRequestSurfaceFromPoolDuringEval:(LXSurfaceRef)surface
{
    if ( !_surfacesFromPoolWithinEval) {
        _surfacesFromPoolWithinEval = [[NSMutableArray alloc] initWithCapacity:32];
    }
    ///NSLog(@"%s: %@, %p", __func__, node, surface);
    [_surfacesFromPoolWithinEval addObject:[NSValue valueWithPointer:surface]];
}

- (void)_cleanupSurfacesRequestedFromPoolWithinEval
{
    if ([_surfacesFromPoolWithinEval count] > 0) {
        ///NSLog(@"%s: cleaning up %ld surfaces back to pool: %@", __func__, [_surfacesFromPoolWithinEval count], _surfacesFromPoolWithinEval);
    
        NSEnumerator *surfEnum = [_surfacesFromPoolWithinEval objectEnumerator];
        id val;
        while (val = [surfEnum nextObject]) {
            LXSurfaceRef surf = [val pointerValue];
            [[self surfacePool] returnSurfaceToPool:surf];
        }
        [_surfacesFromPoolWithinEval removeAllObjects];
    }
}

- (void)cleanupAfterEvalRender
{
    [self _cleanupSurfacesRequestedFromPoolWithinEval];
    
    NSEnumerator *nodeEnum = [self nodeEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if ([node respondsToSelector:@selector(cleanupAfterEvalRender)]) {
            [node cleanupAfterEvalRender];
        }
    }
}

- (void)_moveOwnershipOfSurfaceUsedInEvalRender:(LXSurfaceRef)surface
{
    NSValue *val = [NSValue valueWithPointer:surface];
    
    if ( ![_surfacesFromPoolWithinEval containsObject:val]) {
        NSLog(@"** %s: surface was not from this pool (%p)", __func__, surface);
    }
    [_surfacesFromPoolWithinEval removeObject:val];
}

- (void)object:(id)obj willAssumeOwnershipOfManagedBuffersFromEvalRender:(NSArray *)buffers
{
    // the given array may contain multiple instances of the same object,
    // so convert to a set
    NSSet *set = [NSSet setWithArray:buffers];

    for (id renderedObj in set) {
        BOOL isSurface = [renderedObj isKindOfClass:[LQLXSurface class]];
        if (isSurface) {
            ///NSLog(@"  ... %@ assumes ownership of surface %p", obj, [renderedObj lxSurface]);
            [self _moveOwnershipOfSurfaceUsedInEvalRender:[renderedObj lxSurface]];
        }
    }
    
    // clean up nodes' buffer stacks too
    NSEnumerator *nodeEnum = [self nodeEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if ([node respondsToSelector:@selector(usesPatchOriginatedSurfacesAsBuffers)] && [node usesPatchOriginatedSurfacesAsBuffers]) {
            id buf = [node popBufferFromStackAndClear];
            if (buf) {
                BOOL isBeingOwned = [buffers containsObject:buf];
                ///NSLog(@"... %s: node '%@' had buffer %@ -- was owned: %i", __func__, [node name], buf, hasBeenOwned);
                
                if ( !isBeingOwned) {
                    [[self surfacePool] returnSurfaceToPool:[buf lxSurface]];
                }
            }
        }
    }
}

- (void)cleanupManagedBuffers:(NSArray *)buffers
{
    NSMutableSet *returnedList = nil;

    NSEnumerator *bufferEnum = [buffers objectEnumerator];
    id renderedObj;
    LXInteger n = 0;
    #pragma unused(n)
    while (renderedObj = [bufferEnum nextObject]) {
        BOOL isSurface = [renderedObj isKindOfClass:[LQLXSurface class]];
        if (isSurface) {
            if ( !returnedList)
                returnedList = [NSMutableSet set];
            else if ([returnedList containsObject:renderedObj])
                continue;
                
            [returnedList addObject:renderedObj];
            
            //LXPrintf("returning surface to pool: %p\n", [renderedObj lxSurface]);
        
            [[self surfacePool] returnSurfaceToPool:[renderedObj lxSurface]];
            n++;
            
        }
    }
}


#pragma mark --- copying ---

- (void)_setupAfterCopyOrDecode
{
    _streamLock = [[NSRecursiveLock alloc] init];
    if ([_streamLock respondsToSelector:@selector(setName:)]) {
        [(NSImage *)_streamLock setName:[NSString stringWithFormat:@"owned by streamPatch %p", self]];
    }
    
    if ( !_surfacePool) {
        _surfacePool = [[LQXSurfacePool alloc] init];
        [_surfacePool setName:[NSString stringWithFormat:@"owned by %@ '%@'", [self class], [self name]]];
        //NSLog(@"created surfacepool %p for decoded patch: %@", _surfacePool, self);
    }
    
    // ensure that each node has an individual tag
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        if ([node tag] == 0)
            [node setTag:[self _availableNodeTagWith:0]];
    }
    
    [self _setInitialPatchState];
    
    if ( !_jsSandbox && !_sharedJSContainer)
        [self _recreateJSSandbox];
}

- (id)deepCopyWithAppliedMappingPtr:(NSDictionary **)outMap
{
    id newObj = [super deepCopyWithAppliedMappingPtr:outMap];
    
    [newObj _setupAfterCopyOrDecode];
    
    return newObj;
}


#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    if (_primaryPresenter) {
        [coder encodeObject:_primaryPresenter forKey:@"LAC::Stream::primaryPresenter"];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _primaryPresenter = [coder decodeObjectForKey:@"LAC::Stream::primaryPresenter"];
        
        [self _setupAfterCopyOrDecode];
    }

	return self;
}

@end
