//
//  LQGLacefxViewController_lagoon_d3d.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGLacefxViewController_lagoon_d3d.h"
#import <Lagoon/LGNativeDirect3DWidget.h>


@implementation LQGLacefxViewController_lagoon_d3d


- (void)loadView
{
    if (_widget) return;
    
    LGNativeDirect3DWidget *d3dWidget = [[LGNativeDirect3DWidget alloc] initWithSizeRequest:NSMakeSize(400, 300)];

    [d3dWidget setDelegate:self];

    _widget = d3dWidget;
}

- (id)nativeView {
    return _widget;
}


#pragma mark --- Win32 draw delegate ---

- (void)win32WidgetWasCreated:(LGNativeWin32Widget *)widget
{
    HWND hwnd = [widget win32WindowHandle];
    NSLog(@"%s, %@: %p", __func__, self, hwnd);
}

- (void)win32WidgetNeedsRedraw:(LGNativeWin32Widget *)widget
{
    LGNativeDirect3DWidget *d3dWidget = (LGNativeDirect3DWidget *)widget;
    
    LXSurfaceRef surface = [d3dWidget lxSurface];
    if ( !surface) {
        NSLog(@"** can't redraw, no lxsurface (%@)", self);
        return;
    }
    
    LXRect rect = [d3dWidget viewportLXRect];
    
    LXSurfaceClearRegionWithRGBA(surface, rect, LXMakeRGBA(1, 0.9, 0, 1));
    
    LXSurfaceClearRegionWithRGBA(surface, LXMakeRect(100, 100, 100, 100), LXMakeRGBA(1, 0, 0.1, 1));    
    
    [d3dWidget present];
}


@end
