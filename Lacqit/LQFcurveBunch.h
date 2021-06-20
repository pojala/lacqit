//
//  LQFcurveBunch.h
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQFcurve.h"

/*
  This class can be used to represent arbitrary sets of time-varying data,
  e.g. a vertex that has fcurves for x/y/z coordinates and opacity.
*/


@interface LQFcurveBunch : NSObject  <NSCoding, NSCopying> {

    NSMutableDictionary *_dict;
    NSMutableArray *_keys;
    
    id _owner;
}

- (id)owner;
- (void)setOwner:(id)owner;  // by convention, owner is not retained and not persistent (i.e. not encoded or copied)

- (LXUInteger)count;

- (NSArray *)orderedKeys;
- (NSEnumerator *)keyEnumerator;

- (LQFcurve *)fcurveForKey:(NSString *)key;
- (LQFcurve *)fcurveAtIndex:(LXInteger)index;

// the fcurve's "name" property must be set; it will be used as the key.
// if name is nil, a default name will be created containing the curve's index in this bunch.
- (void)addFcurve:(LQFcurve *)fcurve;

- (void)replaceFcurveForKey:(NSString *)key withFcurve:(LQFcurve *)fcurve;
- (void)replaceFcurveForKey:(NSString *)key withFcurve:(LQFcurve *)fcurve newKey:(NSString *)newKey;

- (void)insertFcurve:(LQFcurve *)fcurve withKey:(NSString *)key atIndex:(LXInteger)index;

- (void)removeFcurveAtIndex:(LXInteger)index;


- (void)sortKeysUsingSelector:(SEL)compareSel;
- (void)sortKeysUsingFunction:(LXInteger (*)(id, id, void *))compareFunc context:(void *)context;

@end
