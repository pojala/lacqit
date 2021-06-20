//
//  LQStreamBufferStack.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamBuffer.h"


@interface LQStreamBufferStack : NSObject {

    NSLock *_bufferLock;
    NSMutableArray *_renderBuffers;
    NSMutableArray *_bufferRetains;
    
    LXInteger _cleanUpMinimum;
    NSMutableArray *_cleanUpStash;
    BOOL _usesStash;
    
    id _delegate;
}

- (int64_t)latestBufferID;
- (double)latestBufferReferenceTime;

- (void)setDelegate:(id)delegate;
- (id)delegate;


- (void)pushBuffer:(id)buffer;
- (void)cleanUpAndPushBuffer:(id)buffer;

- (id)retainLatestBuffer;
- (id)retainBufferWithID:(int64_t)sampleID;

- (id)retainBufferWithReferenceTimeNewerThan:(double)t;
- (id)retainBufferWithReferenceTimeNewerThanOrEqualTo:(double)t;
- (id)retainBufferWithIDGreaterThan:(int64_t)expID;
- (id)retainBufferWithIDGreaterThanOrEqualTo:(int64_t)expID;
- (id)retainBufferWithIDClosestTo:(int64_t)expID;

- (void)releaseBuffer:(id)buffer;

- (BOOL)containsBufferWithID:(int64_t)sampleID;

// removes all buffers that haven't been retained through -retainLastBuffer,
// and returns the number of buffers released
- (LXInteger)cleanUp;

// pop method removes the latest buffer from the stack.
// it should only be used if you know you're the only consumer of this buffer
// (e.g. a presenter that takes a rendered surface).
// the returned buffer is retained.
- (id)popAndCleanUp;

// useful for recycling buffers within a node's implementation
- (id)popOldestBufferWithoutExternalRetains;

- (void)pushBufferToBottom:(id)buffer;

// hardcore cleanup of all buffers
- (void)purgeAllCaches;

- (void)lockStack;
- (void)unlockStack;

- (LXInteger)numberOfBuffers;
- (LXInteger)numberOfExternalRetains;

- (void)setCleanUpMinimumToKeep:(LXInteger)minToKeep;
- (LXInteger)cleanUpMinimumToKeep;

///- (void)setUsesStash:(BOOL)f;
///- (BOOL)usesStash;

@end


@interface NSObject (LQStreamBufferStackDelegate)

- (BOOL)stackShouldPerformCleanup:(LQStreamBufferStack *)stack;

- (void)stack:(LQStreamBufferStack *)stack willReleaseBuffer:(id)buffer;

- (void)stackDidPerformCleanup:(LQStreamBufferStack *)stack;

@end