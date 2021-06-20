//
//  LQJSCanvasRenderer.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSCanvasRenderer.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQModelConstants.h"
#import "LQTimeFunctions.h"
#import "LQLXImageAppKitUtils.h"


@interface NSBitmapImageRep (SnowLeopardAdditions)
- (NSBitmapImageRep *)bitmapImageRepByRetaggingWithColorSpace:(NSColorSpace *)newSpace;
@end


@implementation LQJSCanvasRenderer

- (id)init
{
    self = [super init];
    ///NSLog(@"====== %s ======", __func__);
    _js = [[LQJSContainer alloc] initWithName:@"canvasRenderingJSContext"];
    return self;
}

- (void)dealloc
{
    ///NSLog(@"====== %s ======", __func__);
    [_lastError release];
    [_js release];
    ///NSLog(@"====== %s - done ======", __func__);
    [super dealloc];
}


- (NSString *)script {
    return [_js scriptForKey:@"renderInCanvas"];
}

- (NSError *)lastError {
    return _lastError; }


- (BOOL)compileScript:(NSString *)script
{
    if ( ![_js setScript:script forKey:@"renderInCanvas" parameterNames:[NSArray arrayWithObjects:@"canvas", nil]]) {
        [_lastError autorelease];
        _lastError = [[_js popLastError] retain];
        return NO;
    }
    return YES;
}

- (LQBitmap *)renderBitmapWithSize:(NSSize)iconSize
{
    if (iconSize.width < 1 || iconSize.height < 1) return nil;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    LQCairoBitmap *bmp = [[LQCairoBitmap alloc] initWithSize:iconSize];
    [bmp clear];
    
    id canvas = [[LQJSBridge_2DCanvas alloc] initWithCairoBitmap:bmp name:@"iconCanvas" inJSContext:[_js jsContextRef] withOwner:self];
    
    double t1 = LQReferenceTimeGetCurrent();
    //id jsResult = nil;
    BOOL ok = [_js executeScriptForKey:@"renderInCanvas"
                          withParameters:[NSArray arrayWithObjects:canvas, nil]
                          resultPtr:NULL];  //&jsResult];
                          
    [canvas finishContext];
    [canvas release];

    [pool drain];
    [bmp autorelease];

    double t2 = LQReferenceTimeGetCurrent();    
    
    if ( !ok) {
        [_lastError autorelease];
        _lastError = [[_js popLastError] retain];
        return nil;
    } else {
        ///NSLog(@"%s: render time was %.3f ms", __func__, 1000*(t2-t1));
        return bmp;
    }
}


#if !defined(__LAGOON__)

- (NSImage *)renderNSImageWithSize:(NSSize)size
{
    LQBitmap *bmp = [self renderBitmapWithSize:size];
    
    if ( !bmp) return nil;
    
    LXDECLERROR(lxErr);
    
    NSBitmapImageRep *rep = LXPixelBufferCopyAsNSBitmapImageRep([bmp lxPixelBuffer], &lxErr);
    NSImage *image = nil;
    
    if ( !rep) {
        NSLog(@"** %s: failed to convert to nsimagerep: %i / %s", __func__, lxErr.errorID, lxErr.description);        

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Failed to convert pixel buffer to NSImageRep (error %i)", lxErr.errorID]
                                                             forKey:NSLocalizedDescriptionKey];
        [_lastError autorelease];
        _lastError = [[NSError errorWithDomain:kLQErrorDomain code:394000 userInfo:userInfo] retain];
    }
    else {
        [rep autorelease];

#ifdef __APPLE__
        // 2011.12.07 -- switched to using sRGB-specified rendering in Lacqit's Canvas JS API implementation.
        // ensure that our output image is properly tagged, if possible.
        if ([rep respondsToSelector:@selector(bitmapImageRepByRetaggingWithColorSpace:)]) {
            NSColorSpace *cspace = [NSColorSpace sRGBColorSpace];
            rep = [rep bitmapImageRepByRetaggingWithColorSpace:cspace];
        }
#endif
    
        image = [[NSImage alloc] initWithSize:size];
        [image addRepresentation:rep];
    }
    return [image autorelease];
}

#endif



@end
