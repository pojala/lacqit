//
//  LGViewController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCocoaViewController.h"


static NSMutableDictionary *g_resDict = nil;



@implementation LQGViewController (LQGViewControllerCocoaSpecific)

- (NSView *)view {
    return _view; }

- (void)setView:(NSView *)view {
    if ( !_view && !view) return;
    
    ///NSLog(@"%s (%@): view %@ -- old view is %@", __func__, self, view, _view);
    [_view autorelease];
    _view = [view retain];
}

@end


@implementation LQGCocoaViewController

#pragma mark --- loading Nibs ---

+ (NSNib *)_cachedMainBundleNibNamed:(NSString *)nibName
{
    if ([nibName length] < 1) return nil;
    
    if ( !g_resDict)
        g_resDict = [[NSMutableDictionary alloc] init];
        
    NSNib *nib = [g_resDict objectForKey:nibName];
    if ( !nib) {
        nib = [[NSNib alloc] initWithNibNamed:nibName bundle:nil];
        
        if (nib)
            [g_resDict setObject:nib forKey:nibName];
    }
    return nib;
}

- (void)loadView
{
    if ([_resName length] < 1)
        return;

    [self setView:nil];
    
    [_nibObjects release];
    _nibObjects = nil;

    NSNib *nib = nil;
    if (_resBundle == nil || _resBundle == [NSBundle mainBundle]) {
        nib = [[self class] _cachedMainBundleNibNamed:_resName];
    } else {
        nib = [[NSNib alloc] initWithNibNamed:_resName bundle:_resBundle];
        // this nib object is not released because that seems to cause unwanted effects
        // (presumably something to do with the Obj-C runtime unloading stuff?)
    }
    
    if ( !nib) {
        NSLog(@"** %s: can't load nib (nib '%@', bundle %@)", __func__, _resName, _resBundle);
        return;
    }

    ///NSLog(@"%s / %@: instantiating nib '%@' (%p)", __func__, self, _resName, nib);

    [nib instantiateNibWithOwner:self topLevelObjects:&_nibObjects];
    [_nibObjects retain];

    [_view retain];
    
    if ( !_view) {
        NSLog(@"** warning: no view loaded from nib (%@; nib '%@', bundle %@)", self, _resName, _resBundle);
    }
        
    // release the top-level objects so that they are just owned by the array
    // (this step comes from Apple documentation "loading nibs programmatically")
    [_nibObjects makeObjectsPerformSelector:@selector(release)];
}


- (id)nativeView {
    return _view; }
    
- (void)setNativeView:(id)view {
    if (view) {
        NSAssert1([view isKindOfClass:[NSView class]], @"invalid view (%@)", view);
    }
    [self setView:(NSView *)view];
}

@end
