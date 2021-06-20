/*
 *  lqtestWin32Main.m
 *  Lacqit
 *
 *  Created by Pauli Ojala on 21.8.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#import <windows.h>
#import <cairo/cairo.h>
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXPlatform.h>
#import <Lacefx/LXPatternGen.h>
#import <Lacefx/LXShaderUtils.h>
#import <Lacefx/LXHalfFloat.h>
#import <LacqJS/LacqJS.h>
#import <Lacqit/LacqitInit.h>
#import <Lacqit/LQTimeSpan.h>
#import <Lacqit/LQModelConstants.h>
#import <Lacqit/LQLXBasicFunctions.h>
#import <Lacqit/LQJSBridge_Color.h>
#import <Lacqit/LQJSCanvasRenderer.h>
#import <Lacqit/LQTimeFunctions.h>
/*
#import <Lagoon/LagoonInit.h>
#import <Lagoon/LGConstants.h>
#import <Lagoon/LGAlert.h>
#import <Lagoon/LGNativeWMWindow.h>
#import <Lagoon/LGNativeDirect3DWidget.h>
*/

#define DTIME(t_)  double t_ = LQReferenceTimeGetCurrent();


#define TEST_CONDUIT_API  0


#if (TEST_CONDUIT_API)
#import <Conduit/ConduitC.h>
#endif



@interface lqTestApp : NSObject {
    LXPixelBufferRef _patternPixbuf;
    LXPixelBufferRef _gridPixbuf;
    LXShaderRef _shader;
}
@end


@implementation lqTestApp

- (void)runJSTest
{
    NSError *error = nil;
    LQJSKitInterpreter *js = [[LQJSKitInterpreter alloc] init];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *testName, *prog, *expected;
    
    testName = @"simple math";
    prog = @"var j = 4;   j += (3 * 3);";
    expected = @"13";
    
    id result = [js evaluateScript:prog error:&error];
    if (error) {
        NSLog(@"** %s, '%@' failed: %@", __func__, testName, error);
    } else {
        NSLog(@"%s: '%@' success, result is %@ (expected %@)", __func__, testName, result, expected);
    }

#if 0
    [js loadBridgeClass:[LQJSBridge_Color class]];
    
    testName = @"colorBridge";
    prog = @"aColor = new Color(0.9, 0.5, 0.2, 1.0);  aString = 'a string from JavaScript: bridge object toString: '+aColor+', its type: '+typeof(aColor); ";

    [js evaluateScript:prog error:&error];
    if (error) {
        NSLog(@"** %s, '%@' failed: %@", __func__, testName, error);
    } else {
        NSLog(@"%s: '%@' success", __func__, testName);
    }
    
    id bridged = [js globalVariableForKey:@"aColor"];
    id evaledString = [js globalVariableForKey:@"aString"];
    NSLog(@"test %@: bridge object is %@; rgba is: %@ (expected 0.9, 0.5, 0.2, 1.0)", testName, bridged, NSStringFromLXRGBA([bridged rgba]));
    NSLog(@".... evaled string is: '%@'", evaledString);
#endif

    [pool drain];
    [js release];
}


- (void)runJSCanvasTest
{
    LQJSCanvasRenderer *rend = [[LQJSCanvasRenderer alloc] init];
    NSString *script = @""
"var ctx = canvas.getContext('2d'); "
"var w = canvas.width;"
"var h = canvas.height;"
"ctx.fillStyle = 'rgba(255, 200, 120, 0.1)';"
"ctx.fillRect(0, 0, w, h);";
    
    if ( ![rend compileScript:script]) {
        NSLog(@"*** %s: compile failed (error %@)", __func__, [rend lastError]);
    }
    else {
        LQBitmap *bmp = [rend renderBitmapWithSize:NSMakeSize(200, 200)];
        NSLog(@"%s: rendered bitmap: %@", __func__, bmp);
        
        uint8_t *buf = [bmp buffer];
        NSLog(@".... JS canvas pixel values are: %i, %i, %i, %i -- expected 12, 20, 25, 25 for BGRA data", buf[0], buf[1], buf[2], buf[3]);
    }
    [rend release];
}

/*
- (void)runLagoonTest
{
    id lgWindow = [[LGNativeWMWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
                                        styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask)];
    [lgWindow setDelegate:self];
                                        
    id lgD3DWidget = [[LGNativeDirect3DWidget alloc] initWithSizeRequest:NSMakeSize(640, 480)];
    [lgD3DWidget setDelegate:self];
    
    [lgWindow setContentWidget:lgD3DWidget];
                                            
    [lgWindow makeKeyAndOrderFront:nil];
    
    _patternPixbuf = LXPatternCreateGradientColorBars(LXMakeSize(640, 480));
    _gridPixbuf = LXPatternCreateGrid(LXMakeSize(400, 300));
    
    _shader = LXCreateCompositeShader_OverOp_Premult_Param();
    
    LagoonApplicationMain();
}
 */

#if (TEST_CONDUIT_API)
- (void)renderConduitTestInSurface:(LXSurfaceRef)surf inRect:(LXRect)rect
{
    DTIME(t0)

    static const char *jsonStr = 
"{ \"rootNode\": {"
"	\"nodeClass\": \"RGB to YUV\" "
"  }"
"}";

    LXMapPtr props = LXMapCreateFromJSON(jsonStr, strlen(jsonStr));
    ConduitEffectRef effect = ConduitEffectCreateFromProperties(props, NULL);
    LXMapDestroy(props);

    LXShaderRef shader = ConduitEffectCreateShader(effect, NULL);
    
    // timing info: after first run, the above operations took 0.5 - 0.7 ms on a MacBook Pro 15" (2009.06.24)
    //DTIME(t1)
    //NSLog(@"%s: created shader %p -- creation took %.3f ms", __func__, shader, 1000*(t1-t0));

    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, rect, LXUnitRect);
    
    LXSurfaceDrawTexturedQuadWithShaderAndTransform(surf, vertices, kLXVertex_XYUV, LXPixelBufferGetTexture(_patternPixbuf, NULL), shader, NULL);
    
    LXShaderRelease(shader);
    ConduitEffectRelease(effect);
}

- (void)renderMultipassConduitTestInSurface:(LXSurfaceRef)surf
{
    DTIME(t0)
    LXDECLERROR(err);

    static const char *jsonStr = 
"{ \"rootNode\": {"
"   \"nodeClass\": \"YUV to RGB\", "
"   \"upstreamNode\": {"
"       \"nodeClass\": \"2D Transform\", "
"       \"paramValues\": [ { \"name\": \"X translation\", \"floatValue\": 0.3 },  "
"                          { \"name\": \"Y translation\", \"floatValue\": 0.1 }  ]"
"   }"
"  }"
"}";

    LXMapPtr props = LXMapCreateFromJSON(jsonStr, strlen(jsonStr));
    ConduitEffectRef effect = ConduitEffectCreateFromProperties(props, &err);
    LXMapDestroy(props);

    if ( !effect) {
        NSLog(@"*** %s: error %i / %s", __func__, err.errorID, err.description);
        return;
    }

    LXTextureRef tex = LXPixelBufferGetTexture(_patternPixbuf, NULL);

    ConduitRendererRef rend = ConduitRendererCreate(0, NULL);
    
    DTIME(t1)
    
    LXSuccess ok = ConduitRendererRenderEffectWithInputArrays(rend, effect, surf,
                                                              &tex, 1,
                                                              NULL, 0,
                                                              NULL, 0,
                                                              &err);
    if ( !ok) {
        NSLog(@"*** %s: render error %i / %s", __func__, err.errorID, err.description);
    } else {
        DTIME(t2);
        NSLog(@"conduit mp effect rendered in %.3f ms", 1000*(t2-t1));
    }
    
    ConduitRendererRelease(rend);
    ConduitEffectRelease(effect);
}

#endif

- (void)runSurfaceReadbackTest
{
    LXDECLERROR(err);
    LXSurfaceRef surf = LXSurfaceCreate(NULL, 640, 400, kLX_RGBA_FLOAT16, 0, NULL);
    LXPixelBufferRef pixbuf = LXPixelBufferCreate(NULL, 640, 400, kLX_RGBA_FLOAT16, NULL);
    
    LXSurfaceClearRegionWithRGBA(surf, LXSurfaceGetBounds(surf), LXMakeRGBA(0.5, 0.5, 0.5, 0.5));
    
    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, LXSurfaceGetBounds(surf), LXUnitRect);
    
    LXShaderRef shader = LXCreateShader_SolidColor();
    LXShaderSetParameter(shader, 0, LXMakeRGBA(3.5, 1.2, 0.2, 1.0));
    
    LXSurfaceDrawTexturedQuadWithShaderAndTransform(surf, vertices, kLXVertex_XYUV, NULL, shader, NULL);
    
    if ( !LXSurfaceCopyContentsIntoPixelBuffer(surf, pixbuf, &err)) {
        NSLog(@"*** %s: readback failed: %i / %s", __func__, err.errorID, err.description);
    } else {
        size_t rowBytes = 0;
        LXHalf *data = (LXHalf *)LXPixelBufferLockPixels(pixbuf, &rowBytes, 0, NULL);
        
        NSLog(@"%s: readback data is %f (exp. ~3.5) / %.4f / %.4f / %.4f", __func__,
                    LXFloatFromHalf(data[0]), LXFloatFromHalf(data[1]), LXFloatFromHalf(data[2]), LXFloatFromHalf(data[3]));
        
        LXPixelBufferUnlockPixels(pixbuf);
    }
    
    LXShaderRelease(shader);
}

/*
- (void)windowDidRealize:(NSNotification *)notif
{
    NSLog(@"%s", __func__);
    
    [self runSurfaceReadbackTest];
}

- (void)windowWillClose:(NSNotification *)notif
{
    LagoonApplicationTerminate();
}


#pragma mark --- rendering ---

- (void)_lxRenderViewForD3DWidget:(LGNativeDirect3DWidget *)d3dWidget
{
    LXSurfaceRef lxSurface = [d3dWidget lxSurface];
    LXRect rect = [d3dWidget viewportLXRect];

    NSAssert(d3dWidget, @"no D3D widget");
    NSAssert(lxSurface, @"no LX surface");
    
    LXSurfaceClearRegionWithRGBA(lxSurface, rect, LXMakeRGBA(0.5, 0.2, 0, 1));
        
    LXVertexXYUV vertices[4];
    LXSetQuadVerticesXYUV(vertices, LXMakeRect(0, 0, 320, 240), LXUnitRect);
    
    LXTextureRef tex1 = LXPixelBufferGetTexture(_patternPixbuf, NULL);
    LXTextureRef tex2 = LXPixelBufferGetTexture(_gridPixbuf, NULL);
    LXTextureArrayRef texArray = LXTextureArrayCreateWithTextures(2, tex1, tex2);
    LXDrawContextRef drawCtx = LXDrawContextCreate();

    LXTextureArraySetSamplingAt(texArray, 0, kLXLinearSampling);
    LXTextureArraySetSamplingAt(texArray, 1, kLXLinearSampling);
    
    LXTransform3DRef trs = LXTransform3DCreateIdentity();
    LXTransform3DRotate(trs, 0.1, 0, 0, 1);
    LXTransform3DScale(trs, 2.2, 1.6, 1);
    LXTransform3DTranslate(trs, 20, 30, 0);
    
    LXDrawContextSetTextureArray(drawCtx, texArray);
    LXDrawContextSetModelViewTransform(drawCtx, trs);
    LXDrawContextSetShader(drawCtx, _shader);
    LXDrawContextSetShaderParameter(drawCtx, 0, LXMakeRGBA(0.3, 0.3, 0.3, 0.3));
    
    LXSurfaceDrawPrimitive(lxSurface, kLXQuads, vertices, 4, kLXVertex_XYUV, drawCtx);

    #if (TEST_CONDUIT_API)
    //[self renderConduitTestInSurface:lxSurface inRect:LXMakeRect(0, 0, 300, 200)];
    [self renderMultipassConduitTestInSurface:lxSurface];
    #endif
    
    [d3dWidget present];
    
    LXDrawContextRelease(drawCtx);
    LXTextureArrayRelease(texArray);
}

- (void)win32WidgetNeedsRedraw:(LGNativeWin32Widget *)widget
{
    [self _lxRenderViewForD3DWidget:(LGNativeDirect3DWidget *)widget];
}
*/
@end



#pragma mark --- Win32 main entry ---

int WINAPI WinMain(HINSTANCE inst, HINSTANCE prev, LPSTR cmd, int show)
{
    int retVal = 0;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];    

    ///LXPlatformInitializeWithHWND(GetDesktopWindow());

    id v = [NSNumber numberWithInt:123];
    NSLog(@".... test nslog -- %@", v);

    LXVersion lxVer = LXLibraryVersion();
    NSLog(@"Cairo version is %s, Lacefx version is %i.%i.%i", cairo_version_string(),
                                    lxVer.majorVersion, lxVer.minorVersion, lxVer.milliVersion);

    void *lxMallocedBuf = _lx_malloc(128);
    NSLog(@"... lx malloced buf is: 0x%p (should be 16-byte aligned: %s)", lxMallocedBuf, (((LXUInteger)lxMallocedBuf & 15) == 0) ? "yes" : "FAIL");

    NSLog(@"a constant string from Lacefx DLL: %s", kLXPixelBufferAttachmentKey_ColorSpaceEncoding);
    NSLog(@"a constant string from Lacqit DLL: %s", kLacqitVersionString);

/*
    NSLog(@"constant string from Lagoon: %s", kLagoonVersionString);
    NSLog(@" .... constant NSString from Lagoon: %@", kLagoonVersionLongIdentifier);
    
    HMODULE hmod1 = LoadLibraryA("Lacefx.1.0.dll");
    DWORD winErr = ( !hmod1) ? GetLastError() : 0;
    NSLog(@"... lacefx module is: %p (err %u)", hmod1, winErr);
    
    HMODULE hmod2 = LoadLibraryA("Lagoon.1.0.dll");
    winErr = ( !hmod2) ? GetLastError() : 0;
    NSLog(@"... lagoon module is: %p (err %u)", hmod2, winErr);
    
    HMODULE hmodJSC = LoadLibraryA("LQJavaScriptCore.1.0.dll");
    winErr = ( !hmodJSC) ? GetLastError() : 0;
    NSLog(@"... JavaScriptCore module is: %p (err %u)", hmodJSC, winErr);
    
    HMODULE hmod3 = LoadLibraryA("LacqJS.1.0.dll");
    winErr = ( !hmod3) ? GetLastError() : 0;
    NSLog(@"... lacqjs module is: %p (err %u)", hmod3, winErr);
    
    HMODULE hmod4 = LoadLibraryA("Lacqit.1.0.dll");
    winErr = ( !hmod4) ? GetLastError() : 0;
    NSLog(@"... lacqit module is: %p (err %u)", hmod4, winErr);    
*/
    Class cls;
    //Class cls = [LGAlert class];
    //NSLog(@" ..... a class object from Lagoon: 0x%p", cls);

    cls = [LQTimeSpan class];
    NSLog(@" ..... a class object from Lacqit: 0x%p", cls);

    LQTimeSpan *span = [[LQTimeSpan alloc] init];
    [span setInTime:1.0];
    [span setOutTime:3.55];
    NSLog(@"... test span: %@", span);


    int initResult = 0;
    /*if (0 != (initResult = LagoonInitialize(0, NULL))) {
        NSLog(@"*** Lagoon init failed: %i", initResult);
        exit(1);
    }*/
    if (0 != (initResult = LacqitInitialize(0, NULL))) {
        NSLog(@"*** Lacqit init failed: %i", initResult);
        exit(1);
    }
    
    ///LQWin32ReferenceTime_StartThread();  // enables high-performance timer, but burns CPU time. Lacqit must be initialized before calling this.
        
        
    id testAppObj = [[lqTestApp alloc] init];
    
    [testAppObj runJSTest];
    
    [testAppObj runJSCanvasTest];
    
    //[testAppObj runLagoonTest];

done:
    LacqitDeinitialize();

    [pool drain];
    LXPoolRelease(LXPoolCurrentForThread());
    
    return retVal;
}