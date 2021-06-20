//
//  LQGDetailedViewController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGDetailedViewController_cocoa.h"


@implementation LQGDetailedViewController_cocoa

- (void)dealloc {
    [_container release];
    [super dealloc];
}

- (id)nativeView {
    return _container; }


- (void)setMainViewController:(LQGViewController *)ctrl
{
    if (_viewController) {
        NSLog(@"*** %s: viewctrl already set", __func__);
        return;
    }
    
    [ctrl loadView];
    
    NSView *mainView = (NSView *)[ctrl nativeView];
    if ( !mainView) {
        NSLog(@"*** %s: no native view for main viewctrl (%@)", __func__, ctrl);
        return;
    }
    
    _viewController = [ctrl retain];
}


- (void)setDetailView:(NSView *)view
{
    [_detailView autorelease];
    _detailView = [view retain];
}


- (void)loadView
{
    if (_container) return;  // already loaded

    NSView *mainView = (NSView *)[_viewController nativeView];
    if ( !mainView) {
        NSLog(@"*** %s: no native view for main viewctrl (%@)", __func__, _viewController);
        return;
    }
    
    NSRect frame = [mainView frame];
    frame.origin = NSZeroPoint;
    NSRect mainViewFrame = frame;
    
    if (_detailPosition == kLQGDetailViewAtRight) {
        const double leftMarginForDetail = -8;
        
        BOOL detailResizes = NO;
        if (_detailView) {
            frame.size.width += [_detailView frame].size.width + leftMarginForDetail;
            
            detailResizes = ([_detailView autoresizingMask] & NSViewWidthSizable) ? YES : NO;
        }
        
        _container = [[NSView alloc] initWithFrame:frame];
        [_container setAutoresizingMask:NSViewWidthSizable];
        
        [mainView setFrame:mainViewFrame];
        [mainView setAutoresizingMask:(detailResizes) ? ([mainView autoresizingMask] & ~NSViewWidthSizable)
                                                      : ([mainView autoresizingMask] | NSViewWidthSizable)];
        
        [_container addSubview:mainView];

        if (_detailView) {
            NSRect detailFrame = [_detailView frame];
            detailFrame.origin = frame.origin;
            detailFrame.origin.x += mainViewFrame.size.width + leftMarginForDetail;
            detailFrame.size.height = mainViewFrame.size.height;
            
            [_detailView setAutoresizingMask:(detailResizes) ? NSViewWidthSizable : NSViewMinXMargin];  //(NSViewMinXMargin | ((detailResizes) ? 0 : NSViewWidthSizable))];
            [_detailView setFrame:detailFrame];
            
            [_container addSubview:_detailView];
        }
    }
    else {
        const double topMarginForDetail = 2;
    
        double detailH = (_detailView) ? [_detailView frame].size.height + topMarginForDetail : 0.0;
        frame.size.height += detailH;
        
        _container = [[NSView alloc] initWithFrame:frame];
        [_container setAutoresizingMask:[mainView autoresizingMask]];
        
        mainViewFrame.origin.y += detailH;
        [mainView setFrame:mainViewFrame];
        
        [_container addSubview:mainView];

        if (_detailView) {
            [_container addSubview:_detailView];
        }
    }
}


@end
