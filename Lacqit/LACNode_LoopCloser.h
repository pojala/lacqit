//
//  LACNode_LoopCloser.h
//  Lacqit
//
//  Created by Pauli Ojala on 3.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"
@class LACPatch;

// LoopCloser, also known as "for"


@interface LACNode_LoopCloser : LACNode {

    BOOL _isCollecting;

    LACPatch *_autoclosure;
    
    LXInteger _iterCount;
}

- (void)setIsCollecting:(BOOL)f;
- (BOOL)isCollecting;

@end
