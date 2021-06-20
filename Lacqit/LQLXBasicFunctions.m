//
//  LQLXBasicFunctions.m
//  Lacqit
//
//  Created by Pauli Ojala on 7.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQLXBasicFunctions.h"
#import <Lacefx/LXStringUtils.h>
#import <Lacefx/LXTransform3D.h>


NSAffineTransform *NSAffineTransformFromLXTransform3D(LXTransform3DRef trs)
{
    if ( !trs) return nil;
    
    LX4x4Matrix matrix;
    memset(&matrix, 0, sizeof(LX4x4Matrix));
    
    LXTransform3DGetMatrix(trs, &matrix);

    NSAffineTransformStruct nsAff;
    nsAff.m11 = matrix.m11;
    ///nsAff.m12 = matrix.m12;
    ///nsAff.m21 = matrix.m21;
    nsAff.m12 = matrix.m21;         // FLIP order
    nsAff.m21 = matrix.m12;
    nsAff.m22 = matrix.m22;
    
    nsAff.tX = matrix.m14;
    nsAff.tY = matrix.m24;
    
    NSAffineTransform *newTrs = [NSAffineTransform transform];
    [newTrs setTransformStruct:nsAff];
    
    return newTrs;
}

LXTransform3DRef LXTransform3DCreateFromNSAffineTransform(NSAffineTransform *trs)
{
    if ( !trs) return NULL;
    
    NSAffineTransformStruct nsAff = [trs transformStruct];
    
    return LXTransform3DCreateWith2DTransform(nsAff.m11, nsAff.m21, nsAff.m12,  // FLIP order
                                              nsAff.m22, nsAff.tX, nsAff.tY);
}


size_t LXStrCopyUTF16FromNSString(LXUnibuffer *dstUnibuffer, NSString *nsstr)
{
    if ( !dstUnibuffer) return 0;
    
    if ( !nsstr || [nsstr length] == 0) {
        memset(dstUnibuffer, 0, sizeof(LXUnibuffer));
        return 0;
    }
    
    size_t numChars = [nsstr length];
    dstUnibuffer->numOfChar16 = numChars;
    dstUnibuffer->unistr = _lx_calloc(numChars * sizeof(char16_t), 1);
    
    [nsstr getCharacters:dstUnibuffer->unistr];
    return numChars;
}

LXRGBA LXRGBAFromNSString(NSString *str)
{
    if ( !str)
        return LXZeroRGBA;
        
    NSRange range;
	NSScanner *scanner = [NSScanner scannerWithString:str];
	NSString *s = nil;
	
    NSCharacterSet *numSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"];
    NSCharacterSet *commaSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    float c[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    int n = 0;
    
	while (n < 4 && ![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:numSet intoString:NULL];
        
        if ( ![scanner scanFloat:c+n])
            break;
        else
            n++;
	}

    return LXMakeRGBA(c[0], c[1], c[2], c[3]);
}



#define LXMAP_IS_TOLLFREE_NSDICT 0


NSDictionary *NSDictionaryFromLXMap(LXMapPtr lxMap)
{
#if (LXMAP_IS_TOLLFREE_NSDICT)
    // !!! Lacefx implementation dependent !!!
    return (lxMap) ? [NSDictionary dictionaryWithDictionary:(NSDictionary *)lxMap] : nil;
#else

    LXUInteger count = LXMapCount(lxMap);
    LXUInteger i;
    const char *keys[count];
    
    if ( !LXMapGetKeysArray(lxMap, keys, count)) {
        NSLog(@"*** %s: unable to get keys (%p, count %lu)", __func__, lxMap, (long)count);
        return nil;
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
    
        for (i = 0; i < count; i++) {
            const char *key = keys[i];
            LXPropertyType propType = 0;
            LXMapContainsValueForKey(lxMap, key, &propType);
            
            id obj = nil;
            switch (propType) {
                case kLXIntegerProperty: {
                    LXInteger v = 0;
                    LXMapGetInteger(lxMap, key, &v);
                    obj = [NSNumber numberWithLong:v];
                    break;
                }
                case kLXBoolProperty: {
                    LXBool v = NO;
                    LXMapGetBool(lxMap, key, &v);
                    obj = [NSNumber numberWithBool:v];
                    break;
                }
                case kLXFloatProperty: {
                    double v = 0.0;
                    LXMapGetDouble(lxMap, key, &v);
                    obj = [NSNumber numberWithDouble:v];
                    break;
                }
                case kLXStringProperty: {
                    LXUnibuffer uni = { 0, NULL };
                    LXMapGetUTF16(lxMap, key, &uni);
                    obj = [NSString stringWithCharacters:uni.unistr length:uni.numOfChar16];
                    LXStrUnibufferDestroy(&uni);
                    break;
                }
                case kLXBinaryDataProperty: {
                    uint8_t *data = NULL;
                    size_t len = 0;
                    LXMapGetBinaryData(lxMap, key, &data, &len, NULL);
                    obj = [NSData dataWithBytes:data length:len];
                    _lx_free(data);
                    break;
                }
                case kLXMapProperty: {
                    LXMapPtr v = NULL;
                    LXMapGetMap(lxMap, key, &v);
                    obj = NSDictionaryFromLXMap(v);
                    break;
                }
                case kLXRefProperty: {
                    LXRef ref = NULL;
                    LXMapGetObjectRef(lxMap, key, &ref);
                    
                    if (LXRefIsOfType(ref, LXObjCTypeID())) {
                        obj = LXObjCGetObject(ref);
                        [[obj retain] autorelease];
                    } else if (ref) {
                        NSLog(@"%s: unknown reftype in map, can't convert (key '%s', type '%s')", __func__, key, LXRefGetType(ref));
                    }
                    break;
                }
            }
            if (obj) [dict setObject:obj forKey:[NSString stringWithUTF8String:key]];
        }
        return dict;
    }
    
#endif
}

LXMapPtr LXMapCreateFromNSDictionary(NSDictionary *dict)
{
#if (LXMAP_IS_TOLLFREE_NSDICT)
    // !!! Lacefx implementation dependent !!!
    return (dict) ? (LXMapPtr)[[NSMutableDictionary alloc] initWithDictionary:dict] : NULL;
#else
    
    LXMapPtr lxMap = LXMapCreateMutable();
    
    NSEnumerator *keyEnum = [dict keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        if ( ![key isKindOfClass:[NSString class]])
            continue;
            
        const char *utf8Key = [key UTF8String];
        id obj = [dict objectForKey:key];
        
        LXPropertyType propType = 0;
        
        if ([obj isKindOfClass:[NSData class]])
            propType = kLXBinaryDataProperty;
        else if ([obj isKindOfClass:[NSDictionary class]])
            propType = kLXMapProperty;
        else if ([obj isKindOfClass:[NSString class]])
            propType = kLXStringProperty;
        else if ([obj isKindOfClass:[NSValue class]]) {  // covers NSNumber
            const char *objCType = [obj objCType];
            if (0 == strcmp(objCType, "c")) {
                propType = kLXBoolProperty;
            } else if (0 == strcmp(objCType, "f") || 0 == strcmp(objCType, "d")) {
                propType = kLXFloatProperty;
            } else
                propType = kLXIntegerProperty;
        }
        else propType = kLXRefProperty;  // no special support for this type, will wrap into an LXObjCRef
        
        switch (propType) {
            default:  break;
            case kLXBoolProperty:
                LXMapSetBool(lxMap, utf8Key, [obj boolValue]);
                break;
            case kLXFloatProperty:
                LXMapSetDouble(lxMap, utf8Key, [obj doubleValue]);
                break;
            case kLXIntegerProperty:
                LXMapSetInteger(lxMap, utf8Key, [obj longValue]);
                break;
            case kLXStringProperty:
                LXMapSetUTF8(lxMap, utf8Key, [obj UTF8String]);
                break;
            case kLXBinaryDataProperty:
                LXMapSetBinaryData(lxMap, utf8Key, [(NSData *)obj bytes], [(NSData *)obj length], kLXUnknownEndian);
                break;
            case kLXMapProperty: {
                LXMapPtr m = LXMapCreateFromNSDictionary((NSDictionary *)obj);
                LXMapSetMap(lxMap, utf8Key, m);
                LXMapDestroy(m);
                break;
            }
            case kLXRefProperty: {
                LXObjCRef ref = LXObjCCreateWithObject(obj);
                LXMapSetObjectRef(lxMap, utf8Key, ref);
                LXRefRelease(ref);
                break;
            }
        }
    }
    
    return lxMap;
#endif
}


