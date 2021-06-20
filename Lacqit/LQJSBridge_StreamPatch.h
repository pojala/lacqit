//
//  LQJSBridge_StreamPatch.h
//  Lacqit
//
//  Created by Pauli Ojala on 28.5.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import <Lacefx/LXBasicTypes.h>


@interface LQJSBridge_StreamPatch : LQJSBridgeObject {

    id _patch;  // not retained
    
    BOOL _isTimelineMode;
    double _currentStreamTime;
    
    id _delegate;
}

// the new bridge object is created in the JSContext owned by this patch
- (id)initWithStreamPatch:(id)patch;

// values set by stream patch before eval
- (void)setActiveTimelineMode:(BOOL)isTimeline timeInStream:(double)t;

- (void)setDelegate:(id)del;
- (id)delegate;

@end


// in Conduit Live 2, this delegate is the LCLProject that owns the stream patch
@interface NSObject (LQStreamPatchJSBridgeDelegate)

- (id)jsBridge:(id)bridge getBridgedAssetAtIndex:(LXInteger)index;
- (BOOL)jsBridge:(id)bridge setBridgedAsset:(id)obj atIndex:(LXInteger)index;

- (id)jsBridge:(id)bridge getBridgedAssetNamed:(NSString *)assetName;
- (BOOL)jsBridge:(id)bridge setBridgedAsset:(id)obj named:(NSString *)assetName;

- (void)jsBridgeEnqueueRender:(id)bridge;

- (id)jsBridgeBrowseForMediaRef:(id)bridge;

@end
