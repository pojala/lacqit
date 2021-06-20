//
//  LQMegaDropDown.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQMegaDropDown.h"
#import "LQPopUpWindow.h"
#import "LQGViewController.h"


@interface LQMegaDropDown (Private)
- (void)_endModal;
- (void)windowWillClose:(NSNotification *)notif;
@end


@implementation LQMegaDropDown

- (id)init
{
    self = [super init];
    
    if (self) {
        NSSize hudSize = NSMakeSize(260, 300);
        
        NSRect hudFrame = NSMakeRect(200, 200, hudSize.width, hudSize.height);
    
        LQPopUpWindow *popUp = [[LQPopUpWindow alloc] initWithFrame:hudFrame];
    
        [popUp setLevel:NSPopUpMenuWindowLevel];
        [popUp setResizable:YES];
        //[popUp setClosable:YES];
        [popUp setDraggable:YES];
        [popUp setPopUpControlTint:kLQPopUpDarkBorderlessTint];
        
        //[popUp setDrawsWithLacefx:YES];    
        //[[popUp lacefxView] setDelegate:self];
/*
        NSTextField *field;
        field = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 6, 300, 12)];
        [field setEditable:NO];
        [field setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
        [field setTextColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.95]];
        [field setStringValue:@""];
        [field setAlignment:NSLeftTextAlignment];
        [field setBezeled:NO];
        [field setDrawsBackground:NO];
        
        [[popUp contentView] addSubview:[field autorelease]];
        
        _infoField = field;
*/        
        /*
        NSView *dragView = [[LQPopUpDragAreaView alloc] initWithFrame:NSMakeRect(9, hudSize.height - 8 - 10, hudSize.width - 2*9, 10)];
        [dragView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        [[popUp contentView] addSubview:[dragView autorelease]];
        */
        
        _hudWindow = popUp;    
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if ([_viewCtrl respondsToSelector:@selector(willBeRemovedFromDropDown:)]) {
        [_viewCtrl willBeRemovedFromDropDown:self];
    }

    [_hudWindow hidePopUp];

    [_activeView removeFromSuperview];
    [_viewCtrl release];
    
    [_hudWindow release];
    
    [super dealloc];
}


- (LQPopUpWindow *)popUpWindow
{
    return _hudWindow;
}

- (void)containeeWillBeginModalSession:(id)sender
{
    LQPopUpWindow *window = [self popUpWindow];
    _prevWindowLevel = [window level];
    
    if (_prevWindowLevel != NSFloatingWindowLevel) {
        [window setLevel:NSFloatingWindowLevel];
    }
}

- (void)containeeDidEndModalSession:(id)sender
{
    LQPopUpWindow *window = [self popUpWindow];
    
    if (_prevWindowLevel > 0) {
        [window setLevel:_prevWindowLevel];
        _prevWindowLevel = 0;
    }
}



- (id)viewController {
    return _viewCtrl; }

- (void)setViewController:(id)viewCtrl
{
    if (_viewCtrl) {
        if ([_viewCtrl respondsToSelector:@selector(willBeRemovedFromDropDown:)]) {
            [_viewCtrl willBeRemovedFromDropDown:self];
        }
        
        [_activeView removeFromSuperview];
        [_viewCtrl release];
    }
    
    _viewCtrl = [viewCtrl retain];
    
    [_viewCtrl loadView];

    if ([_viewCtrl respondsToSelector:@selector(willBeContainedInDropDown:)]) {
        [_viewCtrl willBeContainedInDropDown:self];
    }
    
    _activeView = [viewCtrl nativeView];
    
    if (_activeView) {
        NSRect viewFrame = [_activeView frame];
        
        double xMargin = 12.0;
        double yMargin = 12.0;
    
        viewFrame.origin = NSMakePoint(xMargin, yMargin);
        [_activeView setFrame:viewFrame];
        
        NSRect hudFrame = [_hudWindow frame];
        hudFrame.size = NSMakeSize(viewFrame.size.width + 2*xMargin, viewFrame.size.height + 2*yMargin + 6);
        
        [_hudWindow setFrame:hudFrame display:NO];
        
        [[_hudWindow contentView] addSubview:_activeView];
    }
}


- (void)windowWillClose:(NSNotification *)notif
{
    [self _endModal];
}


- (LXInteger)runDropDownForView:(NSView *)clickedView
{
    if (clickedView) {
        NSRect viewBounds = [clickedView bounds];
        NSWindow *clickedWin = [clickedView window];
        NSPoint viewOriginOnScreen = [clickedWin convertBaseToScreen:[clickedView convertPoint:viewBounds.origin toView:nil]];
        
        NSPoint hudTL = NSMakePoint(viewOriginOnScreen.x + 4, viewOriginOnScreen.y - viewBounds.size.height - 4);
        
        ///NSLog(@"view %@ --> hudpoint %@ (%@)", clickedView, NSStringFromPoint(hudTL), clickedWin);
        
        NSRect popUpFrame = [_hudWindow frame];
        popUpFrame.origin = NSMakePoint(hudTL.x, hudTL.y - popUpFrame.size.height);
        
        NSRect screenRect = [[clickedWin screen] frame];
        popUpFrame = [_hudWindow constrainFrameRect:popUpFrame toScreen:[clickedWin screen]];
        
        // the above constrain.. call doesn't seem to do this, so check manually that the window is within the screen
        if (popUpFrame.origin.x + popUpFrame.size.width > screenRect.origin.x + screenRect.size.width) {
            popUpFrame.origin.x = screenRect.origin.x + screenRect.size.width - popUpFrame.size.width - 4;
        }
        
        if (popUpFrame.origin.y < screenRect.origin.y) {
            popUpFrame.origin.y = -1.0 + [clickedWin convertBaseToScreen:[clickedView convertPoint:NSMakePoint(viewBounds.origin.y+viewBounds.size.height, 0) toView:nil]].y;
        }
        
        ///NSLog(@"...hudframe is: %@ (screen %@)", NSStringFromRect(popUpFrame), [clickedWin screen]);
        
        [_hudWindow setFrame:popUpFrame display:NO];
        
        //[_hudWindow setFrameTopLeftPoint:hudTL];
    }

    [_hudWindow displayPopUp];

    [[NSNotificationCenter defaultCenter]
                        addObserver:self selector:@selector(windowWillClose:)
                        name:NSWindowWillCloseNotification object:_hudWindow];
    
    // capture events until the modal session is cancelled, or user clicks outside the window
    _modalReturn = 0;
    _inModal = YES;
    while (_inModal) {
        NSEvent *event;
        if ((event = [NSApp nextEventMatchingMask:NSAnyEventMask
                                     untilDate:[NSDate distantFuture]
                                        inMode:NSDefaultRunLoopMode
                                       dequeue:YES]) != nil) {
            LXUInteger type = [event type];
            BOOL didHandle = NO;
                                       
            if (type == NSLeftMouseDown || type == NSRightMouseDown 
#ifndef __COCOTRON__
                                        || type == NSOtherMouseDown
#endif
            ) {
                NSRect popUpFrame = [_hudWindow frame];
                NSWindow *evWindow = [event window];
                BOOL isOutside = NO;
                
                // if the event's window is something else than the popup, exit modal
                if (evWindow && evWindow != _hudWindow) {
                    isOutside = YES;
                }
                
                // Cocoa docs say that event window can be nil for some event types, in which case locationInWindow is in screen coords; 
                // thus check for it here
                NSPoint posOnScreen = (evWindow) ? [evWindow convertBaseToScreen:[event locationInWindow]] : [event locationInWindow];
                
                if (isOutside || !NSMouseInRect(posOnScreen, popUpFrame, NO)) {
                    // break out of modal session if user clicks outside of the popup
                    _modalReturn = 0;
                    _inModal = NO;
                    didHandle = YES;
                }
            }
            
            if ( !didHandle)
                [NSApp sendEvent:event];
        }
    }
    
    // modal session has ended    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_hudWindow hidePopUp];
    
    return _modalReturn;
}

- (void)_endModal
{
    if ( !_inModal) return;
    
    _inModal = NO;
    
    NSEvent *awaken = [NSEvent otherEventWithType: NSApplicationDefined
                          location: NSMakePoint(-1.0, -1.0)
                     modifierFlags: 0
                         timestamp: [NSDate timeIntervalSinceReferenceDate]
                      windowNumber: [[NSApp mainWindow] windowNumber]
                           context: [NSApp context]
                           subtype: 0
                             data1: 0
                             data2: 0];
                             
   [NSApp postEvent:awaken atStart:NO];
}

- (void)endDropDown
{
    _modalReturn = 1;
    [self _endModal];
}

@end
