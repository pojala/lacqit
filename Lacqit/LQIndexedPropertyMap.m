//
//  LQIndexedPropertyMap.m
//  PixelMath
//
//  Created by Pauli Ojala on 12.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQIndexedPropertyMap.h"
#import "LQMutableIndexedPropertyMap.h"


@implementation LQIndexedPropertyMap


+ (LQIndexedPropertyMap *)propertyMap
{
    return [[[[self class] alloc] init] autorelease];
}

- (void)_privateInit
{
    _dict = [[NSDictionary dictionary] retain];  // empty dictionary
}

- (id)init
{
    self = [super init];
    [self _privateInit];
    return self;
}

- (void)dealloc
{
    [_dict release];
    [super dealloc];
}


- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        NSMutableDictionary *nd = [NSMutableDictionary dictionary];
        
        // convert dictionary objects to arrays and keys to strings
        NSEnumerator *keyEnum = [dict keyEnumerator];
        id key;
        while (key = [keyEnum nextObject]) {
            NSString *prop = [key description];
            NSArray *arr = [NSArray arrayWithObject:[dict objectForKey:key]];
            
            [nd setObject:arr forKey:prop];
        }

        _dict = [nd retain];
    }
    return self;
}

- (NSDictionary *)_dictionary {
    return _dict; }
    

- (id)initWithPropertyMap:(LQIndexedPropertyMap *)propertyMap
{
    self = [super init];
    if (self) {
        _dict = [[propertyMap _dictionary] copy];
    }
    return self;    
}


- (int)countForProperty:(NSString *)property
{
    id arr = [_dict objectForKey:property];
    if ( !arr) return 0;
    
    return [arr count];
}

- (id)objectForProperty:(NSString *)property subindex:(int)index
{
    id arr = [_dict objectForKey:property];
    if ( !arr) return nil;

    int count = [arr count];
    if (index >= count || index < 0) {
        NSLog(@"** %s: out of bounds (%i, %i)", __func__, index, count);
        return nil;
    }
    return [arr objectAtIndex:index];
}

- (id)lastObjectForProperty:(NSString *)property
{
    id arr = [_dict objectForKey:property];
    if ( !arr) return nil;

    return [arr lastObject];
}

- (NSArray *)objectsForProperty:(NSString *)property
{
    return [_dict objectForKey:property];
}


#pragma mark --- copying ---

- (id)copyWithZone:(NSZone *)zone
{
    return [[LQIndexedPropertyMap alloc] initWithPropertyMap:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [[LQMutableIndexedPropertyMap alloc] initWithPropertyMap:self];
}

@end
