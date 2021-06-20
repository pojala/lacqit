//
//  LQJSBridge_LXAccumulator.h
//  Lacqit
//
//  Created by Pauli Ojala on 21.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LXAccumulator : LQJSBridgeObject {

    LXAccumulatorRef _acc;
}

- (id)initWithLXAccumulator:(LXAccumulatorRef)acc
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXAccumulatorRef)lxAccumulator;

@end
