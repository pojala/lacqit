//
//  LACBinderNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"

/*
the Binder node is used to evaluate subpatches.

by default, the Binder has a single input of type "patch".
when a patch is connected to the prime input, the Binder will create other inputs and outputs
to match the subpatch's interface.

the Binder is typically used together with "EmbeddedPatch", which is a source node
that contains and outputs a subpatch.
*/

@interface LACBinderNode : LACNode {

}

@end
