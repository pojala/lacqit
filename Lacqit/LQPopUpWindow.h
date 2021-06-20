//
//  LQPopUpWindow.h
//  Lacqit
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"

#ifndef __LAGOON__
#import "LQLacefxView.h"
#endif


typedef enum {
    kLQPopUpDarkTint = 0,
    kLQPopUpDarkBorderlessTint,
    kLQPopUpDarkPurpleTint,
    kLQPopUpMediumTint,
    kLQPopUpLightTint,
    kLQPopUpTransparentTint,
} LQPopUpControlTint;




@interface LQPopUpWindow : NSWindow {

    id                          _contentDelegate;
 
    NSString                    *_name;
    id                          _repObj;
    
    LXUInteger                  _controlTint;    
    double                      _maxAlpha;
    BOOL                        _isResizable;
    BOOL                        _displaysTitle;
    BOOL                        _canBecomeKey;
    
    id                          _closeButtonView;
    id                          _dragBarView;

#ifndef __LAGOON__
    LQLacefxView                *_lacefxView;
#endif
    id _testView;
    
    // temp event state
    BOOL                        _isInResize;
    BOOL                        _isInWindowDrag;
    LXUInteger                  _activeEventMask;
    NSTimer                     *_windowTimer;
    double                      _startTime;
}

+ (double)maxAlpha;

- (id)initWithFrame:(NSRect)frame;

- (void)setPopUpControlTint:(LXUInteger)tint;
- (LXUInteger)popUpControlTint;

- (void)setName:(NSString *)name;
- (NSString *)name;

- (void)setRepresentedObject:(id)obj;  // retained
- (id)representedObject;

- (void)setResizable:(BOOL)f;
- (BOOL)isResizable;

- (void)setClosable:(BOOL)f;
- (BOOL)isClosable;

- (void)setDraggable:(BOOL)f;
- (BOOL)isDraggable;

- (void)setDisplaysTitle:(BOOL)f;
- (BOOL)displaysTitle;

- (void)setAcceptsKeyEvents:(BOOL)f;
- (BOOL)acceptsKeyEvents;

#ifdef __APPLE__
- (void)setDrawsWithLacefx:(BOOL)f;
- (BOOL)drawsWithLacefx;

- (LQLacefxView *)lacefxView;
#endif


- (void)runPopUpAsMouseModal;

- (void)displayPopUp;
- (void)hidePopUp;

// for view implementation
- (void)doWindowDrag;

- (BOOL)inLiveResize;

@end


@interface LQPopUpContentView : NSView {

}
@end


@interface NSObject (LQPopUpWindowAdditionalDelegateMethods)
- (void)mouseDown:(NSEvent *)event inPopUpWindow:(LQPopUpWindow *)popup;
@end

