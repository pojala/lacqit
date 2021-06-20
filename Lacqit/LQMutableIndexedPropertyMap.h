//
//  LQMutableIndexedPropertyMap.h
//  PixelMath
//
//  Created by Pauli Ojala on 12.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQIndexedPropertyMap.h"


@interface LQMutableIndexedPropertyMap : LQIndexedPropertyMap {

}

- (void)setObject:(id)object forProperty:(NSString *)property subindex:(int)index;
- (void)removeObjectForProperty:(NSString *)property subindex:(int)index;

- (void)pushObject:(id)object forProperty:(NSString *)property;
- (id)popObjectForProperty:(NSString *)property;

@end
