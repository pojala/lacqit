//
//  LQGCanvasController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCanvasController_cocoa.h"
#import "LQCairoBitmapView.h"


@implementation LQGCanvasController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}


- (LQCairoBitmap *)cairoBitmap {
    return [(LQCairoBitmapView *)_view cairoBitmap]; }
    

- (void)setCanvasSize:(NSSize)size {
    _size = size;
    
    if (_view) {
        [_view setFrame:NSMakeRect(0, 0, _size.width, _size.height)];
    }
}

- (NSSize)canvasSize {
    return _size; }


- (void)loadView
{
    if (_view) return;

    NSRect viewRect = (_size.width > 0 && _size.height > 0) ? NSMakeRect(0, 0, _size.width, _size.height)
                                                            : NSMakeRect(0, 0, 200, 150);
    
    _view = [[LQCairoBitmapView alloc] initWithFrame:viewRect];

    [(LQCairoBitmapView *)_view setDelegate:self];
}



#pragma mark --- CairoBitmapView delegate ---

- (void)_delegateMouseEvent:(NSEvent *)event typeName:(NSString *)eventTypeName
{
    NSAssert(eventTypeName, @"no event type name given");

    LXInteger clickCount = [event clickCount];
    LXInteger buttonNumber = 0;
    LXUInteger buttonMask = 0;
    LXFloat pressure = 0.0;
    NSPoint tilt = NSZeroPoint;

#ifdef __APPLE__    
    buttonNumber = [event buttonNumber];
    buttonMask = [event buttonMask];
    pressure = [event pressure];
    tilt = [event tilt];
#endif
    
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        NSPoint posInWindow = [event locationInWindow];
        NSPoint posOnScreen = [[_view window] convertBaseToScreen:posInWindow];
        NSPoint posInView = [_view convertPoint:posInWindow fromView:nil];
        
        // flip Y
        double viewH = [_view frame].size.height;
        posInView.y = viewH - 1 - posInView.y;
        
        [_delegate actionInViewController:self context:kLQGActionContext_MouseEvent
                                                  info:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        eventTypeName, @"eventType",
                                                                        [NSNumber numberWithDouble:posInView.x], @"viewX",
                                                                        [NSNumber numberWithDouble:posInView.y], @"viewY",
                                                                        [NSNumber numberWithDouble:posOnScreen.x], @"screenX",
                                                                        [NSNumber numberWithDouble:posOnScreen.y], @"screenY",
                                                                        [NSNumber numberWithInt:buttonNumber], @"buttonNumber",
                                                                        [NSNumber numberWithUnsignedInt:buttonMask], @"buttonMask",
                                                                        [NSNumber numberWithInt:clickCount], @"clickCount",
                                                                        [NSNumber numberWithDouble:pressure], @"pressure",
                                                                        [NSNumber numberWithDouble:tilt.x], @"penTiltX",
                                                                        [NSNumber numberWithDouble:tilt.y], @"penTiltY",
                                                                        ///event, @"NSEvent",
                                                                        nil]
                                                  ];
    }
}

- (void)_delegateKeyEvent:(NSEvent *)event typeName:(NSString *)eventTypeName
{
	BOOL shiftDown = (([event modifierFlags] & NSShiftKeyMask) ? YES : NO);
	BOOL altDown =   (([event modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    BOOL ctrlDown =  (([event modifierFlags] & NSControlKeyMask) ? YES : NO);

    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        [_delegate actionInViewController:self context:kLQGActionContext_KeyEvent
                                                  info:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        eventTypeName, @"eventType",
                                                                        [event charactersIgnoringModifiers], @"characters",
                                                                        [NSNumber numberWithBool:shiftDown], @"shiftPressed",
                                                                        [NSNumber numberWithBool:altDown],   @"altPressed",
                                                                        [NSNumber numberWithBool:ctrlDown],  @"ctrlPressed",
                                                                        ///event, @"NSEvent",
                                                                        nil]
                                                  ];
    }
}

- (BOOL)handleMouseDown:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view {
    [self _delegateMouseEvent:event typeName:@"mousedown"];
    return YES;
}

- (BOOL)handleMouseDragged:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view {
    [self _delegateMouseEvent:event typeName:@"mousedrag"];
    return YES;
}

- (BOOL)handleMouseUp:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view {
    [self _delegateMouseEvent:event typeName:@"mouseup"];
    return YES;
}

- (BOOL)handleKeyDown:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view {
    [self _delegateKeyEvent:event typeName:@"keydown"];
    return YES;
}

- (BOOL)handleKeyUp:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view {
    [self _delegateKeyEvent:event typeName:@"keyup"];
    return YES;
}


@end
