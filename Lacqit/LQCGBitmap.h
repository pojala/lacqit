//
//  LQCGBitmap.h
//  PixelMath
//
//  Created by Pauli Ojala on 27.11.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQBitmap.h"


@interface LQCGBitmap : LQBitmap {

    CGContextRef    _cgContext;
    NSImage         *_image;
    
    // temp state during -lockFocus
    NSGraphicsContext *_ctx;
    NSGraphicsContext *_prevCtx;
    
    BOOL            _isFlipped;
    
    //GLuint          _texID;
    //BOOL            _texIsDirty;
}

- (id)initWithSize:(NSSize)size;

- (BOOL)isFlipped;
- (void)setFlipped:(BOOL)f;

- (void)lockFocus;
- (void)unlockFocus;

- (CGContextRef)CGContext;

//- (GLuint)glTextureID;
//- (void)purgeTexture;

@end
