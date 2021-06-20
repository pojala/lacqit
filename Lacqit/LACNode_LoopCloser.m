//
//  LACNode_LoopCloser.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_LoopCloser.h"
#import "LACNode_priv.h"
#import "LACMutablePatch.h"
#import "LACPatch_autoclosure.h"

#import <Lacefx/LXFPClosure.h>


@implementation LACNode_LoopCloser

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"autoclosure" typeKey:nil] autorelease],
                                [[[LACInput alloc] initWithName:@"iterations" typeKey:[NSNumber lacTypeID]] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"result" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}

- (void)setOwner:(id)owner
{
    if (_owner) {  // remove previous notification request
        [_owner removeNodeObserver:self];
    }
    [super setOwner:owner];
}

- (void)dealloc
{
    [_owner removeNodeObserver:self];
    [_autoclosure release];
    [super dealloc];
}

+ (BOOL)usesTransientState {
    return YES; }

- (void)setIsCollecting:(BOOL)f {
    _isCollecting = f; }
    
- (BOOL)isCollecting {
    return _isCollecting; }


#pragma mark --- notifications from owner ---

- (void)_createAutoClosure
{
    // create a closure from the first input
    LACInput *inp = [_inputs objectAtIndex:0];
    
    [_autoclosure autorelease];
    
    _autoclosure = [[LACPatch alloc] initAsAutoclosureFromOutput:[inp connectedOutput]];
}


- (void)nodesWereModified:(NSSet *)nodes inPatch:(id)patch contextInfo:(NSDictionary *)info
{
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        if (node != self && [self hasUpstreamConnectionToNode:node])
            break;
    }
    
    if (node) {
        // a node was modified that's upstream from us, so it may affect our auto-closure state
        [self _createAutoClosure];
    }
}

- (BOOL)wantsNotificationOnConnectionChange {
    return YES;
}

- (void)connectionDidChangeForInput:(LACInput *)input
{
    LXInteger index = [_inputs indexOfObject:input];

    if (index == 0) {
        BOOL isConn = [input isConnected];
        
        if ( !isConn) {
            [_owner removeNodeObserver:self];
        }
        else {
            [_owner addNodeObserver:self];
            
            [self _createAutoClosure];
        }
    }
}


- (BOOL)wantsPreAndPostEvaluation {
    return YES; }
    
- (BOOL)wantsLazyEvaluationOfInputs {
    return YES; }


- (void)willEvaluateWithContext:(NSMutableDictionary *)context
{
    LACArrayListPtr iterCountList = [_owner node:self requestsEvaluationOfOutput:[[_inputs objectAtIndex:1] connectedOutput]];
    
    id iterCountObj = LACArrayListFirstObject(iterCountList);
    
    LXInteger iterCount = ([iterCountObj isKindOfClass:[NSNumber class]]) ? [iterCountObj intValue]
                                                                          : ([iterCountObj respondsToSelector:@selector(doubleValue)] ? (LXInteger)[iterCountObj doubleValue]
                                                                                                                                      : 0);
    if (iterCount < 1) {
        NSLog(@"** %@: can't loop, itercount is too small (input obj is %@, %@)", self, [iterCountObj class], iterCountObj);
    } else {
        ///NSLog(@"LoopCloser node will eval; got itercount %i", iterCount);
    }

    _iterCount = iterCount;

    LACArrayListRelease(iterCountList);
}


#define ENABLEDEBUGTESTS 0


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACPatch *patch = _autoclosure;
    
    if ( !_autoclosure) {
        patch = (LACPatch *) LACArrayListFirstObject(inputLists[0]);
        
        if ( ![patch isKindOfClass:[LACPatch class]]) {
            NSLog(@"** %@: can't eval with this object (%@)", self, patch);
            return LACEmptyArrayList;
        }
    }
    
    const LXInteger n = _iterCount;
    const BOOL doesCollectResults = NO;  // _isCollecting -- FIXME: implement collection
    
    LACArrayListPtr resultList = NULL;
    if (doesCollectResults)
        resultList = LACArrayListCreateWithObject([NSMutableArray array]);

#if ENABLEDEBUGTESTS
    // included in the loop are some tests that were used to compare performance
    // in LacqitTestAppDelegate's simple loop test.
    // this is the fragment program for the test:
    const char fp[] = "!!LCQfp1.0\n"
                      "ADD r1, s1, 1.0;"
                      "ADD r1, r1, r1;"
                      "END"
                      ;
    LXFPClosurePtr fpc = LXFPClosureCreateWithString(fp, strlen(fp));
#endif

    // the evaluation context
    NSString *patchOutpBindingName = [[patch publishedOutputNamesSortedEnumerator] nextObject];
    LACOutput *innerOutput = [patch nodeOutputForOutputBinding:patchOutpBindingName];
    if ( !patchOutpBindingName || !innerOutput) {
        NSLog(@"%@: can't eval this patch (%@), lacks output bindings (%@, %p)", self, patch, patchOutpBindingName, innerOutput);
        return nil;
    }

    NSString *patchInpBindingName = [[patch publishedInputNamesSortedEnumerator] nextObject];
    if ( !patchInpBindingName) {
        NSLog(@"%@: can't eval this patch (%@), lacks input bindings (%@)", self, patch, patchInpBindingName);
        return nil;
    }

    NSMutableDictionary *innerCtx = [[self owner] innerContextFromEvalContext:context];

    LACArrayListDictionary *inputValuesForPatch = [LACArrayListDictionary dictionary];    
    [innerCtx setObject:inputValuesForPatch forKey:kLACCtxKey_ExternalInputValues];
    
    LACArrayListPtr iterIndexList = LACArrayListCreateWithObject([NSNumber numberWithInt:0]);    
    [inputValuesForPatch setArrayList:iterIndexList forKey:patchInpBindingName];
    
    // we need a Cocoa pool if the loop is long
    NSAutoreleasePool *pool = (n > 6) ? [[NSAutoreleasePool alloc] init] : nil;
    const LXInteger poolCleanupInterval = 4;
    
    LXInteger i;
    for (i = 0; i < n; i++) {
        LACArrayListPtr res = NULL;

        [iterIndexList->nsObj release];
        iterIndexList->nsObj = [[NSNumber numberWithInt:i] retain];

#if ENABLEDEBUGTESTS
        // test 1: using single NS wrapper object (fastest possible)
        if (0) {
            res = [NSArray arrayWithObject:[NSNumber numberWithInt:(i+1)*2]
                        ];
        }

        // test 2: using multiple NS wrapper objects
        if (0) {
            res = [NSArray arrayWithObject:[NSNumber numberWithInt:([[NSNumber numberWithInt:1] intValue] + [iterObj intValue]) + 
                                                ([[NSNumber numberWithInt:1] intValue] + [iterObj intValue])]
                        ];
        }
                        
        // test 2: using fpclosure
        if (0) {
            float fpRes[4];
            float fpInScalar[1] = { (float)i };
            if (0 != LXFPClosureExecute(fpc, fpRes, fpInScalar, 1, NULL, 0)) {
                [NSException raise:NSInternalInconsistencyException format:@"closure failed to execute"];
            }
            res = [NSArray arrayWithObject:[NSNumber numberWithFloat:fpRes[0] ]];
        }
#endif
               
        // full evaluation
        res = [patch evaluateOutput:innerOutput withContext:innerCtx];

        ///NSLog(@".... %i, %@:  eval result %@", i, self, res);
                                                      
        if (doesCollectResults) {
            //[(NSMutableArray *)resultArray addObject:(res) ? res: [NSArray array]];
            // TODO: add new value to resultList
        } else {
            if (i == n-1)
                resultList = LACArrayListRetain(res);
        }

        LACArrayListRelease(res);
        
        if (pool && (i % poolCleanupInterval) == 2) {
            [pool drain];
            pool = [[NSAutoreleasePool alloc] init];
        }
    }

    if (pool)  [pool drain];

    [inputValuesForPatch setArrayList:NULL forKey:patchInpBindingName];
    LACArrayListRelease(iterIndexList);

#if ENABLEDEBUGTESTS
    LXFPClosureDestroy(fpc);
#endif

    return resultList;
}


@end


