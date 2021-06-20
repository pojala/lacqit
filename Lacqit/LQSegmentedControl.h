//
//  LQSegmentedControl.h
//  Edo
//
//  Created by Pauli Ojala on 17.5.2006.
//  Copyright 2006 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"

enum {
    kLQSegmentSwitchTrackingSelectOne = 0,  // only one button can be selected
    kLQSegmentSwitchTrackingSelectAny = 1,  // any button can be selected
    kLQSegmentSwitchTrackingMomentary = 2   // only selected while tracking
};
typedef LXUInteger LQSegmentSwitchTracking;



@interface LQSegmentedControl : NSSegmentedControl {

}

+ (void)setDefaultInterfaceTint:(LQInterfaceTint)tint;
+ (LQInterfaceTint)defaultInterfaceTint;

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

- (void)resetCellClass;

- (void)setTrackingMode:(LQSegmentSwitchTracking)trackingMode;
- (LQSegmentSwitchTracking)trackingMode;

// convenience method that calls LQSegmentedCell's methods
- (void)setImage:(NSImage *)image withFixedSize:(NSSize)size opacity:(LXFloat)opacity;

@end
