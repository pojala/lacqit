//
//  LQGListController.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQGViewController.h"
#import "LQGCommonUIController.h"
#import "LQGCommonUIControllerSubtypeMethods.h"

/*
A cross-platform view controller that provides a native implementation on supported platforms.
*/



@interface LQGListController : LQGViewController {

    NSMutableArray *_viewControllers;
}

// factory method, returns platform-specific concrete implementation
+ (id)listController;

+ (id)listControllerFromDefinitionPlist:(NSArray *)defs
                         actionDelegate:(id)actionDelegate;

+ (id)listControllerFromDefinitionPlist:(NSArray *)defs
                       creationDelegate:(id)creationDelegate
                         actionDelegate:(id)actionDelegate;

- (LXInteger)numberOfItems;

- (LQGViewController *)viewControllerAtIndex:(LXInteger)index;
- (LQGViewController *)viewControllerNamed:(NSString *)name;

- (LXInteger)indexOfViewController:(LQGViewController *)viewCtrl;

- (void)addViewController:(LQGViewController *)viewCtrl;
- (void)insertViewController:(LQGViewController *)viewCtrl atIndex:(LXInteger)index;
- (void)removeViewControllerAtIndex:(LXInteger)index;

- (void)setVisible:(BOOL)f forViewController:(LQGViewController *)viewCtrl;
- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index;
- (BOOL)isVisibleForViewController:(LQGViewController *)viewCtrl;

- (void)repack;

- (void)setDrawsHorizontalLines:(BOOL)f;
- (BOOL)drawsHorizontalLines;

// --- platform-dependent native UI ---
// native view is an NSView on Mac and an an LGNativeWidget on Lagoon
- (id)nativeContainer;
- (void)setNativeContainer:(id)win;

- (id)nativeView;

@end


@interface NSObject (LQGListControllerCreationDelegate)

// if returns nil, the listcontroller will call the default implementation
- (LQGViewController *)makeViewControllerForUIDefinition:(NSDictionary *)dict;

@end

