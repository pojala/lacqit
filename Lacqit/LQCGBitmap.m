//
//  LQCGBitmap.m
//  PixelMath
//
//  Created by Pauli Ojala on 27.11.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQCGBitmap.h"


static BOOL cgIsTiger = NO;



// quartz hack for Panther only
typedef struct {
    Class isa;
    CGContextRef context;
} *graphicsContextInstance;

static void SetCGContextInCurrentNSGraphicsContext(CGContextRef newContext) {
    ((graphicsContextInstance) [NSGraphicsContext currentContext])->context = newContext;
}


@implementation LQCGBitmap

+ (LXUInteger)defaultStorageHintForLXTexture
{
    return (kLXStorageHint_ClientStorage | kLXStorageHint_PreferDMAToCaching);
}

- (id)initWithSize:(NSSize)size
{
    uint32_t pxf = kLQQTPixelFormat_RGBA_int8;
    LXInteger cgFormat = kCGImageAlphaPremultipliedLast;

    self = [super initWithSize:size pixelFormat:pxf];
    
    if (self) {
        ///NSLog(@"%s: buf %p, size %i * %i, rb %i", __func__, _frameBuf, _w, _h, _rowBytes);
    
        CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
        _cgContext = CGBitmapContextCreate( _frameBuf, _w, _h, 8, _rowBytes, cspace, cgFormat);
        CGColorSpaceRelease(cspace);
        
        if (_cgContext == NULL) {
            NSLog(@"** %s: cgcontext create failed", __func__);
            [self release];
            return nil;
        }
        
        cgIsTiger = [[NSGraphicsContext class] respondsToSelector:@selector(graphicsContextWithGraphicsPort:flipped:)];
        
        if ( !cgIsTiger) {
            // for Panther, we need to use an image as a temp drawing buffer
            _image = [[NSImage alloc] initWithSize:size];
        }
    }
    return self;
}

- (void)dealloc
{
    CGContextRelease(_cgContext);
    [_image release];
    [super dealloc];
}

- (BOOL)isFlipped {
    return _isFlipped; }
    
- (void)setFlipped:(BOOL)f {
    _isFlipped = f; }


- (void)lockFocus
{
    [self willModifyFrameBuffer];

    if (cgIsTiger) {
        _ctx = [[NSGraphicsContext graphicsContextWithGraphicsPort:_cgContext flipped:NO] retain];
        _prevCtx = [[NSGraphicsContext currentContext] retain];
        [NSGraphicsContext setCurrentContext:_ctx];
    } else {
        [_image lockFocus];
    }
    
    // flip context
    if (_isFlipped) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        NSAffineTransform *transform = [NSAffineTransform transform];
        [transform translateXBy:0.0 yBy:_h];
        [transform scaleXBy:1.0 yBy:-1.0];
        [transform concat];
    }
    
#ifdef __COCOTRON__
    // 2011.05.21 -- on Cocotron, the pixel data is in reverse format (actually Mac obeys big-endian even on x86).
    // so flip the data here.
    uint32_t *buf = (uint32_t *)_frameBuf;
    LXInteger n = (_rowBytes/4) * _h;
    LXInteger i;
    for (i = 0; i < n; i++) {
        uint32_t v = *buf;
        v = ((v & 0xff) << 24) | (((v >> 8) & 0xff) << 16) | (((v >> 16) & 0xff) << 8) | ((v >> 24) & 0xff);
        *buf = v;
        buf++;
    }
#endif
}

- (void)unlockFocus
{
    if (_isFlipped) {
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }

    if (cgIsTiger) {
        [NSGraphicsContext setCurrentContext:_prevCtx];
        [_prevCtx release];
        [_ctx release];
        _prevCtx = nil;
        _ctx = nil;        
    }
    else {
        // on Panther, we need to do some unsupported trickery...
        [_image unlockFocus];
    
        // save the quartz context from the current cocoa context
        CGContextRef savedCGContext = [[NSGraphicsContext currentContext] graphicsPort];
        
        // set our bitmap context
        SetCGContextInCurrentNSGraphicsContext(_cgContext);

        NSRect rect = NSMakeRect(0.0f, 0.0f, _w, _h);
        [_image drawInRect:rect fromRect:rect operation:NSCompositeCopy fraction:1.0];
        
        SetCGContextInCurrentNSGraphicsContext(savedCGContext);
    }
    
    CGContextFlush(_cgContext);
    
#ifdef __COCOTRON__
    // see lockFocus for explanation
    uint32_t *buf = (uint32_t *)_frameBuf;
    LXInteger n = (_rowBytes/4) * _h;
    LXInteger i;
    for (i = 0; i < n; i++) {
        uint32_t v = *buf;
        v = ((v & 0xff) << 24) | (((v >> 8) & 0xff) << 16) | (((v >> 16) & 0xff) << 8) | ((v >> 24) & 0xff);
        *buf = v;
        buf++;
    }
#endif

    [self didModifyFrameBuffer];
}


- (CGContextRef)CGContext {
    return _cgContext;
}


#if (0)
- (GLuint)glTextureID
{
    if ( !_texID || _texIsDirty) {
    /*
        _texture = [[EDOGLTexture alloc] init];
        [_texture loadTextureFromBuffer:_frameBuf
                            pixelFormat:pixelFormat_RGBA_int8
                                  width:_size.width
                                 height:_size.height
                                rowBytes:_rowBytes];
                                */
        GLuint texFormat = GL_RGBA;
        GLuint texInternalFormat = GL_RGBA;
        GLuint texType;
        int bytesPerPixel = 4;

        #ifdef __BIG_ENDIAN__
            texType = GL_UNSIGNED_INT_8_8_8_8;
        #else
            texType = GL_UNSIGNED_INT_8_8_8_8_REV;
        #endif
        
        glGenTextures(1, &_texID);
    
        glDisable(GL_TEXTURE_2D);
        glEnable(GL_TEXTURE_RECTANGLE_EXT);

        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, _texID);

        glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, _rowBytes / bytesPerPixel);
	
        glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, texInternalFormat,
								_w, _h, 0,
								texFormat, texType, _frameBuf);
                                
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
        
        _texIsDirty = NO;        
    }
    
    return _texID;
}

#endif

@end
