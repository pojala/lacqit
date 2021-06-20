//
//  LQGTabbedController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTabbedController_cocoa.h"
#import "LQGViewController.h"


@interface LQGTabbedController (PrivateToSubclasses)
- (id)initWithNativeContainer:(id)container;
@end


@implementation LQGTabbedController_cocoa

- (NSRect)_frameFromContainer
{
    if ( !_container) return NSZeroRect;
    
    NSRect frame = [_container bounds];
    
    NSDictionary *styleAttrs = [self nativeStyleAttributes];
    if (styleAttrs) {
        id val;
        double marginL = ((val = [styleAttrs objectForKey:kLQGStyle_MarginLeft]))   ? [val doubleValue]: 0.0;
        double marginR = ((val = [styleAttrs objectForKey:kLQGStyle_MarginRight]))  ? [val doubleValue]: 0.0;
        double marginT = ((val = [styleAttrs objectForKey:kLQGStyle_MarginTop]))    ? [val doubleValue]: 0.0;
        double marginB = ((val = [styleAttrs objectForKey:kLQGStyle_MarginBottom])) ? [val doubleValue]: 0.0;
        
        frame.origin.x += marginL;        
        frame.size.width += marginR;
        
        if ( ![_container isFlipped]) {
            frame.origin.y -= marginB - marginT;
            frame.size.height += marginB;
        } else {
            frame.origin.y += marginT;        
            frame.size.height += marginB;
        }
    }
    
    return frame;
}

- (id)initWithNativeContainer:(id)container
{
    self = [super initWithNativeContainer:container];

    NSRect tvFrame = NSMakeRect(0, 0, 300, 300);

    if (container) {
        NSAssert1([container isKindOfClass:[NSView class]], @"invalid container", container);
        _container = (NSView *)container;
        
        tvFrame = [self _frameFromContainer];
    }

    _tabView = [[NSTabView alloc] initWithFrame:tvFrame];
    [_tabView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

/*        _placeholderTabItem = [[NSTabViewItem alloc] initWithIdentifier:@"(placeholder)"];
        [_placeholderTabItem setLabel:@"()"];
        [_placeholderTabItem setView:[[[NSView alloc] initWithFrame:[_tabView contentRect]] autorelease]];
        [_tabView addTabViewItem:[_placeholderTabItem autorelease]];
*/
    // control size needs to be set before tab items are added,
    // or there will be an invalid offset inside the tabview until the tabview is resized
    
    if (_container)
        [_container addSubview:_tabView];
        
    return self;
}

- (void)dealloc
{
    [_tabView removeFromSuperview];
    [_tabView release];
    _tabView = nil;
    
    [super dealloc];
}

- (void)setControlSize:(LXUInteger)controlSize
{
    [_tabView setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]]];
#if !defined(__COCOTRON__)
    [_tabView setControlSize:controlSize];
#endif
}

- (void)selectTabAtIndex:(LXInteger)index
{
    @try {
        [super selectTabAtIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    [_tabView selectTabViewItemAtIndex:index];
}


- (NSTabViewItem *)_tabViewItemForViewController:(LQGViewController *)viewCtrl
{
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:[viewCtrl title]];    
    NSView *view = [viewCtrl nativeView];
    
    [item setLabel:[viewCtrl title]];
    [item setView:view];

    return [item autorelease];
}

- (void)addViewController:(LQGViewController *)viewCtrl
{
    @try {
        [super addViewController:viewCtrl];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    [_tabView addTabViewItem:[self _tabViewItemForViewController:viewCtrl]];
        
    if ([_tabView numberOfTabViewItems] == 1) {
        [_tabView selectTabViewItemAtIndex:0];
    }    
}

- (void)removeViewControllerAtIndex:(LXInteger)index
{
    @try {
        [super removeViewControllerAtIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    [_tabView removeTabViewItem:[_tabView tabViewItemAtIndex:index]];
}

- (void)insertViewController:(LQGViewController *)viewCtrl atIndex:(LXInteger)index
{
    @try {
        [super insertViewController:viewCtrl atIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
        
    [_tabView insertTabViewItem:[self _tabViewItemForViewController:viewCtrl] atIndex:index];
}


- (id)nativeContainer {
    return _container; }
    
- (void)setNativeContainer:(id)cnt
{
    if (cnt != _container) {        
        _container = cnt;

        [_tabView removeFromSuperview];
        
        if (_container) {
            [_tabView setFrame:[self _frameFromContainer]];
        
            [_container addSubview:_tabView];
        }
    }
}
    
- (id)nativeView {
    return _tabView; }


// these attributes place the tabView within its container so that the Aqua borders are hidden
- (id)nativeStyleAttributes {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithDouble:-9.0],   kLQGStyle_MarginLeft,
                            [NSNumber numberWithDouble:18.0],   kLQGStyle_MarginRight,
                            [NSNumber numberWithDouble:-4.0],   kLQGStyle_MarginTop,
                            [NSNumber numberWithDouble:16.0],   kLQGStyle_MarginBottom,
                            nil];
}

@end
