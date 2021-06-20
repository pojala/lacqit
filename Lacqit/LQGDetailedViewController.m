//
//  LQGDetailedViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGDetailedViewController.h"
#import "LQGViewController_priv.h"
#import "LacqitInit.h"
#import "LQGCommonUIControllerSubtypeMethods.h"


#ifdef __LAGOON__
 #error "Needs implementation on Lagoon"
#else
 #import "LQGDetailedViewController_cocoa.h"
 #define PLATFORMCLASS LQGDetailedViewController_cocoa
#endif




@implementation LQGDetailedViewController

#pragma mark --- init ---

+ (Class)platformImplementationClass
{
    return [PLATFORMCLASS class];
}

- (id)init
{
    self = [super init];
    return self;
}

+ (id)detailedViewController
{
    return [[[[[self class] platformImplementationClass] alloc] init] autorelease];
}

- (void)dealloc
{
    [_viewController release];
    [_detailView release];
    [super dealloc];
}


#pragma mark --- accessors ---

- (LQGViewController *)mainViewController {
    return _viewController; }
    
- (NSView *)detailView {
    return _detailView; }
    
- (LXUInteger)detailViewPosition {
    return _detailPosition; }


- (void)setMainViewController:(LQGViewController *)ctrl
{
    LQInvalidAbstractInvocation();
}

- (void)setDetailView:(NSView *)view
{
    LQInvalidAbstractInvocation();
}

- (void)setDetailViewPosition:(LXUInteger)pos
{
    _detailPosition = pos;
}
    


#pragma mark --- generic message forwarding ---

#define FORWARDOBJ _viewController


- (BOOL)_respondsToSelectorWithoutForwarding:(SEL)aSelector
{
    return [super respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([self _respondsToSelectorWithoutForwarding:aSelector])
        return [super methodSignatureForSelector:aSelector];
    else
        return [FORWARDOBJ methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
 
    if ([FORWARDOBJ respondsToSelector:aSelector])
        [invocation invokeWithTarget:FORWARDOBJ];
    else
        [self doesNotRecognizeSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self _respondsToSelectorWithoutForwarding:aSelector])
        return YES;
    else
        return [FORWARDOBJ respondsToSelector:aSelector];
}

@end
