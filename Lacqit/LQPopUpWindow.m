//
//  LQPopUpWindow.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQPopUpWindow.h"
#import "LQNSBezierPathAdditions.h"
#import "LQPopUpDragAreaView.h"
#import "LQPopUpCloseButtonView.h"
//#import "TestGLView.h"


static BOOL isOSLeopard()
{
    return [NSThread respondsToSelector:@selector(mainThread)];
}


@interface LQPopUpWindow (ImplPrivate)
- (void)_stopWindowTimer;
@end


@implementation LQPopUpWindow

- (id)initWithFrame:(NSRect)frame
{
    return [self initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer:NO];
}


- (id)initWithContentRect:(NSRect)frame
                styleMask:(LXUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                  defer:(BOOL)deferCreation
{
    return [self initWithContentRect:frame
                            styleMask:windowStyle
                            backing:bufferingType
                            defer:deferCreation
                            screen:[NSScreen mainScreen]];
}

+ (Class)contentViewClass {
    return [LQPopUpContentView class]; }

+ (double)maxAlpha {
    return 0.95; }

- (id)initWithContentRect:(NSRect)frame styleMask:(LXUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
                  screen:(NSScreen *)screen
{
    ///NSLog(@"%s: %@, %i, %i, %i, %@", __func__, NSStringFromRect(frame), windowStyle, bufferingType, deferCreation, [screen description]);

    self = [super initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer:NO
                            //screen:screen
                            ];
                            
    if (self)
    {
        //[self setBecomesKeyOnlyIfNeeded:YES];
        //[self setMovableByWindowBackground:YES];
        
        [self setOneShot:NO];
        [self setReleasedWhenClosed:NO];    

        _maxAlpha = [[self class] maxAlpha];

        [self setOpaque:NO];
        [self setAlphaValue:_maxAlpha];
        [self setLevel:NSFloatingWindowLevel]; //NSPopUpMenuWindowLevel];
        [self setHidesOnDeactivate:YES];
        [self setMinSize:NSMakeSize(150, 120)];
    
        if (isOSLeopard()) {
            // only use a shadow on Leopard, because Leopard's lightweight and large shadows are prettier for floater windows
            [self setHasShadow:YES];
            [self invalidateShadow];
        }
        
        LQPopUpContentView *cview = [[[[self class] contentViewClass] alloc] initWithFrame:[[self contentView] frame]];
        [self setContentView:[cview autorelease]];
    }
    return self;
}

- (void)dealloc
{
    [self _stopWindowTimer];
    [_name release];
    [_repObj release];
    [super dealloc];
}


#pragma mark --- accessors ---

- (void)setContentDelegate:(id)delegate {
    _contentDelegate = delegate;
}
        
- (id)contentDelegate {
    return _contentDelegate; }


- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy];
}
    
- (NSString *)name {
    return _name; }

- (void)setRepresentedObject:(id)obj {
    if (obj != _repObj) {
        [_repObj release];
        _repObj = [obj retain];
    }
}
    
- (id)representedObject {
    return _repObj; }


- (void)setResizable:(BOOL)f
{
    if (f != _isResizable) {
        _isResizable = f;
        [[self contentView] setNeedsDisplay:YES];
    }
}

- (BOOL)isResizable {
    return _isResizable; }


- (void)setPopUpControlTint:(LXUInteger)tint {
    _controlTint = tint;
    [[self contentView] setNeedsDisplay:YES];
}

- (LXUInteger)popUpControlTint {
    return _controlTint; }

- (void)windowCloseButtonAction:(id)sender
{
    [self close];
}

- (void)setClosable:(BOOL)f
{
    BOOL recreateDragBar = NO;
    
    if (f && !_closeButtonView) {
        NSSize hudSize = [self frame].size;
        double buttonW = 15.0;
        
        LQPopUpCloseButtonView *buttonView = [[LQPopUpCloseButtonView alloc] initWithFrame:NSMakeRect(6, hudSize.height - 6 - buttonW,  buttonW, buttonW)];
        [buttonView setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
        
        [buttonView setTarget:self];
        [buttonView setAction:@selector(windowCloseButtonAction:)];
        
        [[self contentView] addSubview:[buttonView autorelease]];
        _closeButtonView = buttonView;
        
        recreateDragBar = YES;        
    }
    else if (_closeButtonView && !f) {
        [_closeButtonView removeFromSuperview];
        _closeButtonView = nil;

        recreateDragBar = YES;        
    }
    
    if (recreateDragBar && [self isDraggable]) {
        [_dragBarView removeFromSuperview];
        _dragBarView = nil;
        [self setDraggable:YES];
    }
}

- (BOOL)isClosable {
    return (_closeButtonView) ? YES : NO; }

- (void)setDraggable:(BOOL)f
{
    if (f && !_dragBarView) {
        NSSize hudSize = [self frame].size;
        
        double closeButtonsW = ([self isClosable]) ? 10.0 + 4.0 : 0.0;
        
        NSView *dragView = [[LQPopUpDragAreaView alloc] initWithFrame:NSMakeRect(9 + closeButtonsW, hudSize.height - 8 - 12, hudSize.width - 2*9 - closeButtonsW, 12)];
        [dragView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
        
        [[self contentView] addSubview:[dragView autorelease]];
        _dragBarView = dragView;
        
        [_dragBarView setTitle:(_displaysTitle) ? [self title] : nil];
        
        if (_lacefxView) {
            NSRect frame = [_lacefxView frame];
            frame.size.height -= [_dragBarView frame].size.height;
            [_lacefxView setFrame:frame];
        }
    }
    else if (_dragBarView && !f) {
        [_dragBarView removeFromSuperview];
        _dragBarView = nil;
    }
}

- (BOOL)isDraggable {
    return (_dragBarView) ? YES : NO; }


- (void)setDisplaysTitle:(BOOL)f
{
    _displaysTitle = f;
    if (_dragBarView) {
        [_dragBarView setTitle:(_displaysTitle) ? [self title] : nil];
    }
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    if (_displaysTitle) {
        [self setDisplaysTitle:YES];
    }
}
    
- (BOOL)displaysTitle {
    return _displaysTitle; }
    

- (void)setDrawsWithLacefx:(BOOL)f
{
    if (_lacefxView && !f) {
        // remove the view
    }
    else if ( !_lacefxView && f) {
        // create a new view
        LQPopUpContentView *cview = (LQPopUpContentView *)[self contentView];
        
        NSRect frame = [cview bounds];
        if (_dragBarView) {
            frame.size.height -= [_dragBarView frame].size.height;
        }
        
        _lacefxView = [[LQLacefxView alloc] initWithFrame:frame];
        
        [_lacefxView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
        
        if ([_lacefxView respondsToSelector:@selector(setWindowSystemSurfaceIsOpaque:)])
            [_lacefxView setWindowSystemSurfaceIsOpaque:NO];
        
        [cview addSubview:[_lacefxView autorelease]];
        
        //_testView = [[TestGLView alloc] initWithFrame:[cview bounds]];
        //[cview addSubview:[_testView autorelease]];
    }
}

- (BOOL)drawsWithLacefx {
    return (_lacefxView) ? YES : NO; }

- (LQLacefxView *)lacefxView {
    return _lacefxView; }


- (void)setAcceptsKeyEvents:(BOOL)f {
    _canBecomeKey = f; }
    
- (BOOL)acceptsKeyEvents {
    return _canBecomeKey; }


- (BOOL)canBecomeKeyWindow {
    return [self acceptsKeyEvents]; }

- (BOOL)canBecomeMainWindow {
    return NO; } //[self acceptsKeyEvents]; }


- (void)orderOut:(id)sender
{
    //NSLog(@"%s", __func__);
    if (_lacefxView && [_lacefxView respondsToSelector:@selector(setHasWindowSystemDrawable:)]) {
        [_lacefxView setHasWindowSystemDrawable:NO];
    }
    [super orderOut:sender];
}

- (void)orderFront:(id)sender
{
    if (_lacefxView && [_lacefxView respondsToSelector:@selector(setHasWindowSystemDrawable:)]) {
        [_lacefxView setHasWindowSystemDrawable:YES];
    }
    [super orderFront:sender];
}
    

#pragma mark --- drawing and transforms ---

- (NSRect)_resizeHandleRect
{
    NSRect windowRect = [[self contentView] bounds];
        NSRect resizeRect = NSInsetRect(windowRect, 3.0, 3.0);
        const double resizeHandleSize = 10.0;
        const double resizeHandleMargin = 4.0;
        resizeRect.origin.x += resizeRect.size.width - resizeHandleSize - resizeHandleMargin;
        resizeRect.origin.y += resizeHandleMargin;
        resizeRect.size.width = resizeHandleSize;
        resizeRect.size.height = resizeHandleSize;

    return resizeRect;
}


- (void)_drawResizeHandleInRect:(NSRect)r
{
    NSBezierPath *path;
    const double SW = 1.0;
    const double lineD = 4.0;
    const double shadD = 2.0;
    
    [[NSColor colorWithDeviceRed:0.01 green:0.0 blue:0.15 alpha:1.0] set];
    

    path = [NSBezierPath bezierPath];
    
    [path moveToPoint:NSMakePoint(r.origin.x + lineD*2.0, r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height - lineD*2.0)];
    [path setLineWidth:SW];
    [path stroke];
    
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(r.origin.x + lineD, r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height - lineD)];
    [path stroke];
    
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(r.origin.x, r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height)];
    [path stroke];
    
    [[NSColor colorWithDeviceRed:0.93 green:0.92 blue:0.96 alpha:0.4] set];

    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(r.origin.x + (lineD*2.0 - shadD), r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height - (lineD*2.0 - shadD))];
    [path stroke];
    
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(r.origin.x + (lineD-shadD), r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height - (lineD-shadD))];
    [path stroke];
    
    [path removeAllPoints];
    [path moveToPoint:NSMakePoint(r.origin.x - shadD, r.origin.y)];
    [path lineToPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height + shadD)];
    [path stroke];
        
}


- (void)_drawTitleGradientWithRect:(NSRect)titleRect heightInPixels:(int)gradientH flipY:(BOOL)flipY
{
    NSRect r;
    int i;

    double lineH = (titleRect.size.height > 0.0) ? ceil(titleRect.size.height / gradientH) : 1.0;
    double y = (flipY) ? titleRect.origin.y : (titleRect.origin.y + titleRect.size.height - 1.0);

    float maxAlpha = 0.65;
    if (_controlTint == kLQPopUpLightTint)
        maxAlpha = 0.25;

    for (i = 0; i < gradientH; i++) {
        float alpha = maxAlpha - maxAlpha * ((float)i / gradientH);
        [[NSColor colorWithDeviceRed:0.01 green:0.0 blue:0.15 alpha:alpha] set];
        
        float rounding = 6.0f;
        float xd = MIN((float)i / rounding, 1.0f);
        float xs = rounding - rounding * cosf((1.0f-xd) * M_PI*0.5);  // offset rect width for the rounded edges
        
        r = titleRect;
        r.origin.y = y;
        r.origin.x += xs;
        r.size.width -= xs*2.0f;
        r.size.height = lineH;
        
        NSRectFill(r);
        
        y += (flipY) ? 1.0 : -1.0;
    }
}


- (NSColor *)_backgroundColor
{
    switch (_controlTint) {
        case kLQPopUpDarkBorderlessTint:
        case kLQPopUpDarkTint:           //return [NSColor colorWithDeviceRed:0.1 green:0.09 blue:0.11 alpha:0.8];
                                        return [NSColor colorWithDeviceRed:0.01 green:0.0 blue:0.02 alpha:0.96];
        
        case kLQPopUpDarkPurpleTint:     return [NSColor colorWithDeviceRed:0.125 green:0.09 blue:0.17 alpha:0.92];

        case kLQPopUpMediumTint:         return [NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:0.85];
        
        case kLQPopUpLightTint:          return [NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:0.55];
    }
    return [NSColor grayColor];
}

- (NSColor *)_edgeStrokeColor
{
    switch (_controlTint) {
        default:
        case kLQPopUpDarkTint:           //return [NSColor colorWithDeviceRed:0.26 green:0.25 blue:0.28 alpha:0.6];
                                        //return [NSColor colorWithDeviceRed:0.06 green:0.05 blue:0.08 alpha:0.9];
                                        return [NSColor colorWithDeviceRed:0.58 green:0.55 blue:0.6 alpha:1.0];
                                        //return [NSColor blackColor];

        case kLQPopUpDarkBorderlessTint: return [NSColor colorWithDeviceRed:0.06 green:0.05 blue:0.08 alpha:1.0];
        
        case kLQPopUpDarkPurpleTint:     return [NSColor colorWithDeviceRed:0.58 green:0.55 blue:0.6 alpha:1.0];

        case kLQPopUpMediumTint:         return [NSColor colorWithDeviceRed:0.86 green:0.85 blue:0.88 alpha:0.4];

        case kLQPopUpLightTint:          return [NSColor colorWithDeviceRed:0.86 green:0.85 blue:0.88 alpha:0.3];
    }
    return [NSColor grayColor];
}


+ (double)windowCornerRounding {
    return 12.0; }

- (void)_drawFloaterChromeInRect:(NSRect)windowRect
{        
    //NSLog(@"refresh floater, windowrect %@", NSStringFromRect(windowRect));
    
    // background should be cleared already in caller method
    
    // draw floater window's title bar gradient
    const double gradH = 16.0;
    NSRect titleRect = NSInsetRect(windowRect, 3.0, 3.0);
    titleRect.origin.y += titleRect.size.height - gradH;
    titleRect.size.height = gradH;
    
    [self _drawTitleGradientWithRect:titleRect heightInPixels:gradH flipY:NO];

    // draw bottom gradient
    titleRect = NSInsetRect(windowRect, 3.0, 3.0);
    titleRect.size.height = 14.0;
    [self _drawTitleGradientWithRect:titleRect heightInPixels:14 flipY:YES];
            
    // draw rounded rect window
    NSRect rrect = NSInsetRect(windowRect, 2.5, 2.5);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rrect rounding:[[self class] windowCornerRounding]];
    
    [[self _backgroundColor] set];
    [path fill];

    [[self _edgeStrokeColor] set];
    [path setLineWidth:0.9];
    [path stroke];

    // draw resizing handle
    if (_isResizable)
        [self _drawResizeHandleInRect:[self _resizeHandleRect]];
    

    // draw title
#if (0)
    NSString *title = [self _titleForDisplay];
    
    if ([title length] > 0) {
        [title drawAtPoint:NSMakePoint(10.0, windowRect.size.height - 21.0)
                withAttributes:[[self class] overlayTitleAttributes]];
    }
#endif
}


- (void)drawFloaterBackground
{
    NSRect windowRect = [[self contentView] bounds];

    // clear
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    NSCompositingOperation compOp = [ctx compositingOperation];
    
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0] set];
    [ctx setCompositingOperation:NSCompositeClear];
    NSRectFill(windowRect);
    
    [ctx setCompositingOperation:compOp];


    if (_controlTint != kLQPopUpTransparentTint) {
        [self _drawFloaterChromeInRect:windowRect];    
    }
}



#pragma mark --- dragging/events ---

//(NSLeftMouseDownMask | NSRightMouseDownMask)

- (void)runPopUpWithEventMask:(unsigned long)eventMask
{
    [self displayPopUp];
    
    _activeEventMask = eventMask;
    
    //NSLog(@"entering popup tracking loop");
    
    // tracking loop
    while (1) {
        NSEvent *event = [self nextEventMatchingMask:eventMask];
        
        //NSLog(@"%s, %i", __func__, [event type]);
        
        if ([event type] == NSMouseMoved)
            return;
        
        NSPoint screenPos = [NSEvent mouseLocation];
        NSRect frame = [self frame];
        
        if (NSPointInRect(screenPos, frame)) {
            [[self contentView] mouseDown:event];
        } else
            break;
    }
    //NSLog(@"exited popup");
    
    [self hidePopUp];
}

- (void)runPopUpAsMouseModal
{
    [self runPopUpWithEventMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSMouseMovedMask)];
}


#define KEY_FADEINTIME      @"fadeInTime"
#define KEY_FADEOUTTIME     @"fadeOutTime"
#define KEY_ALPHAVAL        @"alpha"

- (void)_stopWindowTimer
{
    if (_windowTimer) {
            [_windowTimer invalidate];
            [_windowTimer release];
            _windowTimer = nil;
            
            [self autorelease];  // was retained when the timer was created (fixes a crash bug on Tiger)
    }
}


- (void)windowTimerFired:(NSTimer *)timer
{
    id userInfo = [timer userInfo];
    id val;
    id alphaVal = [userInfo objectForKey:KEY_ALPHAVAL];
    
    double maxAlpha = (alphaVal) ? [alphaVal doubleValue] : _maxAlpha;
    
    if ((val = [userInfo objectForKey:KEY_FADEOUTTIME])) {
        double tlen = [val doubleValue];
        double time = LQReferenceTimeGetCurrent();
        double diff = time - _startTime;
        
        if (diff > tlen && [self isVisible]) {
            [self close];
            [self performSelector:@selector(_stopWindowTimer) withObject:nil afterDelay:0.001];
        }
        else {
            double pos = diff / tlen;
            pos = pow(pos, 1.5);
            double alpha = (1.0 - pos) * maxAlpha;
            [self setAlphaValue:alpha];
            
            if (alpha < 0.001) {
                if ([_lacefxView respondsToSelector:@selector(setHasWindowSystemDrawable:)])
                    [_lacefxView setHasWindowSystemDrawable:NO];
            }
        }
    }
    else if ((val = [userInfo objectForKey:KEY_FADEINTIME])) {
        double tlen = [val doubleValue];
        double time = LQReferenceTimeGetCurrent();
        double diff = time - _startTime;
        
        if (diff > tlen) {            
            [self setAlphaValue:_maxAlpha];
            [self _stopWindowTimer];
        }
        else {
            double pos = diff / tlen;
            pos = pow(pos, 4.0);
            [self setAlphaValue:pos * maxAlpha];
            
            if (pos > 0.0) {
                if ([_lacefxView respondsToSelector:@selector(setHasWindowSystemDrawable:)])
                    [_lacefxView setHasWindowSystemDrawable:YES];
            }

        }
    }
}

- (void)_startWindowTimerWithInfo:(id)userInfo
{
        _windowTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0)
                             target:[self retain]  // <-- retain to prevent a crash bug on Tiger
                             ///target:self
                             selector:@selector(windowTimerFired:)
                             userInfo:userInfo
                             repeats:YES] retain];
                             
        [[NSRunLoop currentRunLoop] addTimer:_windowTimer forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:_windowTimer forMode:NSEventTrackingRunLoopMode];
        [[NSRunLoop currentRunLoop] addTimer:_windowTimer forMode:NSModalPanelRunLoopMode];
        
        _startTime = LQReferenceTimeGetCurrent();
}

+ (double)popUpFadeInTime {
    return 0.15; }

+ (double)popUpFadeOutTime {
    return 0.25; }


- (void)displayPopUp
{
    [self setAlphaValue:0.0];
    [self orderFront:nil];
    
    //NSLog(@"%s, %@, timer: %@", __func__, self, _windowTimer);
    
    if ( !_windowTimer) {
        [self _startWindowTimerWithInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[[self class] popUpFadeInTime]] forKey:KEY_FADEINTIME]];
    }
}

- (void)hidePopUp
{
    if ( !_windowTimer) {
        [self _startWindowTimerWithInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:[[self class] popUpFadeOutTime]] forKey:KEY_FADEOUTTIME]];
    } else {
        //NSLog(@"%s", __func__);
        [self close];
    }
    
    ///[self orderOut:self];
}

- (void)doWindowResize
{
    if (_isInResize)
        return;

    _isInResize = YES;
    
    [[self contentView] viewWillStartLiveResize];
    
    NSEvent *event;
    NSPoint startPos = [NSEvent mouseLocation];
    NSRect startFrame = [self frame];

    startPos.x = roundf(startPos.x);
    startPos.y = roundf(startPos.y);
    
    // dragging loop
    while (1) {
        event = [self nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ([event type] == NSLeftMouseUp) {  // end drag
            break;
        }
        
        NSPoint screenPos = [NSEvent mouseLocation];
        screenPos.x = roundf(screenPos.x);
        screenPos.y = roundf(screenPos.y);

        NSSize minSize = [self minSize];
        
        NSRect newFrame = startFrame;
        double yDiff = screenPos.y - startPos.y;
        
        newFrame.size.width  += screenPos.x - startPos.x;
        newFrame.size.height -= yDiff;
        
        if (newFrame.size.height >= minSize.height) {
            newFrame.origin.y += yDiff;
        } else {
            newFrame.origin.y += yDiff - (minSize.height - newFrame.size.height);
        }
        
        newFrame.size.width = MAX(newFrame.size.width, minSize.width);
        newFrame.size.height = MAX(newFrame.size.height, minSize.height);
        
            ///NSLog(@"%s: %@", __func__, NSStringFromRect(newFrame));
        [self setFrame:newFrame display:YES];
    }

    [[self contentView] viewDidEndLiveResize];
        
    _isInResize = NO;
}

- (BOOL)inLiveResize
{
    return _isInResize;
}

- (void)doWindowDrag
{
    if (_isInResize) return;

    NSEvent *event;
    NSPoint startPos = [NSEvent mouseLocation];
    NSRect startFrame = [self frame];

    startPos.x = roundf(startPos.x);
    startPos.y = roundf(startPos.y);
    
    _isInWindowDrag = YES;
    
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect mainScreenFrame = [mainScreen frame];
    
    // dragging loop
    while (1) {
        event = [self nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        
        if ( !event || [event type] == NSLeftMouseUp) {  // end drag
            _isInWindowDrag = NO;
            return;
        }
        
        NSPoint screenPos = [NSEvent mouseLocation];
        screenPos.x = roundf(screenPos.x);
        screenPos.y = roundf(screenPos.y);
        
        NSRect newFrame = startFrame;
        newFrame.origin.x += screenPos.x - startPos.x;
        newFrame.origin.y += screenPos.y - startPos.y;
        
        // constrain window to main screen's visible area vertically (so that the window can't be dragged under the main menu bar), 
        // but only if we're actually on the main screen
        if ([[NSScreen screens] count] < 2 || NSPointInRect(newFrame.origin, mainScreenFrame)) {
            NSRect visFrame = [mainScreen visibleFrame];
            newFrame.origin.y = MIN(newFrame.origin.y, visFrame.origin.y + visFrame.size.height - newFrame.size.height + 4);
        }
        
        [self setFrame:newFrame display:YES];
    }
}



@end



#pragma mark ------ LQPopUpContentView -------

@implementation LQPopUpContentView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];    
    if (self) {
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (BOOL)isOpaque {
    return NO; }

/*
- (BOOL)mouseDownCanMoveWindow {
    return NO; }

- (BOOL)canBecomeKeyView {
    return YES; }

- (BOOL)needsPanelToBecomeKey {
    return YES; }

- (BOOL)acceptsFirstResponder {
    NSLog(@"floater acceptsfirstresp");
    return YES; }

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    NSLog(@"first mouse!");
    return YES; }
*/


- (void)mouseDown:(NSEvent *)event
{
    LQPopUpWindow *win = (LQPopUpWindow *)[self window];
    BOOL didHandle = NO;
    
    NSPoint pos = [self convertPoint:[event locationInWindow] fromView:nil];
    
    ///NSLog(@"pos %@,  resize %@", NSStringFromPoint(pos), NSStringFromRect([win _resizeHandleRect]));

    if ([win isResizable] && NSMouseInRect(pos, [win _resizeHandleRect], NO)) {
        [win doWindowResize];
        didHandle = YES;
    }
    
    if ([[win delegate] respondsToSelector:@selector(mouseDown:inPopUpWindow:)]) {
        [(id)[win delegate] mouseDown:event inPopUpWindow:win];
    }
    
//    if ( !didHandle && [[win contentDelegate] respondsToSelector:@selector(mouseDown:inFloater:)])
//        [[win contentDelegate] mouseDown:event inFloater:win];
}


- (void)drawRect:(NSRect)rect
{
    //[[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.1] set];
#if 0
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.1] set];
    NSRectFill(rect);    
    NSLog(@"debug drawrect for floater bg");
    return;
#endif
    
    LQPopUpWindow *win = (LQPopUpWindow *)[self window];
    
    [win drawFloaterBackground];
}

@end


