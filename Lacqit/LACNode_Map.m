//
//  LACNode_Map.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_Map.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACNode_Map

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"patch to apply" typeKey:[LACPatch lacTypeID]] autorelease],
                                [[[LACInput alloc] initWithName:@"input list" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"result list" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)outerCtx
{

    LACArrayListPtr inList = inputLists[1];
    const LXInteger count = LACArrayListCount(inList);
    LACPatch *patch = (LACPatch *) LACArrayListFirstObject(inputLists[0]);
    
    if (count < 2 || !patch) {
        NSLog(@"%@: reduce needs a patch to apply and a list with >1 element to do anything useful (%ld elems; patch %p)", self, (long)count, patch);
        return LACArrayListRetain(inList);
    }
    
    NSAssert1([patch isKindOfClass:[LACPatch class]], @"invalid patch object", [patch class]);


    // use the first published input/output bindings within the patch
    NSString *patchInpBindingName = [[patch publishedInputNamesSortedEnumerator] nextObject];
    NSString *patchOutpBindingName = [[patch publishedOutputNamesSortedEnumerator] nextObject];
    LACOutput *innerOutput = [patch nodeOutputForOutputBinding:patchOutpBindingName];
            
    if ( !patchInpBindingName || !patchOutpBindingName || !innerOutput) {
        NSLog(@"%@: can't apply this patch (%@), lacks bindings (%@, %@, %p)", self, patch, patchInpBindingName, patchOutpBindingName, innerOutput);
        return LACArrayListRetain(inList);
    }

    NSMutableDictionary *innerCtx = [[self owner] innerContextFromEvalContext:outerCtx];
    
    LACArrayListDictionary *inputValuesForPatch = [LACArrayListDictionary dictionary];    
    [innerCtx setObject:inputValuesForPatch forKey:kLACCtxKey_ExternalInputValues];

    id resultObjects[count];
    LACArrayListPtr resultList = NULL;
    
    LXInteger i;
    for (i = 0; i < count; i++) {
        id obj = LACArrayListObjectAt(inList, i);
        LACArrayListPtr tempList = LACArrayListCreateWithObject(obj);
        
        [inputValuesForPatch setArrayList:tempList forKey:patchInpBindingName];
        
        LACArrayListPtr res = [patch evaluateOutput:innerOutput withContext:innerCtx];

        LACArrayListRelease(tempList);
                
        if ( !res || res->count < 1) {
            NSLog(@"** %@: eval of patch %@ produced nil value", self, patch);
            resultList = LACEmptyArrayList;
            
            // before breaking, release objects that were retained in previous iterations
            LXInteger j;
            for (j = 0; j < i; j++)  [resultObjects[j] release];
            break;
        } else {
            resultObjects[i] = [LACArrayListFirstObject(res) retain];
            LACArrayListRelease(res);
        }
    }
    
    if (resultList)
        return resultList;
    else {
        resultList = LACArrayListCreateWithObjectsAndCount(resultObjects, count);
        
        for (i = 0; i < count; i++)
            [resultObjects[i] release];
        
        return resultList;
    }
}

@end
