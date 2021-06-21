//
//  LQFullscreenCover.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.7.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQFullscreenCover.h"
#import "LQFullscreenCoverView.h"


@implementation LQFullscreenCover


- (void)_createFullScreenBorderlessWindowForScreen:(NSScreen *)screen
{
    //NSDictionary *deviceDesc = [screen deviceDescription];
    //CGDirectDisplayID screenID = (CGDirectDisplayID)[[deviceDesc objectForKey:@"NSScreenNumber"] intValue];
    NSRect frame = [screen frame];
    float opacity = 0.6;
        
    NSWindow *fsWin = [[LQFullscreenCoverWindow alloc]
                            initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer:NO
                            screen:screen];

    [fsWin setHasShadow:NO];
    [fsWin setLevel:NSFloatingWindowLevel];
    [fsWin setOpaque:opacity < 0.99 ? NO : YES];
    [fsWin setAlphaValue:opacity];
    fsWin.backgroundColor = NSColor.clearColor;

    NSView *cview = [fsWin contentView];
    NSAssert(cview, @"no window contentview");
    
    NSView *newView = [[LQFullscreenCoverView alloc] initWithFrame:[cview frame]];
    [fsWin setContentView:[newView autorelease]];

    [fsWin orderFront:self];
    [self setWindow:[fsWin autorelease]];
    
    [cview setNeedsDisplay:YES];
    
    _isFullscreen = YES;
}

- (void)_destroyFullScreenBorderlessWindow
{
    [[self window] orderOut:self];
    [self setWindow:nil];
    
    _isFullscreen = NO;
}

- (void)goFullScreen:(NSScreen *)screen
{
    if ( !_isFullscreen)
        [self _createFullScreenBorderlessWindowForScreen:screen];
}


- (void)endFullScreen
{
    if (_isFullscreen)
        [self _destroyFullScreenBorderlessWindow];
}

@end


@implementation LQFullscreenCoverWindow

- (BOOL)canBecomeKeyWindow {
    return NO; }
    
- (BOOL)canBecomeMainWindow {
    return NO; }

- (BOOL)acceptsFirstResponder {
    return NO; }


@end
