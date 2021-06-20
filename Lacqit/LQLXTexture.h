//
//  LQLXTexture.h
//  Lacqit
//
//  Created by Pauli Ojala on 7.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import "LQStreamBuffer.h"

/*
This class is used for buffers in LQStreamPatch.
The idea is that these objects are thin wrappers that all return -lxTexture.
*/

@interface LQLXTexture : LQStreamBuffer {

    LXTextureRef _texture;
    BOOL _isRetained;
}

- (id)initWithLXTexture:(LXTextureRef)tex retain:(BOOL)doRetain;

- (LXTextureRef)lxTexture;

- (NSSize)imageDataSize;

@end
