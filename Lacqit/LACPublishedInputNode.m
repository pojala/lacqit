//
//  LACPublishedInputNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACPublishedInputNode.h"
#import "LACNode_priv.h"
#import "LACArrayListDictionary.h"



@implementation LACPublishedInputNode

- (id)initWithName:(NSString *)name typeKey:(NSString *)typeKey
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray array]];

    if (typeKey != nil && ![typeKey isEqual:@"id"])  NSLog(@"creating published input '%@' with specific type %@", name, typeKey);

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:name typeKey:typeKey] autorelease],
                                nil]];
    
    return self;
    
}

- (id)initWithName:(NSString *)name
{
    return [self initWithName:name typeKey:nil];
}

- (NSString *)typeKey {
    return [[self primeOutput] typeKey]; }
    

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
    
    result = [extInputValues arrayListForKey:[self name]];
    
    if ( !result) {
        NSLog(@"** unable to get patch external value for node '%@'", self);
        result = LACEmptyArrayList;
    }
    
    return LACArrayListRetain(result);
}

@end
