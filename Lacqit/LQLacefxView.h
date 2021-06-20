/*
 *  LQLacefxView.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 27.1.2011.
 *  Copyright 2011 Lacquer oy/ltd. All rights reserved.
 *
 */

#import <Lacefx/Lacefx.h>


#if defined(LXPLATFORM_WIN)
 #import "LQDirect3DLacefxView.h"
 #define LQLACEFXVIEWBASECLASS LQDirect3DLacefxView
#else
 #import "LQOpenGLLacefxView.h"
 #define LQLACEFXVIEWBASECLASS LQOpenGLLacefxView
#endif


/*
  These are the shared methods between OpenGL and Direct3D implementations.
  
  Each platform-specific implementation class actually overrides this class's alloc
  so the appropriate class is returned. Hence, this class never gets instantiated.
*/

@interface LQLacefxView : NSView {

    IBOutlet id     _delegate;
    id              _baseMixin;
}


// see LQLacefxViewBaseMixin.h for the delegate methods
- (void)setDelegate:(id)del;
- (id)delegate;

- (void)drawNow;  // a.k.a. present

// arbitrary metadata (used in Radi)
- (void)setValue:(id)value forUIContextAttribute:(NSString *)key;
- (id)valueForUIContextAttribute:(NSString *)key;


#if defined(LXPLATFORM_MAC)
// these methods are all dumped here for compatibility with existing code that should be modified
// to call LQOpenGLLacefxView instead -- but that's too much trouble right now...


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

// the cell delegate can be used to intercept events within cells (see LQLacefxViewBaseMixin.h for the methods)
- (void)setCellDelegate:(id)del;
- (id)cellDelegate;

- (void)addCell:(LQXCell *)cell;
- (void)removeCell:(LQXCell *)cell;
- (LQXCell *)cellNamed:(NSString *)name;
- (NSArray *)cells;


- (void)getLXLockAndDrawNow;

// call this to render the view's contents in a surface other than its own drawable
- (void)captureInLXSurface:(LXSurfaceRef)lxSurface;

// subclasses should override for custom drawing;
// the default implementation calls the delegate methods.
// don't call this directly (call -drawNow if you must repaint immediately)
- (void)drawInLXSurface:(LXSurfaceRef)lxSurface;

// subclass can/should call this from a custom implementation of -drawInLXSurface
- (void)drawCellsInLXSurface:(LXSurfaceRef)lxSurface;

#endif

@end
