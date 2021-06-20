//
//  LQFcurveBunch.m
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQFcurveBunch.h"


@implementation LQFcurveBunch

- (id)init
{
    self = [super init];
    
    _keys = [[NSMutableArray alloc] initWithCapacity:16];
    _dict = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_keys release];
    [_dict release];
    [super dealloc];
}

- (id)owner {
    return _owner; }
    
- (void)setOwner:(id)owner {
    _owner = owner; }

- (LXUInteger)count {
    return [_keys count]; }

- (NSArray *)orderedKeys {
    return _keys; }

- (NSEnumerator *)keyEnumerator {
    return [_keys objectEnumerator]; }
    
    
- (LQFcurve *)fcurveForKey:(NSString *)key {
    if ( !key)
        return nil;
        
    return [_dict objectForKey:key];
}
    
- (LQFcurve *)fcurveAtIndex:(LXInteger)index {
    if (index < 0 || index >= [_keys count])
        return nil;
    
    return [_dict objectForKey:[_keys objectAtIndex:index]];
}
    

- (void)replaceFcurveForKey:(NSString *)key withFcurve:(LQFcurve *)fcurve
{
    if ([_dict objectForKey:key]) {
        if ( !fcurve)
            [_dict removeObjectForKey:key];
        else
            [_dict setObject:fcurve forKey:key];
    }
}

- (void)replaceFcurveForKey:(NSString *)key withFcurve:(LQFcurve *)fcurve newKey:(NSString *)newKey
{
    if ([_dict objectForKey:key]) {
        [_dict removeObjectForKey:key];
        
        LXInteger keyIndex = [_keys indexOfObject:key];
        [_keys removeObjectAtIndex:keyIndex];
        
        if (fcurve && newKey) {
            [self insertFcurve:fcurve withKey:newKey atIndex:keyIndex];
        }
    }
}

- (void)insertFcurve:(LQFcurve *)fcurve withKey:(NSString *)key atIndex:(LXInteger)index
{
    if (fcurve && key) {
        [_dict setObject:fcurve forKey:key];
        [_keys insertObject:key atIndex:index];
    }
}

- (void)removeFcurveAtIndex:(LXInteger)index
{
    id key = [_keys objectAtIndex:index];
    [_dict removeObjectForKey:key];
    [_keys removeObjectAtIndex:index];
}

- (void)setFcurve:(LQFcurve *)fcurve forKey:(NSString *)key {
    [_dict setObject:fcurve forKey:key];
    if ( ![_keys containsObject:key]) {
        [_keys addObject:key];
    }
}

- (void)addFcurve:(LQFcurve *)fcurve
{
    NSString *name = [fcurve name];
    if ([name length] < 1) {
        name = [NSString stringWithFormat:@"_curve%ld", (long)[_keys count]];
        [fcurve setName:name];
    }
    [self setFcurve:fcurve forKey:name];
}


- (void)sortKeysUsingSelector:(SEL)sel
{
    [_keys sortUsingSelector:sel];
}

- (void)sortKeysUsingFunction:(LXInteger (*)(id, id, void *))compareFunc context:(void *)context
{
    [_keys sortUsingFunction:compareFunc context:context];
}



#pragma mark --- NSCopying ---

- (void)_copyKeys:(NSArray *)keys fcurves:(NSDictionary *)dict
{
    [_keys release];
    [_dict release];
    _keys = [keys mutableCopy];
    _dict = [dict mutableCopy];
}

- (id)copyWithZone:(NSZone *)zone
{
    id newObj = [[[self class] alloc] init];
    [newObj _copyKeys:_keys fcurves:_dict];
    return newObj;
}


#pragma mark --- NSCoding ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    if (_keys) [coder encodeObject:_keys forKey:@"FcurveBunch::keys"];
    if (_dict) [coder encodeObject:_dict forKey:@"FcurveBunch::dict"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    _keys = [[coder decodeObjectForKey:@"FcurveBunch::keys"] retain];
    _dict = [[coder decodeObjectForKey:@"FcurveBunch::dict"] retain];
    
    return self;
}


@end
