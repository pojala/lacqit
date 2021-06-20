//
//  LQOrderedMap.h
//  Lacqit
//
//  Created by Pauli Ojala on 10.7.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LQOrderedMap : NSObject  <NSCoding, NSCopying> {

    NSMutableArray *_values;
    NSMutableArray *_keys;    
}

- (id)initWithCapacity:(NSInteger)capacity;

- (void)setValue:(id)obj forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

- (NSInteger)count;
- (NSEnumerator *)keyEnumerator;
- (NSEnumerator *)valueEnumerator;

- (NSArray *)allKeys;
- (NSArray *)allValues;

- (id)valueAtIndex:(NSInteger)index;

@end
