//
//  LQDelegatingStreamBuffer.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import "LQStreamBuffer.h"


@interface LQDelegatingStreamBuffer : LQStreamBuffer {

    id _texDelegate;
    
    void *_delegateUserData;
}

- (id)initWithTextureDelegate:(id)del;

- (LXTextureRef)lxTexture;

- (void)setDelegateUserData:(void *)data;
- (void *)delegateUserData;

@end


@interface NSObject (LQDelegatingStreamBufferTextureDelegate)

- (LXTextureRef)textureForDelegatingStreamBuffer:(LQDelegatingStreamBuffer *)buffer;
- (void)delegatingStreamBufferWillBeDestroyed:(LQDelegatingStreamBuffer *)buffer;

@end