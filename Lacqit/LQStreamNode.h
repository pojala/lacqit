//
//  LQStreamNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQScriptableBaseNode.h"
@class LQJSEventRoster;


enum {
    kLQStreamNodeConnectionType_Image = 0x1000
};


@interface LQStreamNode : LQScriptableBaseNode {

    // state during stream preroll
    id _prerollDelegate;
    
    // stream info
    LXUInteger _nodeStreamState;
    double _knownSampleTime;
    double _knownSampleInterval;

    // worker thread
	NSConditionLock     *_condLock;
    LXInteger           _threadMsg;
    NSDictionary        *_threadMsgDict;
    
    // worker thread state (only for subclasses to modify)
    double              _initialWaitOnCondLock;

    void *__res_sn1;
    void *__res_sn2;
}

+ (BOOL)canBecomePrimaryPresenter;

// this info is available only when preroll is completed
- (double)sampleScheduleKnownReferenceTime;  // a "known" time is usually from an external source (e.g. video capture)
- (double)sampleScheduleTimeInterval;

- (LXUInteger)streamState;

// nodes that always need to be eval'ed in the streampatch context can return YES
- (BOOL)wantsEvalIfNotConnectedToPresenter;

// eval implementation utilities
- (BOOL)canEvalWithContext:(NSDictionary *)context;
- (double)currentTimeInStreamFromEvalContext:(NSDictionary *)context;

- (void)invalidateCaches;

// the "onRender" function is meant to be called within eval
- (id)runOnRenderScriptForOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context;


// -- implementation methods that subclasses can override --

- (NSArray *)scriptEvalArgumentsForOutputIndex:(LXInteger)index
                                    inputLists:(LACArrayListPtr *)inputLists
                                    context:(NSDictionary *)context;

@end
