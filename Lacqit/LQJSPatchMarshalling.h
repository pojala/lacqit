/*
 *  LQJSPatchMarshalling.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 8.12.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

@protocol LQJSPatchMarshalling

// returns a copy of the object's contents that's appropriate for
// passing within an LACPatch eval
- (id)copyAsPatchObject;

@end
