//
//  LQGListController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListController_cocoa.h"
#import "LQGViewController.h"
#import "LQListView.h"
#import "LQFlippedView.h"


@interface LQGListController (PrivateToSubclasses)
- (id)initWithNativeContainer:(id)container;
@end


@implementation LQGListController_cocoa

- (NSRect)_frameFromContainer
{
    if ( !_container) return NSZeroRect;
    
    NSRect frame = [_container bounds];
    return frame;
}

- (id)init
{
    self = [super init];

    _listView = [[LQListView alloc] initWithFrame:NSMakeRect(0, 0, 400, 400)];
    [_listView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    return self;
}

- (void)dealloc
{
    [_listView removeFromSuperview];
    [_listView release];
    _listView = nil;
    
    [super dealloc];
}


- (void)loadView {
    // view is already created in -init
}


- (void)_insertNativeView:(NSView *)view atIndex:(LXInteger)index
{    
    /*if ([view autoresizingMask] & NSViewWidthSizable) {
        double w = [view frame].size.width;
        double listW = [_listView frame].size.width;
    
        NSLog(@"%s, %i: view %@ is sizable; list w %f, original view w %f", __func__, index, view, listW, w);
        
        NSRect frame = [view frame];
        frame.size.width = listW;
        [view setFrame:frame];
    }*/
    
    if (index >= [_listView numberOfItems])
        [_listView addItem:view];
    else
        [_listView insertItem:view atIndex:index];
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
    
    NSView *view = viewCtrl.nativeView;
    if ( !view) {
        NSLog(@"** %s: no view for item %ld, ctrl: %@", __func__, self.numberOfItems - 1, viewCtrl);
        return;
    }
    
    //NSLog(@"%s: adding item %ld: %@", __func__, [self numberOfItems]-1, NSStringFromRect([[viewCtrl nativeView] frame]));
    
    [self _insertNativeView:[viewCtrl nativeView] atIndex:[_listView numberOfItems]];    
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
    
    ///NSLog(@"%s: adding item %i: %@", __func__, [self numberOfItems]-1, NSStringFromRect([[viewCtrl nativeView] frame]));
    
    [self _insertNativeView:[viewCtrl nativeView] atIndex:index];
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

    [_listView removeItemAtIndex:index];
}


- (void)setVisible:(BOOL)f forViewController:(LQGViewController *)viewCtrl
{
    [_listView setVisible:f forItem:[viewCtrl nativeView]];
   ///NSLog(@"%s: listview frame now %@", __func__, NSStringFromRect([_listView frame]));
}

- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index
{
    [_listView setVisible:f forItemAtIndex:index];
   /// NSLog(@"%s: listview frame now %@", __func__, NSStringFromRect([_listView frame]));
}

- (BOOL)isVisibleForViewController:(LQGViewController *)viewCtrl
{
    return [_listView isVisibleForItem:[viewCtrl nativeView]];
}

- (void)repack
{
    [_listView repackSubviews];
    
   /// NSLog(@"%s: listview frame now %@", __func__, NSStringFromRect([_listView frame]));
}

- (id)nativeContainer {
    return _container; }
    
- (void)setNativeContainer:(id)cnt
{
    if (cnt != _container) {        
        _container = cnt;

        [_listView removeFromSuperview];
        
        if (_container) {
            [_listView setFrame:[self _frameFromContainer]];
        
            [_container addSubview:_listView];
        }
    }
}
    
- (id)nativeView {
    return _listView; }


- (void)setDrawsHorizontalLines:(BOOL)f {
    [_listView setDrawsHorizontalLines:f];
}

- (BOOL)drawsHorizontalLines {
    return [_listView drawsHorizontalLines]; }


#pragma mark --- scrollview ---

- (NSScrollView *)packIntoScrollView
{
    NSView *view = [self nativeView];
    NSRect tabFrame = [view frame];

    NSView *contentView;
    
    // pack the view into a flipped view if necessary
    if ( ![view isFlipped]) {
        NSRect frame = [view frame];
        NSRect contentFrame = tabFrame;
        contentFrame.size.height = frame.size.height;
        
        contentView = [[[LQFlippedView alloc] initWithFrame:contentFrame] autorelease];
        [contentView setAutoresizingMask:NSViewWidthSizable];

        frame.origin.x = 0;
        frame.origin.y = 0;
        frame.size.width = tabFrame.size.width;
        [contentView addSubview:view];
        [view setFrame:frame];
        ///NSLog(@"packed %@ into flippedview for scrolling", view);
    } else {
        contentView = view;
        [contentView setAutoresizingMask:NSViewWidthSizable];
    }

    NSRect scFrame = tabFrame;
    scFrame.size.width = [contentView frame].size.width;
    
    NSRect newFrame = [contentView frame];
    newFrame.size.width -= 4;
    [contentView setFrame:newFrame];
    
    ///NSLog(@"%s: scrollview frame is %@", __func__, NSStringFromRect(scFrame));
    
    // the scrollview is inside a tabview which darkens its background, so we must try to match that
    ///NSColor *bgColor = [NSColor colorWithHTMLFormattedString:@"#a5a5ac"];  // HARDCODED (color value simply copied from Photoshop)

	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scFrame];
	///[scrollView setBackgroundColor:bgColor];
	[scrollView setDocumentView:contentView];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setHasHorizontalScroller:NO];
	[scrollView setAutohidesScrollers:YES];
#if !defined(__COCOTRON__)
    [[scrollView verticalScroller] setControlSize:NSSmallControlSize];
#endif
	[scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    
	NSAssert([scrollView contentView], @"no clip view");
	NSAssert([contentView superview] == [scrollView contentView], @"no clip view as superview");
    
    return [scrollView autorelease];
}



@end
