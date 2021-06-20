//
//  LQLXTexture.m
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQLXTexture.h"
#import "LQLXBasicFunctions.h"


@implementation LQLXTexture

+ (NSString *)lacTypeID {
    return @"Texture"; }


- (id)initWithLXTexture:(LXTextureRef)tex retain:(BOOL)doRetain
{
    self = [super init];
    
    _texture = (doRetain) ? LXTextureRetain(tex) : tex;
    _isRetained = doRetain;
    
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@", __func__, self);
    if (_isRetained)
        LXTextureRelease(_texture);
    _texture = NULL;
    [super dealloc];
}

- (LXTextureRef)lxTexture {
    return _texture;
}

- (NSSize)imageDataSize {
    return NSSizeFromLXSize(LXTextureGetSize(_texture)); }


@end
