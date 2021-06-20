//
//  LQJSBridge_MutableByteBuffer.m
//  Lacqit
//
//  Created by Pauli Ojala on 16.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_MutableByteBuffer.h"


@implementation LQJSBridge_MutableByteBuffer

- (void)_setRetainedMutableData:(NSMutableData *)data
{
    [_data autorelease];
    _data = data;
    
    _len = [_data length];
    _cbuf = [_data bytes];
    _mbuf = [(NSMutableData *)_data mutableBytes];
}

- (id)initWithData:(NSData *)data
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        [self _setRetainedMutableData:[data mutableCopy]];

        ///NSLog(@"%s (%p): data length is %ld bytes", __func__, self, [_data length]);
    }
    return self;
}

- (id)copyAsPatchObject {
    return [_data copy];
}

+ (NSString *)constructorName
{
    return @"MutableByteBuffer";  // only mutable buffers can be constructed
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] >= 1) {
        id arg = [arguments objectAtIndex:0];
    
        if ([arg isKindOfClass:[LQJSBridge_ByteBuffer class]]) {
            [self _setRetainedMutableData:[[arg data] mutableCopy]];
        }
        else if ([arg respondsToSelector:@selector(doubleValue)]) {
            size_t size = lround([arg doubleValue]);
        
            if (size > 32*1024*1024) {
                NSLog(@"*** ByteBuffer constructor: size exceeds sanity limit (%ld)", size);
                size = 4;
            }            
            [self _setRetainedMutableData:[[NSMutableData alloc] initWithLength:size]];
        }
    }
}

- (BOOL)isMutable {
    return YES; }


+ (NSArray *)objectFunctionNames
{
    NSMutableArray *arr = [NSMutableArray arrayWithArray:[super objectFunctionNames]];
    [arr addObject:@"setUnsignedByte"];
    [arr addObject:@"setSignedByte"];
    return arr;
}

- (id)lqjsCallSetUnsignedByte:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    
    size_t length = _len;
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index])
        return nil;
    if (index < 0 || index >= length)
        return nil;
    
    uint8_t valueToSet = 0;
    if ( ![self parseByteFromArg:[args objectAtIndex:1] outValue:&valueToSet])
        return nil;
        
    uint8_t *buf = _mbuf;
    
    buf[index] = (uint8_t)valueToSet;

    return self;
}

- (id)lqjsCallSetSignedByte:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) return nil;
    
    size_t length = _len; 
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index])
        return nil;
    if (index < 0 || index >= length)
        return nil;
    
    long v = 0;
    if ( ![self parseLongFromArg:[args objectAtIndex:1] outValue:&v])
        return nil;
        
    uint8_t *buf = _mbuf;
    
    buf[index] = (uint8_t)(MIN(INT8_MAX, MAX(INT8_MIN, v)));

    return self;
}


#pragma mark --- array-style indexed access ---

+ (BOOL)hasArrayIndexingSetter {
    return YES;
}

- (id)valueForArrayIndex:(int)index
{
    LXUInteger len = _len;
    ///NSAssert2(index < len, @"index out of bounds: %ld, len %ld", (long)index, len);
    
    const uint8_t *buf = _cbuf;

    return [NSNumber numberWithUnsignedInt:buf[index]];
}

- (void)setValue:(id)value forArrayIndex:(int)index
{
    LXUInteger len = _len;
    ///NSAssert2(index < len, @"index out of bounds: %ld, len %ld", (long)index, len);

    long v = 0;
    if ( ![self parseLongFromArg:value outValue:&v])
        return;
        
    uint8_t *buf = _mbuf;
    buf[index] = (uint8_t)(MIN(UINT8_MAX, MAX(0, v)));
}

- (BOOL)isByteArray {
    return YES;
}

- (uint8_t)byteValueForArrayIndex:(int)index
{
    return _cbuf[index];
}

- (void)setByteValue:(uint8_t)b forArrayIndex:(int)index
{
    _mbuf[index] = b;
}


@end
