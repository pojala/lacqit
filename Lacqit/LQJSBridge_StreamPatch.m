//
//  LQJSBridge_StreamPatch.m
//  Lacqit
//
//  Created by Pauli Ojala on 28.5.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_StreamPatch.h"
#import "LQStreamPatch.h"
#import "LQStreamNode.h"
#import "LQTimeFunctions.h"
#import "LQTimeFormatter.h"


@implementation LQJSBridge_StreamPatch

- (id)initWithStreamPatch:(id)patch
{
    if ( !patch) {
        NSLog(@"** %@: tried to init without patch object", [self class]);
        [self release];
        return nil;
    }
    
    self = [super initInJSContext:[[patch jsInterpreter] context]
                        withOwner:nil];
    if (self) {
        _patch = patch;
    }
    return self;
}

- (void)setActiveTimelineMode:(BOOL)isTimeline timeInStream:(double)t
{
    _isTimelineMode = isTimeline;
    _currentStreamTime = t;
}


#pragma mark --- properties ---

+ (NSString *)constructorName {
    return @"<StreamPatch>";  // can't be constructed
}

+ (NSArray *)objectPropertyNames {
    return [NSArray arrayWithObjects:@"isTimelineMode",
                                     @"startRefTime", @"currentRefTime", @"evalRefTime",  // reference time (absolute)
                                     @"isPlaying",
                                     @"timeInStream",
                                     nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName {
    return NO;
}

- (BOOL)isPlaying {
    return ([_patch streamState] == kLQStreamState_Active);
}

- (double)startRefTime {
    return [_patch streamStartReferenceTime];
}

- (double)currentRefTime {
    return LQReferenceTimeGetCurrent();
}

- (double)evalRefTime {
    return [_patch latestEvalReferenceTime];
}

- (BOOL)isTimelineMode {
    return _isTimelineMode; }
    
- (double)timeInStream {
    return _currentStreamTime; }

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }
    


#pragma mark --- functions ---

+ (NSArray *)objectFunctionNames {
    return [NSArray arrayWithObjects:@"getNodeById", @"getNodeByTag",
                                     @"getAsset", @"setAsset", @"getAssetById", @"setAssetById",
                                     @"enqueueRender",
                                     @"browseForMediaRef",
                                     @"formatTimeForDisplay",
                                     nil];
}

- (id)lqjsCallGetNodeById:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    ///NSLog(@"%s: %@ --> %@", __func__, [args objectAtIndex:0], [_patch nodeNamed:[[args objectAtIndex:0] description]]);
    
    NSString *nodeName = [[args objectAtIndex:0] description];
    if ([nodeName length] < 1) return nil;
    
    id node = [_patch nodeNamed:nodeName];
    id jsBridge = ([node respondsToSelector:@selector(jsBridgeInPatchContext)]) ? [node jsBridgeInPatchContext] : nil;
    
    ///NSLog(@".... js bridge is: %@", jsBridge);
    
    return jsBridge;
}

- (id)lqjsCallGetNodeByTag:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id arg = [args objectAtIndex:0];
    if ( ![arg respondsToSelector:@selector(longValue)]) return nil;
    
    LXInteger tag = [arg longValue];
    if (tag == 0) return nil;
    
    NSEnumerator *nodeEnum = [_patch nodeEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        if (tag == [node tag]) {
            return ([node respondsToSelector:@selector(jsBridgeInPatchContext)]) ? [node jsBridgeInPatchContext] : nil;
        }
    }
    return nil;
}

- (id)lqjsCallEnqueueRender:(NSArray *)args context:(id)contextObj
{
    if ([_delegate respondsToSelector:@selector(jsBridgeEnqueueRender:)]) {
        [_delegate jsBridgeEnqueueRender:self];
    }
    return nil;
}

- (id)lqjsCallBrowseForMediaRef:(NSArray *)args context:(id)contextObj
{
    if ([_delegate respondsToSelector:@selector(jsBridgeBrowseForMediaRef:)]) {
        return [_delegate jsBridgeBrowseForMediaRef:self];
    } else
        return nil;
}

- (id)lqjsCallGetAssetById:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    id arg = [args objectAtIndex:0];
    
    if ([arg isKindOfClass:[NSString class]] && [_delegate respondsToSelector:@selector(jsBridge:getBridgedAssetNamed:)]) {
        return [_delegate jsBridge:self getBridgedAssetNamed:(NSString *)arg];
    }
    return nil;
}

- (id)lqjsCallGetAsset:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    id arg = [args objectAtIndex:0];    
    if ( ![arg respondsToSelector:@selector(longValue)]) return nil;
    LXInteger index = [arg longValue] - 1;  // 1-based index

    if ( ![_delegate respondsToSelector:@selector(jsBridge:getBridgedAssetAtIndex:)])
        return nil;
        
    return [_delegate jsBridge:self getBridgedAssetAtIndex:index];
}

- (id)lqjsCallSetAssetById:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    id arg = [args objectAtIndex:0];
    id asset = [args objectAtIndex:1];

    BOOL retVal = NO;
    if ([arg isKindOfClass:[NSString class]] && [_delegate respondsToSelector:@selector(jsBridge:getBridgedAssetNamed:)]) {
        retVal = [_delegate jsBridge:self setBridgedAsset:asset named:(NSString *)arg];
    }
    return [NSNumber numberWithBool:retVal];
}

- (id)lqjsCallSetAsset:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    id arg = [args objectAtIndex:0];
    if ( ![arg respondsToSelector:@selector(longValue)]) return nil;
    LXInteger index = [arg longValue] - 1;  // 1-based index
    
    id asset = [args objectAtIndex:1];

    BOOL retVal = NO;
    if ([_delegate respondsToSelector:@selector(jsBridge:setBridgedAsset:atIndex:)]) {
        retVal = [_delegate jsBridge:self setBridgedAsset:asset atIndex:index];
    }
    return [NSNumber numberWithBool:retVal];
}

- (id)lqjsCallFormatTimeForDisplay:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    id arg = [args objectAtIndex:0];
    if ( ![arg respondsToSelector:@selector(doubleValue)]) return nil;
    
    LQTimeFormatter *formatter = [[LQTimeFormatter alloc] init];

    double fps = 0.0;
    if ([args count] >= 2 && [[args objectAtIndex:1] respondsToSelector:@selector(doubleValue)]) {
        fps = [[args objectAtIndex:1] doubleValue];
    }
    if (isfinite(fps) && fps > 0.0 && fps <= 10000.0) {
        [formatter setDisplayFrameRate:fps];
    }
    
    NSString *str = [formatter stringForObjectValue:arg];
    [formatter release];
    
    return str;
}

@end
