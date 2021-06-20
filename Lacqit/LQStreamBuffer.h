//
//  LQStreamBuffer.h
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
#import "LacqitExport.h"


@interface LQStreamBuffer : NSObject {

    int64_t _sampleID;
    double _refTime;
    double _originalTime;
    double _sourceTime;
    
    id _owner;
}

- (void)setOwner:(id)owner;
- (id)owner;

- (void)setSampleID:(int64_t)sampleID;
- (int64_t)sampleID;

- (void)setSampleReferenceTime:(double)t;
- (double)sampleReferenceTime;

- (void)setOriginalSampleReferenceTime:(double)t;
- (double)originalSampleReferenceTime;

- (void)setSampleSourceTime:(double)t;
- (double)sampleSourceTime;

- (void)propagatePropertiesFromSample:(id)sample;

// comparison value is NSComparisonResult (suitable for sorting with NSMutableArray's -sortUsingSelector: method)
- (LXInteger)compareSampleID:(LQStreamBuffer *)other;
- (LXInteger)compareSampleReferenceTime:(LQStreamBuffer *)other;

@end


/*
  A plain-C utility object for handling stream buffers from different sources in a more uniform way.
*/
typedef struct LQLockedStreamBuffer *LQLockedStreamBufferPtr;

LACQIT_EXPORT LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithLatestFromNode(id node);  // calls -lockLatestBufferNow on the node
LACQIT_EXPORT LQLockedStreamBufferPtr LQLockedStreamBufferCreateByRetain(id buffer);

LACQIT_EXPORT id LQLockedStreamBufferGetBuffer(LQLockedStreamBufferPtr lockBuf);

LACQIT_EXPORT void LQLockedStreamBufferDestroy(LQLockedStreamBufferPtr lockBuf);

LACQIT_EXPORT LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithLockedBufferAndNode(id buffer, id owner);
LACQIT_EXPORT LQLockedStreamBufferPtr LQLockedStreamBufferCreateWithRecyclableBufferAndNode(id buffer, id owner);


