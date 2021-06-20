//
//  LACDelegatingNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACDelegatingNode.h"
#import "LACInput.h"
#import "LACOutput.h"


@implementation LACDelegatingNode

- (id)initWithName:(NSString *)name
            inputsDesc:(NSArray *)inputsDesc
            outputsDesc:(NSArray *)outputsDesc
{
    self = [super initWithName:name];
    if (self) {
        NSEnumerator *descEnum;
        NSDictionary *desc;
        
        // create inputs
        _inputs = [[NSMutableArray alloc] initWithCapacity:8];
        int inpCount = 0;
        
        descEnum = [inputsDesc objectEnumerator];
        while (desc = [descEnum nextObject]) {
            ///NSLog(@"... %i, %@", inpCount, [desc class]);
            LACInput *inp = [[LACInput alloc] initWithName:[desc objectForKey:@"name"] typeKey:[desc objectForKey:@"typeKey"]];
            [inp setOwner:self];
            [(NSMutableArray *)_inputs addObject:inp];
            [inp release];
            inpCount++;
            ///NSLog(@" %i : created funcnode input: %@, %@", inpCount-1, [inp name], [inp typeKey]);
        }
        
        // create outputs
        _outputs = [[NSMutableArray alloc] initWithCapacity:8];
        int outpCount = 0;
        
        descEnum = [outputsDesc objectEnumerator];
        while (desc = [descEnum nextObject]) {
            ///NSLog(@"... %i, %@ (%@)", outpCount, [desc class], desc);
            LACOutput *outp = [[LACOutput alloc] initWithName:[desc objectForKey:@"name"] typeKey:[desc objectForKey:@"typeKey"]];
            [outp setOwner:self index:outpCount++];
            [(NSMutableArray *)_outputs addObject:outp];
            [outp release];
            ///NSLog(@" %i : created funcnode output: %@, %@", outpCount-1, [outp name], [outp typeKey]);
        }
    }
    return self;
}

- (void)setDownstreamRequiredContext:(NSDictionary *)dict {
    [_downstreamReq release];
    _downstreamReq = [dict retain];
}

- (void)setDownstreamOptionalContext:(NSDictionary *)dict {
    [_downstreamOptional release];
    _downstreamOptional = [dict retain];
}

- (NSDictionary *)downstreamRequiredContext {
    return _downstreamReq; }
    
- (NSDictionary *)downstreamWillUseIfAvailableContext {
    return _downstreamOptional; }


@end
