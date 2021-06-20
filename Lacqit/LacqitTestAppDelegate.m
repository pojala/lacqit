//
//  LacqitTestAppDelegate.m
//  Lacqit
//
//  Created by Pauli Ojala on 23.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LacqitTestAppDelegate.h"

#import <Lacqit/LQCapsuleWrapper.h>
#import "LQCapsuleTypes_priv.h"

#import <Lacqit/LQUUID.h>
#import <Lacqit/LQNSScannerAdditions.h>
#import <Lacqit/LQModelConstants.h>
#import <Lacqit/LACArrayList.h>
#import <Lacqit/LACArrayListDictionary.h>

#import <Lacqit/LACMutablePatch.h>
#import <Lacqit/LACInput.h>
#import <Lacqit/LACNode_ListAppend.h>
#import <Lacqit/LACNode_ListSplitAtFirst.h>
#import <Lacqit/LACNode_If.h>
#import <Lacqit/LACNode_Map.h>
#import <Lacqit/LACNode_Number.h>
#import <Lacqit/LACNode_Stacker.h>
#import <Lacqit/LACNode_StackPushAndEval.h>
#import <Lacqit/LACNode_StackPush.h>
#import <Lacqit/LACNode_StackPop.h>
#import <Lacqit/LACBinderNode.h>
#import <Lacqit/LACDelegatingNode.h>
#import <Lacqit/LACEmbeddedPatchNode.h>
#import <Lacqit/LACParser.h>

#import "LQStreamPatch.h"
#import "LQStreamSource.h"
#import "LQStreamRenderer.h"
#import "LQDummyStreamPresenter.h"


@implementation LacqitTestAppDelegate

- (BOOL)runArrayListTest
{
    LACArrayListPtr arrList = LACArrayListCreateWithObjects(@"1", @"2", @"3", @"4", @"5", nil);
                                                            
    NSLog(@"%s: arrlist count %i; first node count %i; item at index 2: '%@'  (exp 5, 1, '3')", __func__,
                LACArrayListCount(arrList), arrList->count, LACArrayListObjectAt(arrList, 2));
                
    LACArrayListPtr arrList2 = LACArrayListCreateWithObjects(@"20", @"21", @"22", @"23", @"24",
                                                             @"25", @"26", @"27", @"28", @"29", @"30", nil);

    LACArrayListLastNode(arrList, NULL)->next = arrList2;

    NSLog(@"%s: arrlist count %i; second node count %i; item at index 8: '%@'  (exp 16, 11, '23')", __func__,
                LACArrayListCount(arrList), arrList2->count, LACArrayListObjectAt(arrList, 8)); 
                
    return (LACArrayListCount(arrList) == 16) ? YES : NO;
}

- (BOOL)runScannerAdditionsTest
{
    NSString *testStr = @"  [ abc, 123  , \"this has a space\", [ sublist1, sublist2, \"sub list 3\" ]  ,   lastItem  ]  ";
    NSScanner *scanner = [NSScanner scannerWithString:testStr];
    NSArray *arr = nil;

    BOOL ok = [scanner scanPossiblyNestedListOfLiteralsIntoArray:&arr
                        listStartCharacter:'['
                        listEndCharacter:']'
                        separatorCharacter:','];
                        
    NSLog(@"scanner result %@, is:\n%@", (ok ? @"true" : @"false"), arr);
    
    NSString *testStr2 = @"   \"just a literal\"  ";
    scanner = [NSScanner scannerWithString:testStr2];
    ok = [scanner scanPossiblyNestedListOfLiteralsIntoArray:&arr
                        listStartCharacter:'['
                        listEndCharacter:']'
                        separatorCharacter:','];
                        
    NSLog(@"scanner result %@, is:\n%@", (ok ? @"true" : @"false"), arr);
    
    return ok;
}

/*
- (BOOL)runLacParserTest
{
    NSString *testStr = @"   Patch   \"main patch, with \\\"escaped quote\" ( abc: 123     , "
                                                                             "def: \n 456 , \n"
                                                                    "bindOut: stackRoot as \"stacker output\")   { \n"
                         "       Stacker \"name for stacker node\" \n"
                         "       Number (value: 1.44) \n"
                         "       Patch \"embPatch\" { \n"
                         "          StackPush \"push\"  \n"
                         "          StackPop \"pop\" <- push \n"
                         "          If \"if\" \n"
                         "          if.2 <- pop \n"
                         "          \"if.if true\" <- [push, \"pop pop pop\"] \n"
                         "       } \n"
                         "   }";
    
    [[LACParser alloc] parseLacString:testStr];
    
    ///[self runScannerAdditionsTest];
    return YES;
}
*/
- (BOOL)runLacParserTest_1
{
    NSString *testStr = @"   Func 'main' (bindOutAt: summaaja as 'main output') { \n"
                         "      Number 'eka' (doubleValue: 1.44) \n"
                         "      Number 'toka' (doubleValue: 2.03) \n"
                         "      Sum 'summaaja' <- [eka, toka] \n"
                         "   } \n";
                         
    LACParser *parser = [LACParser alloc];
    NSArray *parsed = [parser parseLacString:testStr];
    [parser release];
    
    if ([parsed count] > 0) {
        LACPatch *patch = [parsed objectAtIndex:0];
        
        NSLog(@"summaaja output obj is: %@", [[patch nodeNamed:@"summaaja"] primeOutput]);
        NSLog(@"patch's published interface is: %@", [patch publishedOutputInterface]);
        
        LACArrayListPtr result = [patch evaluateOutput://[[patch nodeNamed:@"summaaja"] primeOutput]
                                                       [[patch publishedOutputInterface] objectForKey:[[patch publishedOutputNamesSortedEnumerator] nextObject]]
                                            withContext:nil];
        
        if (LACArrayListCount(result) > 0 && [LACArrayListFirstObject(result) doubleValue] == (1.44 + 2.03)) {
            NSLog(@"%s: success!\n    result is: %@", __func__, LACArrayListDescribe(result));

            LACArrayListRelease(result);
            return YES;
        } else
            NSLog(@"*** FAIL *** %s, patch result: %@ (expected 1-unit list of 3.47)", __func__, LACArrayListDescribe(result));
    }
    return NO;
}

- (BOOL)runLacParserTest_2
{
/*
    NSString *testStr = @"   Func 'main' (bindOutAt: summaaja as 'main output') { \n"
                         "      Number 'eka' (doubleValue: 1.44) \n"
                         "      Number 'toka' (doubleValue: 2.03) \n"
                         "      Sum 'summaaja' <- [eka, toka] \n"
                         "   } \n";
*/
    NSString *testStr = @"   Func 'main' (bindOutAt: binder) { \n"
                         "      Func 'subpatch' (bindInAs: in1, bindOutAt: summaaja) { \n"
                         "          Number 'toka' (doubleValue: 2.03) \n"
                         "          Sum 'summaaja' \n"
                         "          summaaja.0 <- in1 \n"
                         "          summaaja.1 <- toka \n"
                         "      } \n"
                         "      Number 'eka' (doubleValue: 1.44) \n"
                         "      Bind 'binder' <- subpatch \n"
                         "      binder.1 <- eka \n"
                         "   } \n";
                         
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LACParser *parser = [LACParser alloc];
    NSArray *parsed = [parser parseLacString:testStr];
    [parser release];
    
    BOOL retVal = NO;
    if ([parsed count] > 0) {
        LACPatch *patch = [parsed objectAtIndex:0];
        
        NSLog(@"patch's published output for expected key 'binder' is: %@", [[patch publishedOutputInterface] objectForKey:@"binder"]);
        
        LACArrayListPtr result = [patch evaluateOutput://[[patch nodeNamed:@"binder"] primeOutput]
                                                        [[patch publishedOutputInterface] objectForKey:[[patch publishedOutputNamesSortedEnumerator] nextObject]]
                                            withContext:nil];
        
        if (LACArrayListCount(result) > 0 && [LACArrayListFirstObject(result) doubleValue] == (1.44 + 2.03)) {
            NSLog(@"%s: success!\n    result is: %@", __func__, LACArrayListDescribe(result));
            retVal = YES;
        } else {
            NSLog(@"*** FAIL *** %s, patch result: %@ (expected 1-unit list of 3.47)", __func__, LACArrayListDescribe(result));
        }
        LACArrayListRelease(result);
    }
    [pool drain];
    return retVal;
}

- (BOOL)runLacParserTest_3_loop
{
    NSString *testStr = @"   Func 'main' (bindInAs: iterCount, bindOutAt: theLoop) { \n"
                         "        Open 'i' \n"
                         "        Sum 'addToOne' <- [i, i] \n"
                         "        Sum 'add' <- [addToOne, addToOne] \n"
                         "      LoopCloser 'theLoop' <- [add, iterCount] (isCollecting: false) \n"

                         "      Number 'yksi' (doubleValue: 1.0) \n"
                         "      addToOne <- [i, yksi] \n"  // this should trigger the autoclosure in 'theLoop' to re-close (otherwise this test's result would be 32)
                         "   } \n";

    LACParser *parser = [LACParser alloc];
    NSArray *parsed = [parser parseLacString:testStr];
    [parser release];
    
    BOOL retVal = NO;
    if ([parsed count] > 0) {
        LACPatch *patch = [parsed objectAtIndex:0];
        
        const int iterCount = 500;
        LACArrayListPtr iterCountList = LACArrayListCreateWithObject([NSNumber numberWithInt:iterCount]);        
        LACArrayListDictionary *inputValuesForPatch = [LACArrayListDictionary dictionary];
        [inputValuesForPatch setArrayList:iterCountList forKey:@"iterCount"];
        
        NSDictionary *evalCtx = [NSDictionary dictionaryWithObject:inputValuesForPatch forKey:kLACCtxKey_ExternalInputValues];
        
        double t0 = LQReferenceTimeGetCurrent();
        
        LACArrayListPtr result = [patch evaluateOutput://[[patch nodeNamed:@"theLoop"] primeOutput]
                                                        [[patch publishedOutputInterface] objectForKey:[[patch publishedOutputNamesSortedEnumerator] nextObject]]
                                            withContext:evalCtx];
        
        double spentMs = (LQReferenceTimeGetCurrent() - t0) * 1000.0;
        
        LACArrayListRelease(iterCountList);
        
        // timings (50000 iters): 2200-2400 ms for full eval version
        //                        60-70 ms for simplest nsarray version
        //                        100-110 ms for multiple nsarray version
        //                        80-100 ms for fpclosure version
        //                        --
        //                        800-900 ms for new LACArrayList eval version (2009.01.05)
        
        //f ([result count] > 0 && [[result lastObject] intValue] == (iterCount * 2)) {
        if (LACArrayListCount(result) > 0 && [LACArrayListLastObject(result) intValue] == (iterCount * 2)) {
            NSLog(@"%s: success!\n   time: %.3f ms", __func__, spentMs);
            retVal = YES;
        } else {
            NSLog(@"*** FAIL *** %s, patch result: %@", __func__, LACArrayListDescribe(result));
        }
        LACArrayListRelease(result);
    }
    return retVal;

}

- (BOOL)runLacParserTest_4_stackLoop
{
    NSString *testStr = @"   Func 'main' (bindInAs: iterCount, bindOutAt: stacker) { \n"
                         "        Open 'i' \n"
                         "        StackPop 'fromStack' \n"
                         "        Number 'one' (doubleValue: 1.0) \n"
                         "        Sum 'i+one' <- [i, one] \n"
                         "        Sum 'finalSum' <- [i+one, fromStack] \n"
                         "        StackPush 'backToStack' <- finalSum \n"
                         "      LoopCloser 'theLoop' <- [backToStack, iterCount] (isCollecting: false) \n"

                         "      Number 'stackBaseValue' (doubleValue: 100.2) \n"
                         
                         "      StackPushAndEval 'run-loop-on-stack' <- [stackBaseValue, theLoop] \n"
                         "      Stacker 'stacker' <- run-loop-on-stack (centerPoint: [100, 100]) \n"
                         "   } \n";

    LACParser *parser = [LACParser alloc];
    NSArray *parsed = [parser parseLacString:testStr];
    [parser release];

    BOOL retVal = NO;
    if ([parsed count] > 0) {
        LACPatch *patch = [parsed objectAtIndex:0];
        
        ///NSLog(@"%s: patch output for 'stacker': %@  (patch is %@)", __func__, [[patch publishedOutputInterface] objectForKey:@"stacker"], patch);
        
        const int iterCount = 30;
        LACArrayListPtr iterCountList = LACArrayListCreateWithObject([NSNumber numberWithInt:iterCount]);        
        LACArrayListDictionary *inputValuesForPatch = [LACArrayListDictionary dictionary];        
        [inputValuesForPatch setArrayList:iterCountList forKey:@"iterCount"];
    
        NSDictionary *evalCtx = [NSDictionary dictionaryWithObject:inputValuesForPatch forKey:kLACCtxKey_ExternalInputValues];
        
        LACOutput *outputToEval = [[patch publishedOutputInterface] objectForKey:[[patch publishedOutputNamesSortedEnumerator] nextObject]];
                                  //[[patch nodeNamed:@"theLoop"] primeOutput];
        
        double t0 = LQReferenceTimeGetCurrent();
        
        LACArrayListPtr result;
        //LXInteger j = 0;
        //for (j = 0; j < 50; j++)
        result = [patch evaluateOutput:outputToEval withContext:evalCtx];
        
        double spentMs = (LQReferenceTimeGetCurrent() - t0) * 1000.0;
        
        LACArrayListRelease(iterCountList);
        
        if (LACArrayListCount(result) > 0 && [LACArrayListFirstObject(result) respondsToSelector:@selector(doubleValue)] 
                    && [LACArrayListFirstObject(result) doubleValue] == 565.2) {
            NSLog(@"%s: success\n   result list: %@\n    time: %.3f ms", __func__, LACArrayListDescribe(result), spentMs);
            retVal = YES;
        } else {
            NSLog(@"*** FAIL *** %s, patch result: %@", __func__, LACArrayListDescribe(result));
        }
        LACArrayListRelease(result);
    }
    return retVal;

}


#pragma mark --- capsule tests ---

static BOOL runProtectedCapsuleFileIOTest()
{
    char testStr[19] = "0123456789abcdEFGH";
    
    NSURL *testURL = [NSURL fileURLWithPath:@"/Users/pauli/testcapsule.lqp"];

    CFUUIDBytes uuidBytes = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };
    LQUUID *testUuid = [LQUUID uuidFromUUIDBytes:uuidBytes];
    
    // write to disk
    if (1) {
        NSData *data = [NSData dataWithBytes:testStr length:18];
    
        LQCapsuleParameterSpec blob;
        blob.creatorUUID = testUuid;
    
        LQCapsuleWrapper *capsule = [[LQCapsuleWrapper alloc] initWithData:data spec:&blob];
    
        if ([capsule writeToURL:testURL format:kLQCapsuleProtectedFormat]) {
            NSLog(@"%s: successfully wrote protected capsule to disk", __func__);
        } else {
            NSLog(@"*** %s failed ***  couldn't write capsule to disk", __func__);
            return NO;
        }
    }
    
    // read from disk
    if (1) {
        NSError *error = NULL;
        LQCapsuleWrapper *capsule = [LQCapsuleWrapper decodeCapsuleFromURL:testURL error:&error];
        if ( !capsule) {
            NSLog(@"** decoding error: %@", error);
            return NO;
        } else {
            char outTest[19];
            memset(&outTest, 0, 19);
            
            [[capsule data] getBytes:outTest length:18];
            
            if (0 == memcmp(testStr, outTest, 18) && [[capsule creatorUUID] isEqualToUUID:testUuid]) {
                NSLog(@"%s: success! decoded data matches (%@)", __func__, [capsule creatorUUID]);
            } else {
                NSLog(@"*** %s failed ***  (decoded data length: %i, string: %s; uuid: %@)", __func__, [[capsule data] length], outTest, [capsule creatorUUID]);
            }
            
            if (0 != strncmp(testStr, outTest, 18)) {
                NSLog(@"** decoded data doesn't match (%s, %s)", testStr, outTest);
                return NO;
            }
        }
    }
    return YES;
}



#pragma mark --- lac node tests (disabled) ---

#if 0

- (LACArrayListPtr)willEvaluateFuncNode:(LACNode *)fnode
                        proposedResult:(LACArrayListPtr)proposedResult
                        outputIndex:(LXInteger)outputIndex
                        inputLists:(LACArrayListPtr *)inputLists
                        context:(NSDictionary *)context
{
    NSString *nodeName = [fnode name];
    NSLog(@"will evaluate delegated node '%@', index %i", nodeName, outputIndex);
    
    id retVal = nil;
    
    if ([nodeName isEqual:@"TestNode_NumberOutput"]) {
        retVal = [NSNumber numberWithDouble:2.45123];
    }
/*    else if ([nodeName isEqual:@"TestNode_Append"]) {
        NSArray *inList1 = [inputs objectAtIndex:0];
        NSArray *inList2 = [inputs objectAtIndex:1];
    
        retVal = [inList1 arrayByAddingObjectsFromArray:inList2];
    }*/
    else if ([nodeName isEqual:@"TestNode_Increment"]) {
        NSArray *inList1 = [inputs objectAtIndex:0];
        id val1 = [inList1 objectAtIndex:0];
        double d = ([val1 respondsToSelector:@selector(doubleValue)]) ? [val1 doubleValue]
                                                                      : [[val1 description] doubleValue];
        retVal = [NSNumber numberWithDouble:(1.0 + d)];
    }
    else if ([nodeName isEqual:@"TestNode_SumArray"]) {
        NSArray *inList1 = [inputs objectAtIndex:0];
        
        double sum = 0;
        NSEnumerator *enumerator = [inList1 objectEnumerator];
        id val;
        while (val = [enumerator nextObject]) {
            sum += [val doubleValue];
        }
        
        retVal = [NSNumber numberWithDouble:sum];
    }
    else if ([nodeName isEqual:@"TestNode_NumberToString"]) {
        NSArray *inList1 = [inputs objectAtIndex:0];
        id val1 = [inList1 objectAtIndex:0];
        
        retVal = [NSString stringWithFormat:@"Processed by node: %@", [val1 description]];
    }
    else if ([nodeName isEqual:@"TestNode_LogIntoContext"]) {
        NSArray *inList1 = [inputs objectAtIndex:0];
        id val1 = [inList1 objectAtIndex:0];
        
        NSMutableArray *logList = [context objectForKey:@"logList"];
        
        [logList addObject:val1];
        
        retVal = val1;
    }
    
    //return ([retVal isKindOfClass:[NSArray class]]) ? retVal : [NSArray arrayWithObject:retVal];
    return LACArrayListCreateWithObject(retVal);
}

- (LACPatch *)doubleIncrementerPatch
{
    LACMutablePatch *patch = [[LACMutablePatch alloc] init];
    [patch setName:[NSString stringWithFormat:@"%s", __func__]];

    LACDelegatingNode *fnode1 = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Increment"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [fnode1 setDelegate:self];
    [patch addNode:fnode1];

    LACDelegatingNode *fnode2 = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Increment"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [fnode2 setDelegate:self];
    [patch addNode:fnode2];

    [patch addInputBindingWithType:nil forKey:@"extInput"];
    LACOutput *extOut = [patch outputForInputBinding:@"extInput"];

    [[fnode1 primeInput] connectToOutput:[fnode2 primeOutput]];
    [[fnode2 primeInput] connectToOutput:extOut];
    
    [patch setOutputBinding:[fnode1 primeOutput] forKey:@"patchExportedOutput"];
    
    return [patch autorelease];
}

- (LACPatch *)tripleAppenderPatch
{
    LACMutablePatch *patch = [[LACMutablePatch alloc] init];
    [patch setName:[NSString stringWithFormat:@"%s", __func__]];
 
     LACNode *fnodeAppend1 = [[LACNode_ListAppend alloc] initWithName:@"AppendNode1"];
     LACNode *fnodeAppend2 = [[LACNode_ListAppend alloc] initWithName:@"AppendNode2"];

    [patch addNode:fnodeAppend1];     
    [patch addNode:fnodeAppend2];

    [patch addInputBindingWithType:nil forKey:@"extInput1"];
    [patch addInputBindingWithType:nil forKey:@"extInput2"];
    [patch addInputBindingWithType:nil forKey:@"extInput3"];
    
    LACOutput *extOut1 = [patch outputForInputBinding:@"extInput1"];
    LACOutput *extOut2 = [patch outputForInputBinding:@"extInput2"];
    LACOutput *extOut3 = [patch outputForInputBinding:@"extInput3"];
    
    [[[fnodeAppend1 inputs] objectAtIndex:0] connectToOutput:extOut1];
    [[[fnodeAppend1 inputs] objectAtIndex:1] connectToOutput:[fnodeAppend2 primeOutput]];

    [[[fnodeAppend2 inputs] objectAtIndex:0] connectToOutput:extOut2];
    [[[fnodeAppend2 inputs] objectAtIndex:1] connectToOutput:extOut3];

    [patch setOutputBinding:[fnodeAppend1 primeOutput] forKey:@"patchExportedOutput"];
    
    return [patch autorelease];
}

- (void)runNestedPatchTest
{
    LACPatch *trPatch = [self tripleAppenderPatch];
    
    NSDictionary *inputValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSArray arrayWithObjects:@"1", @"2", @"3", nil],  @"extInput1",
                                        [NSArray arrayWithObjects:@"a", @"b", @"c", nil],  @"extInput2",
                                        [NSArray arrayWithObjects:@"x", @"y", @"z", nil],  @"extInput3",
                                        nil];
    
    NSDictionary *evalCtx = [NSDictionary dictionaryWithObjectsAndKeys:
                                        inputValues, @"__externalInputValues__",
                                        nil];

    id result;
    result = [trPatch evaluateOutput:[trPatch nodeOutputForOutputBinding:@"patchExportedOutput"] withContext:evalCtx];
    
    NSLog(@"result: %@", result);
    
    LACPatch *copyPatch = [trPatch copy];
    NSLog(@"copied patch: %@", copyPatch);
    
    result = [trPatch evaluateOutput:[trPatch nodeOutputForOutputBinding:@"patchExportedOutput"] withContext:evalCtx];
    
    NSLog(@"result from copy: %@", result);
//---
    LACMutablePatch *topPatch = [[LACMutablePatch alloc] init];
    [topPatch setName:@"testPatch"];

    LACBinderNode *spNode = [[LACBinderNode alloc] initWithName:@"testNested" patch:trPatch];  // OUTDATED
    
    [topPatch addNode:spNode];
    
    LACDelegatingNode *fnodeNum = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_NumberOutput"
                                        inputsDesc:nil
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"number output", kLQMetadata_Name,
                                                                                    @"NSNumber", kLQMetadata_SystemTypeName,
                                                                                    nil], nil]
                                    ];
    [fnodeNum setDelegate:self];
    [topPatch addNode:fnodeNum];
    
    [[[spNode inputs] objectAtIndex:0] connectToOutput:[fnodeNum primeOutput]];
    [[[spNode inputs] objectAtIndex:1] connectToOutput:[fnodeNum primeOutput]];
    [[[spNode inputs] objectAtIndex:2] connectToOutput:[fnodeNum primeOutput]];
    
    result = [topPatch evaluateOutput:[spNode primeOutput] withContext:nil];
    
    NSLog(@"result from subpatch eval: %@", result);
}

- (void)runStackPatchTest
{
    LACMutablePatch *patch = [[LACMutablePatch alloc] init];
    [patch setName:@"stackTestPatch"];

    LACNode_Number *numNode1 = [[LACNode_Number alloc] initWithName:@"numNode1"];
    [numNode1 setDoubleValue:3.4];

    LACNode_Number *numNode2 = [[LACNode_Number alloc] initWithName:@"numNode2"];
    [numNode2 setDoubleValue:2.1];

    [patch addNode:numNode1];
    [patch addNode:numNode2];

    LACNode_StackPushAndEval *stackNode = [[LACNode_StackPushAndEval alloc] initWithName:@"stackPushEval"];
    [patch addNode:stackNode];

    
    LACDelegatingNode *incNode = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Increment"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [incNode setDelegate:self];
    [patch addNode:incNode];

    LACNode_StackPush *stackPush1 = [[LACNode_StackPush alloc] initWithName:@"push1"];
    LACNode_StackPush *stackPush2 = [[LACNode_StackPush alloc] initWithName:@"push2"];
    LACNode_StackPush *stackPush3 = [[LACNode_StackPush alloc] initWithName:@"push3"];
    [patch addNode:stackPush1];
    [patch addNode:stackPush2];
    [patch addNode:stackPush3];

    LACNode_StackPop *stackPopNode = [[LACNode_StackPop alloc] initWithName:@"stackPop"];
    [patch addNode:stackPopNode];

    
    [[[stackNode inputs] objectAtIndex:0] connectToOutput:[numNode1 primeOutput]];
    
    [[[stackNode inputs] objectAtIndex:1] connectToOutput:[stackPush1 primeOutput]];

    [[stackPush1 primeInput] connectToOutput:[stackPush2 primeOutput]];
    [[stackPush2 primeInput] connectToOutput:[stackPush3 primeOutput]];
    [[stackPush3 primeInput] connectToOutput:[incNode primeOutput]];
    [[incNode primeInput] connectToOutput:[stackPopNode primeOutput]];

    //NSArray *result = [patch evaluateOutput:[stackNode primeOutput] withContext:nil];


    LACNode_Stacker *stackRootNode = [[LACNode_Stacker alloc] initWithName:@"stackCreate"];
    [patch addNode:stackRootNode];
    
    [[stackRootNode primeInput] connectToOutput:[stackNode primeOutput]];

    NSArray *result = [patch evaluateOutput:[stackRootNode primeOutput] withContext:nil];    
    
    NSLog(@"result from stackNode eval: %@", result);
}


- (LACMutablePatch *)runNestedStackPatchTest
{
    LACMutablePatch *subpatch = [[LACMutablePatch alloc] init];
    [subpatch setName:@"subpatch"];
    
    LACDelegatingNode *incNode = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Increment"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [incNode setDelegate:self];
    [subpatch addNode:incNode];

    LACNode_StackPush *stackPush1 = [[LACNode_StackPush alloc] initWithName:@"push1"];
    LACNode_StackPush *stackPush2 = [[LACNode_StackPush alloc] initWithName:@"push2"];
    LACNode_StackPush *stackPush3 = [[LACNode_StackPush alloc] initWithName:@"push3"];
    [subpatch addNode:stackPush1];
    [subpatch addNode:stackPush2];
    [subpatch addNode:stackPush3];

    LACNode_StackPop *stackPopNode = [[LACNode_StackPop alloc] initWithName:@"stackPop"];
    [subpatch addNode:stackPopNode];
    
    
    [[stackPush1 primeInput] connectToOutput:[stackPush2 primeOutput]];
    [[stackPush2 primeInput] connectToOutput:[stackPush3 primeOutput]];
    [[stackPush3 primeInput] connectToOutput:[incNode primeOutput]];
    [[incNode primeInput] connectToOutput:[stackPopNode primeOutput]];
    
    [subpatch setOutputBinding:[stackPush1 primeOutput] forKey:@"patch output"];
    
    
    LACMutablePatch *topPatch = [[LACMutablePatch alloc] init];
    [topPatch setName:@"stackerPatch"];
    
    LACNode_Stacker *stackRootNode = [[LACNode_Stacker alloc] initWithName:@"stacker"];
    [topPatch addNode:stackRootNode];

    LACNode_Number *numNode2 = [[LACNode_Number alloc] initWithName:@"numNode2"];
    [numNode2 setDoubleValue:2.1];
    [topPatch addNode:numNode2];

    LACNode_StackPushAndEval *stackAddNode = [[LACNode_StackPushAndEval alloc] initWithName:@"stackPushEval"];
    [topPatch addNode:stackAddNode];
    
    LACBinderNode *subpatchNode = [[LACBinderNode alloc] initWithName:@"stackManipSubpatch" patch:subpatch];  // OUTDATED
    [topPatch addNode:subpatchNode];

    [[stackRootNode primeInput] connectToOutput:[stackAddNode primeOutput]];
    
    [[[stackAddNode inputs] objectAtIndex:0] connectToOutput:[numNode2 primeOutput]];
    [[[stackAddNode inputs] objectAtIndex:1] connectToOutput:[subpatchNode primeOutput]];

    NSArray *result = [topPatch evaluateOutput:[stackRootNode primeOutput] withContext:nil];    
    NSLog(@"%s: result from stacker eval: %@ (expecting 3-unit list of value 3.1)", __func__, result);


    [topPatch setOutputBinding:[stackRootNode primeOutput] forKey:@"stackerOutput"];
    
    ///LACEmbeddedPatchNode *embNode = [[LACEmbeddedPatchNode alloc] initWithName:@"embSubpatch" patch:subpatch];
    return topPatch;
}


- (void)runPatchMapTest
{
    LACMutablePatch *listMakerPatch = [self runNestedStackPatchTest];
    
    LACMutablePatch *topPatch = [[LACMutablePatch alloc] init];
    [topPatch setName:@"mapperPatch"];

    LACBinderNode *subpatchNode = [[LACBinderNode alloc] initWithName:@"listPatch" patch:listMakerPatch];  // OUTDATED
    [topPatch addNode:subpatchNode];
    
    
    LACMutablePatch *incPatch = [[LACMutablePatch alloc] init];
    [incPatch setName:@"incrementerPatch"];
    
    LACDelegatingNode *incNode = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Increment"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [incNode setDelegate:self];
    [incPatch addNode:incNode];
    
    [incPatch addInputBindingWithType:nil forKey:@"external input"];
    [incPatch setOutputBinding:[incNode primeOutput] forKey:@"incremented output"];

    [[incNode primeInput] connectToOutput:[incPatch outputForInputBinding:@"external input"]];
    
    
    LACEmbeddedPatchNode *embNode = [[LACEmbeddedPatchNode alloc] initWithName:@"embeddedPatchNode" patch:incPatch];
    [topPatch addNode:embNode];
    
    
    LACNode_Map *mapNode = [[LACNode_Map alloc] initWithName:@"mapper"];
    [topPatch addNode:mapNode];
    
    [[[mapNode inputs] objectAtIndex:0] connectToOutput:[subpatchNode primeOutput]];
    [[[mapNode inputs] objectAtIndex:1] connectToOutput:[embNode primeOutput]];
    
    NSArray *result = [topPatch evaluateOutput:[mapNode primeOutput] withContext:nil];    
    NSLog(@"%s: result from mapping eval: %@ (expecting 3-unit list of value 4.1)", __func__, result);
}


- (void)runIfNodeTest
{
    NSArray *result;
    LACMutablePatch *patch = [[LACMutablePatch alloc] init];
    [patch setName:@"ifPatch"];

    LACNode_Number *numNode1 = [[LACNode_Number alloc] initWithName:@"numNode1"];
    [numNode1 setDoubleValue:3.4];
    [patch addNode:numNode1];

    LACNode_Number *numNode2 = [[LACNode_Number alloc] initWithName:@"numNode2"];
    [numNode2 setDoubleValue:2.1];
    [patch addNode:numNode2];

    LACNode_Number *numNode3 = [[LACNode_Number alloc] initWithName:@"numNode3"];
    [numNode3 setDoubleValue:5.5];
    [patch addNode:numNode3];
    
    LACNode_If *ifNode = [[LACNode_If alloc] initWithName:@"if"];
    [patch addNode:ifNode];    
    
    [[[ifNode inputs] objectAtIndex:0] connectToOutput:[numNode3 primeOutput]];
    [[[ifNode inputs] objectAtIndex:1] connectToOutput:[numNode1 primeOutput]];
    [[[ifNode inputs] objectAtIndex:2] connectToOutput:[numNode2 primeOutput]];
    
    result = [patch evaluateOutput:[ifNode primeOutput] withContext:nil];
    NSLog(@"if simple test: %@ (expected 1-unit list of value 3.4)", result);
    
    
    LACMutablePatch *listMakerPatch = [self runNestedStackPatchTest];
    
    LACEmbeddedPatchNode *embNode = [[LACEmbeddedPatchNode alloc] initWithName:@"listMakerPatch" patch:listMakerPatch];
    [patch addNode:embNode];
    
    [[[ifNode inputs] objectAtIndex:0] connectToOutput:[embNode primeOutput]];
    [[[ifNode inputs] objectAtIndex:1] connectToOutput:[embNode primeOutput]];
    
    result = [patch evaluateOutput:[ifNode primeOutput] withContext:nil];
    NSLog(@"if patch test: %@", result);
}


- (void)runFuncPatchTest
{
    LACMutablePatch *patch = [[LACMutablePatch alloc] init];
    [patch setName:@"testPatch"];

    LACDelegatingNode *fnode1 = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_NumberToString"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"string output", kLQMetadata_Name,
                                                                                    @"NSString", kLQMetadata_SystemTypeName,
                                                                                    nil], nil]
                                    ];
    [fnode1 setDelegate:self];
    [patch addNode:fnode1];

    LACDelegatingNode *fnodeNum = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_NumberOutput"
                                        inputsDesc:nil
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"number output", kLQMetadata_Name,
                                                                                    @"NSNumber", kLQMetadata_SystemTypeName,
                                                                                    nil], nil]
                                    ];
    [fnodeNum setDelegate:self];
    [patch addNode:fnodeNum];

/*
    LACDelegatingNode *fnodeAppend = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_Append"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input 1", kLQMetadata_Name,
                                                                                    nil], 
                                                                             [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input 2", kLQMetadata_Name,
                                                                                    nil], 
                                                                    nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [fnodeAppend setDelegate:self];
*/
    LACNode *fnodeAppend = [[LACNode_ListAppend alloc] initWithName:@"AppendNode"];
    [patch addNode:fnodeAppend];


    LACDelegatingNode *fnodeSum = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_SumArray"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
    [fnodeSum setDelegate:self];
    [patch addNode:fnodeSum];

    
    [[fnode1 primeInput] connectToOutput:[fnodeSum primeOutput]];
    [[fnodeSum primeInput] connectToOutput:[fnodeAppend primeOutput]];
    
    [[[fnodeAppend inputs] objectAtIndex:0] connectToOutput:[fnodeNum primeOutput]];
    [[[fnodeAppend inputs] objectAtIndex:1] connectToOutput:[fnodeNum primeOutput]];


    // testnode that uses context
    LACDelegatingNode *fnodeC1 = [[LACDelegatingNode alloc]
                                        initWithName:@"TestNode_LogIntoContext"
                                        inputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"input", kLQMetadata_Name,
                                                                                    nil], nil]
                                        outputsDesc:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    @"output", kLQMetadata_Name,
                                                                                    nil], nil]
                                    ];
                                    
    [fnodeC1 setDownstreamRequiredContext:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"NSMutableArray", @"logList",
                                                    nil]];
    [fnodeC1 setDelegate:self];
    [patch addNode:fnodeC1];

    [[[fnodeC1 inputs] objectAtIndex:0] connectToOutput:[fnode1 primeOutput]];
    
    NSLog(@"mutable patch node count is %i:\n%@", [[patch allNodes] count], [patch allNodes]);
    
    NSMutableArray *logList = [NSMutableArray array];
    NSDictionary *evalCtx = [NSDictionary dictionaryWithObjectsAndKeys:
                                                logList, @"logList",
                                                nil];
    
    NSDictionary *nodeMapping = nil;
    LACPatch *immutablePatch = [patch deepCopyWithAppliedMappingPtr:&nodeMapping];
    
    NSLog(@"copied patch is %@, nodecount %i", immutablePatch, [[immutablePatch allNodes] count]);
    NSLog(@"node mapping: %@", nodeMapping);
    
    id copyOfNodeC1 = [nodeMapping objectForKey:[NSValue valueWithPointer:fnodeC1]];
    NSAssert(copyOfNodeC1, @"copy failed");
    
    NSArray *result = [immutablePatch evaluateOutput:[[copyOfNodeC1 outputs] objectAtIndex:0] withContext:evalCtx];
    
    result = [immutablePatch evaluateOutput:[[copyOfNodeC1 outputs] objectAtIndex:0] withContext:evalCtx];
    
    NSLog(@"result is: %@", result);
    NSLog(@"loglist is: %@", logList);
}

#endif // 0


#pragma mark --- stream nodes ---

- (void)runStreamNodeTest
{
    /*
    id node = [[LQStreamNode alloc] initWithName:@"(testNode)"];
    
    NSLog(@"%s: starting thread: time is %f", __func__, LQReferenceTimeGetCurrent());
    
    [node startWorkerThread];
    
    usleep(1100*1000);
    NSLog(@"%s: now signalling (%f)", __func__, LQReferenceTimeGetCurrent());
    [node signalWorkerThread];
    
    usleep(500*1000);
    [node stopWorkerThread];
    */
    
    NSLog(@"sizeof: %i, %i", sizeof(LACMutablePatch), sizeof(LQStreamPatch));
    
    LQStreamPatch *patch = [[LQStreamPatch alloc] init];
    [patch setName:@"testStreamPatch"];
    
    LQStreamSource *src = [[LQStreamSource alloc] initWithName:@"testSrc"];
    LQStreamRenderer *rend = [[LQStreamRenderer alloc] initWithName:@"testRend"];
    LQDummyStreamPresenter *pres = [[LQDummyStreamPresenter alloc] initWithName:@"testPres"];
    
    [patch addNode:src];
    [patch addNode:rend];
    [patch addNode:pres];
    
    [[[rend inputs] objectAtIndex:0] connectToOutput:[[src outputs] objectAtIndex:0]];
    [[[pres inputs] objectAtIndex:0] connectToOutput:[[rend outputs] objectAtIndex:0]];
    
    [patch prerollAndPlay];
    
    [patch performSelector:@selector(stop) withObject:nil afterDelay:1.2];
}


#pragma mark --- NSApp delegate ---

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int i;
    
    //runProtectedCapsuleFileIOTest();
    
    //[self runFuncPatchTest];
    //[self runNestedPatchTest];
    //[self runStackPatchTest];
    //[self runPatchMapTest];
    //[self runIfNodeTest];
    
    //if ( ![self runLacParserTest_1])   exit(1);
    //if ( ![self runLacParserTest_2])   exit(1);
    
    //for (i = 0; i < 10; i++)  [self runLacParserTest_2];
    
    //if ( ![self runLacParserTest_3_loop])   exit(1);
    //if ( ![self runLacParserTest_4_stackLoop])   exit(1);
    
    //for (i = 0; i < 10; i++)  [self runLacParserTest_4_stackLoop];
    
    //[self runArrayListTest];
    //[self runStreamNodeTest];
    
    
    /*else {
        for (i = 0; i < 100; i++)
            [self runLacParserTest_2];
    }*/
    //exit(0);
    [pool drain];
}

@end

