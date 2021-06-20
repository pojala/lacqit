//
//  LQJSBridge_JSON.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.5.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_JSON.h"
#import "LQJSON.h"
#import "LQJSUtils.h"



@implementation LQJSBridge_JSON

- (id)initInJSInterpreter:(LQJSInterpreter *)interp withOwner:(id)owner
{
    self = [self initInJSContext:[interp jsContextRef] withOwner:owner];
    if (self) {
        _interp = interp;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+ (NSString *)constructorName {
    return @"<JSON>"; // can't be constructed
}

+ (NSArray *)objectPropertyNames {
    return [NSArray array];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName {
    return NO;
}


+ (NSArray *)objectFunctionNames
{
    return [NSArray arrayWithObjects:@"parse",
                                     @"stringify",
                                     nil]; 
}

- (id)lqjsCallParse:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1)
        return nil;
    
    NSString *jsonStr = [[args objectAtIndex:0] description];
    //if ( ![jsonStr isKindOfClass:[NSString class]]) jsonStr = nil;
    /*
    NSError *jsonErr = nil;
    id parsed = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonErr];
    
    if (jsonErr) {
        NSLog(@"** JSON.parse() failed: %@", jsonErr);
    }*/
    id parsed = [jsonStr parseAsJSON];
    
    if ([parsed isKindOfClass:[NSArray class]]) {
        id jsArray = [_interp emptyProtectedJSArray];
        [jsArray setProtected:NO];
        [jsArray addObjectsFromArray:parsed];
        return jsArray;
    }
    return parsed;
}

static NSDictionary *encodableDictionaryFromKeyedObject(id obj)
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnum = [[obj allKeys] objectEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject]) {
        id value = [obj valueForKey:key];
        
        if ([value respondsToSelector:@selector(allKeys)]) {
            [dict setObject:encodableDictionaryFromKeyedObject(value) forKey:key];
        }
        else if ([value conformsToProtocol:@protocol(NSCopying)] && [value conformsToProtocol:@protocol(NSCoding)]) {
            [dict setObject:value forKey:key];
        }
    }
    return dict;
}

- (id)lqjsCallStringify:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1)
        return nil;

    id obj = [args objectAtIndex:0];
    //NSLog(@"JSON.stringify: obj class %@, %i", [obj class], [obj isKindOfClass:[NSArray class]]);
    
    if ([obj isKindOfClass:[NSArray class]]) {
        obj = obj;
    } else if ([obj respondsToSelector:@selector(allKeys)]) {   // JSKitObject
        obj = encodableDictionaryFromKeyedObject(obj);
    } else if ([obj isKindOfClass:[NSNull class]]) {
        return nil;
    }
    else {
        NSLog(@"** JSON.stringify: invalid object type (%@)", [obj class]);
        return nil;
    }
        
    LQJSON *generator = [[LQJSON alloc] init];
    NSError *error = nil;
    
    //[generator setHumanReadable:YES];
    
    NSString *jsonStr = [generator stringWithObject:obj error:&error];
    if ( !jsonStr) {
        NSLog(@"** JSON.stringify: unable to parse object of class '%@' -- error %@", [obj class], error);
    }
    
    [generator release];
    return jsonStr;
}


@end
