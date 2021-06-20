//
//  LQJSBridge_LXShader.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LXShader : LQJSBridgeObject  <LQJSCopying> {

    LXShaderRef _shader;  // retained
}

- (id)initWithLXShader:(LXShaderRef)shader
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXShaderRef)lxShader;


@end
