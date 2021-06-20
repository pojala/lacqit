//
//  LACNode_If.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_If.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACNode_If

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"condition" typeKey:nil] autorelease],
                                [[[LACInput alloc] initWithName:@"if true" typeKey:nil] autorelease],
                                [[[LACInput alloc] initWithName:@"if false" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"result" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}


- (BOOL)wantsPreAndPostEvaluation {
    return YES; }
    
- (BOOL)wantsLazyEvaluationOfInputs {
    return YES; }


- (void)willEvaluateWithContext:(NSMutableDictionary *)context
{
    LACArrayListPtr condList = [_owner node:self requestsEvaluationOfOutput:[[_inputs objectAtIndex:0] connectedOutput]];

    NSLog(@"%s: condList is %p", __func__, condList);

    id condObj = LACArrayListFirstObject(condList);
    BOOL condRes = [self boolValueFromInputObject:condObj evalContext:context];
    
    _conditionState = condRes;
    
    // now eval only one of the incoming connections
    // (we don't do anything with the eval result, but because we specified -wantsLazyEvaluationOfInputs,
    // the patch won't pull this eval for us so it has to be done here)
    LACOutput *outputToBeEvaled = [[_inputs objectAtIndex:((condRes) ? 1 : 2)] connectedOutput];
    
    LACArrayListPtr evalResult = [_owner node:self requestsEvaluationOfOutput:outputToBeEvaled];
    
    NSLog(@"-- %s done: %@ (outp is %@)", __func__, _conditionState ? @"true" : @"false", outputToBeEvaled);
    
    LACArrayListRelease(condList);
    LACArrayListRelease(evalResult);
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)outerCtx
{
    LXInteger selInIndex = (_conditionState) ? 1 : 2;
    
    LACArrayListPtr inList = inputLists[selInIndex];
    LACPatch *patch = (LACPatch *) LACArrayListFirstObject(inList);
    
    LACArrayListPtr newList = NULL;
    if ([patch isKindOfClass:[LACPatch class]]) {
        newList = [self _evalPatch:patch withInputList:nil outerContext:outerCtx];
    }
    
    if (newList)
        return newList;
    else
        return LACArrayListRetain(inList);
}


@end
