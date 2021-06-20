//
//  LACPatch_autoclosure.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACPatch.h"
@class LACOutput;


@interface LACPatch (Autoclosure)

- (id)initAsAutoclosureFromOutput:(LACOutput *)output;

@end
