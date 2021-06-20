//
//  LQBufferingStreamNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBufferingStreamNode.h"
#import "LQStreamNode_priv.h"

#import <Lacefx/LXRandomGen.h>
#import "LQLXSurface.h"
#import "LQXSurfacePool.h"

#import "LQStreamTimeWatcher.h"
#import "LQStreamBufferStack.h"



#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();


@implementation LQBufferingStreamNode

- (void)setInitialState
{
    if ( !_bufferStack) _bufferStack = [[LQStreamBufferStack alloc] init];
    [_bufferStack setDelegate:self];
}


- (void)dealloc
{
    [_bufferStack release];
    [_bufferOutputTimeWatcher release];
    [super dealloc];
}


- (int64_t)latestBufferID
{
    return [_bufferStack latestBufferID];
}

- (double)latestBufferReferenceTime
{
    return [_bufferStack latestBufferReferenceTime];
}


///#define ENTERSTREAMLOCK              [(LQStreamPatch *)[self owner] lockStreamBeforeIntervalSinceNow:(10.0/1000.0)]   // wait up to 10 ms for the lock
///#define ENTERSTREAMLOCK_CRITICAL     [(LQStreamPatch *)[self owner] lockStreamBeforeIntervalSinceNow:(100.0/1000.0)]  // for an operation that can't be missed
///#define EXITSTREAMLOCK               [(LQStreamPatch *)[self owner] unlockStream];

/*
#define ENTERBUFFERLOCK     [_bufferLock lock];
#define EXITBUFFERLOCK      [_bufferLock unlock];
*/


#pragma mark --- buffer stack push/pop ---

- (void)returnSurfacesToPatchOwnedPool:(NSArray *)buffers
{
    /*if ( !ENTERSTREAMLOCK_CRITICAL) {
        NSLog(@"** %@ (%s): failed to get stream lock, this could be a fatal leak of surfaces **", self, __func__);
        return;
    }*/
    
    LQXSurfacePool *surfPool = [(LQStreamPatch *)[self owner] surfacePool];

    LXInteger count = [buffers count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        LQLXSurface *surfWrapper = (LQLXSurface *) [buffers objectAtIndex:i];
        
        [surfPool returnSurfaceToPool:[surfWrapper lxSurface]];
        ///NSLog(@"%s ('%@'): returning surface %p", __func__, [self name], [surfWrapper lxSurface]);
    }
    ///NSLog(@"%s: returned %i surfaces to pool", __func__, count);
    ///EXITSTREAMLOCK
}

- (BOOL)usesPatchOriginatedSurfacesAsBuffers {
    return NO;
}

- (BOOL)stackShouldPerformCleanup:(LQStreamBufferStack *)stack
{
#if 0
    if ( !ENTERSTREAMLOCK)  
        return NO;
    else
#endif
        return YES;
}

- (void)stack:(LQStreamBufferStack *)stack willReleaseBuffer:(id)buffer
{
    if ([self usesPatchOriginatedSurfacesAsBuffers]) {
        [self returnSurfacesToPatchOwnedPool:[NSArray arrayWithObject:buffer]];
    }
}

- (void)stackDidPerformCleanup:(LQStreamBufferStack *)stack
{
#if 0
    EXITSTREAMLOCK
#endif
}

/*
// subclasses can override to handle special release of buffer objects.
// for renderers that use surfaces from the patch-owned pool, it's enough to
// override -usesPatchOriginatedSurfaces.. method aboce
- (void)buffersWillBeRemovedFromStack:(NSArray *)buffers
{
    if ([self usesPatchOriginatedSurfacesAsBuffers]) {
        [self returnSurfacesToPatchOwnedPool:buffers];
    }
}

- (id)popBufferFromStackAndClear
{
    id bufObj = nil;
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    if (count > 0) {
        bufObj = [_renderBuffers objectAtIndex:count-1];
        [bufObj retain];
        [_renderBuffers removeObjectAtIndex:count-1];
    }
    
    count--;
    if (count > 0) {
        [self buffersWillBeRemovedFromStack:_renderBuffers];
        [_renderBuffers removeAllObjects];
    }
    
    EXITBUFFERLOCK
    return bufObj;
}

- (void)pushBufferToStack:(id)buffer
{
    ENTERBUFFERLOCK
    [_renderBuffers addObject:buffer];
    EXITBUFFERLOCK
}


#pragma mark --- buffer stack locking accessors methods ---

- (id)_findBufferWithReferenceTimeNewerThan:(double)t
{
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    id foundBuffer = nil;
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleReferenceTime)]) {
            NSLog(@"** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
        } else {        
            if ([buffer sampleReferenceTime] > t) {
                foundBuffer = buffer;
                break;
            }
        }
    }
    return foundBuffer;
}

- (id)_findBufferWithIDGreaterThan:(int64_t)expID
{
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    id foundBuffer = nil;
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleID)]) {
            NSLog(@"** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
            break;
        } else {        
            if ([buffer sampleID] > expID) {
                foundBuffer = buffer;
                break;
            }
        }
    }
    return foundBuffer;
}

#define LOCK_WAIT_MS 0.25

- (id)lockBufferWithIDGreaterThan:(int64_t)bufferID beforeIntervalSinceNow:(double)waitIntv
{
    ENTERBUFFERLOCK
    
    ///NSLog(@"%@: looking for buffer ID %ld or higher...", self, (long)bufferID+1);
    
    double t0 = LQReferenceTimeGetCurrent();
    double tA = t0;
    const double finalTime = t0 + waitIntv;
    
    id buffer = nil;
    while (t0 < finalTime) {
        buffer = [self _findBufferWithIDGreaterThan:bufferID];
    
        if (buffer) {
            ///LQPrintf("  ... %p: got buffer %p with ID %i \n", self, buffer, [buffer sampleID]);
            break;
        } else {
            EXITBUFFERLOCK
            ///LQPrintf("  ... %p (%s): sleeping... \n",  self, [[self name] UTF8String]);
            
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            
            ENTERBUFFERLOCK
            t0 = LQReferenceTimeGetCurrent();
        }
    }
    
    [buffer retain];  // retaining while inside the lock is enough
    EXITBUFFERLOCK
    return buffer;
}

- (id)lockBufferWithReferenceTimeNewerThan:(double)refTime beforeIntervalSinceNow:(double)waitIntv
{
    ENTERBUFFERLOCK
    
    double t0 = LQReferenceTimeGetCurrent();
    const double finalTime = t0 + waitIntv;
    
    id buffer = nil;
    while (t0 < finalTime) {
        buffer = [self _findBufferWithReferenceTimeNewerThan:refTime];
    
        if (buffer) {
            break;
        } else {
            EXITBUFFERLOCK
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            t0 = LQReferenceTimeGetCurrent();
            ENTERBUFFERLOCK
        }
    }
    
    [buffer retain];
    EXITBUFFERLOCK
    return buffer;
}

- (id)lockLatestBufferNow
{
    ENTERBUFFERLOCK
    id buffer = [_renderBuffers lastObject];
    
    [buffer retain];
    EXITBUFFERLOCK
    return buffer;
}

- (void)unlockBuffer:(id)buffer
{
    ///EXITBUFFERLOCK
    [buffer release];
}
*/

- (id)popBufferFromStackAndClear
{
    return [_bufferStack popAndCleanUp];
}

- (void)recycleBuffer:(id)buffer
{
    if ( !buffer) return;

    //NSLog(@"%s ('%@'): recycling %@", __func__, [self name], buffer);
    
    if ([self usesPatchOriginatedSurfacesAsBuffers]) {
        [self returnSurfacesToPatchOwnedPool:[NSArray arrayWithObject:buffer]];
    }
    else {
        [_bufferStack pushBufferToBottom:buffer];
    }
}

- (void)pushBufferToStack:(id)buffer
{
    [_bufferStack pushBuffer:buffer];
}


#define LOCK_WAIT_MS 0.5

- (id)lockBufferWithIDGreaterThan:(int64_t)bufferID beforeIntervalSinceNow:(double)waitIntv
{
    if ([self streamState] != kLQStreamState_Active) return nil;

    if (_knownSampleInterval <= 0.0) {
        ///LXPrintf("'%s': no sample interval, returning latest\n", [[self name] UTF8String]);
        return [_bufferStack retainLatestBuffer];
    }

    ///NSLog(@"%@: looking for buffer ID %ld or higher...", self, (long)bufferID+1);
    
    DTIME(t0)
    id buffer = nil;
    double tA = t0;
    const double finalTime = t0 + waitIntv;
    
    while (t0 < finalTime) {
        buffer = [_bufferStack retainBufferWithIDGreaterThan:bufferID];
    
        if (buffer) {
            ///LQPrintf("  ... %p: got buffer %p with ID %i \n", self, buffer, [buffer sampleID]);
            break;
        } else {
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            t0 = LQReferenceTimeGetCurrent();
        }
    }
    return buffer;
}

- (id)lockBufferWithIDGreaterThanOrEqualTo:(int64_t)bufferID beforeIntervalSinceNow:(double)waitIntv
{
    if ([self streamState] != kLQStreamState_Active) return nil;

    if (_knownSampleInterval <= 0.0) {
        ///LXPrintf("'%s': no sample interval, returning latest\n", [[self name] UTF8String]);
        return [_bufferStack retainLatestBuffer];
    }

    ///NSLog(@"%@: looking for buffer ID %ld or higher...", self, (long)bufferID+1);
    
    DTIME(t0)
    id buffer = nil;
    double tA = t0;
    const double finalTime = t0 + waitIntv;
    
    while (t0 < finalTime) {
        buffer = [_bufferStack retainBufferWithIDGreaterThanOrEqualTo:bufferID];
    
        if (buffer) {
            ///LQPrintf("  ... %p: got buffer %p with ID %i \n", self, buffer, [buffer sampleID]);
            break;
        } else {
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            t0 = LQReferenceTimeGetCurrent();
        }
    }
    return buffer;
}


- (id)lockBufferWithReferenceTimeNewerThan:(double)refTime beforeIntervalSinceNow:(double)waitIntv
{
    if ([self streamState] != kLQStreamState_Active) return nil;

    if (_knownSampleInterval <= 0.0) {
        ///LXPrintf("'%s': no sample interval, returning latest\n", [[self name] UTF8String]);
        return [_bufferStack retainLatestBuffer];
    }
    
    DTIME(t0)
    id buffer = nil;            
    const double finalTime = t0 + waitIntv;
    
    while (t0 < finalTime) {
        buffer = [_bufferStack retainBufferWithReferenceTimeNewerThan:refTime];
    
        if (buffer) {
            break;
        } else {
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            t0 = LQReferenceTimeGetCurrent();
        }
    }    
    return buffer;
}

- (id)lockBufferWithReferenceTimeNewerThanOrEqualTo:(double)refTime beforeIntervalSinceNow:(double)waitIntv
{
    if ([self streamState] != kLQStreamState_Active) return nil;

    if (_knownSampleInterval <= 0.0) {
        ///LXPrintf("'%s': no sample interval, returning latest\n", [[self name] UTF8String]);
        return [_bufferStack retainLatestBuffer];
    }
    
    DTIME(t0)
    id buffer = nil;            
    const double finalTime = t0 + waitIntv;
    
    while (t0 < finalTime) {
        buffer = [_bufferStack retainBufferWithReferenceTimeNewerThanOrEqualTo:refTime];
    
        if (buffer) {
            break;
        } else {
            usleep(LOCK_WAIT_MS*1000);  // sleep while waiting for the buffer
            t0 = LQReferenceTimeGetCurrent();
        }
    }    
    return buffer;
}

- (id)lockLatestBufferNow
{
    if ([self streamState] != kLQStreamState_Active) return nil;

    return [_bufferStack retainLatestBuffer];
}

- (void)unlockBuffer:(id)buffer
{
    if (buffer) {
        [_bufferStack releaseBuffer:buffer];
    }
}

- (BOOL)outputsToBufferStack
{
    return YES;
}


#pragma mark --- threaded rendering ---

- (void)doScheduledRenderOnThread:(id)threadParamsDict
{
    // subclasses can override
}

- (void)pollOnWorkerThread:(id)threadParamsDict
{
    if (_knownSampleTime <= 0.0 || _knownSampleInterval <= 0.0) {
        LQPrintf("*** node '%s': can't render (intv %.6f, sampletime %f)\n", [[self name] UTF8String], _knownSampleInterval, _knownSampleTime);
        return;
    }
    
    if (_knownSampleInterval > 5.0) {
        NSLog(@"**** node %@: sample interval is very long, this is probably a bug ****", self);
    }

    DTIME(t0)

    double nextSampleTime = _knownSampleTime;    
    while (nextSampleTime < t0)
        nextSampleTime += _knownSampleInterval;

    // now we know when the next sample should be coming up, so wait for it
    
    id val;
    const BOOL wantsFullyRegular = ((val = [threadParamsDict objectForKey:kLQStreamThreadProperty_WantsFullyRegularRenderSchedule])) ? [val boolValue] : NO;
    const double pollsPerSecond = ((val = [threadParamsDict objectForKey:kLQStreamThreadProperty_PollsPerSecond])) ? [val doubleValue] : 60.0;
    NSAssert(pollsPerSecond > 0.0, @"invalid pollsPerSecond value for thread");
    const double pollInterval = 1.0/pollsPerSecond;
    
    double waitTime = nextSampleTime - t0;
    long waitTime_us = waitTime * 1000 * 1000;
    
    BOOL doRender = NO;
    
    //LQPrintf("polling %p (%s): time %f - waittime is %.3f ms (known time %.3f, interval is %.3f ms)\n", self, [[self name] UTF8String], t0, 1000*waitTime,
    //                        _knownSampleTime, 1000*_knownSampleInterval);
    
    // check how long it took for the last render; allow for a few samples to accumulate before trying this
    double avgRenderTime = 0.0;
    double lastRenderTime = 0.0;
    if (_bufferOutputTimeWatcher && [_bufferOutputTimeWatcher sampleCount] > 5) {
        avgRenderTime = [_bufferOutputTimeWatcher averageInterval];
        lastRenderTime = [_bufferOutputTimeWatcher latestInterval];
    }
    
    if ( !wantsFullyRegular && (avgRenderTime > (_knownSampleInterval*2.01)
                                                        || lastRenderTime > (_knownSampleInterval*3.5))) {
        ///LXPrintf("### %p (%s) going to render immediately because of long render time (avg %.3f ms, last %.3f ms, intv %.3f ms, count %i)\n", self, [[self name] UTF8String],
        ///                avgRenderTime*1000, lastRenderTime*1000, _knownSampleInterval*1000, (int)[_bufferOutputTimeWatcher sampleCount]);
        doRender = YES;
    }
    else
    if (waitTime_us > 10 &&            ///< pollInterval*1.01) {
                            waitTime < _knownSampleInterval*0.8) {
        
        //double timeInStream = LQReferenceTimeGetCurrent() - [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
        //LQPrintf(".. %p (%s) going to wait for sample; %.3f ms / sampleintv %.3f ms (time in stream now %f)\n", self, 
        //                                    [[self name] UTF8String], waitTime_us/1000.0, (_knownSampleInterval*1000), timeInStream);
                    
        usleep(waitTime_us - 10);
        
        doRender = YES;
        
        //timeInStream = LQReferenceTimeGetCurrent() - [[threadParamsDict objectForKey:kLQStreamThreadProperty_StreamStartReferenceTime] doubleValue];
        //LQPrintf("   .... rend %p (%s) finished waiting, stream time is %f\n", self, [[self name] UTF8String], timeInStream);
        
    }
    else if (waitTime < 0.8/1000.0 || (_knownSampleInterval - waitTime) < 1.0/1000.0) {
        // if the time is either very soon, or very close to the known interval (in which case we might have just missed a sample?)
        doRender = YES;
    }
    
    if (doRender) {
        if ( !_bufferOutputTimeWatcher) { /// || [_bufferOutputTimeWatcher isAtEnd]) {
            ///[_bufferOutputTimeWatcher release];
            _bufferOutputTimeWatcher = [[LQStreamTimeWatcher alloc] initWithCapacity:50];
            [_bufferOutputTimeWatcher setName:[self name]];
            [_bufferOutputTimeWatcher setIsFIFO:YES];
        }
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [self doScheduledRenderOnThread:threadParamsDict];
        
        [pool drain];
        
        ///LQPrintf("rend %p (%s) - latest render interval: %.3f ms\n", self, [[self name] UTF8String], 1000*[_bufferOutputTimeWatcher latestInterval]);
    }
}


- (LQStreamTimeWatcher *)renderTimeWatcher
{
    return _bufferOutputTimeWatcher;
}


- (void)doPostrollCleanUp
{
    _latestSampleID = -1;    

    LXInteger cleanCount = [_bufferStack cleanUp];
    
    ///NSLog(@"bufferingnode %@: buffer stack cleanup count %i", self, cleanCount);
    
    LXInteger n = 0;
    while ([_bufferStack numberOfExternalRetains] > 0 && n < 30) {
        usleep(10*1000);
        
        cleanCount = [_bufferStack cleanUp];
        NSLog(@"...bufferingnode '%@' had to retry cleanup, cleanup count %ld (remaining extrefs: %ld)", [self name], cleanCount, [_bufferStack numberOfExternalRetains]);
        n++;
    }
    
    [_bufferStack purgeAllCaches];
}

@end
