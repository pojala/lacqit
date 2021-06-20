//
//  LQMutableIndexedPropertyMap.m
//  PixelMath
//
//  Created by Pauli Ojala on 12.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQMutableIndexedPropertyMap.h"


@interface LQIndexedPropertyMap (ImplPrivate)
- (NSDictionary *)_dictionary;
@end


@implementation LQMutableIndexedPropertyMap

- (void)_privateInit
{
    _dict = [[NSMutableDictionary dictionary] retain];
}

- (id)initWithPropertyMap:(LQIndexedPropertyMap *)propertyMap
{
    self = [super init];
    if (self) {
        NSAssert([_dict isKindOfClass:[NSMutableDictionary class]], @"invalid inner dictionary");
        
        NSDictionary *srcDict = [propertyMap _dictionary];
        
        // mutableCopy the subarrays
        NSEnumerator *keyEnum = [srcDict keyEnumerator];
        NSString *prop;
        while (prop = [keyEnum nextObject]) {
            NSArray *arr = [srcDict objectForKey:prop];
            
            [_dict setObject:[[arr mutableCopy] autorelease] forKey:prop];
        }
    }
    return self;    
}

- (void)setObject:(id)object forProperty:(NSString *)property subindex:(int)index
{
    if ( !object) {
        NSLog(@"** %s: nil object (property: %@)", __func__, property);
        return;
    }
    if ( !property) {
        NSLog(@"** %s: nil property (object: %@)", __func__, object);
        return;
    }
    id arr = [_dict objectForKey:property];
    
    if ( !arr) {
        if (index != 0) {
            NSLog(@"** %s: attempt to add object to nonexisting property at non-zero index (%@, %i)", __func__, property, index);
            return;
        }
        arr = [NSMutableArray arrayWithObject:object];
        [_dict setObject:arr forKey:property];
    }
    else {
        int count = [arr count];
        if (index < 0 || index > count) {
            NSLog(@"** %s: attempt to add object beyond property's current count (%@, %i, %i)", __func__, property, index, count);
            return;
        }
        if (index == count)
            [arr addObject:object];
        else
            [arr replaceObjectAtIndex:index withObject:object];
    }
}

- (void)removeObjectForProperty:(NSString *)property subindex:(int)index
{
    if ( !property) {
        NSLog(@"** %s: nil property", __func__);
        return;
    }
    id arr = [_dict objectForKey:property];
    
    if ( !arr) {
        NSLog(@"** %s: no objects for property %@ (%i)", __func__, property, index);
        return;
    }
    
    int count = [arr count];
    if (index < 0 || index >= count) {
        NSLog(@"** %s: index out of bounds (%@, %i)", __func__, property, index);
        return;
    }
    
    [arr removeObjectAtIndex:index];
}

- (void)pushObject:(id)object forProperty:(NSString *)property
{
    if ( !object) {
        NSLog(@"** %s: nil object (property: %@)", __func__, property);
        return;
    }
    if ( !property) {
        NSLog(@"** %s: nil property (object: %@)", __func__, object);
        return;
    }
    id arr = [_dict objectForKey:property];
    
    if ( !arr) {
        arr = [NSMutableArray arrayWithObject:object];
        [_dict setObject:arr forKey:property];        
    }
    else {
        [arr addObject:object];
    }
}

- (id)popObjectForProperty:(NSString *)property
{
    if ( !property) {
        NSLog(@"** %s: nil property", __func__);
        return nil;
    }
    id arr = [_dict objectForKey:property];
    
    if ( !arr) {
        NSLog(@"** %s: no objects for property %@", __func__, property);
        return nil;
    }
    else {
        id lastObj = [[arr lastObject] retain];
        [arr removeLastObject];
        return [lastObj autorelease];
    }
}


@end
