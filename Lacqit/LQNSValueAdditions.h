//
//  LQNSValueAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 17.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface NSValue (LQNSValueAdditions)

+ (NSValue *)valueWithRGBA:(LXRGBA)rgba;
- (LXRGBA)rgbaValue;

@end
