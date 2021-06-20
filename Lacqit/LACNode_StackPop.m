//
//  LACNode_StackPop.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_StackPop.h"
#import "LACNode_priv.h"


@implementation LACNode_StackPop

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray array]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"list from stack" typeKey:nil] autorelease],
                                nil]];
    
    _popCount = 1;
    
    return self;
}

- (void)setPopCount:(int)count {
    _popCount = count; }
    

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    [copy setPopCount:1];
    
    return copy;
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
    LACArrayListPtr result;
    NSMutableArray *stack = [context objectForKey:kLACCtxKey_Stack];
    
    if ( !stack) {
        NSLog(@"** no stack for eval of node '%@'", self);
        result = LACEmptyArrayList;
    }
    else {
        LXInteger popLen = [stack count];
        popLen = MIN(popLen, _popCount);
        
        if (popLen < 1) {
            result = LACEmptyArrayList;
        } else {
            id objects[popLen];
            
            LXInteger i;
            for (i = 0; i < popLen; i++) {
                objects[i] = [stack objectAtIndex:i];
            }
            
            result = LACArrayListCreateWithObjectsAndCount(objects, popLen);
            
            [stack removeObjectsInRange:NSMakeRange(0, popLen)];
        }
        /*
        NSRange popRange = NSMakeRange(0, popLen);
        
        result = [stack subarrayWithRange:popRange];
        
        [stack removeObjectsInRange:popRange];
        */
    }

    ///NSLog(@"%s: %@", __func__, result);

    return result;
}


@end
