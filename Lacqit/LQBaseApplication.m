//
//  LQBaseApplication.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseApplication.h"
#import "LQAppHoverList.h"
#import "LQPopUpWindow.h"


#ifdef __APPLE__
#import "LQOpenGLLacefxView.h"

@interface LQOpenGLLacefxView (LQGLContext)
+ (LQGLContext *)sharedLQGLContext;
@end
#endif


@interface NSWindow (LionAdditions)
- (NSRect)convertRectToScreen:(NSRect)aRect;
- (NSRect)convertRectFromScreen:(NSRect)aRect;
@end


@implementation LQBaseApplication

#ifdef __APPLE__
- (NSOpenGLContext *)sharedNSOpenGLContext
{
    return [LQOpenGLLacefxView sharedNSOpenGLContext];
}

- (LQGLContext *)sharedLQGLContext
{
    return [LQOpenGLLacefxView sharedLQGLContext];
}
#endif



#pragma mark --- new accessors ---

- (void)addHoverTracking:(id)obj
{
    if ( !_hoverList)
        _hoverList = [[LQAppHoverList alloc] init];

    if ([obj isKindOfClass:[LQPopUpWindow class]])
        [_hoverList trackPopUpLevelWindow:(NSWindow *)obj];
    else if ([obj isKindOfClass:[NSView class]])
        [_hoverList trackBaseLevelView:(NSView *)obj];
    else
        NSLog(@"** %s: unknown type of object to track (%@)", __func__, obj);
}

- (void)removeHoverTracking:(id)obj
{
    [_hoverList removeTrackingForObject:obj];
}

- (void)addHoverTrackingObserver:(id)observer forObject:(id)obsObj
{
    [_hoverList addObserver:observer forObject:obsObj];
}

- (void)removeHoverTrackingObserver:(id)observer
{
    [_hoverList removeObserver:observer];
}


- (void)addMouseMovedObserver:(id)ob
{
    if ( !_moveEventObservers)
        _moveEventObservers = [[NSMutableSet set] retain];
    
    id weakRef = [NSValue valueWithPointer:ob];
    
    [_moveEventObservers addObject:weakRef];
}

- (void)removeMouseMovedObserver:(id)ob
{
    id weakRef = [NSValue valueWithPointer:ob];
    
    [_moveEventObservers removeObject:weakRef];
}

- (LQFlatFileArchive *)updateArchive {
    return _updateArch;
}

- (void)_setUpdateArchive:(LQFlatFileArchive *)archive {
    [_updateArch autorelease];
    _updateArch = [archive retain];
}


#pragma mark --- overrides ---

- (BOOL)_sendMouseMovedEvent:(NSEvent *)event
{
    BOOL didHandle = NO;  // allow event to propagate by default
    
    NSPoint globalPos = [NSEvent mouseLocation];
    NSWindow *mainWindow = [event window];

    NSScreen *screen = [mainWindow screen];
    NSPoint pointInWindow = [event locationInWindow];
    
    NSPoint pointOnScreen = ([mainWindow respondsToSelector:@selector(convertRectToScreen:)])
                    ? [mainWindow convertRectToScreen:NSMakeRect(pointInWindow.x, pointInWindow.y, 1, 1)].origin
                    : [mainWindow convertBaseToScreen:pointInWindow];

    
    //NSLog(@"LQBaseApp: global pos %@ -- screen pos %@  -- main window %@", NSStringFromPoint(globalPos), NSStringFromPoint(pointOnScreen), [event window]);

    LXUInteger hoverEvType = 0;
    id hoverReceiver = [_hoverList sendHoverForEvent:event eventTypePtr:&hoverEvType];
    if (hoverEvType != kLQHoverOutside) {
        ///NSLog(@"LQBaseApp did handle hover event: type %i, receiver %@", hoverEvType, hoverReceiver);
        didHandle = YES;
    }

    if (_moveEventObservers) {
        NSEnumerator *enumerator = [_moveEventObservers objectEnumerator];
        NSValue *weakRef;
        while (weakRef = [enumerator nextObject]) {
            id ob = [weakRef pointerValue];
            [(NSView *)ob mouseMoved:event];
        }
    }
    
    return didHandle;
}


- (void)sendEvent:(NSEvent *)event
{
    LXUInteger flags = [event modifierFlags];
    NSEventType type = [event type];
    BOOL altDown = (flags & NSAlternateKeyMask) ? YES : NO;
	BOOL didHandle = NO;
    
    if (type == NSMouseMoved) {
        didHandle = [self _sendMouseMovedEvent:event];
    }

/*    
#if ( !RELEASE)
    if (type == NSKeyDown) {
        unsigned short keyCode = [event keyCode];
        ///NSLog(@"keycode %i", (int)keyCode);
        
        if (  (keyCode == 76 // numeric Enter
            || keyCode == 53 // Esc
            )) {
            if ( ![event isARepeat]) {
                [[LCLiveClipPanelController sharedController] triggerNextEvent];
            }
            didHandle = YES;
        }
    }
#endif
*/

    if ( !didHandle)
        [super sendEvent:event];
}

@end
