//
//  LQLXSurface.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQLXSurface.h"
#import "LQLXBasicFunctions.h"


@implementation LQLXSurface

+ (NSString *)lacTypeID {
    return @"Surface"; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (id %ld, refTime %.3f, sourceTime %.3f; surf %p, isRetained %i; %ld * %ld)>",
                        [self class], self,
                        (long)[self sampleID],
                        [self sampleReferenceTime],
                        [self sampleSourceTime],
                        _surface,
                        _isRetained,
                        (long)LXSurfaceGetWidth(_surface),
                        (long)LXSurfaceGetHeight(_surface)
                    ];
}


- (id)initWithLXSurface:(LXSurfaceRef)surface retain:(BOOL)doRetain
{
    self = [super init];

    _surface = (doRetain) ? LXSurfaceRetain(surface) : surface;
    _isRetained = doRetain;
    
    ///NSLog(@"%s: %@ (surf %p, ret %i)", __func__, self, _surface, _isRetained);
    
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@ (surf %p, ret %i)", __func__, self, _surface, _isRetained);

    if (_isRetained)
        LXSurfaceRelease(_surface);
    _surface = NULL;
    
    if (_assocPixbuf)
        LXPixelBufferRelease(_assocPixbuf);
    
    [super dealloc];
}

- (id)retain {
    return [super retain];
}

- (LXSurfaceRef)lxSurface {
    return _surface;
}

- (LXTextureRef)lxTexture {
    return LXSurfaceGetTexture(_surface);
}

- (NSSize)imageDataSize {
    return NSSizeFromLXSize(LXSurfaceGetSize(_surface)); }


- (LXPixelBufferRef)associatedLXPixelBuffer {
    return _assocPixbuf; 
}

- (void)setAssociatedLXPixelBuffer:(LXPixelBufferRef)pixbuf {
    LXPixelBufferRelease(_assocPixbuf);
    _assocPixbuf = LXPixelBufferRetain(pixbuf);
}


@end
