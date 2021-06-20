/*
 *  LQStreamNode_priv.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 4.1.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#import <Lacefx/Lacefx.h>

#import "LQStreamNode.h"
#import "LQStreamPatch.h"
#import "LQStreamBufferStack.h"
#import "LQStreamTimeWatcher.h"
#import "LACNode_priv.h"

#import "LQLXBasicFunctions.h"
#import "LQNSValueAdditions.h"
#import "LQTimeFunctions.h"
#import "LQJSEventRoster.h"
#import "LQJSBridge_StreamNodeBase.h"

#import <unistd.h>


enum {
    kThreadCond_NoRequest = 0,
    kThreadCond_HasRequest = 1,
    kThreadCond_ThreadHasStarted = 2,
    kThreadCond_ThreadHasFinished = 0x10,
};
enum {
    kThreadMsg_Proceed = 0,
    kThreadMsg_ExitNow = 0x100,
};

extern NSString *kLQStreamThreadProperty_PollsPerSecond;
extern NSString *kLQStreamThreadProperty_StreamStartReferenceTime;
extern NSString *kLQStreamThreadProperty_WantsFullyRegularRenderSchedule;


@interface LQStreamNode (PrivateToPatch)

- (void)prerollAsyncWithDelegate:(id)del;
- (void)playNow;
- (void)postrollAsync;
- (void)waitForPostrollToFinish;

- (void)startWorkerThread;

- (void)signalWorkerThreadWithDict:(NSDictionary *)dict;

- (void)signalWorkerThreadToExit;
- (void)waitForWorkerThreadToExit;
- (void)stopWorkerThread;  // merely calls the above two methods in order

- (BOOL)patchShouldCreateJSTimerWithTag:(LXInteger)tag repeats:(BOOL)doRepeat;

@end


@interface LQStreamNode (PrivateToPatchEvalOutsidePresenter)
- (NSDictionary *)willEvalOutsidePresenterUsingContext:(NSDictionary *)evalCtx;
@end

@interface LQStreamNode (PrivateToInterNodeNegotiation)
- (void)setStreamState:(LXUInteger)state;
- (void)recursivelySetStreamState:(LXUInteger)state;

// optional method: nodes that can't accept an LXSurface stream buffer should return YES,
// and renderers can do a readback accordingly
- (BOOL)requiresPixelBufferForSurfaceInput;
@end


@interface NSObject (LQStreamNodePlaybackDelegate)
- (void)streamNodeFinishedPreroll:(LQStreamNode *)node;
- (void)streamNode:(LQStreamNode *)node prerollFailedWithError:(NSError *)err;
@end


@interface LQStreamNode (ThreadingPrivateMethods)
- (NSDictionary *)parametersForWorkerThread;

- (void)didEnterWorkerThread:(id)threadParamsDict;
- (BOOL)handleMessageInWorkerThreadMainLoop:(id)threadParamsDict;
- (void)pollOnWorkerThread:(id)threadParamsDict;
- (void)willExitWorkerThread:(id)threadParamsDict;
@end

