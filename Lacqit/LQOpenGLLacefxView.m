//
//  LQLacefxView.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQLacefxView.h"
#import "LQXCell.h"
#import <Lacefx/LQGLContext.h>
#import <Lacefx/LXPlatform_mac.h>
#import "LQLXBasicFunctions.h"
#import "LQTimeFunctions.h"


extern void LQUpdateMainDisplayGLMask();  // implemented in Lacefx

static Class g_viewCls = Nil;

@implementation LQLacefxView (OpenGLImplementation)

+ (void)setImplementationClass:(Class)cls
{
    g_viewCls = cls;
}

// override the base class alloc method to return the platform-specific implementation
+ (id)allocWithZone:(NSZone *)zone
{
    Class cls = g_viewCls ?: [LQOpenGLLacefxView class];
    
    //NSLog(@"%s -- self %@, allocating class %@ (g_viewCls = %p)", __func__, self, cls, g_viewCls);
    return NSAllocateObject(cls, 0, NULL);
}

@end


@interface NSView (LionBackingStoreAdditions)
- (NSPoint)convertPointToBacking:(NSPoint)aPoint;
- (NSPoint)convertPointFromBacking:(NSPoint)aPoint;
- (NSSize)convertSizeToBacking:(NSSize)aSize;
- (NSSize)convertSizeFromBacking:(NSSize)aSize;
- (NSRect)convertRectToBacking:(NSRect)aRect;
- (NSRect)convertRectFromBacking:(NSRect)aRect;
@end

@interface NSOpenGLView (LionHiResAdditions)
- (BOOL)wantsBestResolutionOpenGLSurface;
- (void)setWantsBestResolutionOpenGLSurface:(BOOL)flag;
@end


NSString * const kLQLacefxViewCursorUpdateNotification = @"LQLacefxViewCursorUpdateNotification";


// ---- private methods in LXSurface_objc ----
LXSurfaceRef LXSurfaceCreateFromNSView_(NSOpenGLView *view);
void LXSurfaceStartNSViewDrawing_(LXSurfaceRef surf);
void LXSurfaceEndNSViewDrawing_(LXSurfaceRef surf);



#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();



// --- NSTrackingArea enums and methods (for compile-time compatibility with pre-Leopard) ---
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
enum {
    NSTrackingMouseEnteredAndExited     = 0x01, // owner receives mouseEntered when mouse enters area, and mouseExited when mouse leaves area
    NSTrackingMouseMoved                = 0x02,	// owner receives mouseMoved while mouse is within area.  Note that mouseMoved events do not contain userInfo 
    NSTrackingCursorUpdate 		= 0x04,	// owner receives cursorUpdate when mouse enters area.  Cursor is set appropriately when mouse exits area
};
enum {
    NSTrackingActiveWhenFirstResponder 	= 0x10,	// owner receives mouseEntered/Exited, mouseMoved, or cursorUpdate when view is first responder
    NSTrackingActiveInKeyWindow         = 0x20, // owner receives mouseEntered/Exited, mouseMoved, or cursorUpdate when view is in key window
    NSTrackingActiveInActiveApp 	= 0x40,	// owner receives mouseEntered/Exited, mouseMoved, or cursorUpdate when app is active
    NSTrackingActiveAlways 		= 0x80,	// owner receives mouseEntered/Exited or mouseMoved regardless of activation.  Not supported for NSTrackingCursorUpdate.
};
enum {
    NSTrackingAssumeInside              = 0x100,    // If set, generate mouseExited event when mouse leaves area (same as assumeInside argument in deprecated addtrackingArea:owner:userData:assumeInside:)
    NSTrackingInVisibleRect             = 0x200,    // If set, tracking occurs in visibleRect of view and rect is ignored
    NSTrackingEnabledDuringMouseDrag    = 0x400     // If set, mouseEntered events will be generated as mouse is dragged.
}; 

typedef LXUInteger NSTrackingAreaOptions;

@interface NSObject (NSTrackingAreaMethods)
- (id)initWithRect:(NSRect)rect options:(NSTrackingAreaOptions)options owner:(id)owner userInfo:(NSDictionary *)userInfo;
@end

@interface NSView (NSTrackingAreaMethods)
- (void)addTrackingArea:(id)trackingArea;
- (void)removeTrackingArea:(id)trackingArea;
- (void)updateTrackingAreas;
@end

#define NSTRACKINGAREA_ENUMS_DEFINED 1
#endif




@implementation LQOpenGLLacefxView

#pragma mark --- shared GL state ---

static NSOpenGLContext *g_NSCtx = nil;
static LQGLContext *g_ctx = nil;


// this setting is necessary for proper operation on a multi-GPU system
// (tested on a Mac Pro with Radeon 4870 + Geforce GT 120, the app crashes without this!)
#define USE_GL_SCREENMASK_FOR_MAIN_DISPLAY 1


static void createSharedGLContext()
{
    BOOL lxContextWasSet = (LXPlatformSharedNativeGraphicsContext() != NULL);
    
    NSOpenGLContext *ctx = nil;
    LQUpdateMainDisplayGLMask();
    
    // this is the base shared context; any new contexts will need to match these attributes
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 32,
        NSOpenGLPFADepthSize, 16,
        
#if (USE_GL_SCREENMASK_FOR_MAIN_DISPLAY)
        NSOpenGLPFAScreenMask, LXPlatformMainDisplayIdentifier(),
#endif
        0
    };
    NSOpenGLPixelFormat *pf = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];

    ctx = [[NSOpenGLContext alloc]
                        initWithFormat:pf
                        shareContext:nil];
    if ( !ctx)
        NSLog(@"** Critical graphics state error: couldn't create shared GL context");
    else {
        g_NSCtx = ctx;
        g_ctx = [[LQGLContext alloc] initWithCGLContext:[ctx CGLContextObj] name:@"Lacqit::LQLacefxView::Main"];
        
        LXPlatformSetSharedLQGLContext(g_ctx);
        
        #if !defined(RELEASE)
        if (lxContextWasSet) {
            NSLog(@"LQOpenGLLacefxView shared init: did create CGL context (ctxobj %@, CGL ctx %p), but Lacefx platform was already set", ctx, [ctx CGLContextObj]);
        } else {
            NSLog(@"LQOpenGLLacefxView shared init: did set LX platform CGL context (ctxobj %@, CGL ctx %p)", ctx, [ctx CGLContextObj]);
        }
        #endif
    }
}

+ (NSOpenGLContext *)sharedNSOpenGLContext
{
    if ( !g_ctx)
        createSharedGLContext();
	return g_NSCtx;
}

+ (LQGLContext *)sharedLQGLContext
{
    if ( !g_ctx)
        createSharedGLContext();
    return g_ctx;
}


// a view that doesn't use the shared context doesn't need to acquire the shared lock

#define ENTERSHAREDGLLOCK(fname_)   (( !_usesSharedCtx) ? YES : ([[LQOpenGLLacefxView sharedLQGLContext] lockContextWithTimeout:0.5 caller:fname_ errorInfo:NULL] != -1))
#define EXITSHAREDGLLOCK            if (_usesSharedCtx) { [[LQOpenGLLacefxView sharedLQGLContext] unlockContext]; }

#define SHAREDCTX  [LQOpenGLLacefxView sharedLQGLContext]



#pragma mark --- init ---

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)fmt useSharedGLContext:(BOOL)useSharedGL
{
	self = [super initWithFrame:frame pixelFormat:fmt];

    _usesSharedCtx = useSharedGL;

    if (_usesSharedCtx) {
        NSOpenGLContext *newContext = [[NSOpenGLContext alloc]
										initWithFormat:fmt
										shareContext:[[self class] sharedNSOpenGLContext]
                                    ];
    
        [self setOpenGLContext:[newContext autorelease]];
    }
    
    ///_cells = [[NSMutableArray arrayWithCapacity:32] retain];
    _baseMixin = [[LQLacefxViewBaseMixin alloc] initWithView:self];
    
    _fitToViewMode = kLQFitMode_StretchToFill;
    
    _enableVSync = [[self class] enableVBLSyncByDefault];
    
    // view tracking (Leopard API)
    Class cls = NSClassFromString(@"NSTrackingArea");
    if (cls) {
        _trackingArea = [[cls alloc] initWithRect:NSMakeRect(0, 0, frame.size.width, frame.size.height)
                                        options:(NSTrackingCursorUpdate | NSTrackingActiveInActiveApp)
                                        owner:self
                                        userInfo:nil];
        [self addTrackingArea:_trackingArea];
    }
    
    //if ([self respondsToSelector:@selector(setWantsBestResolutionOpenGLSurface:)]) {
    //    [self setWantsBestResolutionOpenGLSurface:YES];
    //}
	
	return self;
}

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)fmt
{
    return [self initWithFrame:frame pixelFormat:fmt useSharedGLContext:YES];
}

- (id)initWithFrame:(NSRect)frame
{
    LQUpdateMainDisplayGLMask();
    const unsigned int glDispMask = LXPlatformMainDisplayIdentifier();
    
    ///NSLog(@"%s: frame %@; dispmask %u", __func__, NSStringFromRect(frame), glDispMask);

	 NSOpenGLPixelFormatAttribute attribs[] = 
	{
		NSOpenGLPFAWindow,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAColorSize, 32,
		NSOpenGLPFADepthSize, 0,
		//NSOpenGLPFAAlphaSize, 8,
		//NSOpenGLPFAStencilSize, 8,
		NSOpenGLPFAAccumSize, 0,

#if (USE_GL_SCREENMASK_FOR_MAIN_DISPLAY)
        NSOpenGLPFAScreenMask, glDispMask,
#endif
		0
	};

	NSOpenGLPixelFormat *fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs]; 

	if (!fmt) {
		NSLog(@"** No OpenGL pixel format created for glView");
		return nil;
	}

	return [self initWithFrame:frame pixelFormat:[fmt autorelease]];
}

- (void)dealloc
{
    [_baseMixin release];

    [self removeTrackingArea:_trackingArea];
    [_trackingArea release];
    
    ///[[self openGLContext] setView:nil];  // <- this causes an "invalid drawable" error in the log

    LXRefRelease(_lxSurface);
    _lxSurface = nil;

    [super dealloc];
}

- (void)setFrame:(NSRect)frame
{
    NSRect oldFrame = (_delegate) ? [self frame] : NSZeroRect;
    [super setFrame:frame];
    
    if ([_delegate respondsToSelector:@selector(viewFrameDidChange:)])
        [_delegate viewFrameDidChange:self];
        
    [self updateTrackingAreas];
}

#pragma mark --- tracking area (10.5) ---

- (void)updateTrackingAreas
{
    [self removeTrackingArea:_trackingArea];
    [_trackingArea release];
    _trackingArea = nil;
    
    Class cls = NSClassFromString(@"NSTrackingArea");
    if (cls) {
        _trackingArea = [[cls alloc] initWithRect:[self bounds]
                                        options:(NSTrackingCursorUpdate | NSTrackingActiveInKeyWindow)
                                        owner:self
                                        userInfo:nil];
        [self addTrackingArea:_trackingArea];
    }
    
    if ([_delegate respondsToSelector:@selector(updateTrackingAreasForView:)])
        [_delegate updateTrackingAreasForView:self];
}

- (void)cursorUpdate:(NSEvent *)event
{
    //NSLog(@"%s: %@; delegate %@", __func__, event, _delegate);
    if ([_delegate respondsToSelector:@selector(cursorUpdate:)])
        [_delegate cursorUpdate:event];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kLQLacefxViewCursorUpdateNotification
                                                object:self
                                                userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                event, @"event",
                                                                nil]
                                                ];
}


#pragma mark --- basic accessors ---

- (void)_reallySetNeedsDisplay:(BOOL)f {
    [super setNeedsDisplay:f];
}

- (void)setNeedsDisplay:(BOOL)f {
    if ( !_getsPeriodicRefresh)
        [super setNeedsDisplay:f];
}

- (void)setGetsPeriodicRefresh:(BOOL)f {
    _getsPeriodicRefresh = f; }
    
- (BOOL)getsPeriodicRefresh {
    return _getsPeriodicRefresh; }


- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }

- (void)setMouseEventDelegate:(id)del {
    _mouseEventDelegate = del; }

- (id)mouseEventDelegate {
    return _mouseEventDelegate; }

- (void)setCellDelegate:(id)del {
    [_baseMixin setCellDelegate:del]; }
    
- (id)cellDelegate {
    return [_baseMixin cellDelegate]; }

- (void)addCell:(LQXCell *)cell {
    [_baseMixin addCell:cell]; }

- (void)removeCell:(LQXCell *)cell {
    [_baseMixin removeCell:cell]; }

- (LQXCell *)cellNamed:(NSString *)name {
    return [_baseMixin cellNamed:name]; }

- (NSArray *)cells {
    return [_baseMixin cells]; }
    

- (LXUInteger)fitToViewMode {
    return _fitToViewMode; }
    
- (void)setFitToViewMode:(LXUInteger)mode {
    if (mode != _fitToViewMode) {
        _fitToViewMode = mode;
        [self setNeedsDisplay:YES];
    }
}

- (void)setValue:(id)value forUIContextAttribute:(NSString *)key {
    [_baseMixin setValue:value forUIContextAttribute:key]; }

- (id)valueForUIContextAttribute:(NSString *)key {
    return [_baseMixin valueForUIContextAttribute:key]; }



#pragma mark --- context setup ---

- (void)setHasWindowSystemDrawable:(BOOL)f
{
    _isOffscreen = !f;
}

- (void)setWindowSystemSurfaceIsOpaque:(BOOL)f
{
    _isOpaque = f;
    int opacity = (f) ? 1 : 0;
    [[self openGLContext] setValues:&opacity forParameter:NSOpenGLCPSurfaceOpacity];
}

// NSView override, necessary for proper compositing!
- (BOOL)isOpaque {
    return _isOpaque; }

// NSView override
- (BOOL)isFlipped {
    return YES; }


+ (BOOL)enableVBLSyncByDefault
{
    return YES;
}

- (void)setVBLSyncEnabled:(BOOL)f
{
    _enableVSync = f;

    GLint swapInt = (f) ? 1 : 0;  // 1 == enabled
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
}

- (void)prepareOpenGL
{
    static long s_n = 0;  // recursion prevention
    if (s_n > 0)
        return;
    
    s_n++;
    
    if ( !ENTERSHAREDGLLOCK(__nsfunc__)) {
        NSLog(@"*** %s: failed to lock LX drawing", __func__);
        // oh no, didn't get lock, call these anyway recklessly...
        [[self openGLContext] setView:self];
        [super prepareOpenGL];
    }
    else {
        [[self openGLContext] setView:self];
        [super prepareOpenGL];

        glClearColor(0.3, 0.3, 0.3, 1.0);
        glDisable(GL_DEPTH_TEST);
        glDisable(GL_BLEND);

        [self reshape];

        [self setVBLSyncEnabled:_enableVSync];
        
        _isFreshlyInited = YES;
        
        EXITSHAREDGLLOCK
    }
    s_n--;
}

- (void)_recreateLXSurfaceIfNecessary
{
    NSSize size = [self bounds].size;
    if ([self respondsToSelector:@selector(convertRectToBacking:)]) {
        size = [self convertRectToBacking:[self bounds]].size;
    }
    
    LXSize lxs = LXSurfaceGetSize(_lxSurface);
    
    //NSLog(@"%s: size %@, lxsize %@", __func__, NSStringFromSize(size), NSStringFromSize(NSSizeFromLXSize(lxs)));
    
    if ((int)lxs.w != (int)size.width || (int)lxs.h != (int)size.height) {
        LXRefRelease(_lxSurface);
        _lxSurface = LXSurfaceCreateFromNSView_(self);
    }
}

- (void)reshape
{
    if (_getsPeriodicRefresh && [self inLiveResize]) {
        double t0 = LQReferenceTimeGetCurrent();
        if ((t0 - _liveResizeLastRefreshT) < 16.0/1000.0) {
            return;  // --
        }
        //NSLog(@"-- %s: lx view w/ periodic refresh is in resize (%p)", __func__, self);
        
        _liveResizeLastRefreshT = t0;
    }
    if ( ![self window] || ![self superview]) {
        return;
    }


    if ( !ENTERSHAREDGLLOCK(@"lxViewReshape")) {
        NSLog(@"*** %s: failed to lock shared GL context", __func__);
        return;
    }

    
    NSOpenGLContext *prevCtx = [NSOpenGLContext currentContext];
    [[self openGLContext] makeCurrentContext];
    
	NSSize size = [self bounds].size;
    double backingScale = 1.0;
    if ([self respondsToSelector:@selector(convertRectToBacking:)]) {
        NSSize backingSize = [self convertRectToBacking:[self bounds]].size;
        backingScale = backingSize.width / size.width;
        size = backingSize;
        //NSLog(@"GL view reshaped: backing size is %@ -> scale factor is %.2f", NSStringFromSize(size), size.width / [self bounds].size.width);
    }

	[super reshape];
    
	glViewport(0, 0, size.width, size.height);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self _recreateLXSurfaceIfNecessary];
        
    (prevCtx) ? [prevCtx makeCurrentContext] : [NSOpenGLContext clearCurrentContext];
    
    EXITSHAREDGLLOCK
	return;
}

- (BOOL)isFullScreen
{
    return NO;  // fullscreen is implemented in LQFullScreenLacefxView subclass
}


#pragma mark --- events ---

- (void)mouseDown:(NSEvent *)event
{
    if (_mouseEventDelegate && [_mouseEventDelegate respondsToSelector:@selector(handleMouseDown:inLacefxView:)]) {
        if ([_mouseEventDelegate handleMouseDown:event inLacefxView:self])
            return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(handleMouseDown:inLacefxView:)]) {
        if ([_delegate handleMouseDown:event inLacefxView:self])
            return;
    }

    ///[self handleMouseDownInCells:event];
    [_baseMixin handleMouseDownInCells:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
    if (_mouseEventDelegate && [_mouseEventDelegate respondsToSelector:@selector(handleRightMouseDown:inLacefxView:)]) {
        if ([_mouseEventDelegate handleRightMouseDown:event inLacefxView:self])
            return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(handleRightMouseDown:inLacefxView:)]) {
        if ([_delegate handleRightMouseDown:event inLacefxView:self])
            return;
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    if (_mouseEventDelegate && [_mouseEventDelegate respondsToSelector:@selector(handleMouseDragged:inLacefxView:)]) {
        if ([_mouseEventDelegate handleMouseDragged:event inLacefxView:self])
            return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(handleMouseDragged:inLacefxView:)]) {
        if ([_delegate handleMouseDragged:event inLacefxView:self])
            return;
    }

    ///[self handleMouseDraggedInCells:event];
    [_baseMixin handleMouseDraggedInCells:event];
}

- (void)mouseUp:(NSEvent *)event
{
    if (_mouseEventDelegate && [_mouseEventDelegate respondsToSelector:@selector(handleMouseUp:inLacefxView:)]) {
        if ([_mouseEventDelegate handleMouseUp:event inLacefxView:self])
            return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(handleMouseUp:inLacefxView:)]) {
        if ([_delegate handleMouseUp:event inLacefxView:self])
            return;
    }

    ///[self handleMouseUpInCells:event];
    [_baseMixin handleMouseUpInCells:event];
}

- (void)flagsChanged:(NSEvent *)event
{
    if (_delegate && [_delegate respondsToSelector:@selector(cursorUpdate:)])
        [_delegate cursorUpdate:event];
    
    [super flagsChanged:event];
}

- (void)keyDown:(NSEvent *)event
{
    if (_delegate && [_delegate respondsToSelector:@selector(handleKeyDown:inLacefxView:)]) {
        if ([_delegate handleKeyDown:event inLacefxView:self])
            return;
    }
    [super keyDown:event];
}

- (void)keyUp:(NSEvent *)event
{
    if (_delegate && [_delegate respondsToSelector:@selector(handleKeyUp:inLacefxView:)]) {
        if ([_delegate handleKeyUp:event inLacefxView:self])
            return;
    }
    [super keyUp:event];
}

- (void)scrollWheel:(NSEvent *)event
{
    if (_delegate && [_delegate respondsToSelector:@selector(handleScrollWheel:inLacefxView:)]) {
        if ([_delegate handleScrollWheel:event inLacefxView:self])
            return;
    }
    [super scrollWheel:event];
}


- (BOOL)acceptsFirstResponder
{
    ///NSLog(@"%s: %i (super %i)", __func__, (_delegate && [_delegate respondsToSelector:@selector(handleKeyDown:inLacefxView:)]), [super acceptsFirstResponder]);
    return (_delegate && [_delegate respondsToSelector:@selector(handleKeyDown:inLacefxView:)]) ? YES : [super acceptsFirstResponder];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
    if (_mouseEventDelegate && [_mouseEventDelegate respondsToSelector:@selector(handleMouseDown:inLacefxView:)]) return YES;
    
    return (_delegate && [_delegate respondsToSelector:@selector(handleMouseDown:inLacefxView:)]) ? YES : [super acceptsFirstMouse:event];
}



// -- touch events on 10.6+

- (void)beginGestureWithEvent:(NSEvent *)event
{
    if ([_delegate respondsToSelector:@selector(handleBeginGesture:inLacefxView:)]) {
        [_delegate handleBeginGesture:event inLacefxView:self];
    }
    _inGesture = YES;
}

- (void)touchesMovedWithEvent:(NSEvent *)event
{
    if (_inGesture) {
        if ([_delegate respondsToSelector:@selector(handleTouchesMovedInGesture:inLacefxView:)]) {
            [_delegate handleTouchesMovedInGesture:event inLacefxView:self];
        }        
    }
}

- (void)endGestureWithEvent:(NSEvent *)event
{
    if ([_delegate respondsToSelector:@selector(handleEndGesture:inLacefxView:)]) {
        [_delegate handleEndGesture:event inLacefxView:self];
    }
    _inGesture = NO;
}

- (void)swipeWithEvent:(NSEvent *)event
{
    if ([_delegate respondsToSelector:@selector(handleSwipe:inLacefxView:)]) {
        [_delegate handleSwipe:event inLacefxView:self];
    }
}

-(void)magnifyWithEvent:(NSEvent *)event
{
    double mag = [event magnification];
    if (mag == 0.0)
        return;
    
    if ([_delegate respondsToSelector:@selector(handleMagnify:inLacefxView:)]) {
        [_delegate handleMagnify:event inLacefxView:self];
    }
}

- (void)smartMagnifyWithEvent:(NSEvent *)event
{
    if ([_delegate respondsToSelector:@selector(handleSmartMagnify:inLacefxView:)]) {
        [_delegate handleSmartMagnify:event inLacefxView:self];
    }    
}
    


#pragma mark --- NSDraggingDestination protocol ---

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return [_delegate dragOperationForDrag:sender inLacefxView:self didEnter:YES];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return [_delegate dragOperationForDrag:sender inLacefxView:self didEnter:NO];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    [_delegate dragOperationExited:sender inLacefxView:self];
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    return [_delegate performDragOperation:sender inLacefxView:self];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
}


#pragma mark --- drawing ---

- (void)startOrthoCoordinateMode
{
	NSSize size = [self bounds].size;
    double backingScale = 1.0;
    if ([self respondsToSelector:@selector(convertRectToBacking:)]) {
        NSSize backingSize = [self convertRectToBacking:[self bounds]].size;
        backingScale = backingSize.width / size.width;
        size = backingSize;
    }
    //NSLog(@"%s: backing scale %.3f", __func__, backingScale);
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
		glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
			glLoadIdentity();
			glScaled(2.0 / size.width, -2.0 / size.height, 1.0);
			glTranslated( -size.width / 2.0, -size.height / 2.0f, 0.0);
            //if (backingScale != 1.0) glScaled(backingScale, backingScale, 1.0);
}

- (void)endOrthoCoordinateMode
{
		glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
}

- (void)drawQuadWithTextureSize1:(NSSize)texSize1 size2:(NSSize)texSize2 outputRect:(NSRect)rect flip:(BOOL)flip
{
    float left, bottom, top, right;
    left = rect.origin.x;
    bottom = rect.origin.y;
    right = rect.origin.x + rect.size.width;
    top = rect.origin.y + rect.size.height;

    if (flip) {
        bottom = top; 
        top = rect.origin.y;
    }

		glBegin(GL_QUADS);
            glMultiTexCoord2f(GL_TEXTURE0,  0, 0);
            glMultiTexCoord2f(GL_TEXTURE1,  0, 0);
			glVertex2f(left, top);

			glMultiTexCoord2f(GL_TEXTURE0,  texSize1.width, 0);
            glMultiTexCoord2f(GL_TEXTURE1,  texSize2.width, 0);
			glVertex2f(right, top);
			
			glMultiTexCoord2f(GL_TEXTURE0,  texSize1.width, texSize1.height);
            glMultiTexCoord2f(GL_TEXTURE1,  texSize2.width, texSize2.height);
			glVertex2f(right, bottom);
			
			glMultiTexCoord2f(GL_TEXTURE0,  0, texSize1.height);
            glMultiTexCoord2f(GL_TEXTURE1,  0, texSize2.height);
			glVertex2f(left, bottom);
		glEnd();    
}


- (void)drawCellsInLXSurface:(LXSurfaceRef)lxSurface
{
    NSArray *cells = [_baseMixin cells];
    
    if ([cells count] < 1)
        return;
        
    NSEnumerator *cellEnum = [cells objectEnumerator];
    LQXCell *cell;
    while (cell = [cellEnum nextObject]) {
        ///NSLog(@"..drawing cell %@", cell);
        [cell drawInSurface:lxSurface];
    }
}


- (void)drawInLXSurface:(LXSurfaceRef)lxSurface
{
    ///if ([_delegate respondsToSelector:@selector(shouldBeginDrawForLacefxView:)])
    ///    [_delegate shouldBeginDrawForLacefxView:self];

    ///NSLog(@"%s: delegate %@", __func__, _delegate);

    LXTextureRef tex = NULL;
    if ([_delegate respondsToSelector:@selector(contentTextureForLacefxView:)] && 
        (tex = [_delegate contentTextureForLacefxView:self])) {

        LXSize s = LXTextureGetSize(tex);
        LXRect bounds = LXSurfaceGetBounds(lxSurface);
        
        LXRect outRect = LQFitRectToView(s, bounds, _fitToViewMode, 1.0);
        
        LXTextureOpenGL_EnableInTextureUnit(tex, 0, NULL);

        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);
        
        [self drawQuadWithTextureSize1:NSMakeSize(s.w, s.h)
                                 size2:NSZeroSize
                                 outputRect:NSRectFromLXRect(outRect)
                                 flip:YES];
                    
        LXTextureOpenGL_DisableInTextureUnit(tex, 0, NULL);
        
        //glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
        glDisable(GL_BLEND);
    }
    else if ([_delegate respondsToSelector:@selector(drawContentsForLacefxView:inSurface:)]) {
        [_delegate drawContentsForLacefxView:self inSurface:lxSurface];
    }
    else {
        glClearColor(0.18, 0.18, 0.18, 1);
        glClear(GL_COLOR_BUFFER_BIT);
    }
    
    [self drawCellsInLXSurface:lxSurface];
    
    ///if ([_delegate respondsToSelector:@selector(didEndDrawForLacefxView:)])
    ///    [_delegate didEndDrawForLacefxView:self];
}

- (void)_reallyDrawRect:(NSRect)rect flushGLBuffer:(BOOL)doFlush
{
    DTIME(t0)

    if ( !ENTERSHAREDGLLOCK(@"lxViewDrawRect")) {
        NSLog(@"*** %s: failed to lock shared GL context", __func__);
        return;
    }
        
    if (_isOffscreen) {
        ///NSLog(@"-- lx view is offscreen (%@)", self);
        EXITSHAREDGLLOCK
        return;
    }
    if ( !_lxSurface) {
        [self _recreateLXSurfaceIfNecessary];
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LXPoolRef lxPool = LXPoolCreateForThread();

    //NSRect outRect = [self bounds];

    glActiveTexture(GL_TEXTURE0);
    glDisable(GL_TEXTURE_2D);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    glColor4f(1, 1, 1, 1);

    DTIME(t1)
    
    //glClearColor(0.9, 0.3, 0.3, 1.0);
    //glClearColor(0, 0, 0, 0);
    //glClear(GL_COLOR_BUFFER_BIT);
    
    ///LXSurfaceClear(_lxSurface);

    ///LXPrintf("view %s - now drawing\n", [[self description] UTF8String]);
    
    [self startOrthoCoordinateMode];
    
    LXSurfaceStartNSViewDrawing_(_lxSurface);

    DTIME(t2)
    [self drawInLXSurface:_lxSurface];
    
    LXSurfaceEndNSViewDrawing_(_lxSurface);
    

    [self endOrthoCoordinateMode];

    DTIME(t3)

    if (doFlush) {
        if (_usesSharedCtx) [SHAREDCTX lockContextWithTimeout:1.0 caller:@"(view context flush)" errorInfo:NULL];  // inner locking is here for more precise debugging info
        [[self openGLContext] flushBuffer];
        if (_usesSharedCtx) [SHAREDCTX unlockContext];
    }

    LXPoolRelease(lxPool);
    [pool drain];

    EXITSHAREDGLLOCK

    ///DTIME(t4)
    ///LQPrintf("%s (%p): init took %.3f ms, draw took %.3f ms, flush took %.3f ms\n", __func__, self, 1000*(t2-t0),  1000*(t3-t2), 1000*(t4-t3));
}

// this is only called by NSView's internal update
- (void)drawRect:(NSRect)rect
{
    ///NSLog(@"%s: %i", __func__, [self needsDisplay]);
    if (_isFreshlyInited) {
        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);    
        _isFreshlyInited = NO;
    }

    if (_getsPeriodicRefresh && [self inLiveResize]) {
        ///NSLog(@"-- %s: lx view is in resize (%@)", __func__, self);
        return;
    }
    
    [self _reallyDrawRect:rect flushGLBuffer:YES];
}

- (void)_activateGLContextAndDrawWithGLBufferFlush:(BOOL)doFlush
{
    DTIME(t0)
    
    NSOpenGLContext *prevCtx = [NSOpenGLContext currentContext];
    NSOpenGLContext *myCtx = [self openGLContext];
    if (prevCtx != myCtx) {
        [myCtx makeCurrentContext];
    }
    DTIME(t1)
    
    [self _reallyDrawRect:NSZeroRect flushGLBuffer:doFlush];
    
    DTIME(t2)
    
    if (prevCtx != myCtx) {
        (prevCtx) ? [prevCtx makeCurrentContext] : [NSOpenGLContext clearCurrentContext];
    }
    
    ///LQPrintf("%s (%p): gl lock took %.3f ms; draw took %.3f ms\n", __func__, self, 1000*(t1-t0), 1000*(t2-t1));
	return;
}

- (void)getLXLockAndDrawNow
{
    if ( !ENTERSHAREDGLLOCK(__nsfunc__)) {
        NSLog(@"*** %s: failed to lock shared GL context", __func__);
        return;
    }
    
    [self _activateGLContextAndDrawWithGLBufferFlush:YES];
    
    ///[[self openGLContext] flushBuffer];

    EXITSHAREDGLLOCK
}

// the caller should be holding the lock on the GL context already
- (void)drawNow
{
    [self _activateGLContextAndDrawWithGLBufferFlush:YES];
}

- (void)captureInLXSurface:(LXSurfaceRef)lxSurface
{
    if ( !lxSurface) return;
    
    [self drawInLXSurface:lxSurface];
}


@end
