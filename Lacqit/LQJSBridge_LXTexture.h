//
//  LQJSBridge_LXTexture.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LXTexture : LQJSBridgeObject {

    LXTextureRef _texture;
}

- (id)initWithLXTexture:(LXTextureRef)texture
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXTextureRef)lxTexture;

@end
