//
//  LQGTabbedController.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQGViewController.h"
#import "LQGCommonUIController.h"
#import "LQGCommonUIControllerSubtypeMethods.h"

/*
A cross-platform tab view controller that provides a native implementation on supported platforms.

the subviews are automatically packed into scrollviews.
*/

@interface LQGTabbedController : LQGViewController {

    int _selectedTab;
    
    NSMutableArray *_viewControllers;
}

// factory method, returns platform-specific concrete implementation. container can be nil
+ (id)tabbedControllerWithNativeContainer:(id)container;

- (LXInteger)indexOfSelectedTab;
- (void)selectTabAtIndex:(LXInteger)index;

- (LXInteger)numberOfTabs;

//- (NSString *)labelForTabAtIndex:(LXInteger)index;
//- (void)setLabel:(NSString *)str forTabAtIndex:(LXInteger)index;

- (LQGViewController *)viewControllerAtIndex:(LXInteger)index;

- (void)addViewController:(LQGViewController *)viewCtrl;
- (void)insertViewController:(LQGViewController *)viewCtrl atIndex:(LXInteger)index;
- (void)removeViewControllerAtIndex:(LXInteger)index;


// --- platform-dependent native UI ---

// native view is an NSView on Mac and an an LGNativeWidget on Lagoon
- (id)nativeContainer;
- (void)setNativeContainer:(id)win;

- (id)nativeView;

/*
- (id)nativeViewForTabAtIndex:(LXInteger)index;
- (void)setNativeView:(id)view forTabAtIndex:(LXInteger)index;
*/

@end
