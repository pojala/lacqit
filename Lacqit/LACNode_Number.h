//
//  LACNode_Number.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"


@interface LACNode_Number : LACNode {

    LACArrayListPtr _outList;
}

- (void)setDoubleValue:(double)f;
- (double)doubleValue;

@end
