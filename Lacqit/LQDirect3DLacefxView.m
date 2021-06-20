//
//  LQDirect3DView.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQDirect3DLacefxView.h"
#import "LQLacefxView.h"
#import <Lacefx/LXPlatform_d3d.h>
#import "LQXCell.h"
#import "LQUIConstants.h"


//#define DEBUGLOG(format, args...)
#define DEBUGLOG(format, args...)          NSLog(format , ## args);


static BOOL g_didInitLacefxD3D = NO;


// override the base class alloc method to return the platform-specific implementation
@implementation LQLacefxView (WindowsImplementation)

+ (id)allocWithZone:(NSZone *)zone {
    NSLog(@"%s -- self %@", __func__, self);
   return NSAllocateObject([LQDirect3DLacefxView class], 0, NULL);
}

@end



@implementation LQDirect3DLacefxView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _baseMixin = [[LQLacefxViewBaseMixin alloc] initWithView:self];
    
        _fitToViewMode = kLQFitMode_StretchToFill;
    }
    return self;
}

- (void)dealloc
{
    [_baseMixin release];
    
    LXSurfaceRelease(_lxSurface);
    
    if (_swapChain) {
        IDirect3DSwapChain9_Release(_swapChain);
        _swapChain = NULL;
    }
    
    [super dealloc];
}


#pragma mark --- accessors ---

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }

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



#pragma mark --- Direct3D rendering ---

- (void)_recreateSwapChainIfNeeded
{
    int curBufW = 0, curBufH = 0;
    
    if (_swapChain) {
        D3DPRESENT_PARAMETERS pp;
        memset(&pp, 0, sizeof(pp));
        
        IDirect3DSwapChain9_GetPresentParameters(_swapChain, &pp);
        
        curBufW = pp.BackBufferWidth;
        curBufH = pp.BackBufferHeight;
        
        //DEBUGLOG(@"d3dview -- swapchain exists: size is %i * %i; format is %i; bufferCount %i", curBufW, curBufH, (int)pp.BackBufferFormat, pp.BackBufferCount);
    }
    
    int curWinW = 0, curWinH = 0;
    [self getChildWindowWidth:&curWinW height:&curWinH];
    
    if (curBufW != curWinW || curBufH != curWinH) {
        // the win32 window size has changed, so the d3d swap chain must be recreated
        if (_lxSurface) {
            LXSurfaceRelease(_lxSurface);
            _lxSurface = NULL;
        }
        if (_swapChain)
            IDirect3DSwapChain9_Release(_swapChain);
        
        _swapChain = _LXPlatformCreateD3DSwapChainForView(self, curWinW, curWinH);
        
        if ( !_swapChain) {
            NSLog(@"** Unable to create D3D swap chain for view (window client rect is %i * %i)", curWinW, curWinH);
        }
        else {
            NSLog(@"d3dview -- created new swapchain, win size is %i * %i (was %i * %i)", curWinW, curWinH, curBufW, curBufH);
        
            _lxSurface = LXSurfaceCreateWithD3DSwapChain_(_swapChain, curWinW, curWinH);
        }
    }
}

- (void)update
{
    [super update];
    
    if ( !g_didInitLacefxD3D) {
        LXPlatformInitializeWithHWND((HWND)_childWindow);
        
        if (LXPlatformGetSharedD3D9Device()) {
            g_didInitLacefxD3D = YES;
        }
    }
    
    [self _recreateSwapChainIfNeeded];
}


- (void)present
{
    if ( !_swapChain) {
        NSLog(@"** %@: can't present, no swap chain", self);
        return;
    }
    IDirect3DSwapChain9_Present(_swapChain, NULL, NULL, (HWND)[self nativeChildWindow], NULL, 0);
}

- (void)drawNow
{
    [self present];
}


- (LXRect)viewportLXRect
{
    int curWinW = 0, curWinH = 0;
    [self getChildWindowWidth:&curWinW height:&curWinH];

    return LXMakeRect(0, 0, curWinW, curWinH);
}

- (LXSurfaceRef)lxSurface {
    return _lxSurface; 
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
    LXTextureRef tex = NULL;
    if ([_delegate respondsToSelector:@selector(contentTextureForLacefxView:)] && 
        (tex = [_delegate contentTextureForLacefxView:self])) {

        LXSize s = LXTextureGetSize(tex);
        LXRect bounds = LXRectFromNSRect([self bounds]);
        
        LXRect outRect = LXMakeRect(0, 0, s.w, s.h);
        LXDrawContextRef drawCtx = LXDrawContextWithTexture(NULL, tex);
        ///LXDrawContextSetFlags(drawCtx, kLXDrawFlag_UseFixedFunctionBlending_SourceIsPremult);

        LXTransform3DRef trs = LXAutorelease(LQFitRectToView_CreateTransform(s, bounds, _fitToViewMode, 1.0));
        LXDrawContextSetModelViewTransform(drawCtx, trs);
        
        ///LXSurfaceCopyTexture(lxSurface, tex, drawCtx);
        
        LXVertexXYUV vertices[4];
        LXSetQuadVerticesXYUV(vertices, outRect, LXUnitRect);
        
        LXSurfaceClearRegionWithRGBA(lxSurface, LXSurfaceGetBounds(lxSurface), LXMakeRGBA(0.5, 0.5, 0.5, 1));
        
        LXSurfaceDrawPrimitive(lxSurface, kLXQuads, vertices, 4, kLXVertex_XYUV, drawCtx);
        
        NSLog(@"... d3d lx view: did draw texture %p / 44: size %@, bounds %@, fitmode %i", tex, NSStringFromLXSize(s), NSStringFromLXRect(bounds), _fitToViewMode);
    }
    else if ([_delegate respondsToSelector:@selector(drawContentsForLacefxView:inSurface:)]) {
        [_delegate drawContentsForLacefxView:self inSurface:lxSurface];
    }
    else {
        LXSurfaceClearRegionWithRGBA(lxSurface, LXSurfaceGetBounds(lxSurface), LXMakeRGBA(0.18, 0.18, 0.18, 1));
    }
    
    [self drawCellsInLXSurface:lxSurface];
}


- (void)_reallyDrawRect:(NSRect)rect
{
    ///DTIME(t0)

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LXPoolRef lxPool = LXPoolCreateForThread();

    ///NSRect outRect = [self bounds];

    [self drawInLXSurface:_lxSurface];

    ///DTIME(t3)

    [self present];

    LXPoolRelease(lxPool);
    [pool drain];
}

- (void)_renderD3DTest
{
    if ( !_lxSurface) {
        NSLog(@"** %s: can't render, no surface", __func__);
        return;
    }
    
    // verify that the Win32 window's size matches our surface
    int curWinW = 0, curWinH = 0;
    [self getChildWindowWidth:&curWinW height:&curWinH];
    
    LXRect surfBounds = LXSurfaceGetBounds(_lxSurface);

    if (curWinW != surfBounds.w || curWinH != surfBounds.h) {
        NSLog(@"** %s: warning -- surface size differs from viewport (%.0f * %.0f vs. %i * %i)", __func__, surfBounds.w, surfBounds.h, curWinW, curWinH);
    }
    
    // draw a red box on a yellow background
    LXSurfaceClearRegionWithRGBA(_lxSurface, surfBounds, LXMakeRGBA(1, 0.9, 0, 1));
    LXSurfaceClearRegionWithRGBA(_lxSurface, LXMakeRect(100, 100, 100, 100), LXMakeRGBA(1, 0, 0.1, 1));    
    
    [self present];
}

- (void)drawRect:(NSRect)rect
{
    [self _recreateSwapChainIfNeeded];
    
    if (_swapChain) {
        //[self _renderD3DTest];
        [self _reallyDrawRect:rect];
    }
}

@end
