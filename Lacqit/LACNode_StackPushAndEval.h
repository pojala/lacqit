//
//  LACNode_StackPushAndEval.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"


@interface LACNode_StackPushAndEval : LACNode {

    NSMutableArray *_origStack;
    NSMutableArray *_theStack;
    int _pushedListCount;
}

@end
