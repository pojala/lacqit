//
//  LACAutoOpenNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACAutoOpenNode.h"
#import "LACNode_priv.h"


@implementation LACAutoOpenNode

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray array]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:name typeKey:nil] autorelease],
                                nil]];
    
    return self;
}


- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    LACArrayListPtr result = nil;
    LACArrayListDictionary *extInputValues = [context objectForKey:kLACCtxKey_ExternalInputValues];
    
    if ( ![extInputValues respondsToSelector:@selector(arrayListForKey:)]) {
        NSLog(@"** %@: can't eval, invalid extInputValues context object: %@ (%@)", self, [extInputValues class], extInputValues);
        return LACEmptyArrayList;
    }
    
    NSString *inputPublishName = [NSString stringWithFormat:@"__autoopened:%@__", [self name]];
    
    result = [extInputValues arrayListForKey:inputPublishName];
    
    if ( !result) {
        NSLog(@"** unable to get patch external value for node '%@' (patch is %@)", self, _owner);
        return LACEmptyArrayList;
    } else
        return LACArrayListRetain(result);
}


@end
