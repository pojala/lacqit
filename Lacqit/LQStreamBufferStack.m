//
//  LQStreamBufferStack.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamBufferStack.h"
#import "LQStreamBuffer.h"
#import "LQTimeFunctions.h"


#define ENTERBUFFERLOCK     [_bufferLock lock];
#define EXITBUFFERLOCK      [_bufferLock unlock];


@implementation LQStreamBufferStack

- (id)init
{
    self = [super init];
    
    _bufferLock = [[NSRecursiveLock alloc] init];
    if ([_bufferLock respondsToSelector:@selector(setName:)]) {
        [_bufferLock setName:[NSString stringWithFormat:@"bufferStack %p", self]];
    }
    
    _renderBuffers = [[NSMutableArray alloc] initWithCapacity:32];
    _bufferRetains = [[NSMutableArray alloc] initWithCapacity:32];
    _cleanUpStash = [[NSMutableArray alloc] initWithCapacity:32];

    return self;
}

- (void)dealloc
{
    [_bufferLock release];
    [_renderBuffers release];
    [_bufferRetains release];
    [_cleanUpStash release];
    [super dealloc];
}

- (void)setUsesStash:(BOOL)f {
    _usesStash = f; }
    
- (BOOL)usesStash {
    return _usesStash; }


- (LXInteger)numberOfBuffers
{
    ENTERBUFFERLOCK
    LXInteger count = [_renderBuffers count];
    EXITBUFFERLOCK
    return count;
}

- (int64_t)latestBufferID
{
    int64_t bufferID;
    ENTERBUFFERLOCK
    id lastBuffer = [_renderBuffers lastObject];
    bufferID = (lastBuffer) ? [lastBuffer sampleID] : 0;
    EXITBUFFERLOCK
    return bufferID;
}

- (double)latestBufferReferenceTime
{
    double t;
    ENTERBUFFERLOCK
    id lastBuffer = [_renderBuffers lastObject];
    t = (lastBuffer) ? [lastBuffer sampleReferenceTime] : 0.0;
    EXITBUFFERLOCK
    return t;
}

// this extra reference counting is necessary to keep track of
// which buffers are still in use by the stream (and thus can't be cleaned up).
// we only count external references, so the buffer retaincount starts at 0 when it's pushed.

- (void)pushBuffer:(id)buffer
{
    if ( !buffer) {
        NSLog(@"*** buffer stack %p (delegate is %@): attempt to insert nil buffer", self, _delegate);
    }
    ENTERBUFFERLOCK
    [_renderBuffers addObject:buffer];
    [_bufferRetains addObject:[NSNumber numberWithInt:0]];
    
    LXInteger count = [_renderBuffers count];
    if (count >= 2) {
        id prevBuffer = [_renderBuffers objectAtIndex:count-2];
        int64_t thisID = [buffer sampleID];
        int64_t prevID = [prevBuffer sampleID];
        if (prevID > thisID) {
            ///NSLog(@"*** samples pushed onto streambuffer stack in incorrect order (%lld, prev %lld)", thisID, prevID);
        }
    }
    EXITBUFFERLOCK
}

- (void)pushBufferToBottom:(id)buffer
{
    if ( !buffer) {
        NSLog(@"*** buffer stack %p (delegate is %@): attempt to insert nil buffer (at bottom of stack)", self, _delegate);
    }
    ENTERBUFFERLOCK
    [_renderBuffers insertObject:buffer atIndex:0];
    [_bufferRetains insertObject:[NSNumber numberWithInt:0] atIndex:0];
    EXITBUFFERLOCK
}

- (void)cleanUpAndPushBuffer:(id)buffer
{
    if ( !buffer) {
        NSLog(@"*** buffer stack %p (delegate is %@): attempt to insert nil buffer", self, _delegate);
    }
    ENTERBUFFERLOCK

    [self cleanUp];
    [self pushBuffer:buffer];

    EXITBUFFERLOCK
}

- (void)_addRetainForIndex:(LXInteger)index
{
    int bufRetCount = [[_bufferRetains objectAtIndex:index] intValue];
    bufRetCount++;
    [_bufferRetains replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:bufRetCount]];    
    
    //NSLog(@"added retain, count %i, buffer %@", bufRetCount, [_renderBuffers objectAtIndex:index]);
}

- (id)retainLatestBuffer
{
    ENTERBUFFERLOCK
    id buffer = [_renderBuffers lastObject];
    
    if (buffer) {
        [self _addRetainForIndex:([_renderBuffers count]-1)];
        [buffer retain];
    }
    
    EXITBUFFERLOCK
    return buffer;
}

- (void)releaseBuffer:(id)buffer
{
    ENTERBUFFERLOCK
    LXInteger index = [_renderBuffers indexOfObject:buffer];
    
    int bufRetCount = 0;
    
    if (index == NSNotFound) {
        // this probably means that -purgeAllCaches was called while the buffer was being used.
        // no problem, we'll just give it a regular release.
    }
    else {    
        bufRetCount = [[_bufferRetains objectAtIndex:index] intValue];
        bufRetCount--;
        [_bufferRetains replaceObjectAtIndex:index withObject:[NSNumber numberWithInt:bufRetCount]];
    }
    
    //LQPrintf("..releasing buffer with id %ld, %s (index is %ld; retcount now %i; delegate %s; total %i)\n", (long)[buffer sampleID],
    //            [NSStringFromClass([buffer class]) UTF8String], (long)index, bufRetCount, [[_delegate name] UTF8String], (int)[self numberOfBuffers]);
    
    [buffer release];
    EXITBUFFERLOCK
}


- (id)popOldestBufferWithoutExternalRetains
{
    id bufObj = nil;
    ENTERBUFFERLOCK
    
    if ([_cleanUpStash count] > 0) {
        bufObj = [_cleanUpStash objectAtIndex:0];
        [bufObj retain];
        [_cleanUpStash removeObjectAtIndex:0];
        goto bail;
    }
    
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        int refCount = [[_bufferRetains objectAtIndex:i] intValue];
        if (refCount < 1) {
            bufObj = [_renderBuffers objectAtIndex:i];
            [bufObj retain];
            
            [_renderBuffers removeObjectAtIndex:i];
            [_bufferRetains removeObjectAtIndex:i];
            break;
        }
    }

bail:
    EXITBUFFERLOCK
    return bufObj;
}


- (id)popAndCleanUp
{
    id bufObj = nil;
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    
    if (count > 0) {
        bufObj = [_renderBuffers objectAtIndex:count-1];
        [bufObj retain];
        
        int refCount = [[_bufferRetains objectAtIndex:count-1] intValue];
        if (refCount < 1) {
            [_renderBuffers removeObjectAtIndex:count-1];
            [_bufferRetains removeObjectAtIndex:count-1];
        }
    }
    
    count--;
    if (count > 0) {
        [self cleanUp];
    }
    
    EXITBUFFERLOCK
    return bufObj;
}

- (LXInteger)cleanUp
{
    LXInteger cleanCount = 0;
    LXInteger i;
        
    if ( ![_delegate stackShouldPerformCleanup:self])
        return 0;
    ENTERBUFFERLOCK

    // just a sanity check that the stash of "almost-released" buffers isn't growing too large
    if ([_cleanUpStash count] > 4) {
        NSRange rangeToClean = NSMakeRange(0, [_cleanUpStash count] - 4);
        for (i = 0; i < rangeToClean.length; i++) {
            [_delegate stack:self willReleaseBuffer:[_cleanUpStash objectAtIndex:i]];
        }
        [_cleanUpStash removeObjectsInRange:rangeToClean];
    }
    
    LXInteger count = [_renderBuffers count];
    LXInteger amountToLeave = _cleanUpMinimum;
    for (i = 0; i < count; i++) {
        id buffer = [_renderBuffers objectAtIndex:i];
        int retCount = [[_bufferRetains objectAtIndex:i] intValue];
        
        if (retCount < 1) {
            BOOL doRemove = YES;
            if (i < (count - amountToLeave)) {
                // really release the thing
                [_delegate stack:self willReleaseBuffer:buffer];
            } else {
                // keep it around for recycling
                if (1 || _usesStash) {  /// OTHER PATH IS DISABLED
                    [_cleanUpStash addObject:buffer];
                    doRemove = YES;
                } else {
                    doRemove = NO;
                }
            }
            
            if (doRemove) {
                [_renderBuffers removeObjectAtIndex:i];
                [_bufferRetains removeObjectAtIndex:i];
                i--;
                count--;
                cleanCount++;
            }
        }
    }
        
    EXITBUFFERLOCK
    [_delegate stackDidPerformCleanup:self];
    
    return cleanCount;
}

- (void)purgeAllCaches
{
    ENTERBUFFERLOCK
    [self cleanUp];
    [_renderBuffers removeAllObjects];
    [_bufferRetains removeAllObjects];
    [_cleanUpStash removeAllObjects];
    EXITBUFFERLOCK
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
}

- (id)delegate
{
    return _delegate;
}

- (void)lockStack {
    ENTERBUFFERLOCK
}

- (void)unlockStack {
    EXITBUFFERLOCK
}

- (void)setCleanUpMinimumToKeep:(LXInteger)minToKeep {
    ENTERBUFFERLOCK
    _cleanUpMinimum = minToKeep;
    EXITBUFFERLOCK
}

- (LXInteger)cleanUpMinimumToKeep {
    LXInteger v;
    ENTERBUFFERLOCK
    v = _cleanUpMinimum;
    EXITBUFFERLOCK
    return v;
}


- (LXInteger)numberOfExternalRetains
{
    LXInteger retains = 0;
    LXInteger bufferCount;
    ENTERBUFFERLOCK
    
    bufferCount = [_renderBuffers count];
    
    LXInteger i;
    for (i = 0; i < bufferCount; i++) {
        int bufRetCount = [[_bufferRetains objectAtIndex:i] intValue];
        if (bufRetCount > 0) {
            //NSLog(@"buffer %i -- retcount is %i -- object is: %@", i, bufRetCount, [_renderBuffers objectAtIndex:i]);
            retains++;
        }
    }
    
    EXITBUFFERLOCK
    
    ///NSLog(@"%@: buffercount %i, ext retains %i", self, bufferCount, retains);
    return retains;
}


- (id)retainBufferWithReferenceTimeNewerThan:(double)t
{
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    id foundBuffer = nil;
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleReferenceTime)]) {
            NSLog(@"*** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
        } else {        
            if ([buffer sampleReferenceTime] > t) {
                foundBuffer = buffer;
                break;
            }
        }
    }
    
    if (foundBuffer) {
        [self _addRetainForIndex:i];
        [foundBuffer retain];
    }
    EXITBUFFERLOCK
    return foundBuffer;
}

- (id)retainBufferWithReferenceTimeNewerThanOrEqualTo:(double)t
{
    return [self retainBufferWithReferenceTimeNewerThan:t - 0.00001];
}

- (id)retainBufferWithIDClosestTo:(int64_t)expID
{
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    id closestBuffer = nil;
    int64_t closestID = -1000;
    LXInteger closestBufIndex = -1;
    
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleID)]) {
            NSLog(@"*** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
            break;
        } else {
            int64_t sampleID = [buffer sampleID];
            if (abs(expID - sampleID) < abs(expID - closestID)) {
                closestBuffer = buffer;
                closestID = sampleID;
                closestBufIndex = i;
            }
        }
    }

    if (closestBuffer) {
        ///LQPrintf("..retaining closest buffer with id %ld\n", (long)[closestBuffer sampleID]);
        [self _addRetainForIndex:closestBufIndex];
        [closestBuffer retain];
    }
    EXITBUFFERLOCK
    return closestBuffer;  
}


- (id)_retainBufferWithIDMin:(int64_t)minID max:(int64_t)maxID
{
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    id foundBuffer = nil;
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleID)]) {
            NSLog(@"*** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
            break;
        } else {
            int64_t sampleID = [buffer sampleID];
            if (sampleID >= minID && sampleID <= maxID) {
                foundBuffer = buffer;
                break;
            }
        }
    }

    if (foundBuffer) {
        //LQPrintf("..retaining buffer with id %ld (retcount now %i; delegate %s)\n", (long)[foundBuffer sampleID], [[_bufferRetains objectAtIndex:i] intValue], [[_delegate name] UTF8String]);
        [self _addRetainForIndex:i];
        [foundBuffer retain];
    }
    EXITBUFFERLOCK
    return foundBuffer;  
}

- (id)retainBufferWithIDGreaterThan:(int64_t)expID
{
    return [self _retainBufferWithIDMin:expID + 1 max:INT64_MAX];
}

- (id)retainBufferWithIDGreaterThanOrEqualTo:(int64_t)expID
{
    return [self _retainBufferWithIDMin:expID max:INT64_MAX];
}

- (id)retainBufferWithID:(int64_t)wantedID
{
    id foundBuffer = nil;
    ENTERBUFFERLOCK

    // the caller may be looking for an older buffer that's already in the cleanup stash
    if ([_cleanUpStash count] > 0) {
        LXInteger i;
        LXInteger n = [_cleanUpStash count];
        for (i = 0; i < n; i++) {
            id buffer = [_cleanUpStash objectAtIndex:i];
            if ([buffer sampleID] == wantedID) {
                ///NSLog(@"%s: found buffer in cleanup stash: %@ (stash count %i)", __func__, buffer, (int)n);
                foundBuffer = buffer;
                break;
            }
        }
        if (foundBuffer) {
            [foundBuffer retain];
            [_cleanUpStash removeObject:foundBuffer];
            
            [self pushBufferToBottom:foundBuffer];
            [self _addRetainForIndex:0];
        }
    }
    
    if ( !foundBuffer) {
        foundBuffer = [self _retainBufferWithIDMin:wantedID max:wantedID];
    }
    
    EXITBUFFERLOCK
    return foundBuffer;
}

- (BOOL)containsBufferWithID:(int64_t)wantedID
{
    BOOL found = NO;
    ENTERBUFFERLOCK
    
    LXInteger count = [_renderBuffers count];
    LXInteger i;
    for (i = count-1; i >= 0; i--) {
        id buffer = [_renderBuffers objectAtIndex:i];
        
        if ( ![buffer respondsToSelector:@selector(sampleID)]) {
            NSLog(@"*** %s (%@): buffer doesn't implement expected method (%@)", __func__, self, buffer);
            break;
        } else {
            int64_t sampleID = [buffer sampleID];
            if (sampleID == wantedID) {
                found = YES;
                break;
            }
        }
    }

    EXITBUFFERLOCK
    return found;
}

@end
