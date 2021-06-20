//
//  LQJSBridge_ByteBuffer.m
//  Lacqit
//
//  Created by Pauli Ojala on 21.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_ByteBuffer.h"


@implementation LQJSBridge_ByteBuffer

- (id)initWithData:(NSData *)data
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _data = [data retain];
        
        _len = [_data length];
        _cbuf = [_data bytes];

        ///NSLog(@"%s (%p): data length is %ld bytes", __func__, self, [_data length]);
    }
    return self;
}

- (void)dealloc
{
    _cbuf = NULL;
    [_data release];
    [super dealloc];
}

- (NSData *)data {
    return _data; }


- (id)copyAsPatchObject {
    return [_data retain];
}


+ (NSString *)constructorName
{
    return @"<ByteBuffer_immutable>";  // only mutable buffers can be constructed
}
/*
- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] >= 1) {
        size_t size = lround([[arguments objectAtIndex:0] doubleValue]);
        
        if (size > 32*1024*1024) {
            NSLog(@"*** ByteBuffer constructor: size exceeds sanity limit (%ld)", size);
            size = 4;
        }
        
        _data = [[NSMutableData alloc] initWithLength:size];
    }
}
*/

- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj;
    
    if ([self isMutable]) {
        newObj = [[[self class] alloc] initWithData:_data  // will be copied by the mutable version of -initWithData:
                                            inJSContext:dstContext
                                            withOwner:nil];    
    } else {
        newObj = [[[self class] alloc] initWithData:[[_data copy] autorelease]
                                            inJSContext:dstContext
                                            withOwner:nil];
    }
    return [newObj autorelease];
}


+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"length", @"isMutable", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return NO; //[propertyName isEqualToString:@"endian"] ? YES : NO;
}

- (LXUInteger)length {
    return _len; }

- (BOOL)isMutable {
    return NO; }


+ (NSArray *)objectFunctionNames
{
    return [NSArray arrayWithObjects:@"indexOfByte",
                                     @"asString",
                                     @"at",  // equal to unsignedByteAt
                                     @"getSignedByte",
                                     @"getUnsignedByte",
/*                                     @"shortAt",
                                     @"unsignedShortAt",
                                     @"intAt",
                                     @"unsignedIntAt",
                                     @"floatAt",
                                     @"doubleAt",
*/
                                     nil];
}

- (id)lqjsCallGetUnsignedByte:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;

    size_t length = _len;
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index])
        return nil;
    if (index < 0 || index >= length)
        return nil;
    
    const uint8_t *buf = _cbuf;

    return [NSNumber numberWithUnsignedInt:buf[index]];
}

- (id)lqjsCallAt:(NSArray *)args context:(id)contextObj
{
    return [self lqjsCallGetUnsignedByte:args context:contextObj];
}

- (id)lqjsCallGetSignedByte:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;

    size_t length = _len;
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index])
        return nil;
    if (index < 0 || index >= length)
        return nil;
    
    const int8_t *buf = (const int8_t *)_cbuf;
    
    return [NSNumber numberWithInt:buf[index]];
}


// example call:  buffer.indexOfByte(0, [startIndex, length])
//
- (id)lqjsCallIndexOfByte:(NSArray *)args context:(id)contextObj
{
    id notFoundRet = [NSNumber numberWithInt:-1];

    if ([args count] < 1) return notFoundRet;
    
    uint8_t b = 0;
    if ( ![self parseByteFromArg:[args objectAtIndex:0] outValue:&b])
        return notFoundRet;

    size_t length = _len;
    if (length < 1)
        return notFoundRet;

    long startIndex = 0;
    long endIndex = length;
    
    if ([args count] >= 2) {
        [self parseLongFromArg:[args objectAtIndex:1] outValue:&startIndex];
        
        startIndex = MAX(0, MIN(length - 1, startIndex));
    }
        
    if ([args count] >= 3) {
        long searchLen = 0;
        [self parseLongFromArg:[args objectAtIndex:2] outValue:&searchLen];
        
        endIndex = startIndex + searchLen;
        endIndex = MAX(startIndex, MIN(length, endIndex));
    }
    
    const uint8_t *buf = _cbuf;
    LXInteger i;
    for (i = startIndex; i < endIndex; i++) {
        if (buf[i] == b)
            break;
    }
    if (i < endIndex) {
        return [NSNumber numberWithLong:i];
    } else {
        return notFoundRet;
    }
}

// example call:  buffer.asString("utf-8", [startIndex, length])
// 
- (id)lqjsCallAsString:(NSArray *)args context:(id)contextObj
{
    NSStringEncoding encoding = NSUTF8StringEncoding;
    
    NSString *str;
    if ([args count] >= 1 && [(str = (NSString *)[args objectAtIndex:0]) isKindOfClass:[NSString class]]) {
        str = [str lowercaseString];
        if ([str isEqual:@"utf-8"] || [str isEqual:@"utf8"]) {
            encoding = NSUTF8StringEncoding;
        }
        else if ([str isEqual:@"utf-16"] || [str isEqual:@"utf16"]) {
            encoding = NSUnicodeStringEncoding;
        }
        else if ([str isEqual:@"iso-8859-1"] || [str isEqual:@"iso-latin1"] || [str isEqual:@"iso-latin"]) {
            encoding = NSISOLatin1StringEncoding;
        }
        else if ([str isEqual:@"ascii"]) {
            encoding = NSISOLatin1StringEncoding;  //NSASCIIStringEncoding;  <-- not supported correctly on Cocotron, so just pretend with Latin1
        }
        else {
            NSLog(@"** JS call 'asString': unknown encoding requested: '%@'", [args objectAtIndex:0]);
            return nil;
        }
    }
    
    size_t length = _len;
    if (length < 1) return @"";
    
    long startIndex = 0;
    long readLength = length;
    
    if ([args count] >= 2) {
        [self parseLongFromArg:[args objectAtIndex:1] outValue:&startIndex];
        
        startIndex = MAX(0, MIN(length - 1, startIndex));
        readLength = MAX(0, length - startIndex);
    }
        
    if ([args count] >= 3) {
        [self parseLongFromArg:[args objectAtIndex:2] outValue:&readLength];
        
        readLength = MAX(0, MIN(length - startIndex, readLength));
    }
    
    if (readLength == 0) return @"";
    
    const uint8_t *buf = _cbuf + startIndex;
    
    if (encoding == NSUnicodeStringEncoding) {
        return [NSString stringWithCharacters:(unichar *)buf length:readLength / 2];
    }
    else {
        return [[[NSString alloc] initWithBytes:buf length:readLength encoding:encoding] autorelease];
    }
}


#pragma mark --- array-style indexed access ---

+ (BOOL)hasArrayIndexingGetter {
    return YES;
}

+ (BOOL)hasArrayIndexingSetter {
    return NO;
}

- (int)lengthForArrayIndexing {
    return _len;
}

- (id)valueForArrayIndex:(int)index
{
    LXUInteger len = _len;
    NSAssert2(index < len, @"index out of bounds: %ld, len %ld", (long)index, len);
    
    const uint8_t *buf = _cbuf;

    return [NSNumber numberWithUnsignedInt:buf[index]];
}

- (void)setValue:(id)value forArrayIndex:(int)index
{
    // should be implemented in mutable subclass
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
    // should be implemented in mutable subclass
}


@end

