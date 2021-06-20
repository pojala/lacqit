//
//  LACPatch.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LacqitExport.h"
#import "EDUINodeGraph.h"
#import "LACNode.h"
#import "LACInput.h"
#import "LACOutput.h"


LACQIT_EXPORT NSString *LACTypeIDFromObject(id obj);


@class LACArrayListDictionary;

/*
Lac patch objects are immutable to make life easier in a multithreaded environment.

In general, patch objects are created either by:

  - creating a LACMutablePatch, filling it with nodes, and making a copy of it (the copy is an immutable LACPatch)
  - using LACParser to parse a text representation of the patch.
*/


LACQIT_EXPORT_VAR NSString * const kLACCtxKey_ExternalInputValues;        // value is of type LACArrayListDictionary
LACQIT_EXPORT_VAR NSString * const kLACCtxKey_Stack;                      // value is of type NSMutableArray


@interface LACPatch : NSObject  <EDUINodeGraph, NSCopying, NSCoding> {

    NSString *_name;
    
    NSArray *_nodes;
    
    NSMutableDictionary *_inputInterface;
    NSMutableDictionary *_outputInterface;
    
    // transient state during eval of a node
    LXInteger _evalDepth;
    NSMutableDictionary *_currCtx;
    LACArrayListDictionary *_resultsCache;
    
    // UI state (setter is in LACMutablePatch)
    double _scaleFactor;
    
    // eval state logging
    NSMutableDictionary *_evalLog;

    BOOL _enableEvalLog;
    BOOL __resBool1;
    BOOL __resBool2;
    BOOL __resBool3;
    
    void *__res1;
    void *__res2;
}

- (id)initWithName:(NSString *)name nodes:(NSArray *)nodes;

- (NSString *)name;

- (NSArray *)allNodes;
- (NSEnumerator *)nodeEnumerator;

- (LACNode *)nodeNamed:(NSString *)name;
- (LACNode *)nodeWithTag:(LXInteger)tag;

- (LACInput *)inputWithNodePath:(NSString *)str;  // path to an input/output is either with ordinal ("nodeName.1") or name ("nodeName.outputName")
- (LACOutput *)outputWithNodePath:(NSString *)str;

// --- published (external) interface ---
- (NSDictionary *)publishedInputInterface;
- (NSEnumerator *)publishedInputNamesSortedEnumerator;
- (LACOutput *)outputForInputBinding:(NSString *)key;

- (NSDictionary *)publishedOutputInterface;
- (NSEnumerator *)publishedOutputNamesSortedEnumerator;
- (LACOutput *)nodeOutputForOutputBinding:(NSString *)key;
- (id)objectForOutputBinding:(NSString *)key;

// --- copying ---
- (id)deepCopyWithAppliedMappingPtr:(NSDictionary **)outMap;

- (NSDictionary *)nodeConnectionsByTagPlist;  // returns a dictionary of the connections in the patch (keys are node tags, values are arrays of node inputs)

// --- execution ---
// returned list is retained, caller must destroy it using LACArrayListRelease()
- (LACArrayListPtr)evaluateOutput:(LACOutput *)output withContext:(NSDictionary *)evalCtx;

- (LACArrayListPtr)evaluateNode:(LACNode *)node forOutputAtIndex:(LXInteger)index
                                                withContext:(NSDictionary *)evalCtx;

@end
