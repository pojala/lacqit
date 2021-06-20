//
//  LQGListController.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListController.h"
#import "LacqitInit.h"
#import "LQGViewController_priv.h"
#import "LQGViewController_ScriptedUI.h"
#import "LQGCommonUIControllerSubtypeMethods.h"
#import "LQGCommonUINSViewController.h"
#import "LQGUITextField.h"
#import "LQGUIButton.h"
#import "LQNSColorAdditions.h"


#ifdef __LAGOON__
 #import "LQGListController_lagoon.h"
 #define PLATFORMCLASS LQGListController_lagoon
#else
 #import "LQGListController_cocoa.h"
 #define PLATFORMCLASS LQGListController_cocoa
#endif


@implementation LQGListController



#pragma mark --- creating a list of views from plist ---

+ (id)listControllerFromDefinitionPlist:(NSArray *)defs
                         actionDelegate:(id)actionDelegate
{
    return [self listControllerFromDefinitionPlist:defs
                                  creationDelegate:nil
                                    actionDelegate:actionDelegate];
}

+ (id)listControllerFromDefinitionPlist:(NSArray *)defs
                       creationDelegate:(id)creationDelegate
                         actionDelegate:(id)actionDelegate
{
    LXInteger count = [defs count];
    if (count < 1) return nil;
    
    LQGListController *newList = [self listController];
    
    LXInteger i;
    for (i = 0; i < count; i++) {
        NSDictionary *def = [defs objectAtIndex:i];
        LQGViewController *viewCtrl = nil;
        
        if ([creationDelegate respondsToSelector:@selector(makeViewControllerForUIDefinition:)]) {
            viewCtrl = [creationDelegate makeViewControllerForUIDefinition:def];
        }
        if ( !viewCtrl) {
            viewCtrl = [self viewControllerFromScriptedUIDefinition:def];
        }
        
        if (viewCtrl) {
            if ( !viewCtrl.name) {
                NSString *ctrlID = [def objectForKey:@"id"];
                [viewCtrl setName:ctrlID];  // ensure id is set
            }
            
            if ( !viewCtrl.representedObject) {
                viewCtrl.representedObject = def;
            }
            
            [viewCtrl loadView];
            ///NSLog(@"%s - %i - created viewctrl %@ / %@", __func__, i, viewCtrl, [viewCtrl nativeView]);
            
            [viewCtrl _setEnclosingViewController:newList];
            
            if (actionDelegate) {
                [viewCtrl setDelegate:actionDelegate];
                
                if ([viewCtrl respondsToSelector:@selector(subviewControllers)]) {
                    for (id subviewCtrl in [(id)viewCtrl subviewControllers]) {
                        [subviewCtrl setDelegate:actionDelegate];
                    }
                }
            }
            [newList addViewController:viewCtrl];
        }
    }
    
    [newList repack];
    
    return newList;
}




#pragma mark --- init ---

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

+ (id)listController
{
    return [[[[[self class] platformImplementationClass] alloc] init] autorelease];
}

- (void)dealloc
{
    [_viewControllers release];
    [super dealloc];
}


- (LXInteger)numberOfItems {
    return [_viewControllers count]; }
    
    
- (LQGViewController *)viewControllerAtIndex:(LXInteger)index
{
    if (index >= [_viewControllers count]) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)[_viewControllers count]);
        return nil;
    }
    
    return [_viewControllers objectAtIndex:index];
}

- (LQGViewController *)viewControllerNamed:(NSString *)name
{
    NSEnumerator *vcEnum = [_viewControllers objectEnumerator];
    id vc;
    while (vc = [vcEnum nextObject]) {
        if ([[vc name] isEqualToString:name])
            return vc;
    }
    return nil;
}

- (LXInteger)indexOfViewController:(LQGViewController *)wanted
{
    NSEnumerator *vcEnum = [_viewControllers objectEnumerator];
    id vc;
    int n = 0;
    while (vc = [vcEnum nextObject]) {
        if (vc == wanted)
            return n;
        n++;
    }
    return NSNotFound;
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
    LXInteger count = [_viewControllers count];
    
    if (index >= count)
        [_viewControllers addObject:viewCtrl];
    else
        [_viewControllers insertObject:viewCtrl atIndex:index];
        
    [viewCtrl _setEnclosingViewController:self];
}


- (void)setVisible:(BOOL)f forViewController:(LQGViewController *)viewCtrl {
    LQInvalidAbstractInvocation();
}

- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index {
    LQInvalidAbstractInvocation();
}

- (BOOL)isVisibleForViewController:(LQGViewController *)viewCtrl {
    LQInvalidAbstractInvocation();
    return NO;
}

- (void)repack {
    LQInvalidAbstractInvocation();
}

- (id)nativeContainer {
    LQInvalidAbstractInvocation();
    return nil;
}
    
- (void)setNativeContainer:(id)win {
    LQInvalidAbstractInvocation();
}

- (void)setDrawsHorizontalLines:(BOOL)f {
}

- (BOOL)drawsHorizontalLines {
    return NO; }


- (id)nativeView {
    LQInvalidAbstractInvocation();
    return nil;
}

@end
