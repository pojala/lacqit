 //
//  LACArrayListDictionary.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LACArrayListDictionary.h"


@implementation LACArrayListDictionary

- (id)initWithCapacity:(LXUInteger)numItems
{
    self = [super init];
    _dict = [[NSMutableDictionary alloc] initWithCapacity:numItems];
    return self;
}

- (id)init
{
    return [self initWithCapacity:32];
}

+ (id)dictionary
{
    return [[[[self class] alloc] init] autorelease];
}

+ (id)dictionaryWithArrayList:(LACArrayListPtr)list forKey:(NSString *)key
{
    id dict = [self dictionary];
    [dict setArrayList:list forKey:key];
    return dict;
}

+ (NSString *)lacTypeID {
    return @"ArrayListDictionary"; }


- (void)_removeAllWeakKeys
{
    id keysToRemove = (_weakKeys) ? [NSSet setWithSet:_weakKeys] : nil;
    
    [_weakKeys release];
    _weakKeys = nil;

    NSEnumerator *keyEnum = [keysToRemove objectEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        id val = [_dict objectForKey:key];
        LACArrayListRelease( (LACArrayListPtr)[val pointerValue] );
        
        [_dict removeObjectForKey:key];
    }
}

- (void)_releaseArrayListsForAllValues
{
    NSEnumerator *valEnum = [[_dict allValues] objectEnumerator];
    id val;
    while (val = [valEnum nextObject]) {
        LACArrayListRelease( (LACArrayListPtr)[val pointerValue] );
    }
}

- (void)dealloc
{
    if (_weakKeys) {
        //[self _removeAllWeakKeys];
        [_weakKeys release];
        _weakKeys = nil;
    }
    [self _releaseArrayListsForAllValues];
    
    [_dict release];
    
    [super dealloc];
}

- (void)removeObjectForKey:(id)key
{
    if (_weakKeys && [_weakKeys containsObject:key]) {
        [_weakKeys removeObject:key];
    }

    id val = [_dict objectForKey:key];
    LACArrayListRelease( (LACArrayListPtr)[val pointerValue] );
    
    [_dict removeObjectForKey:key];
}

-(void)removeAllObjects
{
    if (_weakKeys) {
        //[self _removeAllWeakKeys];
        [_weakKeys release];
        _weakKeys = nil;
    }
    [self _releaseArrayListsForAllValues];
    
    [_dict removeAllObjects];
}

- (void)setArrayList:(LACArrayListPtr)list forWeakKey:(id)obj
{
    if ( !list) return;
    if ( !obj) return;
    NSAssert(_dict, @"no dictionary");

    id key = [NSValue valueWithPointer:obj];
    id val = [NSValue valueWithPointer:LACArrayListRetain(list)];

    //NSLog(@" -- %s, key %p -> val %p (ptr %p)", __func__, obj, list, [val pointerValue]);

    if ([_dict objectForKey:key]) [self removeObjectForKey:key];

    [_dict setObject:val forKey:key];
    
    if ( !_weakKeys) _weakKeys = [[NSMutableSet alloc] init];
    [_weakKeys addObject:key];
    
    //NSLog(@"   ... value is: %@", [_dict objectForKey:key]);
}

- (void)setArrayList:(LACArrayListPtr)list forKey:(NSString *)key
{
    if ( !list) return;
    if ( !key || [key length] < 1) return;
    NSAssert(_dict, @"no dictionary");
    
    id val = [NSValue valueWithPointer:LACArrayListRetain(list)];
    
    if ([_dict objectForKey:key]) [self removeObjectForKey:key];
    
    [_dict setObject:val forKey:key];
}

- (void)setArrayListWithObject:(id)obj forKey:(NSString *)key
{
    LACArrayListPtr list = LACArrayListCreateWithObject(obj);
    [self setArrayList:list forKey:key];
    LACArrayListRelease(list);
}


- (LACArrayListPtr)arrayListForWeakKey:(id)obj
{
    id key = [NSValue valueWithPointer:obj];
    
    id val = [_dict objectForKey:key];

    //NSLog(@" -- %s, key %p -> val %p (ptr %p)", __func__, obj, val, [val pointerValue]);
    
    if (val) {
        return (LACArrayListPtr)[val pointerValue];
    } else
        return NULL;
}

- (LACArrayListPtr)arrayListForKey:(NSString *)key
{
    id val = [_dict objectForKey:key];
    if (val) {
        return (LACArrayListPtr)[val pointerValue];
    } else
        return NULL;
}

@end
