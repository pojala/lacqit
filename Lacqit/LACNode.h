//
//  LACNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 30.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
#import "LACArrayList.h"
#import "EDUINodeGraphConnectable.h"

@class LACInput, LACOutput;


enum {
    kLACNodeDefaultConnectionType = 1
};


@interface LACNode : NSObject  <EDUINodeGraphConnectable, NSCopying, NSCoding> {

    NSString *_name;
    
    NSArray *_inputs;
    NSArray *_outputs;

    // non-retained
    id _owner;
    id _delegate;
    
    LXInteger _sortLevel;

    // user data
    LXInteger _tag;
    
    // visual state
    NSPoint         _centerPoint;
    LXFloat         _scaleFactor;
    LXUInteger      _appearanceFlags;
    
    void *__res1;
    void *__res2;
}

+ (NSString *)packageIdentifier;
+ (NSString *)proposedDefaultName;

- (id)initWithName:(NSString *)name;

- (NSArray *)inputs;
- (NSArray *)outputs;

- (LACInput *)primeInput;
- (LACOutput *)primeOutput;
- (LACInput *)inputNamed:(NSString *)name;
- (LACOutput *)outputNamed:(NSString *)name;

- (NSString *)name;
- (id)owner;
- (void)setOwner:(id)owner;

- (id)delegate;
- (void)setDelegate:(id)del;

- (LXInteger)tag;  // not used by the framework; user can use to attach simple numeric metadata (value is encoded)
- (void)setTag:(LXInteger)tag;

- (void)disconnectAll;

// describing the node's evaluation
- (NSDictionary *)upstreamProvidedContext;
- (NSDictionary *)downstreamRequiredContext;
- (NSDictionary *)downstreamWillUseIfAvailableContext;

// the following default to NO
+ (BOOL)usesTransientState;             // the node uses private state during execution (e.g. creates something in -willEvaluate)
- (BOOL)wantsPreAndPostEvaluation;
- (BOOL)wantsLazyEvaluationOfInputs;
- (BOOL)wantsNotificationOnConnectionChange;

// execution.
// size of the "inputLists" C array is always [[self inputs] count]
- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context;

// pre-/post-evaluation
- (void)willEvaluateWithContext:(NSMutableDictionary *)context;
- (void)didEvaluateWithContext:(NSMutableDictionary *)context;

// deep copying
- (id)deepCopyWithMap:(NSMutableDictionary *)map;

// visual state
- (NSPoint)centerPoint;
- (void)setCenterPoint:(NSPoint)point;

// user interface bindings
- (NSArray *)editableBindingDescriptions;

// recursive sorting
- (LXInteger)sortLevel;
- (void)setSortLevel:(LXInteger)level;
- (LXInteger)compareSortLevelTo:(id)node;
- (void)clearSortLevel;



// --- for use by subclasses only ---

- (LACArrayListPtr)delegateEvalResult:(LACArrayListPtr)result
                        outputIndex:(LXInteger)outputIndex
                        inputLists:(LACArrayListPtr *)inputLists
                        context:(NSDictionary *)context;
                    
// if the object is a patch, it is activated (i.e. evaluated)
- (BOOL)boolValueFromInputObject:(id)obj evalContext:(NSDictionary *)outerCtx;
//- (LACArrayListPtr)listValueFromInputObject:(id)obj evalContext:(NSDictionary *)outerCtx;

@end


// --- delegation ---
@interface NSObject (LACNodeDelegate)

// NULL return value is ok and means the delegate accepts the proposed result.
// if delegate returns a new list, the proposed result list is released
- (LACArrayListPtr)willEvaluateFuncNode:(LACNode *)fnode
                        proposedResult:(LACArrayListPtr)proposedResult
                        outputIndex:(LXInteger)outputIndex
                        inputLists:(LACArrayListPtr *)inputLists
                        context:(NSDictionary *)context;

@end


// --- categories ---
#import "LACNode_installed.h"

