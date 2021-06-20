//
//  LQIndexedPropertyMap.h
//  PixelMath
//
//  Created by Pauli Ojala on 12.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"


@interface LQIndexedPropertyMap : NSObject  <NSCopying, NSMutableCopying> {

    id _dict;
}

+ (LQIndexedPropertyMap *)propertyMap;

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithPropertyMap:(LQIndexedPropertyMap *)propertyMap;

- (int)countForProperty:(NSString *)property;

- (id)objectForProperty:(NSString *)property subindex:(int)index;
- (id)lastObjectForProperty:(NSString *)property;
- (NSArray *)objectsForProperty:(NSString *)property;

@end
