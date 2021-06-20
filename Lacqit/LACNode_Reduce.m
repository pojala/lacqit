//
//  LACNode_Reduce.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_Reduce.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACNode_Reduce

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
    NSEnumerator *inpEnum = [patch publishedInputNamesSortedEnumerator];
    NSString *patchInp1BindingName = [inpEnum nextObject];
    NSString *patchInp2BindingName = [inpEnum nextObject];    
    NSString *patchOutpBindingName = [[patch publishedOutputNamesSortedEnumerator] nextObject];
    LACOutput *innerOutput = [patch nodeOutputForOutputBinding:patchOutpBindingName];
        
    if ( !patchInp1BindingName || !patchInp2BindingName || !patchOutpBindingName || !innerOutput) {
        NSLog(@"%@: can't apply this patch (%@), lacks bindings (%@, %@; %@, %p)", self, patch, patchInp1BindingName, patchInp2BindingName,
                                                                                                patchOutpBindingName, innerOutput);
        return LACArrayListRetain(inList);
    }


    NSMutableDictionary *innerCtx = [[self owner] innerContextFromEvalContext:outerCtx];
    
    LACArrayListDictionary *inputValuesForPatch = [LACArrayListDictionary dictionary];    
    [innerCtx setObject:inputValuesForPatch forKey:kLACCtxKey_ExternalInputValues];
    
    id obj1 = LACArrayListObjectAt(inList, 0);
    LACArrayListPtr accResultList = NULL;
    
    LXInteger i;
    for (i = 1; i < count; i++) {
        id obj2 = LACArrayListObjectAt(inList, i);
    
        LACArrayListPtr tempList1 = (accResultList) ? LACArrayListRetain(accResultList)
                                                    : LACArrayListCreateWithObject(obj1);
        LACArrayListPtr tempList2 = LACArrayListCreateWithObject(obj2);
        
        [inputValuesForPatch setArrayList:tempList1 forKey:patchInp1BindingName];
        [inputValuesForPatch setArrayList:tempList2 forKey:patchInp2BindingName];
        
        LACArrayListPtr res = [patch evaluateOutput:innerOutput withContext:innerCtx];

        LACArrayListRelease(tempList1);
        LACArrayListRelease(tempList2);
        
        if ( !res) {
            NSLog(@"** %@: eval of patch %@ produced nil value", self, patch);
            accResultList = LACEmptyArrayList;
            break;
        } else {
            if (accResultList != res) {
                LACArrayListRelease(accResultList);
                accResultList = LACArrayListRetain(res);
            }
        }
        
        /*
        id obj1 = (i == 0) ? [inList objectAtIndex:i] : accResult;
        id obj2 = [inList objectAtIndex:i+1];
        const BOOL inputIsList = ISARR(obj1);
                
        [inputValuesForPatch setObject:MAKEARR(obj1) forKey:patchInp1BindingName];
        [inputValuesForPatch setObject:MAKEARR(obj2) forKey:patchInp2BindingName];
        
        NSArray *resList = [patch evaluateOutput:innerOutput withContext:innerCtx];
        
        if (resList) {
            id resObj = ( !inputIsList && [resList count] > 0) ? [resList objectAtIndex:0] : resList;
        
            ///NSLog(@"%@ -- %i: result %@", self, i, resObj);
            accResult = resObj;
        } else {
            NSLog(@"** %@: patch %@ produced nil value", self, patch);
            accResult = [NSArray array];
            break;
        }
        */
    }

    return accResultList;
}

@end
