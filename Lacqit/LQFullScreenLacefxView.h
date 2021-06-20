//
//  LQFullScreenLacefxView.h
//  Lacqit
//
//  Created by Pauli Ojala on 25.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQLacefxView.h"


@interface LQFullScreenLacefxView : LQLACEFXVIEWBASECLASS {

    NSScreen *_screen;
}

- (id)initFullScreen:(NSScreen *)screen;

- (NSScreen *)associatedScreen;

// instead of creating a real OpenGL fullscreen context (which is what -initFullScreen does),
// it's also possible to create a regular view in a borderless window and use this method to
// set the associated screen.
// this seems to work better in Conduit Live in combination with Core Video's display link.
- (void)setAssociatedScreen:(NSScreen *)screen;

@end
