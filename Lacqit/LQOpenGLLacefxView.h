//
//  LQLacefxView.h
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQLacefxViewBaseMixin.h"

#import <OpenGL/GL.h>
#import <OpenGL/CGLTypes.h>

/*
  although this is an OpenGLView subclass, it should only be used through its own platform-independent methods
  and those inherited from NSView because on a different Lacefx implementation it may derive from something else (e.g. Direct3DView)
*/

LACQIT_EXPORT_VAR NSString * const kLQLacefxViewCursorUpdateNotification;


@interface LQOpenGLLacefxView : NSOpenGLView {

    IBOutlet id     _delegate;
    id              _mouseEventDelegate;

    id              _baseMixin;
    
    // window system state
    BOOL            _isFreshlyInited;
    BOOL            _isOpaque;
    BOOL            _isOffscreen;
    BOOL            _getsPeriodicRefresh;
    BOOL            _enableVSync;
    
    BOOL            _usesSharedCtx;
    LXSurfaceRef    _lxSurface;
    
    LXUInteger      _fitToViewMode;
    
    // transient event state
    id              _trackingArea;
    BOOL            _inGesture;
    
    double          _liveResizeLastRefreshT;
}

+ (NSOpenGLContext *)sharedNSOpenGLContext;

// standard initializer. uses an RGBA pixel format with no depth/stencil, and with the main display specified as screen mask.
- (id)initWithFrame:(NSRect)frame;

// to create a view that does not share state with the main GL context, pass NO to useSharedGL.
// note that such a view can't e.g. draw from regular LXSurfaces because they are created in the main GL context
- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)fmt useSharedGLContext:(BOOL)useSharedGL;


- (void)setWindowSystemSurfaceIsOpaque:(BOOL)f;
- (void)setHasWindowSystemDrawable:(BOOL)f;
- (void)setVBLSyncEnabled:(BOOL)f;

- (void)setGetsPeriodicRefresh:(BOOL)f;
- (BOOL)getsPeriodicRefresh;

- (BOOL)isFullScreen;

// when the delegate provides a content texture, this is used to determine how to fit it to the view.
// must be one of the LQFitToViewMode constants
- (LXUInteger)fitToViewMode;
- (void)setFitToViewMode:(LXUInteger)mode;

// see LQLacefxViewBaseMixin.h for the delegate methods
- (void)setDelegate:(id)del;
- (id)delegate;

- (void)setMouseEventDelegate:(id)del;  // if set, takes priority over plain delegate
- (id)mouseEventDelegate;

// the cell delegate can be used to intercept events within cells (see LQLacefxViewBaseMixin.h for the methods)
- (void)setCellDelegate:(id)del;
- (id)cellDelegate;

- (void)addCell:(LQXCell *)cell;
- (void)removeCell:(LQXCell *)cell;
- (LQXCell *)cellNamed:(NSString *)name;
- (NSArray *)cells;


- (void)drawNow;  // caller must be holding the context lock already
- (void)getLXLockAndDrawNow;

// call this to render the view's contents in a surface other than its own drawable
- (void)captureInLXSurface:(LXSurfaceRef)lxSurface;

// subclasses should override for custom drawing;
// the default implementation calls the delegate methods.
// don't call this directly (call -drawNow if you must repaint immediately)
- (void)drawInLXSurface:(LXSurfaceRef)lxSurface;

// subclass can/should call this from a custom implementation of -drawInLXSurface
- (void)drawCellsInLXSurface:(LXSurfaceRef)lxSurface;


+ (BOOL)enableVBLSyncByDefault;

@end

