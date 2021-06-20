//
//  LQAppHoverList.h
//  Lacqit
//
//  Created by Pauli Ojala on 27.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Lacefx/LXBasicTypes.h>


typedef enum {
    kLQHoverOutside = 0,
    kLQHoverEntered = 1,
    kLQHoverExited,
    kLQHoverInside    
} LQHoverEventType;


@interface LQAppHoverList : NSObject {

    NSMutableArray *_level1;
    NSMutableArray *_level2;
    
    id _currentHovered;
    
    NSMutableDictionary *_observed;
}

- (void)trackBaseLevelView:(NSView *)view;
- (void)trackPopUpLevelWindow:(NSWindow *)window;

- (void)removeTrackingForObject:(id)obj;

- (void)addObserver:(id)obs forObject:(id)obj;
- (void)removeObserver:(id)obs;

- (id)sendHoverForEvent:(NSEvent *)event eventTypePtr:(LXUInteger *)outType;

@end


@interface NSObject (LQHoverEvents)
// sent directly to the observed view/window if it accepts them
- (void)hoverEntered:(NSEvent *)event;
- (void)hoverExited:(NSEvent *)event;
- (void)hoverInside:(NSEvent *)event;

// sent to observers
- (void)hoverEntered:(NSEvent *)event forObject:(id)obj;
- (void)hoverExited:(NSEvent *)event forObject:(id)obj;
- (void)hoverInside:(NSEvent *)event forObject:(id)obj;
@end