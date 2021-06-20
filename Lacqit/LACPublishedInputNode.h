//
//  LACPublishedInputNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"


@interface LACPublishedInputNode : LACNode {

}

- (id)initWithName:(NSString *)name typeKey:(NSString *)typeKey;

- (NSString *)typeKey;

@end
