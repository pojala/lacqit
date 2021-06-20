//
//  LACNode_installed.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//
#import "LACNode.h"


@interface LACNode (InstalledClasses)

+ (Class)nodeClassNamed:(NSString *)name inNamespace:(NSString *)nspace;

+ (void)addNodeClassRepository:(id)obj;
+ (void)removeNodeClassRepository:(id)obj;

@end


@protocol LACNodeClassRepository

- (NSArray *)lacNodeNamespaces;
- (Class)nodeClassNamed:(NSString *)name inNamespace:(NSString *)nspace;

@end
