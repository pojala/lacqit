//
//  LQViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 27.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQViewController.h"
#import "LQGCocoaViewController.h"



@implementation LQViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithResourceName:nibName bundle:nibBundle];
    //_viewCtrl = [[LQGCocoaViewController alloc] initWithResourceName:nibName bundle:nibBundle];
    
    return self;
}

- (void)dealloc
{
    ///[_viewCtrl release];
    [super dealloc];
}

#pragma mark --- loading Nibs ---
/*
- (void)loadView
{
    [_viewCtrl loadView];
}
*/

#pragma mark --- accessors ---

- (NSString *)nibName {
    return [super resourceName]; }
    
- (NSBundle *)nibBundle {
    return [super resourceBundle]; }

/*
- (id)representedObject {
    return [_viewCtrl representedObject]; }
    
- (void)setRepresentedObject:(id)obj {
    [_viewCtrl setRepresentedObject:obj]; }

- (NSString *)title {
    return [_viewCtrl title]; }
    
- (void)setTitle:(NSString *)title {
    [_viewCtrl setTitle:title]; }

- (NSView *)view {
    return [_viewCtrl view]; }

- (void)setView:(NSView *)view {
    [_viewCtrl setView:view];
}
*/

@end
