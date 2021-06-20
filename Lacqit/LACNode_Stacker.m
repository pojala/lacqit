//
//  LACNode_Stacker.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_Stacker.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACNode_Stacker


- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"list to evaluate" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"stack contents" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}


- (NSDictionary *)upstreamProvidedContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray lacTypeID], kLACCtxKey_Stack,
                                nil];
}

+ (BOOL)usesTransientState {
    return YES; }

- (BOOL)wantsPreAndPostEvaluation {
    return YES; }


- (void)willEvaluateWithContext:(NSMutableDictionary *)context
{
    NSMutableArray *theStack;
    
    theStack = [NSMutableArray array];
    [context setObject:theStack forKey:kLACCtxKey_Stack];
    
    _theStack = theStack;
}


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    return LACArrayListCreateWithArray(_theStack);
}


- (void)didEvaluateWithContext:(NSMutableDictionary *)context
{
    [context removeObjectForKey:kLACCtxKey_Stack];
    
    _theStack = nil;
}


@end
