//
//  LQStreamPatch.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LACMutablePatch.h"
#import "LQTimeFunctions.h"
#import "LQModelConstants.h"
#import <LacqJS/LacqJS.h>
#import "LQXSurfacePool.h"


enum {
    kLQStreamState_Idle = 0,
    kLQStreamState_Waiting,
    kLQStreamState_Prerolled,
    kLQStreamState_Paused,
    kLQStreamState_Active
};
typedef LXUInteger LQStreamState;

LACQIT_EXPORT NSString *NSStringFromLQStreamState(LQStreamState state);


enum {
    kLQStreamIsFreeRun = 0,
    kLQStreamIsJamSynced
};
typedef LXUInteger LQStreamPatchSyncMode;


// patch evaluation context keys
LACQIT_EXPORT_VAR NSString * const kLQStreamPatchCtxKey_RequestedTime;  // NSNumber
LACQIT_EXPORT_VAR NSString * const kLQStreamPatchCtxKey_RequestedTimeConstrainedToProjectBase;  // NSNumber
LACQIT_EXPORT_VAR NSString * const kLQStreamPatchCtxKey_RequestedTimeFrameIncrement;  // NSNumber
LACQIT_EXPORT_VAR NSString * const kLQStreamPatchCtxKey_RenderFailures; // NSMutableSet with nodes that failed to render during this eval



@interface LQStreamPatch : LACMutablePatch {

    NSRecursiveLock *_streamLock;
    LXUInteger _streamState;
    double _streamStartTime;
    double _streamStartTime_wallClock_nsDate;
    NSArray *_activeStreamNodes;

    int _prerollWaitState;
    NSMutableArray *_prerollWaitList;    

    id _primaryPresenter;
    LXUInteger _syncMode;
    BOOL _isTimeline;
    double _inTime;
    
    // lx graphics state
    LQXSurfacePool *_surfacePool;
    LXSize _preferredRenderSize;
    BOOL _prefersRenderSpeedToPrecision;
    BOOL _prefersRenderNoVSync;
    BOOL __resGfxBool[2];
    
    // javascript state
    BOOL _sharedJSContainer;
    LQJSContainer *_jsSandbox;
    id _jsObj_stream;
    id _jsObj_sysBridge;
    id _jsObj_app;
    NSMutableArray *_jsIntervalTimers;
    id _jsInterceptionDelegate;
    
    id _jsActiveNode;
    NSString *_jsActiveNodeFuncName;
    
    id _jsCreationDelegate;
    
    // eval state
    NSMutableArray *_surfacesFromPoolWithinEval;
    double _latestEvalTime;
    
    NSLock *_infoLock;
    NSString *_lockHolderName;
}

- (id)initWithSurfacePool:(LQXSurfacePool *)surfacePool;  // can be nil (the patch will create its own pool)
- (id)initWithSurfacePool:(LQXSurfacePool *)surfacePool shareJSContainer:(LQJSContainer *)shareJSContainer;

- (void)prerollAndPlay;
- (void)preroll;
- (void)play;
- (void)stop;
- (void)rewind;
- (void)windToTimeInStream:(double)t;

- (double)inTimeInStream;
- (void)setInTimeInStream:(double)t;

// only the preroll/play/stop operations acquire this lock automatically;
// **** for any other operations on the patch _or_ its contained nodes, you must get this lock ****
// (unless you know the patch is not in a playback state)
- (BOOL)lockStreamBeforeIntervalSinceNow:(double)intv;
- (void)unlockStream;

- (NSString *)lockHolderName;
- (void)setLockHolderName:(NSString *)str;

// this calls -lockStream.. with a default timeout (always check for the result value).
// the call may do something else UI-related too, so don't use it for non-UI updates.
- (BOOL)enterUIAction;
- (void)exitUIAction;

// performs a delayed selector on the main thread, with the stream lock acquired if specified
- (void)performAsyncSelectorOnMainThread:(SEL)sel target:(id)target argumentObject:(id)arg withinStreamLock:(BOOL)enterStreamLock;


- (id)primaryPresenter;
- (void)setPrimaryPresenter:(id)node;

- (LQStreamPatchSyncMode)streamSyncMode;
- (void)setStreamSyncMode:(LQStreamPatchSyncMode)syncMode;

- (BOOL)isFixedTimeline;
- (void)setIsFixedTimeline:(BOOL)f;

- (LQStreamState)streamState;

- (double)streamStartReferenceTime;          // this is a monotonically increasing reftime from LQReferenceTimeGetCurrent()
- (NSDate *)streamStartTimeAsWallClockDate;  // this is the "wall clock" time taken at the same time as the start reftime
- (double)latestEvalReferenceTime;

- (LQXSurfacePool *)surfacePool;

- (LXSize)preferredRenderSize;
- (void)setPreferredRenderSize:(LXSize)size;

- (BOOL)prefersRenderSpeedToPrecision;
- (void)setPrefersRenderSpeedToPrecision:(BOOL)f;

- (BOOL)prefersRenderWithoutVSync;
- (void)setPrefersRenderWithoutVSync:(BOOL)f;

- (BOOL)isEvalLoggingEnabled;
- (void)setEvalLoggingEnabled:(BOOL)f;

// utility methods for creating nodes
- (NSString *)validateNodeName:(NSString *)proposedName integerSuffix:(LXInteger)suffix;  // pass 0 for suffix

// utility methods for finding nodes
- (NSArray *)nodesWithPrimaryPresenterConnection;
- (id)findFirstPresentableNodeOfClass:(Class)cls;


// --- scripting ---

- (LQJSInterpreter *)jsInterpreter;
- (id)executeScript:(NSString *)script;

// the "this" object for this stream (a JSKitObject *).
// all eval/func calls made to this patch's jsInterpreter should be made in this object context
- (id)streamJSThis;

// "app" and "stream" JS singleton objects.
- (id)jsSingleton_stream;   // this is an LQJSBridge_StreamPatch object that provides stream services
- (id)jsSingleton_app;      // empty object for app-specific properties (in CL2, the project will fill this object with stuff like plugin's bridges)

- (BOOL)runMethodNamed:(NSString *)funcName onNode:(id)node parameters:(NSArray *)params resultPtr:(id *)outResult;

- (void)willEnterJSMethodNamed:(NSString *)funcName onNode:(id)node;
- (void)didExitJSMethod;

// currently this can be used to catch setInterval() / clearInterval() calls.
// informal protocol definition is below
- (void)setJSCallInterceptionDelegate:(id)obj;
- (void)clearJSTimerWithTag:(LXInteger)timerTag;  // does not call the interception delegate

// utility methods for marshalling eval result data for JS scripts
- (id)jsifyAndRetainEvalResultObject:(id)obj;  // makes bridge objects for known classes (e.g. NSData -> ByteBuffer)
- (id)createJSMapObjectFromEvalInputList:(LACArrayListPtr)inputList;  // returns a JavaScript "Map" object (defined in "Map.js")

- (void)addTimerToCommonRunLoopModes:(NSTimer *)timer;  // this adds the timer to any extra runloop modes where the stream ought to run (NSDefaultRunLoopMode not included)


// --- eval ----

// to render a single frame (outside of playback),
// call -evaluateNode:forOutputAtIndex:withContext: and pass the frame time for 'kLQStreamPatchCtxKey_RequestedTime'.
//
// this message is a convenience that calls the eval method on the primary presenter node.
// you should call -cleanupAfterEvalRender: when you're done using the returned frame (because it may be a surface from the pool).
// NOTE: the returned object can be an array of frames (for a multihead presenter)!
//
- (LACArrayListPtr)evaluateSingleFrameOnPrimaryPresenterAtTime:(double)timeInStream withContext:(NSDictionary *)context;

// surround a presenter eval call with these (-evaluateSingleFrameOnPrimaryPresenter.. does it)
- (void)willEvaluateForPresenter:(id)presenter withContext:(NSDictionary *)context;
- (void)didEvaluateForPresenter:(id)presenter;

- (void)cleanupAfterEvalRender;

// these manage an array of rendered objects that can be LQLXSurfaces, which will be then returned to the pool
- (void)object:(id)obj willAssumeOwnershipOfManagedBuffersFromEvalRender:(NSArray *)buffers;
- (void)cleanupManagedBuffers:(NSArray *)buffers;

// when rendering a single frame, it's necessary to keep track of surfaces acquired during rendering
- (void)streamNode:(id)node didRequestSurfaceFromPoolDuringEval:(LXSurfaceRef)surface;


// --- private ----
- (void)_logJSError:(NSError *)error type:(LXInteger)errorType;

- (NSString *)_tagHashForNode:(id)node;

- (void)setJSCreationDelegate:(id)del;
+ (void)setJSCreationDelegate:(id)del;

@end


// some nodes (or other script containers) want to intercept timer calls made from within their scripts
@interface NSObject (LQStreamPatchJSCallInterception)

// if the delegate wants to control the timer itself,
// it should return NO from this call while returning YES for reserveThisTag.
// this causes the patch to reserve the tag, but not initiate the timer on its own.
- (BOOL)shouldSetJSTimerWithTag:(LXInteger)timerTag repeats:(BOOL)doRepeat function:(id)funcObj interval:(double)interval reserveThisTag:(BOOL *)pDoReserve;
- (void)didSetJSTimerWithTag:(LXInteger)timerTag repeats:(BOOL)doRepeat;

- (BOOL)shouldClearJSTimerWithTag:(LXInteger)timerTag;
- (void)didClearJSTimerWithTag:(LXInteger)timerTag;

@end


@interface NSObject (LQStreamPatchJSCreationDelegate)
- (void)patchDidCreateJSInterpreter:(id)patch;
@end
