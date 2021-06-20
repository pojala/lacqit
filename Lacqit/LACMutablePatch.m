//
//  LACMutablePatch.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACMutablePatch.h"
#import "LACPublishedInputNode.h"
#import "LQNSScannerAdditions.h"
#import "LACDataMethods.h"


NSString * const kLACNodeInterfaceHasChanged = @"LACNodeInterfaceHasChanged";



@interface LACMutablePatch (PrivateImpl)
- (void)_notifyAboutModifiedNodes:(NSSet *)nodeSet contextInfo:(NSDictionary *)ctx;
@end



@implementation LACMutablePatch

// private init method called by superclass's initializers
- (void)_initNodesIvarWithArray:(NSArray *)nodes
{
    if (_nodes) [_nodes release];

    _nodes = (nodes) ? [NSMutableArray arrayWithArray:nodes] : [NSMutableArray array];
    [_nodes retain];
    
    // registered connection observers
    _nodeObservers = [[NSMutableArray alloc] initWithCapacity:16];
}

- (void)dealloc
{
    [_nodes makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];  // this needs to happen before any state is dealloced
    
    [_modifiedNodes release];
    _modifiedNodes = nil;

    [_nodeObservers release];
    [super dealloc];
}


- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy]; }
    

- (void)addInputBindingWithType:(NSString *)type forKey:(NSString *)key
{
    if ( !key || [key length] < 1)
        return;
    
    if ( !type) 
        type = [NSObject lacTypeID];
    
    if ( ![_inputInterface respondsToSelector:@selector(setObject:forKey:)]) {
        _inputInterface = [[NSMutableDictionary dictionaryWithDictionary:[_inputInterface autorelease]] retain];
    }
    [_inputInterface setObject:type forKey:key];
    
    // create a matching node
    LACPublishedInputNode *node = [[LACPublishedInputNode alloc] initWithName:key typeKey:type];
    
    [self addNode:node];
    [node release];
    ///NSLog(@"patch %@: created patch input node for key '%@', type is '%@'", [self name], key, [node typeKey]);
}

- (void)setOutputBinding:(id)output forKey:(NSString *)key
{
    if ( !key || [key length] < 1)
        return;
        
    if ( ![_outputInterface respondsToSelector:@selector(setObject:forKey:)]) {
        _outputInterface = [[NSMutableDictionary dictionaryWithDictionary:[_outputInterface autorelease]] retain];
    }
    if (output)
        [_outputInterface setObject:output forKey:key];
    else
        [_outputInterface removeObjectForKey:key];
        
    ///NSLog(@"patch %@: created binding for output: key '%@', output %@", [self name], key, output);
}

// subclasses can override
- (void)_willAddNode:(id)node
{
}

- (void)addNode:(id)node
{
    if ( ![_nodes containsObject:node]) {
        [self _willAddNode:node];
        [(NSMutableArray *)_nodes addObject:node];
        [node setOwner:self];
        
        ///NSLog(@"%p: added node %@, retcount %i", self, node, [node retainCount]);
        
        [self _notifyAboutModifiedNodes:[NSSet setWithObject:node] contextInfo:nil];
    }
}

- (void)_removePatchInterfaceForNode:(id)node
{
    NSEnumerator *outputInterfaceEnum = [_outputInterface keyEnumerator];
    NSMutableArray *killList = [NSMutableArray array];
    id key;
    while (key = [outputInterfaceEnum nextObject]) {
        id outp = [_outputInterface objectForKey:key];
        if ([outp owner] == node) {
            ///NSLog(@"... %s: deleting node %@ - published output %@ -- key %@", __func__, node, outp, key);
            [killList addObject:key];
        }
    }
    if ([killList count] > 0) [_outputInterface removeObjectsForKeys:killList];
}

- (void)deleteNode:(id)node
{
    if ([_nodes containsObject:node]) {
        [node disconnectAll];
        
        [node setOwner:nil];
        
        [self _removePatchInterfaceForNode:node];
        
        [self _notifyAboutModifiedNodes:[NSSet setWithObject:node] contextInfo:nil];
        
        [(NSMutableArray *)_nodes removeObject:node];
    }
}

- (void)detachNodesFromTree:(NSSet *)nodeSet
{
    NSMutableArray *delList = [NSMutableArray array];
    for (id node in nodeSet) {
        if ([_nodes containsObject:node]) {
            [node setOwner:nil];
            [delList addObject:node];
            
            [self _removePatchInterfaceForNode:node];
        }
    }
    [(NSMutableArray *)_nodes removeObjectsInArray:delList];
}


- (void)sortNodesRecursivelyFromPublishedOutputs
{
	[(NSMutableArray *)_nodes makeObjectsPerformSelector:@selector(clearSortLevel) ];	

    NSEnumerator *enumerator = [self publishedOutputNamesSortedEnumerator];
    NSString *outpBindingName;
    while (outpBindingName = [enumerator nextObject]) {
        LACOutput *outp = [self nodeOutputForOutputBinding:outpBindingName];
        
        [[outp owner] setSortLevel:1];    // this call recursively walks through the tree
    }

	[(NSMutableArray *)_nodes sortUsingSelector:@selector(compareSortLevelTo:) ];
}


- (void)setGlobalScaleFactor:(double)f {
    _scaleFactor = f; }
    
- (double)globalScaleFactor {
    return _scaleFactor; }
    
    
- (void)applyNodeConnectionsByTagPlist:(NSDictionary *)info
{
    NSEnumerator *keyEnum = [info keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        long tag = ([key respondsToSelector:@selector(longValue)]) ? [key longValue] : [key intValue];
        id node;
        if (tag > 0 && (node = [self nodeWithTag:tag])) {
            NSArray *arr = [info objectForKey:key];
            LXInteger inpCount = MIN([arr count], [[node inputs] count]);
            LXInteger i;
            for (i = 0; i < inpCount; i++) {
                id connInfo = [arr objectAtIndex:i];
                LACInput *inp = [[node inputs] objectAtIndex:i];
                if ([connInfo length] < 1) {
                    if ([inp isConnected])
                        [inp disconnect];
                } else {
                    NSRange range = [connInfo rangeOfString:@"."];
                    LXInteger connOutpIndex = 0;
                    if (range.location != NSNotFound) {
                        connOutpIndex = [[connInfo substringFromIndex:range.location+1] intValue];
                        connInfo = [connInfo substringToIndex:range.location];
                    }
                    LXInteger connNodeTag = lround([connInfo doubleValue]);
                    id connNode = [self nodeWithTag:connNodeTag];
                    if (connNode && [[connNode outputs] count] > connOutpIndex) {
                        [inp connectToOutput:[[connNode outputs] objectAtIndex:connOutpIndex]];
                    }
                }
            }
        }
    }
}
    

#pragma mark --- notifying about modified nodes ---

- (BOOL)isInsideInterfaceChangeGrouping {
    return (_interfaceChangeInitiator) ? YES : NO;
}

- (void)_notifyAboutModifiedNodes:(NSSet *)nodeSet contextInfo:(NSDictionary *)ctx
{
    if ([nodeSet count] > 0 && [_nodeObservers count] > 0) {
        NSEnumerator *obsEnum = [_nodeObservers objectEnumerator];
        id weakObs;
        while (weakObs = [obsEnum nextObject]) {
            id observer = [weakObs pointerValue];
            [observer nodesWereModified:nodeSet inPatch:self contextInfo:ctx];
        }
    }
}

- (void)_enqueueNotificationOfModifiedNodes:(NSSet *)nodeSet
{
    if ([self isInsideInterfaceChangeGrouping]) {
        // postpone notification until grouping is complete
        [_modifiedNodes unionSet:nodeSet];
    } else {
        // no need to wait, just notify now
        [self _notifyAboutModifiedNodes:nodeSet contextInfo:nil];
    }
}

- (void)nodeWillModifyInterface:(LACNode *)node
{
    _interfaceChangeInitiator = node;
    
    [_modifiedNodes release];
    _modifiedNodes = [[NSMutableSet alloc] initWithCapacity:32];
    [_modifiedNodes addObject:node];
}

- (void)nodeDidModifyInterface:(LACNode *)node
{
    _interfaceChangeInitiator = nil;
    
    NSDictionary *ctx = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithBool:YES], kLACNodeInterfaceHasChanged,
                                            nil];
    
    [self _notifyAboutModifiedNodes:[_modifiedNodes autorelease] contextInfo:ctx];
    _modifiedNodes = nil;
}



#pragma mark --- node input change notifs ---
// these are sent directly by the LACInput

- (void)connectionWillChangeForInput:(LACInput *)input
{
    // currently, when disconnecting an input,
    // the modified nodes set will only include the node owning the input.
    // to fix that problem, this method should keep an eye on the previous
    // connected upstream node and add it to the modified nodes set.

    // ^^ this functionality added 2009.06.22:
    if (_modifiedNodes) {
        LACNode *otherNode = [[input connectedOutput] owner];
        if (otherNode) {
            [_modifiedNodes addObject:otherNode];
        }
    }
}

- (void)connectionDidChangeForInput:(LACInput *)input
{
    LACNode *node = [input owner];
    if ( !node) return;
    
    if ( ![self isInsideInterfaceChangeGrouping]) {
        if ([node wantsNotificationOnConnectionChange]) {
            [(id)node connectionDidChangeForInput:input];
        }
    }

    LACNode *otherNode = [[input connectedOutput] owner];
    
    NSSet *nodeSet = (otherNode) ? [NSSet setWithObjects:node, otherNode, nil] : [NSSet setWithObject:node];
    
    [self _enqueueNotificationOfModifiedNodes:nodeSet];
}



#pragma mark --- observing connections ---

- (void)addNodeObserver:(id)observer
{
    id weakPtr = [NSValue valueWithPointer:observer];
    if ( ![_nodeObservers containsObject:weakPtr])
        [_nodeObservers addObject:weakPtr];
}

- (void)removeNodeObserver:(id)observer
{
    id weakPtr = [NSValue valueWithPointer:observer];
    if ([_nodeObservers containsObject:weakPtr])
        [_nodeObservers removeObject:weakPtr];
}



#pragma mark --- parser support ---

- (void)applyOutputBindingProperty:(id)value forKey:(NSString *)key
{
    if ([key length] < 1)
        return;
     
    if ([key isEqualToString:@"bindOutAt"]) {
        NSString *bindingDecl = [value description];
        
        NSScanner *scanner = [NSScanner scannerWithString:bindingDecl];
        NSString *nodePath = nil;
        
        ///NSLog(@"OUTBIND: %@, self %@", bindingDecl, [self name]);
        
        if ([scanner scanPossiblyQuotedLiteralIntoString:&nodePath]) {
            LACOutput *output = [self outputWithNodePath:nodePath];
            
            if (output) {
                NSString *asDecl = nil;
                // continue scanning for a possible name declaration
                if ([scanner scanString:@"as" intoString:NULL]) {
                    [scanner scanPossiblyQuotedLiteralIntoString:&asDecl];
                }
                if ([asDecl length] < 1)
                    asDecl = nodePath;
                
                [self setOutputBinding:output forKey:asDecl];
            }
        }
    }
}

- (void)applyInputBindingProperty:(id)value forKey:(NSString *)key
{
    if ([key length] < 1)
        return;
        
    if ([key isEqualToString:@"bindInAs"]) {
        NSString *bindingDecl = [value description];
        
        NSScanner *scanner = [NSScanner scannerWithString:bindingDecl];
        NSString *str = nil;
        
        if ([scanner scanPossiblyQuotedLiteralIntoString:&str]) {
            [self addInputBindingWithType:nil forKey:str];
        }
    }

}


// the array comes from the Lac string parser,
// and is expected to be filled with NSDictionary objects with string key/value pairs
- (void)parseInputBindingsFromArray:(NSArray *)props
{
    NSEnumerator *arrEnum = [props objectEnumerator];
    NSDictionary *prop;
    while (prop = [arrEnum nextObject]) {
        NSString *key = [[prop keyEnumerator] nextObject];
        if (key) {
            id value = [prop objectForKey:key];
            
            [self applyInputBindingProperty:value forKey:key];
        }
    }
}

- (void)parseOutputBindingsFromArray:(NSArray *)props
{
    NSEnumerator *arrEnum = [props objectEnumerator];
    NSDictionary *prop;
    while (prop = [arrEnum nextObject]) {
        NSString *key = [[prop keyEnumerator] nextObject];
        if (key) {
            id value = [prop objectForKey:key];
            
            [self applyOutputBindingProperty:value forKey:key];
        }
    }
}


#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    // encode node observers only if they're owned by us
    // (the idea is that we don't want to encode controller layer objects that may have registered as observers)
    NSMutableArray *encObs = [NSMutableArray array];
    NSEnumerator *obsEnum = [_nodeObservers objectEnumerator];
    id ob;
    while (ob = [obsEnum nextObject]) {
        if ([_nodes containsObject:ob]) {
            [encObs addObject:ob];
        }
    }
    if ([encObs count] > 0) {
        [coder encodeObject:[NSArray arrayWithArray:encObs] forKey:@"LAC::Mutable::nodeObserverNodes"];
    }
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _nodeObservers = [[NSMutableArray alloc] initWithCapacity:16];
    
        NSArray *encObs = [coder decodeObjectForKey:@"LAC::Mutable::nodeObserverNodes"];
        if ([encObs count] > 0) {
            [_nodeObservers addObjectsFromArray:encObs];
        }
    }

	return self;
}


@end
