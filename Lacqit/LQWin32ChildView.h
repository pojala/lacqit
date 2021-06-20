//
//  LQWin32ChildView.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQWin32ChildView : NSView {
    
    void *_childWindow;
    BOOL _childVisible;
}

- (void)update;

- (void *)nativeChildWindow;  // a native window handle (HWND)

- (void)getChildWindowWidth:(int *)outW height:(int *)outH;  // actual window size from native Win32 call

@end
