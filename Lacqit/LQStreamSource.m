//
//  LQStreamSource.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamSource.h"
#import "LQStreamNode_priv.h"
#import <Lacefx/LXRandomGen.h>


NSString * const kLQSourceAttribute_VideoLoops = @"videoLoops";
NSString * const kLQSourceAttribute_Deinterlace = @"deinterlace";
NSString * const kLQSourceAttribute_ImageCropSettings = @"imageCropSettings";
NSString * const kLQSourceAttribute_SequenceFrameRate = @"sequenceFrameRate";
NSString * const kLQSourceAttribute_RendersInNativeColorspace = @"rendersInNativeColorspace";
NSString * const kLQSourceAttribute_EnableAudio = @"enableAudio";


NSDictionary *LQBitmapCropToDictionary(LQBitmapCrop crop)
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt:crop.top],          @"topPx",
                [NSNumber numberWithInt:crop.bottom],       @"bottomPx",
                [NSNumber numberWithInt:crop.left],         @"leftPx",
                [NSNumber numberWithInt:crop.right],        @"rightPx",
                nil];
}

LQBitmapCrop LQBitmapCropFromDictionary(NSDictionary *dict)
{
    LQBitmapCrop crop = { 0, 0, 0, 0 };
    if ([dict objectForKey:@"topPx"])
        crop.top = [[dict objectForKey:@"topPx"] intValue];
        
    if ([dict objectForKey:@"bottomPx"])
        crop.bottom = [[dict objectForKey:@"bottomPx"] intValue];
        
    if ([dict objectForKey:@"leftPx"])
        crop.left = [[dict objectForKey:@"leftPx"] intValue];
        
    if ([dict objectForKey:@"rightPx"])
        crop.right = [[dict objectForKey:@"rightPx"] intValue];
        
    return crop;
}



#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();


@implementation LQStreamSource

+ (NSString *)proposedDefaultName {
    return @"source"; }

+ (NSString *)nameForPrimeOutput {
    return @"stream image"; }


- (void)setInitialState
{
    [super setInitialState];
    [_bufferStack setCleanUpMinimumToKeep:1];
    ///[_bufferStack setUsesStash:YES];
}

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray array]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:[[self class] nameForPrimeOutput] typeKey:nil] autorelease],
                                nil]];
    return self;
}


- (BOOL)isCapableOfSingleFileCapture {
    return NO; }

- (BOOL)isCapableOfImageSequenceCapture {
    return NO; }
    


#pragma mark --- threaded playback ---

- (NSDictionary *)parametersForWorkerThread {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithDouble:240.0], kLQStreamThreadProperty_PollsPerSecond,
                                    nil];
}


- (void)prerollOnThread
{
    int prerollMs = 200 + LXRdUniform(0, 700);
    
    //NSLog(@"%s: %@", __func__, self);
    LQPrintf("%s -- %s... going to sleep for %i millisecs (this is for debug only)\n", __func__, [[self name] UTF8String], prerollMs);
    
    usleep(prerollMs * 1000);  // testing stand-in for the actual preroll

    LQPrintf("%s (%s) .. slept for %i ms\n", __func__, [[self name] UTF8String], prerollMs);
    
    _knownSampleTime = LQReferenceTimeGetCurrent();
    _knownSampleInterval = 1.0 / 30.0;

    LQPrintf("%s (%s) -- done! known sample time is %f\n", __func__, [[self name] UTF8String], _knownSampleTime);
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

- (void)doScheduledRenderOnThread:(id)threadParamsDict
{
    id val = [threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime];
    if ( !val) {
        LQPrintf(".. no streamtime for stand-in source %p.. (%p)\n", self, threadParamsDict);
    } else {
        double timeInStream = LQReferenceTimeGetCurrent() - [val doubleValue];
    
        LQPrintf("stand-in source %p || sample time: %f\n", self, timeInStream);
    }
    
    [_bufferOutputTimeWatcher addSampleRefTime:LQReferenceTimeGetCurrent()];
}

/*
- (void)pollOnWorkerThread:(id)threadParamsDict
{
    if (_knownSampleTime <= 0.0 || _knownSampleInterval <= 0.0) {
        return;
    }
    double t0 = LQReferenceTimeGetCurrent();

    double nextSampleTime = _knownSampleTime;    
    while (nextSampleTime < t0)
        nextSampleTime += _knownSampleInterval;
    
    double waitTime = nextSampleTime - t0;
    long waitTime_us = waitTime * 1000 * 1000;
    
    // this waiting simulates a live source
    
    if (waitTime_us > 10 && waitTime < _knownSampleInterval*0.8) {
        //LQPrintf("...src %p sleeping for %i us / max %i us\n", self, waitTime_us, (long)(_knownSampleInterval*1000*1000));
        usleep(waitTime_us - 10);
        
        double timeInStream = LQReferenceTimeGetCurrent() - [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
    
        LQPrintf("stand-in source %p || sample time: %f\n", self, timeInStream);
    }
}
*/


#pragma mark --- stream control ---

- (void)prerollAsyncWithDelegate:(id)del
{
    _prerollDelegate = del;
    
    _latestSampleID = -1;    
    _streamStartRefTime = 0.0;

    [_bufferOutputTimeWatcher release];
    _bufferOutputTimeWatcher = nil;
    
    [self startWorkerThread];
}

- (void)startPlaybackOnThread:(id)threadDict
{
    ///NSLog(@"%s (%@): msgdict is %@", __func__, self, threadDict);
}

- (void)playNow
{
    _streamStartRefTime = [[self owner] streamStartReferenceTime];

    //NSLog(@"%@ play:  sample time offset is %f", self, _knownSampleTime - _streamStartRefTime);    
    
    NSInvocation *playInv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(startPlaybackOnThread:)]];
    [playInv setSelector:@selector(startPlaybackOnThread:)];
    [playInv setTarget:self];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithDouble:_streamStartRefTime], kLQStreamThreadProperty_StreamStartReferenceTime,
                                playInv, @"invocationToPerformOnThread",
                                nil];

    [self signalWorkerThreadWithDict:dict];
}

- (void)postrollAsync
{
    [self signalWorkerThreadToExit];
}

- (void)waitForPostrollToFinish
{
    [self waitForWorkerThreadToExit];

    [self doPostrollCleanUp];
}


//- (BOOL)handleMessageInWorkerThreadMainLoop:(id)threadParamsDict;
//- (void)pollOnWorkerThread:(id)threadParamsDict;
//- (void)willExitWorkerThread:(id)threadParamsDict;


@end
