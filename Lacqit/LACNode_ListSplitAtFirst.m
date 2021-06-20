//
//  LACNode_ListSplitAtFirst.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_ListSplitAtFirst.h"
#import "LACNode_priv.h"
#import "LACInput.h"
#import "LACOutput.h"


@implementation LACNode_ListSplitAtFirst

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"input list" typeKey:nil] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"first element" typeKey:nil] autorelease],
                                [[[LACOutput alloc] initWithName:@"rest of list" typeKey:nil] autorelease],
                                nil]];
    
    return self;
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)outputIndex
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr inList = inputLists[0];
    LACArrayListPtr result;
    
    switch (outputIndex) {
        case 0:  // get first element
        {
            result = LACArrayListCreateWithObject( LACArrayListFirstObject(inList) );
            break;
        }
            
        default:  // get rest of list
        {
            const LXInteger count = LACArrayListCount(inList);
            if (count < 2) {
                result = LACEmptyArrayList;
            } else {
                id objects[count-1];
            
                LXInteger i;
                for (i = 0; i < count-1; i++) {
                    objects[i] = LACArrayListObjectAt(inList, i+1);
                }
                result = LACArrayListCreateWithObjectsAndCount(objects, count-1);
            }
            break;
        }
    }
    
    return result;
}

@end
