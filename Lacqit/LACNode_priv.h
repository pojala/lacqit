/*
 *  LACNode_Priv.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 31.8.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LACInput.h"
#import "LACOutput.h"
#import "LACPatch.h"
#import "LACMutablePatch.h"
#import "LACDataMethods.h"
#import "LACArrayListDictionary.h"


@interface LACNode (PrivateToSubclasses)

- (void)_setInputs:(NSArray *)inputs;
- (void)_setOutputs:(NSArray *)outputs;

- (LACArrayListPtr)_evalPatch:(LACPatch *)patch
                     withInputList:(LACArrayListPtr)input
                     outerContext:(NSDictionary *)outerCtx;

@end


@interface LACPatch (CallbacksForNodeEval)

// a node can use this to evaluate another output while inside its own eval/pre-eval method
- (LACArrayListPtr)node:(LACNode *)node requestsEvaluationOfOutput:(LACOutput *)output;

// copies all keys of the given context except private keys
- (NSMutableDictionary *)innerContextFromEvalContext:(NSDictionary *)outerCtx;

@end


@interface LACMutablePatch (ActionInitiatedByNode)

- (void)nodeWillModifyInterface:(LACNode *)node;
- (void)nodeDidModifyInterface:(LACNode *)node;

@end

#define ISARR(_v_)          ([_v_ isKindOfClass:[NSArray class]])


