//
//  LACNode_installed.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"
#import "LACNode_installed.h"

#import "LACBinderNode.h"
#import "LACAutoOpenNode.h"

#import "LACNode_ListAppend.h"
#import "LACNode_ListSplitAtFirst.h"
#import "LACNode_Map.h"
#import "LACNode_Reduce.h"
#import "LACNode_Stacker.h"
///#import "LACNode_StackPushAndEval.h"
#import "LACNode_StackPush.h"
#import "LACNode_StackPop.h"
#import "LACNode_Number.h"
#import "LACNode_If.h"
#import "LACNode_Sum.h"
#import "LACNode_LoopCloser.h"


static NSMutableArray *g_classes = nil;
static NSMutableArray *g_repos = nil;


@implementation LACNode (InstalledClasses)

+ (Class)builtInClassNamed:(NSString *)name
{
    if ( !g_classes) {
        g_classes = [[NSMutableArray alloc] initWithObjects:
                              [LACNode_ListAppend class],
                              [LACNode_ListSplitAtFirst class],
                              [LACNode_Map class],
                              [LACNode_Reduce class],
                              [LACNode_Stacker class],
                              ///[LACNode_StackPushAndEval class],
                              [LACNode_StackPush class],
                              [LACNode_StackPop class],
                              [LACNode_Number class],
                              [LACNode_If class],
                              [LACNode_Sum class],
                              [LACNode_LoopCloser class],
                              nil];
    }
    
    // special cases
    if ([name isEqual:@"Bind"])
        return [LACBinderNode class];
    else if ([name isEqual:@"Open"])
        return [LACAutoOpenNode class];


    NSString *wantedClassName = [NSString stringWithFormat:@"LACNode_%@", name];
        
    NSEnumerator *clsEnum = [g_classes objectEnumerator];
    Class cls;
    while (cls = [clsEnum nextObject]) {
        if ([NSStringFromClass(cls) isEqualToString:wantedClassName]) {
            return cls;
        }
    }
    return Nil;
}

+ (void)addNodeClassRepository:(id)obj
{
    if ( !obj) return;
    if ([g_repos containsObject:obj]) return;
    if ( !g_repos) g_repos = [[NSMutableArray alloc] init];
    
    [g_repos addObject:obj];
}

+ (void)removeNodeClassRepository:(id)obj
{
    if ( !obj) return;
    
    [g_repos removeObject:obj];
}

+ (Class)nodeClassNamed:(NSString *)name inNamespace:(NSString *)nspace
{
    Class cls = Nil;

    if (nspace == nil || [nspace isEqualToString:@"Lac"]) {
        cls = [self builtInClassNamed:name];
    }
    for (id repo in g_repos) {
        if (nspace == nil || [[repo lacNodeNamespaces] containsObject:nspace]) {
            if ((cls = [repo nodeClassNamed:name inNamespace:nspace]))
                break;
        }
    }
    
    if ( !cls)
        NSLog(@"Can't find class %@ in known nodes, namespace %@", name, nspace);

    return cls;
}

@end
