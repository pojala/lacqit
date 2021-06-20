//
//  LQFullscreenCover.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.7.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQFullscreenCover : NSWindowController {

    BOOL _isFullscreen;
}

- (void)goFullScreen:(NSScreen *)screen;
- (void)endFullScreen;

@end


@interface LQFullscreenCoverWindow : NSWindow {

}

@end