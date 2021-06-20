//
//  LQJSBridge_MutableByteBuffer.h
//  Lacqit
//
//  Created by Pauli Ojala on 16.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_ByteBuffer.h"


@interface LQJSBridge_MutableByteBuffer : LQJSBridge_ByteBuffer {

    uint8_t *_mbuf;
}

@end
