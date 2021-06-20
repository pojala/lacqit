//
//  LACNode_Number.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode_Number.h"
#import "LACNode_priv.h"


@implementation LACNode_Number

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    [self _setInputs:[NSArray array]];

    [self _setOutputs:[NSArray arrayWithObjects:
                                [[[LACOutput alloc] initWithName:@"value" typeKey:[NSNumber lacTypeID]] autorelease],
                                nil]];
        
    [self setDoubleValue:0.0];
    
    return self;
}

- (void)dealloc
{
    LACArrayListRelease(_outList);
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    [copy setDoubleValue:[self doubleValue]];
    return copy;
}

- (void)setDoubleValue:(double)f
{
    NSNumber *num = [NSNumber numberWithDouble:f];

    if ( !_outList) {
        _outList = LACArrayListCreateWithObject(num);
    } else {
        [_outList->nsObj autorelease];
        _outList->nsObj = [num retain];
    }
}

- (double)doubleValue {
    return [_outList->nsObj doubleValue]; }
    

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    return LACArrayListRetain(_outList);
}

@end
