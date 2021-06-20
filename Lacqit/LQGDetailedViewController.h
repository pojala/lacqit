//
//  LQGDetailedViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQGViewController.h"
#import "LQGCommonUIController.h"
#import "LQGCommonUIControllerSubtypeMethods.h"

/*
A cross-platform view controller that provides a native implementation on supported platforms.

Attaches an NSView to an LQGViewController.
*/

enum {
    kLQGDetailViewAtRight = 0,
    kLQGDetailViewBelow
};
typedef LXUInteger LQGDetailViewPosition;



@interface LQGDetailedViewController : LQGViewController {

    id _viewController;
    
    NSView *_detailView;
    
    LXUInteger _detailPosition;
}

// factory method, returns platform-specific concrete implementation
+ (id)detailedViewController;

- (LQGViewController *)mainViewController;
- (void)setMainViewController:(LQGViewController *)ctrl;

- (NSView *)detailView;
- (void)setDetailView:(NSView *)view;

- (LXUInteger)detailViewPosition;
- (void)setDetailViewPosition:(LXUInteger)pos;

@end
