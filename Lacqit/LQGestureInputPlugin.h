//
//  LQGestureInputPlugin.h
//  Inro
//
//  Created by Pauli Ojala on 3.4.2013.
//
//

#import <Lacqit/LQPlugin.h>
#import "LQGestureInputFrame.h"


@protocol LQGestureInputPlugin <NSObject>

- (NSUInteger)gestureInputType;

- (void)addInputListener:(id)listener;
- (void)removeInputListener:(id)listener;

@end

@interface NSObject (InroGestureInputListener)
- (void)gestureInputSourceConnected:(id)source;
- (void)gestureInputSourceDisconnected:(id)source;
- (void)gestureInputSource:(id)source receivedFrame:(id<LQGestureInputFrame>)frame;
@end
