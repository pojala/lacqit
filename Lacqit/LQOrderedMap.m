//
//  LQOrderedMap.m
//  Inro
//
//  Created by Pauli Ojala on 10.7.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQOrderedMap.h"


@implementation LQOrderedMap

- (id)initWithCapacity:(NSInteger)capacity
{
    self = [super init];
    _keys = [[NSMutableArray alloc] initWithCapacity:capacity];
    _values = [[NSMutableArray alloc] initWithCapacity:capacity];
    return self;
}

- (id)init
{
    self = [self initWithCapacity:32];
    return self;
}

- (void)dealloc
{
    [_keys release];
    [_values release];
    [super dealloc];
}

- (NSInteger)count {
    return [_keys count]; }

- (id)valueForKey:(NSString *)key
{
    NSInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound)
        return [_values objectAtIndex:index]; 
    else
        return nil;
}

- (void)setValue:(id)obj forKey:(NSString *)key
{
    NSInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound) {
        if ( !obj) {
            [_keys removeObjectAtIndex:index];
            [_values removeObjectAtIndex:index];
        } else {
            [_values replaceObjectAtIndex:index withObject:obj];
        }
    }
    else {
        if (obj) {
            [_keys addObject:key];
            [_values addObject:obj];
        }
    }
}

- (NSEnumerator *)keyEnumerator {
    return [_keys objectEnumerator];
}

- (NSEnumerator *)valueEnumerator {
    return [_values objectEnumerator];
}

- (id)valueAtIndex:(NSInteger)index {
    return [_values objectAtIndex:index];
}

- (NSArray *)allKeys {
    return _keys;
}

- (NSArray *)allValues {
    return _values;
}



#pragma mark --- NSCoding & NSCopying ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_keys forKey:@"LQ::keys"];
    [coder encodeObject:_values forKey:@"LQ::values"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    _keys = [[coder decodeObjectForKey:@"LQ::keys"] retain];
    _values = [[coder decodeObjectForKey:@"LQ::values"] retain];
    return self;
}

- (id)_initWithKeys:(id)keys values:(id)values
{
    self = [super init];
    _keys = [keys retain];
    _values = [values retain];
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id newObj = [[[self class] alloc] _initWithKeys:[[_keys mutableCopy] autorelease] values:[[_values mutableCopy] autorelease]];
    return newObj;
}

@end
