//
//  LACNode_StackPush.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_StackPush.h"
#import "LACNode_priv.h"


@implementation LACNode_StackPush

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"list to push" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"the input list" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}


- (NSDictionary *)upstreamProvidedContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray lacTypeID], kLACCtxKey_Stack,
                                nil];
}

- (NSDictionary *)downstreamRequiredContext {
    return [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSMutableArray lacTypeID], kLACCtxKey_Stack,
                                nil];
}


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr inList = inputLists[0];
    LACArrayListPtr result;
    NSMutableArray *stack = [context objectForKey:kLACCtxKey_Stack];
    
    LACArrayListPtr list = inList;
    while (list) {
        ///NSLog(@"%s: list obj is '%@'", __func__, list->nsObj);
        
        if (list->count == 1)
            [stack addObject:list->nsObj];
        else if (list->count > 1)
            [stack addObjectsFromArray:(NSArray *)list->nsObj];
        
        list = list->next;
    }

    return LACArrayListRetain(inList);
}

@end
