//
//  LACArrayListDictionary.h
//  Lacqit
//
//  Created by Pauli Ojala on 5.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LACArrayList.h"

/*
A dictionary that contains only LACArrayList values with weak-ref NSObject keys
*/

@interface LACArrayListDictionary : NSObject {

    NSMutableDictionary *_dict;
    NSMutableSet *_weakKeys;
}

+ (id)dictionary;
+ (id)dictionaryWithArrayList:(LACArrayListPtr)list forKey:(NSString *)key;

- (void)setArrayList:(LACArrayListPtr)list forKey:(NSString *)key;
- (LACArrayListPtr)arrayListForKey:(NSString *)key;

// a convenience method that creates the array list containing just the object
- (void)setArrayListWithObject:(id)obj forKey:(NSString *)key;

// weak keys are used e.g. to cache an array list by an output pointer, which shouldn't be retained
- (void)setArrayList:(LACArrayListPtr)list forWeakKey:(id)obj;
- (LACArrayListPtr)arrayListForWeakKey:(id)obj;

@end
