//
//  LQDelegatingStreamBuffer.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQDelegatingStreamBuffer.h"


@implementation LQDelegatingStreamBuffer

- (id)initWithTextureDelegate:(id)del
{
    self = [super init];

    NSAssert1([del respondsToSelector:@selector(textureForDelegatingStreamBuffer:)], @"invalid delegate (%@)", _texDelegate);
        
    _texDelegate = [del retain];
    
    return self;
}

- (void)dealloc
{
    if ([_texDelegate respondsToSelector:@selector(delegatingStreamBufferWillBeDestroyed:)])
        [_texDelegate delegatingStreamBufferWillBeDestroyed:self];
        
    [_texDelegate release];
        
    [super dealloc];
}

- (LXTextureRef)lxTexture
{
    return [_texDelegate textureForDelegatingStreamBuffer:self];
}


- (void)setDelegateUserData:(void *)data {
    _delegateUserData = data; }
    
- (void *)delegateUserData {
    return _delegateUserData; }

@end
