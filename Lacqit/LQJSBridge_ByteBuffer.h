//
//  LQJSBridge_ByteBuffer.h
//  Lacqit
//
//  Created by Pauli Ojala on 21.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/LXBasicTypes.h>
#import <LacqJS/LacqJS.h>
#import "LQJSPatchMarshalling.h"


@interface LQJSBridge_ByteBuffer : LQJSBridgeObject  <LQJSCopying, LQJSPatchMarshalling> {

    NSData *_data;
    LXUInteger _len;
    const uint8_t *_cbuf;
}

- (id)initWithData:(NSData *)data
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (NSData *)data;

- (LXUInteger)length;
- (BOOL)isMutable;

@end
