//
//  LQNSBezierPathAdditions.h
//  Edo
//
//  Created by Pauli Ojala on 12.12.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface NSBezierPath ( LQNSBezierPathAdditions )

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect rounding:(double)rounding;
+ (NSBezierPath *)bezierPathWithCutCornersRect:(NSRect)rect cornerSize:(double)cornerSize;

+ (NSBezierPath *)roundButtonPathWithRect:(NSRect)rect;

@end
