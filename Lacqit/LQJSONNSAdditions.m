//
//  NSLQJSONAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSONNSAdditions.h"
#import "LQJSON.h"


@implementation NSObject (LQJSONAdditions)

- (NSString *)lq_JSONFragment {
    LQJSON *generator = [LQJSON new];    
    NSError *error = nil;
    NSString *json = [generator stringWithFragment:self error:&error];
    
    if ( !json)
        NSLog(@"** %s (%@): %@", __func__, self, error);
        
    [generator release];
    return json;
}

- (NSString *)lq_JSONRepresentation {
    LQJSON *generator = [LQJSON new];
    NSError *error = nil;
    NSString *json = [generator stringWithObject:self error:&error];
    
    if ( !json)
        NSLog(@"** %s (%@): %@", __func__, self, error);
        
    [generator release];
    return json;
}

- (NSString *)humanReadableJSONRepresentation {
    LQJSON *generator = [LQJSON new];
    NSError *error = nil;
    [generator setHumanReadable:YES];
    NSString *json = [generator stringWithObject:self error:&error];
    
    if ( !json)
        NSLog(@"** %s (%@): %@", __func__, self, error);
        
    [generator release];
    return json;
}

@end



@implementation NSString (LQJSONAdditions)

// renamed from: - (id)JSONFragmentValue
- (id)parseAsJSONFragment
{
    if ([self length] < 1)
        return nil;

    LQJSON *json = [LQJSON new];
    
    NSError *error = nil;
    id o = [json fragmentWithString:self error:&error];
    
    if (!o)
        NSLog(@"** %s (%@): %@", __func__, self, error);

    [json release];
    return o;
}

// renamed from: - (id)JSONValue
- (id)parseAsJSON
{
    if ([self length] < 1)
        return nil;

    LQJSON *json = [LQJSON new];
    
    NSError *error = nil;
    id o = [json objectWithString:self error:&error];
    
    if (!o) {
        NSLog(@"** %s: %@", __func__, error);
    }

    [json release];
    return o;
}

@end


// helper function and error codes copied over from LQJSON.m
static NSError *err(int code, NSString *str) {
    NSDictionary *ui = [NSDictionary dictionaryWithObject:str forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:kLQJSONErrorDomain code:code userInfo:ui];
}
enum {
    EUNSUPPORTED = 1,
    EPARSENUM,
    EPARSE,
    EFRAGMENT,
    ECTRL,
    EUNICODE,
    EDEPTH,
    EESCAPE,
    ETRAILCOMMA,
    ETRAILGARBAGE,
    EEOF,
    EINPUT
};


@implementation NSArray (LQJSONAdditions)

+ (NSArray *)arrayFromJSON:(NSString *)jsonStr
{
    NSError *error = nil;
    NSArray *arr = [self arrayFromJSON:jsonStr error:&error];
    if ( !arr) {
        NSLog(@"** %s: %@", __func__, error);
    }
    return arr;
}

+ (NSArray *)arrayFromJSON:(NSString *)jsonStr error:(NSError **)error
{
    LXInteger len = [jsonStr length];
    if (len < 2) {
        return nil;
    }
        
    // look for the opening bracket to indicate that this is an array
    unichar c = 0;
    LXInteger i;
    for (i = 0; i < len; i++) {
        c = [jsonStr characterAtIndex:i];
        if ( !isspace(c))
            break;
    }
    if (c != '[') {
        if (error) *error = err(EINPUT, [NSString stringWithFormat:@"Can't create array from this string (first character is 0x%x)", (int)c]);
        return nil;
    }
    
    NSArray *arr = (NSArray *)[LQJSON parseObjectFromString:jsonStr error:error];
    if ( !arr) {
        return nil;
    }
    if ( ![arr isKindOfClass:[NSArray class]]) {
        if (error) *error = err(EPARSE, [NSString stringWithFormat:@"Parsed object is unexpected (exp. array, class '%@')", [arr class]]);
        return nil;
    }
    return arr;
}

@end

@implementation NSDictionary (LQJSONAdditions)

+ (NSDictionary *)dictionaryFromJSON:(NSString *)jsonStr
{
    NSError *error = nil;
    NSDictionary *dict = [self dictionaryFromJSON:jsonStr error:&error];
    if ( !dict) {
        NSLog(@"** %s: %@", __func__, error);
    }
    return dict;
}

+ (NSDictionary *)dictionaryFromJSON:(NSString *)jsonStr error:(NSError **)error
{
    LXInteger len = [jsonStr length];
    if (len < 2) {
        return nil;
    }
        
    // look for the opening bracket to indicate that this is a dictionary
    unichar c = 0;
    LXInteger i;
    for (i = 0; i < len; i++) {
        c = [jsonStr characterAtIndex:i];
        if ( !isspace(c))
            break;
    }
    if (c != '{') {
        if (error) *error = err(EINPUT, [NSString stringWithFormat:@"Can't create dictionary from this string (first character is 0x%x)", (int)c]);
        return nil;
    }
    
    NSDictionary *dict = (NSDictionary *)[LQJSON parseObjectFromString:jsonStr error:error];
    if ( !dict) {
        return nil;
    }
    if ( ![dict isKindOfClass:[NSDictionary class]]) {
        if (error) *error = err(EPARSE, [NSString stringWithFormat:@"Parsed object is unexpected (exp. dict, class '%@')", [dict class]]);
        return nil;
    }
    return dict;
}

@end
