//
//  LACEmbeddedPatchNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACEmbeddedPatchNode.h"
#import "LACNode_priv.h"
#import "LACPatch.h"


@implementation LACEmbeddedPatchNode

- (id)initWithName:(NSString *)name patch:(LACPatch *)patch
{
    self = [super initWithName:name];

    [self setPatch:patch];

    [self _setInputs:[NSArray array]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"output" typeKey:[LACPatch lacTypeID]] autorelease],
                                nil]];
                
    return self;
}

- (void)dealloc
{
    LACArrayListRelease(_outList);
    [_patch release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    [copy setPatch:_patch];
    
    return copy;
}

- (void)setPatch:(LACPatch *)patch
{
    [_patch release];
    _patch = [patch copy];
    
    if ( !_outList) {
        _outList = LACArrayListCreateWithObject(_patch);
    } else {
        [_outList->nsObj autorelease];
        _outList->nsObj = [_patch retain];
        _outList->count = (_patch) ? 1 : 0;
    }
}

- (LACPatch *)patch {
    return _patch; }

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    return LACArrayListRetain(_outList);
}


@end
