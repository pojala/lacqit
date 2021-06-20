//
//  LACBinderNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACBinderNode.h"
#import "LACNode_priv.h"
#import "LACPatch.h"



@implementation LACBinderNode

- (void)_createBindingInterfaceForPatch:(LACPatch *)patch
{
    NSEnumerator *keyEnum;
    NSString *key;

    // create new inputs
    {
        // the "prime input" always exists, so we'll restore the previous connection
        LACOutput *connPatchOut = [[self primeInput] connectedOutput];
        
        NSMutableArray *inputs = [NSMutableArray arrayWithCapacity:16];
        
        // one input is always created: this allows the patch to be connected
        LACInput *primeInput = [[LACInput alloc] initWithName:@"patch" typeKey:[LACPatch lacTypeID]];
        [inputs addObject:[primeInput autorelease]];
        
        // if a patch is connected, create input interface for it
        keyEnum = (patch) ? [patch publishedInputNamesSortedEnumerator] : nil;
        while (key = [keyEnum nextObject]) {
            NSString *type = [[patch publishedInputInterface] objectForKey:key];
            
            NSLog(@"_createBinding for %@: created input '%@'", self, key);
            [inputs addObject:[[[LACInput alloc] initWithName:key typeKey:type] autorelease]];
        }
        [self _setInputs:inputs];    

        [[self primeInput] connectToOutput:connPatchOut];
    }
    
    // same for outputs
    {
        NSMutableArray *outputs = [NSMutableArray arrayWithCapacity:16];
        
        // if a patch is connected, create output interface for it
        keyEnum = (patch) ? [patch publishedOutputNamesSortedEnumerator] : nil;
        while (key = [keyEnum nextObject]) {
            LACOutput *outp = [[patch publishedOutputInterface] objectForKey:key];
            NSString *type = [outp typeKey];
            
            NSLog(@"creating binding interface for %@: created output '%@'", self, key);
            [outputs addObject:[[[LACOutput alloc] initWithName:key typeKey:type] autorelease]];
        }
        [self _setOutputs:outputs];
    }
}

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _createBindingInterfaceForPatch:nil];
    
    return self;
}


- (BOOL)wantsNotificationOnConnectionChange {
    return YES;
}

- (void)connectionDidChangeForInput:(LACInput *)input
{
    int index = [_inputs indexOfObject:input];

    if (index == 0) {
        // pull the patch data from the input
        LACArrayListPtr patchInputList = [_owner node:self requestsEvaluationOfOutput:[[_inputs objectAtIndex:0] connectedOutput]];
        
        LACPatch *patch = (LACPatch *) LACArrayListFirstObject(patchInputList);
        if ( ![patch isKindOfClass:[LACPatch class]])
            patch = nil;
        
        NSLog(@"binder '%@' got patch: %@; interface: %@", [self name], patch, [patch publishedOutputInterface]);
        
        [_owner nodeWillModifyInterface:self];
        [self _createBindingInterfaceForPatch:patch];
        [_owner nodeDidModifyInterface:self];
        
        LACArrayListRelease(patchInputList);
    }
}


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)outputIndex
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)outerCtx
{
    LACPatch *patch = (LACPatch *) LACArrayListFirstObject(inputLists[0]);
    
    if ( !patch || [[[patch publishedOutputInterface] allKeys] count] < 1)
        return LACEmptyArrayList;

    LACArrayListPtr result = NULL;

    NSString *reqOutputBindingName = [[_outputs objectAtIndex:outputIndex] name];
    LACOutput *innerOutput = [patch nodeOutputForOutputBinding:reqOutputBindingName];
    
    if ( !innerOutput) {
        NSLog(@"** nested patch node %@: unable to find output '%@' (patch %@)", self, reqOutputBindingName, patch);
        return LACEmptyArrayList;
    }

    NSMutableDictionary *innerCtx = [[self owner] innerContextFromEvalContext:outerCtx];
    
    // get the input values
    LACArrayListDictionary *inputValuesDict = [LACArrayListDictionary dictionary];
    
    int count = [_inputs count];
    int i;
    for (i = 1; i < count; i++) {
        LACInput *inp = [_inputs objectAtIndex:i];
        NSString *inputName = [inp name];
        
        [inputValuesDict setArrayList:inputLists[i] forKey:inputName];
    }
    
    [innerCtx setObject:inputValuesDict forKey:kLACCtxKey_ExternalInputValues];
    
    result = [patch evaluateOutput:innerOutput withContext:innerCtx];

    return result;
}

@end
