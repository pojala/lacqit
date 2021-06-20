//
//  LQUUID.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUUID.h"

#if !defined(__APPLE__)
#import <Lacefx/LXRandomGen.h>
#endif



@implementation LQUUID

- (id)init
{
    self = [super init];
    
#if defined(__APPLE__)
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    _bytes = CFUUIDGetUUIDBytes(uuid);
    CFRelease(uuid);
    
#else
    // on non-Apple platforms, we can create the id using Lacefx's random generator.
    int32_t *ip = (int32_t *)(&_bytes);
    int i;
    for (i = 0; i < 4; i++) {
        ip[i] = LXRdUniform_i32(INT32_MIN, INT32_MAX);
    }
    
    // according to UUID spec, hex digit 12 must be the version number of the UUID generation scheme (4 for randomized).
    _bytes.byte6 = LXRdUniform_i32(0x40, 0x4f);
    
    // ... and hex digit 16 must be: "8, 9, A, or B".
    _bytes.byte8 = LXRdUniform_i32(0x80, 0xbf);
#endif

    return self;
}

+ (id)uuid
{
    return [[[[self class] alloc] init] autorelease];
}


- (id)initWithCFUUIDBytes:(CFUUIDBytes)bytes
{
    self = [super init];
    
    _bytes = bytes;
    
    return self;
}

+ (id)uuidFromUUIDBytes:(CFUUIDBytes)bytes
{
    return [[[[self class] alloc] initWithCFUUIDBytes:bytes] autorelease];
}

- (NSString *)description
{
#if 0 // defined(__APPLE__)
    CFUUIDRef uuidRef = [self createCFUUIDRef];
    CFStringRef cfStr = CFUUIDCreateString(NULL, uuidRef);
    NSString *nsStr = [NSString stringWithString:(NSString *)cfStr];
    CFRelease(cfStr);
    CFRelease(uuidRef);
    return nsStr;
    
#else    
    NSAssert1(sizeof(CFUUIDBytes) == 16, @"invalid uuidBytes size on this platform (%i, expected 16)", (int)sizeof(CFUUIDBytes));

    // CFUUIDRef string format is: 01020304-0506-0708-090A-0B0C0D0E0F10
    char buf[48];
    memset(buf, 0, 48);
    
    int i;
    char *s = buf;
    for (i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
            *s++ = '-';
        }
        uint8_t *b = ((uint8_t *)(&_bytes)) + i;
        
        sprintf(s, "%02X", (int)(*b));
        s += 2;
    }

    return [NSString stringWithUTF8String:buf];
#endif
}

+ (id)uuidFromString:(NSString *)str
{
    if ([str length] < 32+4) {
        NSLog(@"** %s: string is too short (%ld)", __func__, (long)[str length]);
        return nil;
    }
    str = [str substringWithRange:NSMakeRange(0, 32+4)];
    unichar buf[32+5];
    [str getCharacters:buf];
    
    CFUUIDBytes bytes;
    
    BOOL ok = YES;
    int i;
    int bn = 0;
    for (i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
            if (buf[bn] != '-') {
                ok = NO;
                NSLog(@"** %s: error at dash at pos %i (char is %i)", __func__, i, (int)buf[bn]);
                break;
            }
            bn++;
        }
        char hexStr[5] = { '0', 'x', buf[bn], buf[bn+1], 0 };
        bn += 2;
        int value = strtol(hexStr, NULL, 16);
        if (value < 0 || value > 255) {
            ok = NO;
            NSLog(@"** %s: error at value at pos %i", __func__, i);
            break;
        } else {
            ((uint8_t *)&bytes)[i] = (uint8_t)value;
        }
    }
    if ( !ok) { 
        return nil;
    } else {
        return [self uuidFromUUIDBytes:bytes];
    }
}


- (CFUUIDBytes)uuidBytes
{
    return _bytes;
}


- (BOOL)isEqual:(id)obj
{
    if ( ![obj isKindOfClass:[LQUUID class]])
        return NO;
    else
        return [self isEqualToUUID:(LQUUID *)obj];
}

- (BOOL)isEqualToUUID:(LQUUID *)other
{
    if ( !other) return NO;
    
    CFUUIDBytes bytes = [other uuidBytes];
    
    return (0 == memcmp(&bytes, &_bytes, 16)) ? YES : NO;
}

- (BOOL)hasPrefix:(NSString *)prefix
{
    return [[self description] hasPrefix:prefix];
}


#ifdef __APPLE__
- (CFUUIDRef)createCFUUIDRef
{
    return CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, _bytes);
}
#endif



#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    id newObj = [[[self class] alloc] initWithCFUUIDBytes:[self uuidBytes]];
    return newObj;
}

@end
