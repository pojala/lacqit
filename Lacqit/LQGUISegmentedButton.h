//
//  LQGUISegmentedButton.h
//  Lacqit
//
//  Created by Pauli Ojala on 5.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIControl.h"
#import "LQSegmentedControl.h"

/*
  LQGUIControl implements forwarding, so all of NS/LQSegmentedControl's methods can be called on this object
*/


@interface LQGUISegmentedButton : LQGUIControl {

}

+ (id)segmentedButtonWithLabels:(NSArray *)labels
                          name:(NSString *)name
                       context:(NSString *)context
                        target:(id)target
                        action:(SEL)action;

+ (double)heightForControlSize:(NSControlSize)controlSize;

- (void)setTrackingMode:(LQSegmentSwitchTracking)trackingMode;
- (LQSegmentSwitchTracking)trackingMode;

- (void)setControlSize:(LXUInteger)controlSize;

@end
