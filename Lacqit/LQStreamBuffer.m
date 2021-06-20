//
//  LQStreamBuffer.m
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamBuffer.h"
#import "LQBufferingStreamNode.h"


@implementation LQStreamBuffer

+ (NSString *)lacTypeID {
    return @"StreamBuffer"; }


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (id %ld, refTime %.3f, sourceTime %.3f)>",
                        [self class], self,
                        (long)[self sampleID],
                        [self sampleReferenceTime],
                        [self sampleSourceTime]
                    ];
}


- (void)setSampleID:(int64_t)sampleID {
    _sampleID = sampleID; }
    
- (int64_t)sampleID {
    return _sampleID; }
    
    
- (void)setSampleReferenceTime:(double)t {
    _refTime = t; }
    
- (double)sampleReferenceTime {
    return _refTime; }

- (void)setOriginalSampleReferenceTime:(double)t {
    _originalTime = t;
    
    if (_refTime < t)
        _refTime = t;
}
    
- (double)originalSampleReferenceTime {
    return _originalTime; }


- (void)setSampleSourceTime:(double)t {
    _sourceTime = t; }
    
- (double)sampleSourceTime {
    return _sourceTime; }


- (void)setOwner:(id)owner {
    _owner = owner; }
    
- (id)owner {
    return _owner; }


- (void)propagatePropertiesFromSample:(id)sample
{
    [self setSampleID:[sample sampleID]];
    [self setOriginalSampleReferenceTime:[sample originalSampleReferenceTime]];
    [self setSampleReferenceTime:[sample sampleReferenceTime]];
    [self setSampleSourceTime:[sample sampleSourceTime]];
}


- (LXInteger)compareSampleID:(LQStreamBuffer *)other
{
    int64_t a = [self sampleID];
    int64_t b = [other sampleID];
    
    if (b > a)
        return NSOrderedAscending;
    else if (b < a)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (LXInteger)compareSampleReferenceTime:(LQStreamBuffer *)other
{
    double a = [self sampleReferenceTime];
    double b = [other sampleReferenceTime];
    
    if (b > a)
        return NSOrderedAscending;
    else if (b < a)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@end


typedef struct LQLockedStreamBuffer {
    id buffer;
    id node;
    LXUInteger retainType;
    void *__res;
} LQLockedStreamBuffer;


LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithLatestFromNode(id node)
{
    id buffer = [node lockLatestBufferNow];
    if (buffer) {
        return LQLockedStreamBufferCreateWithLockedBufferAndNode(buffer, node);
    }
    else return NULL;
}

LQLockedStreamBufferPtr LQLockedStreamBufferCreateByRetain(id buffer)
{
    if ( !buffer) return NULL;
    LQLockedStreamBuffer *lockBuf = _lx_calloc(sizeof(LQLockedStreamBuffer), 1);
    lockBuf->buffer = [buffer retain];
    lockBuf->retainType = 1;
    return lockBuf;
}

void LQLockedStreamBufferDestroy(LQLockedStreamBufferPtr lockBuf)
{
    if ( !lockBuf) return;
    
    //NSLog(@"%s -- rettype %i -- buffer %@", __func__, lockBuf->retainType, lockBuf->buffer);
    
    switch (lockBuf->retainType) {
        case 1:
            [lockBuf->buffer release];
            break;
        case 2:
            [lockBuf->node unlockBuffer:lockBuf->buffer];
            break;
        case 3:
            [lockBuf->node recycleBuffer:lockBuf->buffer];
            break;
    }
    
    _lx_free(lockBuf);
}

id LQLockedStreamBufferGetBuffer(LQLockedStreamBufferPtr lockBuf)
{
    if ( !lockBuf) return nil;
    return lockBuf->buffer;
}

LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithLockedBufferAndNode(id buffer, id owner)
{
    if ( !buffer) return NULL;
    LQLockedStreamBuffer *lockBuf = _lx_calloc(sizeof(LQLockedStreamBuffer), 1);
    lockBuf->buffer = buffer;
    lockBuf->node = owner;
    lockBuf->retainType = 2;
    return lockBuf;
}

LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithRecyclableBufferAndNode(id buffer, id owner)
{
    if ( !buffer) return NULL;
    LQLockedStreamBuffer *lockBuf = _lx_calloc(sizeof(LQLockedStreamBuffer), 1);
    lockBuf->buffer = buffer;
    lockBuf->node = owner;
    lockBuf->retainType = 3;
    return lockBuf;
}
