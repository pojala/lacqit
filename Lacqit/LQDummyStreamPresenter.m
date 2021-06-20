//
//  LQStreamPresenter.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQDummyStreamPresenter.h"
#import "LQStreamNode_priv.h"
#import <Lacefx/LXRandomGen.h>


@implementation LQDummyStreamPresenter

+ (NSString *)proposedDefaultName {
    return @"presenter"; }


- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"data to be presented" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray array]];    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    return copy;
}


#pragma mark --- threaded playback ---

- (NSDictionary *)parametersForWorkerThread {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:60.0], kLQStreamThreadProperty_PollsPerSecond,
                                    nil];
}

- (void)prerollOnThread
{
    double prerollMs = 20 + LXRdUniform(0, 120);
    usleep(prerollMs * 1000);  // testing stand-in for the actual preroll
    
    _knownSampleTime = LQReferenceTimeGetCurrent();
    _knownSampleInterval = 1.0 / 60.0;    
}

- (void)didEnterWorkerThread:(id)threadParamsDict
{
    // we are in the worker thread and can do prerolling here
    
    if (_prerollDelegate) {
        [self prerollOnThread];
        
        [_prerollDelegate performSelectorOnMainThread:@selector(streamNodeFinishedPreroll:)
                          withObject:self
                          waitUntilDone:NO];
        _prerollDelegate = nil;
    }
    
    // this prevents polling until we get a "play" message (60 hours is far enough in the future for this purpose)
    _initialWaitOnCondLock = 60*60*60;
}


- (void)pollOnWorkerThread:(id)threadParamsDict
{
    double t0 = LQReferenceTimeGetCurrent();

    double nextSampleTime = _knownSampleTime;    
    while (nextSampleTime < t0)
        nextSampleTime += _knownSampleInterval;
    
    double waitTime = nextSampleTime - t0;
    long waitTime_us = waitTime * 1000 * 1000;
    
    // this waiting simulates a live source
    
    if (waitTime_us > 1 && waitTime < _knownSampleInterval*0.5) {
        //LQPrintf("...pres %p sleeping for %i us / max %i us\n", self, waitTime_us, (long)(_knownSampleInterval*1000*1000));
        usleep(waitTime_us);
    }
        
    [super pollOnWorkerThread:threadParamsDict];
}



#pragma mark --- stream control ---

- (void)prerollAsyncWithDelegate:(id)del
{
    _prerollDelegate = del;
    
    [self startWorkerThread];
}

- (void)playNow
{
    double startTime = [[self owner] streamStartReferenceTime];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithDouble:startTime], kLQStreamThreadProperty_StreamStartReferenceTime,
                                nil];

    NSLog(@"%@ play:  offset is %f", self, _knownSampleTime - startTime);

    [self signalWorkerThreadWithDict:dict];
}

- (void)postrollAsync
{
    [self signalWorkerThreadToExit];
}

- (void)waitForPostrollToFinish
{
    [self waitForWorkerThreadToExit];
}

    

@end
