//
//  LACOutput.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
@class LACInput;


@interface LACOutput : NSObject <NSCopying, NSCoding> {

    NSString *_name;
    NSString *_type;
    
    id _owner;
    LXInteger _index;

    NSMutableSet *_connectedInputs;
}

- (id)initWithName:(NSString *)name typeKey:(NSString *)str;

- (NSString *)typeKey;
- (NSString *)name;

- (void)setOwner:(id)owner index:(LXInteger)index;
- (id)owner;

- (LXInteger)index;

- (NSSet *)connectedInputs;
- (void)disconnectFromInput:(LACInput *)input;

@end
