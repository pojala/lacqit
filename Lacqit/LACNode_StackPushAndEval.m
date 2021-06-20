//
//  LACNode_StackPushAndEval.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_StackPushAndEval.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACNode_StackPushAndEval

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"list to push" typeKey:nil] autorelease],
                                [[[LACInput alloc] initWithName:@"list to evaluate" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"evaluated list" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}


- (NSDictionary *)upstreamProvidedContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray lacTypeID], kLACCtxKey_Stack,
                                nil];
}

- (NSDictionary *)downstreamWillUseIfAvailableContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray lacTypeID], kLACCtxKey_Stack,
                                nil];
}

+ (BOOL)usesTransientState {
    return YES; }

- (BOOL)wantsPreAndPostEvaluation {
    return YES; }
    
- (BOOL)wantsLazyEvaluationOfInputs {
    return YES; }


- (void)willEvaluateWithContext:(NSMutableDictionary *)context
{
    LACArrayListPtr listToPush = [_owner node:self requestsEvaluationOfOutput:[[_inputs objectAtIndex:0] connectedOutput]];
    const LXInteger listCount = LACArrayListCount(listToPush);
    
    ///NSLog(@"%s: list to push on stack is %@", __func__, LACArrayListDescribe(listToPush));
    
    if (listCount > 0) {
        NSMutableArray *origStack = [context objectForKey:kLACCtxKey_Stack];
        const LXInteger origStackCount = [origStack count];
        NSMutableArray *theStack;
    
        if (origStack) {
            theStack = origStack;
        } else {
            theStack = [NSMutableArray array];
            [context setObject:theStack forKey:kLACCtxKey_Stack];
        }
    
        LXInteger i;
        for (i = 0; i < listCount; i++) {
            [theStack addObject:LACArrayListObjectAt(listToPush, i)];
        }

        _origStack = origStack;
        _theStack = theStack;
        _pushedListCount = listCount;
    }
    
    LACArrayListRelease(listToPush);
    
    // now evaluate the second input
    LACArrayListPtr evalResult = [_owner node:self requestsEvaluationOfOutput:[[_inputs objectAtIndex:1] connectedOutput]];
 
    ///NSLog(@"%s: evaluated list is %@ (upstream node is %@)", __func__, LACArrayListDescribe(evalResult), [[[_inputs objectAtIndex:1] connectedOutput] owner]);
    LACArrayListRelease(evalResult);
}


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr inList = inputLists[1];

    ///NSLog(@"%s: stack is now %@; input list is %@", __func__, _theStack, LACArrayListDescribe(inList));
    
    // we don't need to do anything here, just pass through the evaluated second input
    return LACArrayListRetain(inList);
}


- (void)didEvaluateWithContext:(NSMutableDictionary *)context
{
    // restore stack to its original state
    if (_origStack) {
        //[_origStack removeObjectsInRange:NSMakeRange([_origStack count]-_pushedListCount, _pushedListCount)];
    } else {
        [context removeObjectForKey:kLACCtxKey_Stack];
    }
    
    _origStack = nil;
    _theStack = nil;
    _pushedListCount = 0;
}

@end
