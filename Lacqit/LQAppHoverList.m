//
//  LQAppHoverList.m
//  Lacqit
//
//  Created by Pauli Ojala on 27.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQAppHoverList.h"


@implementation LQAppHoverList

- (id)init
{
    self = [super init];
    _level1 = [[NSMutableArray alloc] init];
    _level2 = [[NSMutableArray alloc] init];
    _observed = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)dealloc
{
    [_level1 release];
    [_level2 release];
    [_observed release];
    [super dealloc];
}


- (void)trackBaseLevelView:(NSView *)view
{
    if ( ![_level1 containsObject:view])
        [_level1 addObject:view];
}


- (void)trackPopUpLevelWindow:(NSWindow *)window
{
    if ( ![_level2 containsObject:window])
        [_level2 addObject:window];
}

- (void)removeTrackingForObject:(id)obj
{
    if (_currentHovered == obj)
        _currentHovered = nil;

    if ([_level1 containsObject:obj])
        [_level1 removeObject:obj];
        
    else if ([_level2 containsObject:obj])
        [_level2 removeObject:obj];
        
    id weakRef = [NSValue valueWithPointer:obj];
    if ([_observed objectForKey:weakRef])
        [_observed removeObjectForKey:weakRef];
}


- (void)_sendHoverExited:(NSEvent *)event forObject:(id)obj
{
    if ([obj respondsToSelector:@selector(hoverExited:)])
        [obj hoverExited:event];
        
    id observers = [_observed objectForKey:[NSValue valueWithPointer:obj]];
    NSEnumerator *obsEnum = [observers objectEnumerator];
    id obsv;
    while (obsv = [obsEnum nextObject]) {
        if ([obsv respondsToSelector:@selector(hoverExited:forObject:)])
            [obsv hoverExited:event forObject:obj];
    }
}

- (void)_sendHoverEntered:(NSEvent *)event forObject:(id)obj
{
    if ([obj respondsToSelector:@selector(hoverEntered:)])
        [obj hoverEntered:event];
        
    id observers = [_observed objectForKey:[NSValue valueWithPointer:obj]];
    NSEnumerator *obsEnum = [observers objectEnumerator];
    id obsv;
    while (obsv = [obsEnum nextObject]) {
        if ([obsv respondsToSelector:@selector(hoverEntered:forObject:)])
            [obsv hoverEntered:event forObject:obj];
    }
}

- (void)_sendHoverInside:(NSEvent *)event forObject:(id)obj
{
    if ([obj respondsToSelector:@selector(hoverInside:)])
        [obj hoverInside:event];
        
    id observers = [_observed objectForKey:[NSValue valueWithPointer:obj]];
    NSEnumerator *obsEnum = [observers objectEnumerator];
    id obsv;
    while (obsv = [obsEnum nextObject]) {
        if ([obsv respondsToSelector:@selector(hoverInside:forObject:)])
            [obsv hoverInside:event forObject:obj];
    }
}


- (LXUInteger)_updateHoverStateForObject:(id)obj withEvent:(NSEvent *)event
{
    ///NSLog(@"hoverlist state: rec %@, current %@", obj, _currentHovered);

    if ( !obj && !_currentHovered)
        return kLQHoverOutside;

    else if ( !obj && _currentHovered) {
        [self _sendHoverExited:event forObject:_currentHovered];
        _currentHovered = nil;
        return kLQHoverExited;
    }

    else if (_currentHovered != obj) {
        [self _sendHoverExited:event forObject:_currentHovered];

        _currentHovered = obj;        
        
        [self _sendHoverEntered:event forObject:obj];
        return kLQHoverEntered;
    }
    
    else {
        [self _sendHoverInside:event forObject:obj];
        return kLQHoverInside;
    }
}


- (id)sendHoverForEvent:(NSEvent *)event eventTypePtr:(LXUInteger *)outType
{
    const NSPoint globalScreenPos = [NSEvent mouseLocation];
    const NSWindow *mainWindow = [event window];
    /*
    NSScreen *screen = [mainWindow screen];
    NSPoint pointInWindow = [event locationInWindow];
    NSPoint pointOnScreen = [mainWindow convertBaseToScreen:pointInWindow];
    */
    
    id receiver = nil;
    LXUInteger evType = 0;
    
    NSEnumerator *enumerator = [_level2 reverseObjectEnumerator];
    NSWindow *win;
    while (win = [enumerator nextObject]) {
        NSRect winFrame = [win frame];
        
        if (NSPointInRect(globalScreenPos, winFrame))
            break;
    }
    if (win) {
        receiver = win;
        goto done;
    }
    
    enumerator = [_level1 reverseObjectEnumerator];
    NSView *view;
    while (view = [enumerator nextObject]) {
        if ([view isHidden])
            continue;
        
        NSRect viewFrameInWin = [view convertRect:[view bounds] toView:nil];
        NSScreen *screen = [[view window] screen];
        
        NSRect viewFrameOnScreen = viewFrameInWin;
        viewFrameOnScreen.origin = [[view window] convertBaseToScreen:viewFrameInWin.origin];
        
        //NSLog(@"hoverview %@: frame %@, pos %@", view, NSStringFromRect(viewFrameOnScreen), NSStringFromPoint(globalScreenPos));
        
        if (NSPointInRect(globalScreenPos, viewFrameOnScreen))
            break;
    }
    if (view) {
        receiver = view;
        goto done;
    }
    
done:
    evType = [self _updateHoverStateForObject:receiver withEvent:event];
    
    if (outType) *outType = evType;
    return receiver;
}


#pragma mark --- observers ---

- (void)addObserver:(id)obsv forObject:(id)obj
{
    id weakRef = [NSValue valueWithPointer:obj];
    NSMutableArray *observerList = [_observed objectForKey:weakRef];
    if ( !observerList) {
        observerList = [NSMutableArray array];
        [_observed setObject:observerList forKey:weakRef];
    }
    
    if ( ![observerList containsObject:obsv]) {
        [observerList addObject:obsv];
    }
}

- (void)removeObserver:(id)obsv
{
    // TODO
}


@end
