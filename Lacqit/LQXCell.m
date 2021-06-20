//
//  LQXCell.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQXCell.h"
#import "LQBitmap.h"


@interface LQXCell (PrivateImpl)
- (LXTextureRef)_getSourceTexture;
@end


@implementation LQXCell

- (id)initWithFrame:(NSRect)frame
{
    self = [super init];
    _frame = frame;
    
    return self;
}

- (void)dealloc
{
    [_contentBitmap release];
    LXSurfaceRelease(_contentSurf);
    [super dealloc];
}


#pragma mark --- accessors ---

- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy];
}

- (NSString *)name {
    return _name; }


- (void)setFrame:(NSRect)frame {
    _frame = frame; }
    
- (NSRect)frame {
    return _frame; }

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }


- (void)setContentLQBitmap:(LQBitmap *)frame {
    [_contentBitmap release];
    _contentBitmap = [frame retain];
}

- (void)setContentLXSurface:(LXSurfaceRef)surface {
    LXSurfaceRelease(_contentSurf);
    _contentSurf = LXSurfaceRetain(surface);
}


#pragma mark --- events ---

- (BOOL)handleMouseDown:(NSEvent *)event location:(NSPoint)pos
{
    return NO;
}

- (BOOL)handleMouseDragged:(NSEvent *)event location:(NSPoint)pos
{
    return NO;
}

- (BOOL)handleMouseUp:(NSEvent *)event location:(NSPoint)pos
{
    return NO;
}



#pragma mark --- drawing ---

- (LXTextureRef)_getSourceTexture
{
    LXTextureRef texture = NULL;

    ///NSLog(@"%s: %@, %p, %p", __func__, self, _contentBitmap, _contentSurf);
    
    if (_contentBitmap) {
        texture = [_contentBitmap lxTexture];
    }
    
    if ( !texture && _contentSurf) {
        texture = LXSurfaceGetTexture(_contentSurf);
        ///NSLog(@"surface %p, outRect %@", _contentSurf, NSStringFromRect(_frame));
    }
    
    return texture;
}

- (void)drawInSurface:(LXSurfaceRef)surface
{
    LXVertexXYUV vertices[4];
    LXTextureRef texture = [self _getSourceTexture];
  
    if (texture) {
        LXRect outRect = LXRectFromNSRect(_frame);
    
        LXSetQuadVerticesXYUV(vertices, outRect, LXUnitRect);

        LXSurfaceDrawTexturedQuad(surface, (void *)vertices, kLXVertex_XYUV, texture, NULL);
    }
}

@end
