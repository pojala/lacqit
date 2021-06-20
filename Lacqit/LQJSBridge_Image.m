//
//  LQJSBridge_Image.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_Image.h"
#import "LQJSBridge_ByteBuffer.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQCairoBitmap.h"
#import "LQLXPixelBuffer.h"


static NSLock *g_cacheLock = nil;
static NSMutableArray *g_pixbufCache = nil;
static const LXInteger g_pixbufCacheMax = 12;


@implementation LQJSBridge_Image

+ (void)initialize
{
    if (self == [LQJSBridge_Image class]) {
        g_cacheLock = [[NSLock alloc] init];
        g_pixbufCache = [[NSMutableArray alloc] initWithCapacity:g_pixbufCacheMax+1];
    }
}

+ (LXPixelBufferRef)_createPixbufFromCacheForBitmap:(LQBitmap *)bitmap
{
    LXUInteger lxPF = LXPixelFormatFromQTPixelFormat([bitmap pixelFormat]);
    const LXInteger w = [bitmap size].width;
    const LXInteger h = [bitmap size].height;
    const LXSize lxSize = LXMakeSize(w, h);
    
    if (lxPF == 0 || w < 1 || h < 1) return NULL;
    
    [g_cacheLock lock];
    LXPixelBufferRef pixbuf = NULL;
    
    LXInteger n = [g_pixbufCache count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        LXPixelBufferRef cachedPixbuf = (LXPixelBufferRef)[[g_pixbufCache objectAtIndex:i] pointerValue];
        
        if (LXPixelBufferMatchesSize(cachedPixbuf, lxSize)
                    && (lxPF == kLX_RGBA_INT8 || lxPF == kLX_BGRA_INT8 || lxPF == kLX_ARGB_INT8)) {
            pixbuf = cachedPixbuf;
            break;
        }
    }
    if (pixbuf)  [g_pixbufCache removeObjectAtIndex:i];

    [g_cacheLock unlock];
    
    if (pixbuf) {  // copy data into pixbuf we got from cache
        size_t srcRowBytes = [bitmap bufferRowBytes];
        uint8_t *srcBuf = [bitmap buffer];
        LXDECLERROR(err)
        
        if ( !LXPixelBufferWriteDataWithPixelFormatConversion(pixbuf,
                                                        srcBuf, w, h, srcRowBytes,
                                                        lxPF, NULL, &err)) {
            NSLog(@"** %s: pixel copy failed with error %i / %s", __func__, err.errorID, err.description);
            LXErrorDestroyOnStack(err);
        }
    } else {
        pixbuf = LXPixelBufferCreateFromLQBitmap(bitmap);
    }
    
    return pixbuf;
}

+ (void)_cachePixbuf:(LXPixelBufferRef)pixbuf
{
    [g_cacheLock lock];
    
    [g_pixbufCache addObject:[NSValue valueWithPointer:pixbuf]];
    
    if ([g_pixbufCache count] > g_pixbufCacheMax) {
        LXPixelBufferRelease((LXPixelBufferRef)[[g_pixbufCache objectAtIndex:0] pointerValue]);
        [g_pixbufCache removeObjectAtIndex:0];
    }
    
    [g_cacheLock unlock];
}



- (id)initWithLXPixelBuffer:(LXPixelBufferRef)pixbuf
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _pixbuf = LXPixelBufferRetain(pixbuf);
    }
    return self;
}

- (void)dealloc
{
    [_cairoBitmap release];
    _cairoBitmap = nil;

    if (YES) {
        [[self class] _cachePixbuf:_pixbuf];
    } else {
        LXPixelBufferRelease(_pixbuf);
    }
    _pixbuf = NULL;
    
    [super dealloc];
}

- (LXPixelBufferRef)lxPixelBuffer {
    return _pixbuf; }


- (LQCairoBitmap *)cairoBitmap
{
    if ( !_cairoBitmap) {
        _cairoBitmap = [[LQCairoBitmap alloc] initWithLXPixelBuffer:_pixbuf];
    }
    return _cairoBitmap;
}

- (id)copyAsPatchObject
{
    return [[LQLXPixelBuffer alloc] initWithLXPixelBuffer:_pixbuf retain:YES];
}

+ (NSString *)constructorName
{
    return @"Image";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    LXDECLERROR(lxErr)
    
    if ([arguments count] >= 1) {
        id arg = [arguments objectAtIndex:0];
        
        if ([arg isKindOfClass:[LQJSBridge_2DCanvas class]]) {
            [arg finishContext];
            
            LQCairoBitmap *bitmap = [arg cairoBitmap];
            if ( !bitmap) return;
            
            // the canvas may be garbage-collected at any time, so copy its image data into a new buffer
            LXPixelBufferRef pixbuf = [[self class] _createPixbufFromCacheForBitmap:bitmap];  ///LXPixelBufferCreateFromLQBitmap(bitmap);
            if ( !pixbuf) {
                NSLog(@"** JS Image constructor: unable to convert canvas bitmap to pixel buffer");
            } else {
                _pixbuf = pixbuf;
            }
        }
        
        else if ([arg respondsToSelector:@selector(data)]) {
            NSData *data = [arg data];
            if ([data length] > 0) {
                id fileFormatUTI = ([arguments count] >= 2) ? [[arguments objectAtIndex:1] description] : nil;
                
                ///NSLog(@"... constructing image object: data size %i, type: %@", [data length], type);
            
                LXPixelBufferRef pixbuf = LXPixelBufferCreateFromFileInMemory([data bytes], [data length], [fileFormatUTI UTF8String], NULL, &lxErr);
                if ( !pixbuf) {
                    NSLog(@"** JS Image constructor: unable to load pixbuf data: %i / %s", lxErr.errorID, lxErr.description);
                    LXErrorDestroyOnStack(lxErr);
                } else {
                    _pixbuf = pixbuf;
                }
            }
        }
    }
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"width", @"height", @"src", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return [propertyName isEqualToString:@"src"] ? YES : NO;
}

- (int)width {
    return LXPixelBufferGetWidth(_pixbuf);
}

- (int)height {
    return LXPixelBufferGetHeight(_pixbuf);
}

- (NSString *)src {
    return @"";
}

- (void)setSrc:(NSString *)src {
    // src property isn't implemented;
    // this is just a stub to prevent JS interpreter error
    // if executing some web-originated JavaScript code that expects to write this property
    NSLog(@"Image.src property setter is not implemented in Conduit");
}

+ (NSArray *)objectFunctionNames
{
    return [NSArray array]; 
}


@end

