//
//  LQGestureInputFrame.h
//  Inro
//
//  Created by Pauli Ojala on 3.4.2013.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    kLQGestureInputFlag_PreciseHands = 1,             // Leap data with finger precision
    kLQGestureInputFlag_LargeHandGestures = 1 << 10   // hand gestures, can be from Leap or Kinect
} InroGestureInputType;


@protocol LQGestureInputFrame <NSObject>

- (NSUInteger)gestureInputType;

- (int64_t)frameId;
- (int64_t)timestamp;

// -- methods for the "precise hands" input type (Leap Motion) --
- (NSArray *)hands;
- (NSArray *)pointables;
- (NSArray *)fingers;
- (NSArray *)tools;
- (id)hand:(int32_t)handId;
- (id)pointable:(int32_t)pointableId;
- (id)finger:(int32_t)fingerId;
- (id)tool:(int32_t)toolId;

@end
