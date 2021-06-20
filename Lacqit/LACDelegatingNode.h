//
//  LACDelegatingNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"


@interface LACDelegatingNode : LACNode {

    NSDictionary *_downstreamReq;
    NSDictionary *_downstreamOptional;
}

- (id)initWithName:(NSString *)name
            inputsDesc:(NSArray *)inputsDesc
            outputsDesc:(NSArray *)outputsDesc;  // desc arrays contain NSDictionary objects describing the inputs/outputs

- (void)setDownstreamRequiredContext:(NSDictionary *)dict;
- (void)setDownstreamOptionalContext:(NSDictionary *)dict;

@end

