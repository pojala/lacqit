//
//  LQStreamRenderer.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamRenderer.h"
#import "LQStreamNode_priv.h"
#import <Lacefx/LXRandomGen.h>


#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();


@implementation LQStreamRenderer

+ (NSString *)proposedDefaultName {
    return @"renderer"; }


- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"input data" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"rendered data" typeKey:nil] autorelease],
                                nil]];

    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    return copy;
}


#pragma mark --- render state info ---

/*
- (int64_t)latestBufferID
{
    ///LQPrintf("%s / %p (%s): %ld\n", __func__, self, [[self name] UTF8String], (long)_latestSampleID);
    return _latestSampleID;
}
*/

/*
#define ENTERSTREAMLOCK     [(LQStreamPatch *)[self owner] lockStreamBeforeIntervalSinceNow:(10.0/1000.0)]  // wait up to 10 ms for the lock
#define EXITSTREAMLOCK      [(LQStreamPatch *)[self owner] unlockStream];


- (void)doScheduledRenderOnThread:(id)threadParamsDict
{
    // - wait for frame from the source
    //
    
    // do some rendering.
    // if the rendering is double-buffered, we don't need to acquire the stream lock yet
    
    if (_debugDummyMode) {  // testing stand-in for the actual rendering
        double renderMs = 10.0 + LXRdUniform(10, 18);
        usleep(renderMs * 1000);  
    }

    if ( !ENTERSTREAMLOCK) {
        NSLog(@"** %@: couldn't get stream lock on render", self);
    } else {
        //LQPrintf("node %p: has rendered (%.3f ms)\n", self, renderMs);
        
        // swap buffers
        
        _latestSampleID++;
        EXITSTREAMLOCK
    }
}
*/



#pragma mark --- threaded playback ---

#ifdef __WIN32__
#define DEFAULTPOLLSPERSEC  120.0
#else
#define DEFAULTPOLLSPERSEC  300.0
#endif

- (NSDictionary *)parametersForWorkerThread {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:DEFAULTPOLLSPERSEC], kLQStreamThreadProperty_PollsPerSecond,
                                    nil];
}

- (void)prerollOnThread
{
    if (_debugDummyMode) {
        usleep(120 * 1000);  // testing stand-in for the actual preroll
    }
}

- (void)didEnterWorkerThread:(id)threadParamsDict
{
    // we are in the worker thread and can do prerolling here
    
    if (_prerollDelegate) {
        [self prerollOnThread];

        ///NSLog(@"%s: %@", __func__, self);
            
        [_prerollDelegate performSelectorOnMainThread:@selector(streamNodeFinishedPreroll:)
                          withObject:self
                          waitUntilDone:NO];
        _prerollDelegate = nil;
    }
    
    // this prevents polling until we get a "play" message (60 hours is far enough in the future for this purpose)
    _initialWaitOnCondLock = 60*60*60;
}

/*
- (void)pollOnWorkerThread:(id)threadParamsDict
{
    double t0 = LQReferenceTimeGetCurrent();
    double startTime = [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
    
    LQPrintf("stand-in renderer %s | poll time: %f\n", [[self name] UTF8String], t0-startTime);
}*/

- (void)doScheduledRenderOnThread:(id)threadParamsDict
{
    double t0 = LQReferenceTimeGetCurrent();
    double startTime = [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
    
    LQPrintf("stand-in renderer %s | sched. render | time in stream: %f\n", [[self name] UTF8String], t0-startTime);
    
    [_bufferOutputTimeWatcher addSampleRefTime:LQReferenceTimeGetCurrent()];
}

- (void)willExitWorkerThread:(id)threadParamsDict
{
    if (_debugDummyMode) {
        usleep(200 * 1000); // testing stand-in for something that takes a long time to finish (e.g. closing a stream)
    }
}


#pragma mark --- render schedule ---

- (void)_calcUpcomingTimesWithCurrentTime:(double)t0
                    knownTime:(double)knownTime
                    interval:(double)intv
                    intoArray:(double *)arr
                    size:(int)arrSize
{
    while (knownTime < t0) {
        knownTime += intv;
    }
    arr[0] = knownTime;
    //LQPrintf("-- upcoming time: %f", arr[0]-t0);

    int i;
    for (i = 1; i < arrSize; i++) {
        arr[i] = knownTime + intv*i;
        //LQPrintf(", %f", arr[i]-t0);
    }
    //LQPrintf("\n");
}

- (LQStreamNode *)findNonRendererNodeUpstream
{
    LQStreamNode *node;
    LACInput *inp = [self primeInput];
    
    int n = 0;
    while ((node = [[inp connectedOutput] owner]) && ([node isKindOfClass:[LQStreamRenderer class]])) {
        inp = [node primeInput];
        n++;
    }
    ///NSLog(@"found upstream node %@, n %i", node, n);
    return node;
}

- (LACInput *)presenterInputInSet:(NSSet *)set
{
    NSEnumerator *setEnum = [set objectEnumerator];
    LACInput *inp;
    while (inp = [setEnum nextObject]) {
        LQStreamNode *node = [inp owner];
        ///NSLog(@"inp %@ -- owner %@", inp, node);
        if ([node isKindOfClass:[LQStreamNode class]] && ![node isKindOfClass:[LQStreamRenderer class]])
            break;
    }
    return inp;
}

- (LQStreamNode *)findNonRendererNodeDownstreamWithInputOffsetPtr:(LXInteger *)pInputOffset
{
    LXInteger inputOffset = 0;

    LQStreamNode *node;
    LACInput *inp = [self presenterInputInSet:[[self primeOutput] connectedInputs]];
    if ( !inp)
        inp = [[[self primeOutput] connectedInputs] anyObject];
    
    if (inp)
        inputOffset += [[[inp owner] inputs] indexOfObject:inp];
    
    int n = 0;
    while ((node = [inp owner]) && ([node isKindOfClass:[LQStreamRenderer class]])) {
        inp = [self presenterInputInSet:[[node primeOutput] connectedInputs]];
        if ( !inp)
            inp = [[[self primeOutput] connectedInputs] anyObject];
        
        if (inp)
            inputOffset += [[[inp owner] inputs] indexOfObject:inp];
        
        n++;
        if (n > 100) break;
    }
    ///NSLog(@"found downstream node %@, n %i", node, n);
    if (pInputOffset) *pInputOffset = inputOffset;
    
    return node;
}

#define PRINTSAMPLEINFO 0

- (void)decideRenderingSchedule
{
    /*
    LQStreamNode *upstreamNode = [[[self primeInput] connectedOutput] owner];

    LQStreamNode *downstreamNode = nil;
    id dsInputs = [[self primeOutput] connectedInputs];
    if ([dsInputs count] > 0) {
        downstreamNode = [[dsInputs anyObject] owner];
    }*/
    LQStreamNode *upstreamNode = [self findNonRendererNodeUpstream];
    
    LXInteger downstreamInputOffset = 0;
    LQStreamNode *downstreamNode = [self findNonRendererNodeDownstreamWithInputOffsetPtr:&downstreamInputOffset];
    BOOL hasOutputs = ([[self outputs] count] > 0);
    
    #if (PRINTSAMPLEINFO)
    NSLog(@"%s (%@) -- up %@, down %@; ds input offset is %ld", __func__, [self name], upstreamNode, downstreamNode, downstreamInputOffset);
    #endif
    
    if ( !downstreamNode && hasOutputs) {
        if ( ![self wantsEvalIfNotConnectedToPresenter]) {
            _knownSampleInterval = 0.0;
            return;  // -- early exit
        } else {
            hasOutputs = NO;
        }
    }
    
    double myRenderBaseTime = 0.0;
    double myRenderInterval = 0.0;
    
    if ( !hasOutputs && [upstreamNode respondsToSelector:@selector(sampleScheduleTimeInterval)]) {
        myRenderInterval = [upstreamNode sampleScheduleTimeInterval];
        myRenderBaseTime = [upstreamNode sampleScheduleKnownReferenceTime];
        myRenderBaseTime += 4.0/1000.0;
    }
    
    else if ([upstreamNode respondsToSelector:@selector(sampleScheduleTimeInterval)]
        && [downstreamNode respondsToSelector:@selector(sampleScheduleTimeInterval)]) {
        double inRateIntv = [upstreamNode sampleScheduleTimeInterval];
        double outRateIntv = [downstreamNode sampleScheduleTimeInterval];
        double inKnownTime = [upstreamNode sampleScheduleKnownReferenceTime];
        double outKnownTime = [downstreamNode sampleScheduleKnownReferenceTime];
        
        #if (PRINTSAMPLEINFO)
        NSLog(@"... '%@': upstream rate %.4f fps, downstream %.4f fps", [self name], (inRateIntv > 0.0) ? 1.0/inRateIntv : 0.0,  1.0/outRateIntv);
        #endif
        
        myRenderInterval = inRateIntv;
        
        if (inRateIntv <= 0.0 || !isfinite(inRateIntv)) { // || inRateIntv == outRateIntv) {
            if (outRateIntv > 0.0 && outKnownTime > 0.0) {
                ///NSLog(@"   ... only downstream base time: %.3f", outKnownTime);
                myRenderInterval = outRateIntv;
                myRenderBaseTime = outKnownTime - 2.0/1000.0;
            }
        }
        else if (outRateIntv > 0.0) {  // && outRateIntv < inRateIntv) {
            // the typical case: downstream presentation rate is e.g. 60 fps, while upstream (live source) sample rate is e.g. 25 fps.
            // instead of synchronizing with the upstream source, this renderer works out its own frame schedule
            // and lets its own private rendering thread tick away, fetching new samples from the upstream source based on
            // this schedule.
            // this means less need to use mutex-based interlocking of threads in different nodes -> less threading bugs -> less nightmares...
            //
            
            #if (PRINTSAMPLEINFO)
            NSLog(@"   ... upstream base time %.3f, downstream base time %.3f", inKnownTime, outKnownTime);
            #endif
            
            if (inKnownTime <= 0.0 || outKnownTime <= 0.0) {
                // we need this information to compute our sample timing, so can't proceed
            } else {
                // first compute the next sample time for each
                double curTime = [[self owner] streamStartReferenceTime];
                
                const int timeN = 9;
                double nextInTimes[timeN+1];
                [self _calcUpcomingTimesWithCurrentTime:curTime knownTime:inKnownTime interval:inRateIntv
                                            intoArray:nextInTimes size:timeN];
                
                //NSLog(@"curtime %.3f, knownintime %.3f, intv %.4f --> intime %.3f, outtime %.3f, outintv %.4f", curTime, inKnownTime, inRateIntv, nextInTimes[0], outKnownTime, outRateIntv);
                
                double nextOutTimes[timeN+1];
                int i;
                for (i = 0; i < timeN; i++) {
                    [self _calcUpcomingTimesWithCurrentTime:nextInTimes[i] knownTime:outKnownTime interval:outRateIntv
                                            intoArray:nextOutTimes+i size:1];
                }
                            
                //LQPrintf("..time offsets: ");
                
                // find the smallest time difference (the assumption is that this will get us the freshest frame from the source)
                int minN = -1;
                double minV = 0.0;
                for (i = 0; i < timeN; i++) {
                    double diff = nextOutTimes[i] - nextInTimes[i];
                    ///LQPrintf("%f, ", diff);
                    
                    if (minN < 0 || (diff < minV)) {
                        minN = i;
                        minV = diff;
                    }
                }
                //LQPrintf("\n");
                ///LQPrintf("smallest offset: index %i\n", minN);
                
                myRenderBaseTime = nextOutTimes[minN] - inRateIntv*(minN+1);
                myRenderInterval = inRateIntv;
                
                // add a delay to give the downstream node time to consume the previous frame
                //   -- I don't think this is useful at all?
                ///myRenderBaseTime += (0.2 / 1000.0);
            }
        }
        if (outRateIntv < 1.0/40.0 && myRenderInterval < outRateIntv) {
            myRenderInterval = outRateIntv;  // clamp to downstream display rate (no point in rendering at e.g. 120 fps when display is 60 fps)
//            myRenderInterval = 1.0/60.0; 
        }
    }

    if (myRenderInterval <= 0.0 || !isfinite(myRenderInterval)) {
        // if rendering schedule couldn't be computed, look for the primary presenter
        // and try to adjust our schedule to it
        LACOutput *presenterOutput = [[self owner] nodeOutputForOutputBinding:@"__streamPrimaryPresenter.0__"];
        id node = [[[presenterOutput connectedInputs] anyObject] owner];
        
        if (node && [node respondsToSelector:@selector(sampleScheduleKnownReferenceTime)]) {
            myRenderBaseTime = [node sampleScheduleKnownReferenceTime];
            myRenderInterval = [node sampleScheduleTimeInterval];
            ///NSLog(@"   ... %@: getting time from primarypres: %.3f, intv %.3f (node %@)", [self name], myRenderBaseTime, myRenderInterval, [node name]);
            _shouldRenewRenderSchedule = YES;
        }
    }
    if (myRenderInterval <= 0.0 || !isfinite(myRenderInterval)) {
        // oh no, we have no idea when to render, so default to something reasonable
        myRenderInterval = 1.0/30.0;
        _shouldRenewRenderSchedule = YES;
    }
    if (myRenderBaseTime < LQReferenceTimeGetCurrent() - 1000 || !isfinite(myRenderBaseTime)) {
        myRenderBaseTime = LQReferenceTimeGetCurrent();
        _shouldRenewRenderSchedule = YES;
    }
    
    if (downstreamInputOffset > 0)
        myRenderBaseTime += 2.0/1000.0;   // to prevent collisions with simultaneous renderers, offset the time. this is hacky and weird.
    if (downstreamInputOffset > 1)
        myRenderBaseTime += MIN(4, (downstreamInputOffset-1)) * 2.0/1000.0;
    
    #if (PRINTSAMPLEINFO)
    NSLog(@"   '%@' -- decideSched finished: base time is %.3f / interval is %.3f (%.4f fps); should renew: %i", [self name], myRenderBaseTime, myRenderInterval, 1.0/myRenderInterval,
                _shouldRenewRenderSchedule);
    #endif
    
    _knownSampleTime = myRenderBaseTime;
    _knownSampleInterval = myRenderInterval;
}



#pragma mark --- stream control ---


- (BOOL)usePrivateWorkThread
{
    return ([[self owner] streamSyncMode] == kLQStreamIsFreeRun);
}

// separating this method allows a subclass to perform thread-startup check only once
- (BOOL)usePrivateWorkThreadOnPlay
{
    return [self usePrivateWorkThread];
}


- (void)prerollAsyncWithDelegate:(id)del
{
    _latestSampleID = -1;
    
    [_bufferOutputTimeWatcher release];
    _bufferOutputTimeWatcher = nil;

    // 2009.12.09: thread starting moved to -playNow
/*
    const BOOL useThreading = [self usePrivateWorkThread];
    
    if (useThreading) {
        _prerollDelegate = del;

        NSLog(@"%s: %@", __func__, self);
        
        [self startWorkerThread];
    }
    else {
        NSLog(@"%s: %@ -- not using thread", __func__, self);
        
        [del streamNodeFinishedPreroll:self];
    }*/
    [del streamNodeFinishedPreroll:self];
}

- (void)playNow
{
    const BOOL useThreading = [self usePrivateWorkThreadOnPlay];
    //NSLog(@"'%@': will play, threading: %i", self, useThreading);

    _latestSampleID = 0;

    if (useThreading) {
        [self startWorkerThread];
    
        [self decideRenderingSchedule];
        
        //NSLog(@"... '%@': render interval %.3f ms, known time %.3f", [self name], _knownSampleInterval*1000, _knownSampleTime);

        _shouldRenewRenderSchedule = YES;
    
        double startTime = [[self owner] streamStartReferenceTime];
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:startTime], kLQStreamThreadProperty_StreamStartReferenceTime,
                                    nil];

        [self signalWorkerThreadWithDict:dict];
    }
    else {
        
    }
}

- (void)postrollAsync
{
    const BOOL useThreading = [self usePrivateWorkThread];

    if (useThreading) {
        ///NSLog(@".... '%@': signalling exit to thread", [self name]);
        [self signalWorkerThreadToExit];
    }
}

- (void)waitForPostrollToFinish
{
    const BOOL useThreading = [self usePrivateWorkThread];

    if (useThreading) {
        ///NSLog(@".... '%@': waiting for thread to exit", [self name]);
        [self waitForWorkerThreadToExit];
        ///NSLog(@".... '%@': wait completed", [self name]);
    }
    
    [self doPostrollCleanUp];
}

@end
