//
//  LACNode_Sum.m
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_Sum.h"
#import "LACNode_priv.h"


@implementation LACNode_Sum

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray arrayWithObjects:
                                [[[LACInput alloc] initWithName:@"first value" typeKey:[NSNumber lacTypeID]] autorelease],
                                [[[LACInput alloc] initWithName:@"second value" typeKey:[NSNumber lacTypeID]] autorelease],
                                nil]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"the sum" typeKey:[NSNumber lacTypeID]] autorelease],
                                nil]];
    
    return self;
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr inList1 = inputLists[0];
    LACArrayListPtr inList2 = inputLists[1];

    const LXInteger count = MIN(LACArrayListCount(inList1), LACArrayListCount(inList2));
    
    if (count < 1) {
        return NULL;
    }
    else if (count == 1) {
        id in1 = LACArrayListObjectAt(inList1, 0);
        id in2 = LACArrayListObjectAt(inList2, 0);
        double v1 = ([in1 respondsToSelector:@selector(doubleValue)]) ? [in1 doubleValue] : 0.0;
        double v2 = ([in2 respondsToSelector:@selector(doubleValue)]) ? [in2 doubleValue] : 0.0;
        double d = v1 + v2;
        
        ///NSLog(@"sum: %f + %f", v1, v2);
        
        return LACArrayListCreateWithObject([NSNumber numberWithDouble:d]);
    }
    else {
        id results[count];
        
        LXInteger i;
        for (i = 0; i < count; i++) {
            id in1 = LACArrayListObjectAt(inList1, i);
            id in2 = LACArrayListObjectAt(inList2, i);
            double v1 = ([in1 respondsToSelector:@selector(doubleValue)]) ? [in1 doubleValue] : 0.0;
            double v2 = ([in2 respondsToSelector:@selector(doubleValue)]) ? [in2 doubleValue] : 0.0;
            double d = v1 + v2;
            results[i] = [NSNumber numberWithDouble:d];
        }
        
        return LACArrayListCreateWithObjectsAndCount(results, count);
    }
}

@end

