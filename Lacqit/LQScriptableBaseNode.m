//
//  LQScriptableBaseNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQScriptableBaseNode.h"
#import "LACMutablePatch.h"
#import "LQJSEventRoster.h"
#import "LQJSON.h"
#import "LQJSUtils.h"


enum {
    kLQScriptableNodeWasLoadedFromCoder = 1 << 0,
    kLQScriptableNodeHasNotYetLoadedScript = 1 << 1,
};


@interface NSObject (LQScriptableBaseNodeOwnerPatchMethods)

- (NSString *)validateNodeName:(NSString *)prefix integerSuffix:(LXInteger)num;
- (NSString *)_tagHashForNode:(id)node;

- (LQJSInterpreter *)jsInterpreter;
- (id)streamJSThis;

- (BOOL)runMethodNamed:(NSString *)funcName onNode:(id)node parameters:(NSArray *)params resultPtr:(id *)outResult;

- (void)willEnterJSMethodNamed:(NSString *)funcName onNode:(id)node;
- (void)didExitJSMethod;

- (void)_reallyClearJSTimerWithTag:(LXInteger)timerTag allowDelegation:(BOOL)doDelegate;

- (void)_logJSError:(NSError *)error type:(LXInteger)errorType;

@end



@implementation LQScriptableBaseNode


#pragma mark --- init ---

// -setInitialState is introduced here for subclasses to override
- (void)setInitialState
{
    if ( !_attrLock)  _attrLock = [[NSLock alloc] init];
}

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    if (self) {
        [self setInitialState];
        
        _attrs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)_clearActiveJSTimers
{
    if ([_activeTimerTags count] > 0) {
        NSLog(@"... node %@: clearing out %lu timer tags", self, [_activeTimerTags count]);
    
        // clear out existing timers that are related to us
        NSEnumerator *tagEnum = [_activeTimerTags objectEnumerator];
        id obj;
        while (obj = [tagEnum nextObject]) {
            LXInteger tag = [obj longValue];
            NSAssert1(tag > 0, @"invalid tag value in array (%ld)", tag);
            [[self owner] _reallyClearJSTimerWithTag:tag allowDelegation:NO];
        }
        [_activeTimerTags removeAllObjects];
    }
}

- (void)dealloc
{
    [self _clearActiveJSTimers];

    [[self owner] removeNodeObserver:self];  // call this just in case

    [_eventRoster release];
    
    [_interfaceDef release];

    [_attrs release];
    [_attrLock release];
    [super dealloc];
}



#pragma mark --- NSCopying protocol ---

- (void)_copyAttributes:(NSDictionary *)attrs
{
    [_attrLock lock];
    [_attrs autorelease];
    _attrs = [[NSMutableDictionary alloc] initWithDictionary:attrs];
    [_attrLock unlock];
}

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [super copyWithZone:zone];
    
    [copy _copyAttributes:_attrs];
    
    return copy;
}


#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeObject:_attrs forKey:@"LQ::attributes"];
    
    if (_nodeScript) {
        [coder encodeObject:_nodeScript forKey:@"LQ::nodeScript"];
        
        if (_tag != 0) {
            [self runNodeFunctionNamed:@"persist"];
        }
    }
    
    if (_scriptData)
        [coder encodeObject:_scriptData forKey:@"LQ::nodeScriptPersistentData"];
}


- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setInitialState];
        
        _attrs = [[coder decodeObjectForKey:@"LQ::attributes"] retain];
        
        if ( !_attrs && [coder containsValueForKey:@"LQStreamNode::attributes"]) {  // old name (changed 2010.01.03)
            _attrs = [[coder decodeObjectForKey:@"LQStreamNode::attributes"] retain];
        }
        
        if ( !_attrs) {
            _attrs = [[NSMutableDictionary alloc] init];
        }
        else if ( ![_attrs isKindOfClass:[NSMutableDictionary class]]) {
            [_attrs autorelease];
            _attrs = [[NSMutableDictionary alloc] initWithDictionary:_attrs];
        }
        
        _nodeScript = [[coder decodeObjectForKey:@"LQ::nodeScript"] retain]; 
        
        if ( !_nodeScript && [coder containsValueForKey:@"LQStreamNode::nodeScript"]) {  // old name (changed 2010.01.03)
            _nodeScript = [[coder decodeObjectForKey:@"LQStreamNode::nodeScript"] retain]; 
        }
        
        _scriptData = [[coder decodeObjectForKey:@"LQ::nodeScriptPersistentData"] retain];
        
        // can't activate the script yet, because the -owner is probably not set yet,
        // so defer it into -setOwner method
        if ([_nodeScript length] > 0) {
            _scriptStateFlags |= kLQScriptableNodeWasLoadedFromCoder;
        }
    }
    return self;
}

- (void)setOwner:(id)owner
{
    id prevOwner = [self owner];
    
    [super setOwner:owner];
    
    BOOL hasPendingLoad = (_scriptStateFlags & kLQScriptableNodeHasNotYetLoadedScript) != 0;
    if (hasPendingLoad) {
        //NSLog(@"%s -- node '%@' has pending load, owner %@", __func__, [self name], owner);
        _scriptStateFlags &= ~kLQScriptableNodeHasNotYetLoadedScript;
    }
    
    if (hasPendingLoad || owner != prevOwner) {
        [self _clearActiveJSTimers];

        [prevOwner removeNodeObserver:self];
    
        if (_nodeScript) {
            [self setNodeScript:_nodeScript];
            
            if (_scriptStateFlags & kLQScriptableNodeWasLoadedFromCoder) {
                _scriptStateFlags &= ~kLQScriptableNodeWasLoadedFromCoder;
                
                [self runNodeFunctionNamed:@"unpersist"];
            }
        }
    }
}


#pragma mark --- naming ---

+ (NSString *)validateLocalizedClassName:(NSString *)proposedName forNode:(id)node {
    return proposedName;
}

- (void)setName:(NSString *)name
{
    if ([name isEqualToString:_name]) return;
    
    id owner = [self owner];
    if (owner) {
        name = [owner validateNodeName:name integerSuffix:0];
    }

    [_name autorelease];
    _name = [name copy];
}


#pragma mark --- attributes ---

- (void)setAttribute:(id)attr forKey:(NSString *)key
{
    if ( !key || [key length] < 1) {
        NSLog(@"** tried to use null key for stream source attribute");
        return;
    }
    
    [_attrLock lock];
    if (attr && attr != [NSNull null]) {
        NSAssert2([attr respondsToSelector:@selector(copy)], @"invalid value for attribute '%@': %@", key, [attr class]);
        
        [_attrs setObject:[[attr copy] autorelease] forKey:key];
    } else {
        [_attrs removeObjectForKey:key];
    }
    [_attrLock unlock];
}

- (id)attributeForKey:(NSString *)key
{
    id val;
    [_attrLock lock];
    val = [_attrs objectForKey:key];
    [_attrLock unlock];
    return val;
}

- (NSDictionary *)nodeAttributes
{
    id val;
    [_attrLock lock];
    val = [[_attrs copy] autorelease];
    [_attrLock unlock];
    return val;
}


#pragma mark --- JavaScript support ---

+ (BOOL)wantsJSBridgeInPatchContext
{
    return NO;
}

// caller will autorelease the returned object
- (id)createJSBridgeObject
{
    return [[[[self owner] jsInterpreter] emptyProtectedJSObject] retain];
    
    // subclasses should override if they want javascript support, e.g.:
    // return [[LCLLiveLoopRendererJSBridge alloc] initWithNode:self];
}

// this method replaces the JS proxy object with a fresh one
- (void)recreateJSBridgeInPatchContext
{
    [self _clearActiveJSTimers];

    id myJSObj = [[self createJSBridgeObject] autorelease];
    
    NSString *tagHash = [[self owner] _tagHashForNode:self];

    [[[self owner] streamJSThis] setValue:myJSObj forKey:tagHash];
    ///NSLog(@"%s: %@ -> %@", __func__, myJSObj, tagHash);

    if ( !_eventRoster) {
        _eventRoster = [[LQJSEventRoster alloc] init];
        [_eventRoster setDelegate:self];
    }
}

- (id)jsBridgeInPatchContext
{
    if ( ![[self class] wantsJSBridgeInPatchContext])
        return nil;
        
    if ( ![self owner])
        return nil;

    // node JS objects are contained in the stream's 'this' object
    id streamJSObj = [[self owner] streamJSThis];
    
    NSAssert(streamJSObj, @"couldn't get JS 'this' for owner patch");
    
    id tagHash = [[self owner] _tagHashForNode:self];
    id myJSObj;
    if ( !(myJSObj = [streamJSObj valueForKey:tagHash])) {
        ///NSLog(@"recreating js bridge for stream node (%@ --> hash '%@'; stream obj is %p)", self, tagHash, streamJSObj);
        [self recreateJSBridgeInPatchContext];
        myJSObj = [streamJSObj valueForKey:tagHash];
    }
    return myJSObj;
}


- (NSString *)nodeScript {
    return (_nodeScript) ? _nodeScript : @""; }
    

- (void)willExecuteNodeScript {
    // subclasses can implement
}

- (void)setNodeScript:(NSString *)nodeScript
{
    [_nodeScript autorelease];
    _nodeScript = [nodeScript copy];
    
    if ([self tag] == 0) {
        // we don't have a tag set by the owner yet, so we can't have a bridge object either
        //NSLog(@"script node '%@': load pending", [self name]);
        _scriptStateFlags |= kLQScriptableNodeHasNotYetLoadedScript;
        return;
    }
    
    if ( ![self jsBridgeInPatchContext]) {
        if ([self owner]) {  // lack of the bridge object is a potential problem only if the owner has already been set
            NSLog(@"** node '%@': couldn't set script, no JS bridge", [self name]);
        }
        _scriptStateFlags |= kLQScriptableNodeHasNotYetLoadedScript;
        return;
    }
    
    [self recreateJSBridgeInPatchContext];
    
    [self willExecuteNodeScript];

    [self executeScript:_nodeScript];
/*        
    NSError *error = nil;
    id newFunc = [[[self owner] jsInterpreter] compileScript:_nodeScript functionName:@"_nodeScriptFunc"
                                                  parameterNames:[NSArray array]
                                                  error:&error];
    if ( !newFunc) {
        NSLog(@"** %@: failed to create JS func (%@)", self, error);
        
        [[self owner] _logJSError:error type:1];
    } else {
        // the script is run only this once.
        // it is expected to create any persistent values into myJSObj
        // (for example:   this.onRender = function() { ... } )
        
        id result = [newFunc callWithThis:myJSObj parameters:[NSArray array] error:&error];
        if (error) {
            NSLog(@"** %@: failed to execute JS func (%@)", self, error);
            
            [[self owner] _logJSError:error type:2];
        } else {
            if (result) {
                LXPrintf(".. setNodeScript (%@): js result is '%s'\n", [self name], [[result description] UTF8String]);
            } else {
                LXPrintf(".. setNodeScript (%@) successful, no result", [self name]);
            }
        }        
    }
*/
}

- (id)executeScript:(NSString *)script
{
    if ([script length] < 1) return nil;
    
    id result = nil;
    NSError *error = nil;
    id interp = [[self owner] jsInterpreter];
    id myJSObj = [self jsBridgeInPatchContext];
    
    if (interp && myJSObj) {
        id newFunc = [interp compileScript:script functionName:@"_nodeExecFunc" parameterNames:[NSArray array] error:&error];
        if (error) {
            NSLog(@"** %@: failed to compile script on node (%@)", [self name], error);
            [[self owner] _logJSError:error type:1];
        }
        else {
            [[self owner] willEnterJSMethodNamed:@"(not a method)" onNode:self];
        
            result = [newFunc callWithThis:myJSObj parameters:[NSArray array] error:&error];
            
            if (error) {
                NSLog(@"** %@: failed to execute JS func (%@)", [self name], error);
                [[self owner] _logJSError:error type:2];
            }
            else {
                ///if (result) LXPrintf(".. execScript (%s): js result is '%s'\n", [[self name] UTF8String], [[result description] UTF8String]);
                ///else LXPrintf(".. execScript (%s) successful, no result", [[self name] UTF8String]);
            }
            
            [[self owner] didExitJSMethod];
        }
    }
    return result;
}

/*
- (void)_logRuntimeJSError:(NSError *)error withinFunctionNamed:(NSString *)funcName
{
    NSMutableDictionary *userInfo = [[[error userInfo] mutableCopy] autorelease];
    NSString *desc = [userInfo objectForKey:NSLocalizedDescriptionKey];
    desc = [desc stringByAppendingFormat:@" (node id: %@, function: %@)", [self name], funcName];
    [userInfo setObject:desc forKey:NSLocalizedDescriptionKey];
    
    NSError *newError = [NSError errorWithDomain:[error domain] code:[error code] userInfo:userInfo];
    NSLog(@"** %@: failed to execute '%@' script (%@)", [self name], funcName, newError);
    
    [[self owner] _logJSError:newError type:2];
}
*/

- (id)runNodeFunctionNamed:(NSString *)funcName
{
    if ([funcName length] < 1) return nil;    
    id result = nil;
    
    [[self owner] runMethodNamed:funcName onNode:self parameters:nil resultPtr:&result];
/*
    NSError *error = nil;
    id myJSObj = [self jsBridgeInPatchContext];
    
    if (myJSObj) {
        id func = [myJSObj propertyForKey:funcName];

        if (func && [func respondsToSelector:@selector(isFunction)] && [func isFunction]) {
            result = [func callWithThis:myJSObj parameters:nil error:&error];
            
            if (error) {
                [self _logRuntimeJSError:error withinFunctionNamed:funcName];
                result = nil;
            }
        }
    }
*/
    return result;
}


#pragma mark --- node interface definition ---

- (NSArray *)nodeInterfaceDefinitionPlist {
    return _interfaceDef; }

- (BOOL)parseNodeInterfaceDefinitionFromJS
{
    NSError *error = nil;
    BOOL didUpdateInterface = NO;
    id interfaceDef = [[self jsBridgeInPatchContext] propertyForKey:@"nodeUIDefinition"];
    if ( !interfaceDef) {
        [[self jsBridgeInPatchContext] propertyForKey:@"nodeInterfaceDef"];  // old name, kept here for compatibility (2010.05.07)
    }
    
    ///NSLog(@"...parsing node interface def: %@", interfaceDef);
    if (interfaceDef && [interfaceDef respondsToSelector:@selector(jsObjectRef)]) {
        id json = [[[self owner] jsInterpreter] evaluateScript:@"JSON.stringify(this)" thisValue:interfaceDef error:&error];
        if (error) {
            NSLog(@"*** %s: json call failed: %@", __func__, error);
            return NO;
        }
        interfaceDef = ([json respondsToSelector:@selector(parseAsJSON)]) ? [json parseAsJSON] : nil;
    
        if ( ![interfaceDef isKindOfClass:[NSArray class]]) {
            NSLog(@"** JS script (%@): invalid interface def (%@)", self, [interfaceDef class]);
        } else {
            [_interfaceDef release];
            _interfaceDef = [interfaceDef copy];
            didUpdateInterface = YES;
        }
    } else {
        if (_interfaceDef) {
            [_interfaceDef release];
            _interfaceDef = nil;
            didUpdateInterface = YES;
        }
    }
    return didUpdateInterface;
}


#pragma mark --- node JS events ---

// subclasses should override for events that they support
- (NSArray *)nodeEventNames {
    return nil;
}

- (BOOL)addObserverNode:(LQScriptableBaseNode *)node forEventName:(NSString *)eventName jsCallback:(id)callback
{
    if ( ![[self nodeEventNames] containsObject:eventName])
        return NO;
      
    BOOL ok = [_eventRoster addObserver:node forEventName:eventName jsCallback:callback];
    if (ok) {
        [[self owner] addNodeObserver:self];  // a node was added as our event observer, so in turn we need to know when that node gets deleted
    }
    return ok;
}

- (void)nodesWereModified:(NSSet *)nodes inPatch:(id)patch contextInfo:(NSDictionary *)info
{
    ///NSLog(@"%s (%@): %@; info %@", __func__, [self name], nodes, info);

    NSEnumerator *setEnum = [nodes objectEnumerator];
    id node;
    while (node = [setEnum nextObject]) {
        if ([node owner] != [self owner]) {
            [_eventRoster removeObserver:node];
        }
    }
}

#pragma mark --- LQJSEventRoster delegate methods ---

- (id)jsCallbackThisForEventNamed:(NSString *)eventName observer:(id)obs argumentsPtr:(NSArray **)outParams
{
    id this = nil;
    if ([obs isKindOfClass:[LQScriptableBaseNode class]]) {
        this = [obs jsBridgeInPatchContext];
    }
    
    id myBridge = [self jsBridgeInPatchContext];

    *outParams = [NSArray arrayWithObject:myBridge];
    return (this) ? this : myBridge;
}

- (BOOL)shouldDispatchEventNamed:(NSString *)eventName toObserver:(id)obs {
    ///NSLog(@"%s: %@ -- node %@", __func__, eventName, obs);
    [[self owner] willEnterJSMethodNamed:eventName onNode:obs];
    return YES;
}

- (void)didDispatchEventNamed:(NSString *)eventName toObserver:(id)obs error:(NSError *)error {
    [[self owner] didExitJSMethod];
}


#pragma mark --- script timers ---

- (BOOL)patchShouldCreateJSTimerWithTag:(LXInteger)tag repeats:(BOOL)doRepeat
{
    if ( ![[self class] wantsJSBridgeInPatchContext])
        return NO;

    ///NSLog(@"%s, %@: tag %i, repeats %i", __func__, self, tag, doRepeat);
    
    if ( !_activeTimerTags) _activeTimerTags = [[NSMutableArray alloc] init];
    
    [_activeTimerTags addObject:[NSNumber numberWithLong:tag]];
    
    return YES;
}


#pragma mark --- script data ---

- (id)nodeScriptData {
    return _scriptData; }

- (void)setNodeScriptData:(id)obj {
    [_scriptData release];
    _scriptData = [LQJSConvertKeyedItemsRecursively(obj) retain];
}


@end
