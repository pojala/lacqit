//
//  LQFullScreenLacefxView.m
//  Lacqit
//
//  Created by Pauli Ojala on 25.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQFullScreenLacefxView.h"


@implementation LQFullScreenLacefxView

- (id)initFullScreen:(NSScreen *)screen
{
    NSAssert(screen, @"no screen specified");

    NSDictionary *deviceDesc = [screen deviceDescription];
    NSSize screenSize = [[deviceDesc objectForKey:NSDeviceSize] sizeValue];

    CGDirectDisplayID displayID = (CGDirectDisplayID) [[deviceDesc objectForKey:@"NSScreenNumber"] intValue];
    LXInteger glDisplayID = CGDisplayIDToOpenGLDisplayMask(displayID);
    
    NSLog(@"-- fullscreen LX view init; size is %@; cg display id is %i; gl display mask is %ld", NSStringFromSize(screenSize), displayID, (long)glDisplayID);
    
    NSOpenGLPixelFormatAttribute attribs[] = {
        NSOpenGLPFAFullScreen,
        NSOpenGLPFAScreenMask, glDisplayID,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 32,
        //NSOpenGLPFADepthSize, 16,
        0
    };

	NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs]; 

	if (!fmt) {
		NSLog(@"** Unable to create OpenGL pixel format for fullscreen view");
        [self release];
		return nil;
	}

    self = [self initWithFrame:NSMakeRect(0, 0, screenSize.width, screenSize.height)
                  pixelFormat:[fmt autorelease]];

	/*LXInteger err = glGetError();
	if (err) {
        NSLog(@"** fullscreen init produced error: error %i", err);
    }*/

    _screen = screen;

	return self;
}

- (NSScreen *)associatedScreen
{
    return _screen;
}

- (BOOL)isFullScreen
{
    return YES;
}

- (void)setAssociatedScreen:(NSScreen *)screen {
    _screen = screen;
}

+ (BOOL)enableVBLSyncByDefault
{
    return YES;
}

@end
