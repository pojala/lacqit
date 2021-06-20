//
//  LQBufferingStreamNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamNode.h"
@class LQStreamTimeWatcher;
@class LQStreamBufferStack;


@interface LQBufferingStreamNode : LQStreamNode {

    BOOL _debugDummyMode;

    LQStreamBufferStack *_bufferStack;
    
    // render info
    LQStreamTimeWatcher *_bufferOutputTimeWatcher;
    
    int64_t _latestSampleID;    
}


- (int64_t)latestBufferID;
- (double)latestBufferReferenceTime;

// -- multibuffering implementation --

- (BOOL)outputsToBufferStack;

// to access the newest buffer, lock it with these methods.
// although this is called a "lock", the default implementation just gets a buffer
// from the stack and uses retain/release semantics for lockBuffer/unlockBuffer
// (i.e. acquiring this lock for a long time doesn't prevent the stream from adding
// new buffers to the stream).
//
// passing 0 for bufferID or refTime will simply get you the newest buffer;
// otherwise the node will wait the specified time for a new buffer to come in.
// (this is useful when you know that a new buffer is due any time now,
// e.g. when consuming live samples.)
//
- (id)lockBufferWithIDGreaterThan:(int64_t)bufferID beforeIntervalSinceNow:(double)waitIntv;
- (id)lockBufferWithIDGreaterThanOrEqualTo:(int64_t)bufferID beforeIntervalSinceNow:(double)waitIntv;
- (id)lockBufferWithReferenceTimeNewerThan:(double)refTime beforeIntervalSinceNow:(double)waitIntv;
- (id)lockBufferWithReferenceTimeNewerThanOrEqualTo:(double)refTime beforeIntervalSinceNow:(double)waitIntv;
- (id)lockLatestBufferNow;

- (void)unlockBuffer:(id)buffer;

// instead of locking, you can also pop the buffer from the stack,
// in which case you own it and should deal with it appropriately (e.g. return it to an LQXSurfacePool).
// 
// this is feasible in a situation where you know you're the only consumer of these buffers
// (e.g. a presenter that draws on-screen), so it's ok to clear the buffer stack.
//
// returned object is retained.
- (id)popBufferFromStackAndClear;

// when the buffer consumer is done with a popped buffer, it can return it to
// to the node using this call.
// the default implementation returns patch-originated surfaces to the pool, and
// for other buffer types, just pushes the buffer back to the bottom of the stack.
//
// this call does _not_ release the buffer object, so that's still the caller's responsibility.
- (void)recycleBuffer:(id)buffer;

// override to YES if the buffers are surfaces from the patch-owned pool,
// so the default implementation will manage them automatically
- (BOOL)usesPatchOriginatedSurfacesAsBuffers;

// override for rendering
- (void)doScheduledRenderOnThread:(id)threadParamsDict;

// for statistics
- (LQStreamTimeWatcher *)renderTimeWatcher;

// to be called in -waitForPostroll..; empties the buffer stack and resets frame counter
- (void)doPostrollCleanUp;

@end
