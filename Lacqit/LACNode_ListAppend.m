//
//  LACNode_ListAppend.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_ListAppend.h"
#import "LACNode_priv.h"


@implementation LACNode_ListAppend

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"first list" typeKey:nil] autorelease],
                                [[[LACInput alloc] initWithName:@"second list" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"combined list" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr list1 = inputLists[0];
    LACArrayListPtr list2 = inputLists[1];
    
    LACArrayListPtr result = LACArrayListCopy(list1);
    
    LACArrayListLastNode(result, NULL)->next = LACArrayListCopy(list2);
    
    NSLog(@"%s: list1 len %ld, list2 len %ld --> new list len %ld", __func__, (long)LACArrayListCount(list1), (long)LACArrayListCount(list2),  (long)LACArrayListCount(result));

    return result;
}

@end
