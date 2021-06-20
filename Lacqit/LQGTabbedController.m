//
//  LQGTabbedController.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTabbedController.h"
#import "LQGViewController_priv.h"
#import "LacqitInit.h"

#ifdef __LAGOON__
 #import "LQGTabbedController_lagoon.h"
 #define PLATFORMCLASS LQGTabbedController_lagoon
#else
 #import "LQGTabbedController_cocoa.h"
 #define PLATFORMCLASS LQGTabbedController_cocoa
#endif


@implementation LQGTabbedController

+ (Class)platformImplementationClass
{
    return [PLATFORMCLASS class];
}

- (id)init
{
    self = [super init];
    _viewControllers = [[NSMutableArray alloc] initWithCapacity:16];
    return self;
}

- (id)initWithNativeContainer:(id)container
{
    self = [self init];
    [self setNativeContainer:container];
    return self;
}

+ (id)tabbedControllerWithNativeContainer:(id)container
{
    return [[[[[self class] platformImplementationClass] alloc] initWithNativeContainer:container] autorelease];
}

- (void)dealloc
{
    [_viewControllers release];
    [super dealloc];
}


- (LXInteger)indexOfSelectedTab {
    return _selectedTab; }

- (LXInteger)numberOfTabs {
    return [_viewControllers count]; }
    
    
- (void)selectTabAtIndex:(LXInteger)index
{
    _selectedTab = index;
}


- (LQGViewController *)viewControllerAtIndex:(LXInteger)index
{
    if (index >= [_viewControllers count]) {
        NSLog(@"** %s: index out of bounds (%ld, %lu)", __func__, index, [_viewControllers count]);
        return nil;
    }
    
    return [_viewControllers objectAtIndex:index];
}

- (void)addViewController:(LQGViewController *)viewCtrl
{
    [_viewControllers addObject:viewCtrl];
    
    [viewCtrl _setEnclosingViewController:self];
}

- (void)removeViewControllerAtIndex:(LXInteger)index
{
    [[_viewControllers objectAtIndex:index] _setEnclosingViewController:nil];

    [_viewControllers removeObjectAtIndex:index];
}

- (void)insertViewController:(LQGViewController *)viewCtrl atIndex:(LXInteger)index
{
    [_viewControllers insertObject:viewCtrl atIndex:index];
    
    [viewCtrl _setEnclosingViewController:self];
}


- (id)nativeContainer {
    LQInvalidAbstractInvocation();
    return nil;
}
    
- (void)setNativeContainer:(id)win {
    LQInvalidAbstractInvocation();
}

- (id)nativeView {
    LQInvalidAbstractInvocation();
    return nil;
}

@end
