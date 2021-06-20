//
//  LACEmbeddedPatchNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"
@class LACPatch;


@interface LACEmbeddedPatchNode : LACNode {

    LACPatch *_patch;
    
    LACArrayListPtr _outList;
}

- (id)initWithName:(NSString *)name patch:(LACPatch *)patch;

- (void)setPatch:(LACPatch *)patch;
- (LACPatch *)patch;

@end
