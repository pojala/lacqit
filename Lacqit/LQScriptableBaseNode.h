//
//  LQScriptableBaseNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"
#import <LacqJS/LacqJS.h>
@class LQJSEventRoster;


/*
  The base class for LQStreamNode and other node types
  that can have scripts set
*/


@interface LQScriptableBaseNode : LACNode {

    // attributes
    NSLock *_attrLock;
    NSMutableDictionary *_attrs;
    
    // scripting
    NSString *_nodeScript;
    LQJSEventRoster *_eventRoster;
    
    NSMutableArray *_activeTimerTags;
    
    // node interface definition (from JavaScript "this.nodeUIDefinition" key)
    NSArray *_interfaceDef;
    
    // persistent data stored by the script
    id _scriptData;
    LXUInteger _scriptStateFlags;
    
    void *__res_sbnode[3];
}

// attributes are protected by a private lock so they can be accessed in a node's threaded implementation
// without having to acquire the stream lock
- (void)setAttribute:(id)attr forKey:(NSString *)key;
- (id)attributeForKey:(NSString *)key;
- (NSDictionary *)nodeAttributes;  // copy of attributes

// LACNode is not mutable so doesn't include a name changing method.
// this method checks with the owning patch to avoid duplicate names.
- (void)setName:(NSString *)name;

// for customising how the node's class is displayed in the Conduit Live UI
+ (NSString *)validateLocalizedClassName:(NSString *)proposedName forNode:(id)node;

- (NSArray *)nodeInterfaceDefinitionPlist;


// -- scripting support --
+ (BOOL)wantsJSBridgeInPatchContext;

// permanent per-evaluation script
- (void)setNodeScript:(NSString *)nodeScript;
- (NSString *)nodeScript;

- (id)jsBridgeInPatchContext;

// running defined functions (e.g. "onStop")
- (id)runNodeFunctionNamed:(NSString *)funcName;

// running one-time textual scripts (e.g. on events)
- (id)executeScript:(NSString *)script;

- (BOOL)addObserverNode:(LQScriptableBaseNode *)node forEventName:(NSString *)eventName jsCallback:(id)callback;

- (NSArray *)nodeEventNames;

// when set, the data is copied and converted to eliminate JS object references
- (id)nodeScriptData;
- (void)setNodeScriptData:(id)obj;


// -- implementation methods that subclasses can override --
- (void)setInitialState;

- (id)createJSBridgeObject;


// -- private --
///- (void)_logRuntimeJSError:(NSError *)error withinFunctionNamed:(NSString *)funcName;

// utility for parsing the 'nodeInterfaceDef' array in the node script
- (BOOL)parseNodeInterfaceDefinitionFromJS;

@end
