//
//  LQUUID.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
This class merely wraps CFUUIDBytes for cross-platform use
*/

#if defined(__APPLE__) || defined(__COCOTRON__)
#import <CoreFoundation/CoreFoundation.h>

#else
typedef struct {
    uint8_t byte0;
    uint8_t byte1;
    uint8_t byte2;
    uint8_t byte3;
    uint8_t byte4;
    uint8_t byte5;
    uint8_t byte6;
    uint8_t byte7;
    uint8_t byte8;
    uint8_t byte9;
    uint8_t byte10;
    uint8_t byte11;
    uint8_t byte12;
    uint8_t byte13;
    uint8_t byte14;
    uint8_t byte15;
} CFUUIDBytes;
#endif


@interface LQUUID : NSObject  <NSCopying> {

    CFUUIDBytes _bytes;
}

+ (id)uuid;
+ (id)uuidFromUUIDBytes:(CFUUIDBytes)bytes;
+ (id)uuidFromString:(NSString *)str;

- (CFUUIDBytes)uuidBytes;

- (BOOL)isEqualToUUID:(LQUUID *)otherUUID;

- (BOOL)hasPrefix:(NSString *)prefix;

- (NSString *)description; // returns an UUID string (format 01020304-0506-0708-090A-0B0C0D0E0F10)

#ifdef __APPLE__
- (CFUUIDRef)createCFUUIDRef;
#endif

@end
