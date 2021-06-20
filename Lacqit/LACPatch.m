//
//  LACPatch.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACPatch.h"
#import "LACNode.h"
#import "LACInput.h"
#import "LACOutput.h"
#import "LACPublishedInputNode.h"
#import "LACArrayListDictionary.h"


// evaluation context dictionary keys
NSString * const kLACCtxKey_ExternalInputValues = @"__externalInputValues__";
NSString * const kLACCtxKey_Stack = @"_stack";



@implementation LACPatch

+ (NSString *)lacTypeID {
    return @"Closure"; }
    

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p -- '%@', %i nodes, interface in/out %i/%i>",
                        [self class], self,
                        [self name], (int)[_nodes count], (int)[[_inputInterface allKeys] count], (int)[[_outputInterface allKeys] count]];
}

+ (NSArray *)deepCopyOfNodes:(NSArray *)nodes outMapping:(NSDictionary **)outMap
{
    if ( !nodes)
        return nil;
        
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    
    NSEnumerator *nodeEnum = [nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        //NSLog(@"doing patch deep copy: copying '%@'...", node);
        [node deepCopyWithMap:map];
    }
    
    NSArray *copies = [NSArray arrayWithArray:[map allValues]];
    
    // this assertion isn't needed, it's OK if the node array contains the same node multiple times
    ///NSAssert2([copies count] == [nodes count], @"copy count mismatch (%i, orig %i)", [copies count], [nodes count]);
    
    if (outMap) *outMap = map;
    return copies;
}

- (void)_initNodesIvarWithArray:(NSArray *)nodes
{
    if (_nodes)
        [_nodes release];

    _nodes = (nodes) ? nodes : (NSArray *)[NSArray array];
    [_nodes retain];
}

- (id)init
{
    self = [super init];
    _name = [@"(untitled)" retain];
    _inputInterface = [[NSMutableDictionary alloc] init];
    _outputInterface = [[NSMutableDictionary alloc] init];
    
    _scaleFactor = 1.0;
    
    [self _initNodesIvarWithArray:nil];
    if ([_nodes count] > 0)
        [_nodes makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    
    return self;
}

- (id)initWithName:(NSString *)name nodesNoCopy:(NSArray *)nodes
        inputInterface:(NSDictionary *)inInt
        outputInterface:(NSDictionary *)outInt
{
    self = [super init];
    _name = [(name) ? name : (NSString *)@"(untitled)" retain];
    _inputInterface = [[NSMutableDictionary alloc] initWithDictionary:inInt];
    _outputInterface = [[NSMutableDictionary alloc] initWithDictionary:outInt];
    
    [self _initNodesIvarWithArray:nodes];
    if ([_nodes count] > 0)
        [_nodes makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
    
    return self;
}


- (NSDictionary *)_translateOutputInterface:(NSDictionary *)oldDict
                    fromOriginalNodes:(NSArray *)nodes
                    usingMapping:(NSDictionary *)map
{
    NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
    
    NSEnumerator *keyEnum = [oldDict keyEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject]) {
        id obj = [oldDict objectForKey:key];
        if ([obj isKindOfClass:[LACOutput class]]) {
            LACOutput *outp = (LACOutput *)obj;
            LXInteger index = [outp index];
            LACNode *node = [outp owner];
        
            LACNode *copiedNode = [map objectForKey:[NSValue valueWithPointer:node]];
            NSAssert2(copiedNode, @"node copy doesn't exist (original %@, had output %i in interface)", node, (int)index);
        
            LACOutput *copiedOutp = [[copiedNode outputs] objectAtIndex:index];
        
            [newDict setObject:copiedOutp forKey:key];
        }
        else if ([obj isKindOfClass:[LACInput class]]) {
            LACInput *inp = (LACInput *)obj;
            LACNode *node = [inp owner];
            
            LACNode *copiedNode = [map objectForKey:[NSValue valueWithPointer:node]];
            NSAssert1(copiedNode, @"node copy doesn't exist (original %@, had input in interface)", node);
        
            LACInput *copiedInp = [[copiedNode inputs] objectAtIndex:[[node inputs] indexOfObject:inp]];
        
            [newDict setObject:copiedInp forKey:key];
        }
        //NSLog(@"  - did copy output interface binding: %@ -- orig was %@; new is %@", key, outp, copiedOutp);
    }
    
    return newDict;
}

- (id)initWithName:(NSString *)name nodes:(NSArray *)nodes
        inputInterface:(NSDictionary *)inInt
        outputInterface:(NSDictionary *)outInt
{
    NSDictionary *map = nil;
    NSArray *copiedNodes = [[self class] deepCopyOfNodes:nodes outMapping:&map];
    
    // the output interface contains references to the pre-copy nodes,
    // so those must be reset accordingly
    NSDictionary *copiedOutInt = [self _translateOutputInterface:outInt
                                                fromOriginalNodes:nodes
                                                usingMapping:map];

    self = [self initWithName:name
                    nodesNoCopy:copiedNodes
                    inputInterface:inInt
                    outputInterface:copiedOutInt
                 ];
    return self;
}

- (id)initWithName:(NSString *)name nodes:(NSArray *)nodes
{
    return [self initWithName:name nodes:nodes inputInterface:nil outputInterface:nil];
}

- (void)dealloc
{
    [_nodes makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    [_nodes release];
    [_name release];
    [_inputInterface release];
    [_outputInterface release];
    [super dealloc];
}

- (NSString *)name {
    return _name; }


- (NSDictionary *)publishedInputInterface {
    return _inputInterface; }

- (NSEnumerator *)publishedInputNamesSortedEnumerator {
    // TODO: keep the keys in their original order
    return [_inputInterface keyEnumerator]; }


- (LACOutput *)outputForInputBinding:(NSString *)key
{
    if ( !key || [key length] < 1)
        return nil;
        
    Class cls = [LACPublishedInputNode class];
        
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        if ([node isKindOfClass:cls] && [[node name] isEqualToString:key]) {
            return [node primeOutput];
        }
    }
    return nil;

}

- (NSDictionary *)publishedOutputInterface {
    return _outputInterface; }

- (NSEnumerator *)publishedOutputNamesSortedEnumerator {
    // TODO: keep the keys in their original order
    return [_outputInterface keyEnumerator]; }

- (id)objectForOutputBinding:(NSString *)key
{
    return [_outputInterface objectForKey:key];
}

- (LACOutput *)nodeOutputForOutputBinding:(NSString *)key
{
    id obj = [_outputInterface objectForKey:key];
    if ([obj isKindOfClass:[LACOutput class]]) {
        return (LACOutput *)obj;
    } else if ([obj respondsToSelector:@selector(connectedOutput)]) {
        return [(LACInput *)obj connectedOutput];
    }
    return nil;
}
    

- (NSArray *)allNodes {
    return _nodes; }
    
- (NSEnumerator *)nodeEnumerator {
    return [_nodes objectEnumerator]; }

- (LACNode *)nodeNamed:(NSString *)name {
    if ( !name || [name length] < 1)
        return nil;
        
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        if ([[node name] isEqualToString:name])
            return node;
    }
    return nil;
}

- (LACNode *)nodeWithTag:(LXInteger)tag {
    if (tag <= 0)
        return nil;

    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        if ([node tag] == tag)
            return node;
    }
    return nil;
}

// path to an output is either with ordinal ("nodeName.1") or name ("nodeName.outputName")
- (LACOutput *)outputWithNodePath:(NSString *)name
{
    NSString *nodeName = name;
    NSString *subName = nil;
    NSRange range;
    if ((range = [name rangeOfString:@"."]).location != NSNotFound) {
        nodeName = [name substringToIndex:range.location];
        subName = [name substringFromIndex:range.location + 1];            
    }
    
    LACNode *node = [self nodeNamed:nodeName];
    LACOutput *outp = (subName) ? [node outputNamed:subName] : [node primeOutput];
    
    if ( !outp && [subName rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
        // subname is a number, so try to use it as an input index
        LXInteger index = [subName intValue];
        if ([[node outputs] count] > index)
            outp = [[node outputs] objectAtIndex:index];        
    }

    return outp;
}

- (LACInput *)inputWithNodePath:(NSString *)name
{
    NSString *nodeName = name;
    NSString *subName = nil;
    NSRange range;
    if ((range = [name rangeOfString:@"."]).location != NSNotFound) {
        nodeName = [name substringToIndex:range.location];
        subName = [name substringFromIndex:range.location + 1];            
    }
    
    LACNode *node = [self nodeNamed:nodeName];
    LACInput *inp = (subName) ? [node inputNamed:subName] : [node primeInput];
    
    if ( !inp && [subName rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
        // subname is a number, so try to use it as an input index
        LXInteger index = [subName intValue];
        if ([[node inputs] count] > index)
            inp = [[node inputs] objectAtIndex:index];
    }

    return inp;
}

- (NSDictionary *)nodeConnectionsByTagPlist
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSEnumerator *nodeEnum = [self nodeEnumerator];
    id node;
    while (node = [nodeEnum nextObject]) {
        NSEnumerator *inpEnum = [[node inputs] objectEnumerator];
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[[node inputs] count]];
        LACInput *inp;
        while (inp = [inpEnum nextObject]) {
            id connInfo = @"";
            if ([inp isConnected]) {
                LACOutput *connOutp = [inp connectedOutput];
                connInfo = [NSString stringWithFormat:@"%ld.%i", (long)[[connOutp owner] tag], (int)[connOutp index]];
            }
            [arr addObject:connInfo];
        }
        [dict setObject:arr forKey:[NSNumber numberWithLong:[node tag]]];
    }
    return dict;
}


#pragma mark --- NSCopying ---

- (Class)classForImmutableCopy {
    return [LACPatch class]; }

- (Class)classForDeepCopy {
    return [self class]; }

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self classForImmutableCopy] alloc] initWithName:_name nodes:_nodes
                                                 inputInterface:_inputInterface
                                                 outputInterface:_outputInterface];
}

- (id)deepCopyWithAppliedMappingPtr:(NSDictionary **)outMap
{
    NSDictionary *map = nil;
    NSArray *copiedNodes = [[self class] deepCopyOfNodes:_nodes outMapping:&map];

    // the output interface contains references to the pre-copy nodes,
    // so those must be reset accordingly
    NSDictionary *copiedOutInt = [self _translateOutputInterface:_outputInterface
                                                fromOriginalNodes:_nodes
                                                usingMapping:map];
    
    if (outMap) *outMap = map;
    
    //NSLog(@"%s, %@ -- mapping: %@", __func__, self, map);
    
    return [[[self classForDeepCopy] alloc] initWithName:_name nodesNoCopy:copiedNodes
                                                 inputInterface:_inputInterface
                                                 outputInterface:copiedOutInt];
}



#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSString stringWithString:_name] forKey:@"LAC::name"];
    
    [coder encodeObject:_nodes forKey:@"LAC::nodes"];
    
    [coder encodeObject:_inputInterface forKey:@"LAC::inputInterface"];
    [coder encodeObject:_outputInterface forKey:@"LAC::outputInterface"];
    
    [coder encodeDouble:_scaleFactor forKey:@"LAC::globalScaleFactor"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	_name = [[coder decodeObjectForKey:@"LAC::name"] retain];
    
    _nodes = [[coder decodeObjectForKey:@"LAC::nodes"] retain];
    
    _inputInterface = [[coder decodeObjectForKey:@"LAC::inputInterface"] retain];
    _outputInterface = [[coder decodeObjectForKey:@"LAC::outputInterface"] retain];
    
    _scaleFactor = ([coder containsValueForKey:@"LAC::globalScaleFactor"]) ? [coder decodeDoubleForKey:@"LAC::globalScaleFactor"] : 1.0;
    if (_scaleFactor <= 0.0000001)
        _scaleFactor = 1.0;
    
    NSEnumerator *nodeEnum = [_nodes objectEnumerator];
    LACNode *node;
    while (node = [nodeEnum nextObject]) {
        [node setOwner:self];
    }

	return self;
}


#pragma mark --- node input change notifs ---
// these are sent directly by the LACInput

- (void)connectionWillChangeForInput:(LACInput *)input
{
    // mutable patch overrides this
    NSLog(@"** connections shouldn't be modified on a non-mutable patch\n   (%@; %@)", self, input);
}


#pragma mark --- execution ---

// this is a callback that is called within evaluation from a node's -preEval method
- (LACArrayListPtr)node:(LACNode *)node
                   requestsEvaluationOfOutput:(LACOutput *)output
{
    LACArrayListPtr cachedResult = NULL;
    
    // check if we already have a cached result
    if ((cachedResult = [_resultsCache arrayListForWeakKey:output])) {
        return cachedResult;
    }
    
    // TODO: should check against cycles before evaluating
    
    ///NSLog(@"%s -- current context: %@", __func__, _currCtx);
    
    LACArrayListPtr result = [self evaluateOutput:output withContext:_currCtx];
    
    //NSLog(@"%s (%p): completed evaluation requested by node %@; result is %@; cache is %@", __func__, self, node, LACArrayListDescribe(result), _resultsCache);
    
    if (_resultsCache) {
        if ( !result) result = LACEmptyArrayList;
        [_resultsCache setArrayList:result forWeakKey:output];
        //NSLog(@" ... did store result %p for key %@", result, output);
    }

    return result;
}

- (NSMutableDictionary *)innerContextFromEvalContext:(NSDictionary *)outerCtx
{
    NSMutableDictionary *innerCtx = [NSMutableDictionary dictionary];
    
    NSEnumerator *keyEnum = [outerCtx keyEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject]) {
        // private keys are marked with a "__" prefix; don't copy those to the inner scope
        if ([key rangeOfString:@"__"].location != 0) {
            [innerCtx setObject:[outerCtx objectForKey:key] forKey:key];
        }
    }
    return innerCtx;
}


static void releaseArrayListsInDictionary(NSDictionary *resultsCache)
{
    NSEnumerator *keyEnum = [resultsCache keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        id val = [resultsCache objectForKey:key];
        LACArrayListPtr cachedList = (LACArrayListPtr)[val pointerValue];
        
        LACArrayListRelease(cachedList);
    }
}

- (void)_logExtraInfoAboutEvalResultObject:(id)obj inDictionary:(NSMutableDictionary *)dict
{
    // subclasses can override to log more data
}

- (BOOL)isCompatibleWithPatch:(LACPatch *)patch
{
    return NO;
}

void LACPatchEvalIncompatibleNodeError_(id self, id node, id owner)
{
    NSLog(@"** %s (%@): can't eval node that is not part of this patch and was not determined compatible (%@; owner: %@)", __func__, self, node, owner);
}

- (LACArrayListPtr)evaluateOutput:(LACOutput *)output withContext:(NSDictionary *)evalCtx
{
    if ( !output)
        return NULL;
    if ( ![output isKindOfClass:[LACOutput class]]) {
        NSLog(@"*** %@: invalid output specified for evaluation: %@ (%@)", self, [output class], output);
        return NULL;
    }
        
    LACNode *node = (LACNode *)[output owner];
        
    if ( ![_nodes containsObject:node]) {
        if ([self isCompatibleWithPatch:[node owner]]) {
        } else {
            LACPatchEvalIncompatibleNodeError_(self, node, [node owner]);
            return NULL;
        }
    }

    LXInteger outputIndex = [[node outputs] indexOfObject:output];    
    NSAssert(outputIndex != NSNotFound, @"output doesn't belong to its owner node");

    return [self evaluateNode:node forOutputAtIndex:outputIndex withContext:evalCtx];
}


//#define EVALDEBUG(format, args...) NSLog(format, ## args);
#define EVALDEBUG(format, args...)


- (LACArrayListPtr)evaluateNode:(LACNode *)node forOutputAtIndex:(LXInteger)outputIndex
                                                withContext:(NSDictionary *)evalCtx
{
    NSAssert(node, @"can't evaluate nil");

    if (_evalDepth == 0 && !_resultsCache)
        _resultsCache = [[LACArrayListDictionary alloc] init];
    _evalDepth++;

    NSDictionary *innerCtx = evalCtx;
    
    // check if node wants to do pre-evaluation state init
    BOOL nodeNeedsPrePostEval = [node wantsPreAndPostEvaluation];
    BOOL nodeAlreadyHadPrePost = NO;
    if (nodeNeedsPrePostEval) {
        // 2011.01.14 -- need to keep track of whether the node already had this callback,
        // so stuff it in this existing transient cache. kind of ugly...
        id nodeEvalInfo = LACArrayListFirstObject([_resultsCache arrayListForWeakKey:node]);
        nodeAlreadyHadPrePost = ([nodeEvalInfo objectForKey:@"hasHadPrePostEval"] != nil);
        
        if (nodeAlreadyHadPrePost) {
            nodeNeedsPrePostEval = NO;
        } else {
            NSMutableDictionary *ctx = [NSMutableDictionary dictionaryWithDictionary:evalCtx];
            innerCtx = ctx;
            _currCtx = ctx;
            [node willEvaluateWithContext:ctx];
            
            // store a flag to indicate that this node already got preposteval once during this eval session.
            // this ensures that the node gets only one -willEval notif, and can rely on this callback
            // to do stuff like increment a frame counter if it has multiple outputs.
            // (this was implemented for the Conduit 3D Stereo Tools)
            if ( !nodeEvalInfo)  nodeEvalInfo = [NSMutableDictionary dictionary];
            [nodeEvalInfo setObject:[NSNumber numberWithBool:YES] forKey:@"hasHadPrePostEval"];
            LACArrayListPtr al = LACArrayListCreateWithObject(nodeEvalInfo);
            [_resultsCache setArrayList:al forWeakKey:node];
            LACArrayListRelease(al);
        }
    }
    
    //NSLog(@"%s (%p): now evaluating node %@, depth %ld, wants pre %i (already had: %i), cache %p; context %@", __func__, self, node, (long)_evalDepth, nodeNeedsPrePostEval, nodeAlreadyHadPrePost, _resultsCache, innerCtx);
    
    // pull inputs.
    // if the node wants lazy evaluation, it's assumed that it has already pulled its needed values
    // inside its pre-eval call
    const BOOL nodeWantsLazyEval = [node wantsLazyEvaluationOfInputs];
    
    const LXInteger inputsCount = [[node inputs] count];
    const LXInteger inpListsArraySizeOnStack = (inputsCount > 0) ? inputsCount : 1;
    LACArrayListPtr inputLists[inpListsArraySizeOnStack];
    
    if (inputsCount == 0)  inputLists[0] = NULL;
    
    LXInteger i;
    for (i = 0; i < inputsCount; i++) {
        LACInput *inp = [[node inputs] objectAtIndex:i];
        LACOutput *output = [inp connectedOutput];
        
        ///EVALDEBUG(@"node '%@': input %i: connected output %@; wantslazy: %i", [node name], i, output, nodeWantsLazyEval);

        LACArrayListPtr theList = NULL;
        if (output) {
            // check if this result was already evaluated
            if (_resultsCache && (theList = [_resultsCache arrayListForWeakKey:output])) {
                // must retain here because all values in inputLists will be released at the end of this method
                LACArrayListRetain(theList);
                ///NSLog(@".. found existing eval result for output %@; cached listptr is %p", output, theList);
            }
            else if ( !nodeWantsLazyEval) {
                EVALDEBUG(@"node '%@' (%p) / input %i/%i - doing regular eval (non-lazy) for output owned by '%@'...", [node name], node, i+1, inputsCount, [output owner]);
                
                theList = [self evaluateOutput:output withContext:innerCtx];
                
                if (theList) {
                    if (_resultsCache) {
                        [_resultsCache setArrayList:theList forWeakKey:output];
                    }
                } else {
                    NSLog(@"** %s (%p): output %@ returned nil (node '%@')", __func__, self, output, [[output owner] name]);
                }
            }
            else {
                EVALDEBUG(@"won't render '%@', downstream node wants lazy eval", output);
            }
        }
        inputLists[i] = theList;
    }
    /*
    NSMutableArray *inputValues = [NSMutableArray arrayWithCapacity:inputsCount];
    
    NSEnumerator *inpEnum = [[node inputs] objectEnumerator];
    LACInput *inp;
    while (inp = [inpEnum nextObject]) {
        LACOutput *output = [inp connectedOutput];
        id val = nil;
        if (output) {
            // check if this result was already evaluated
            if (_resultsCache && (val = [_resultsCache objectForKey:[NSValue valueWithPointer:output]])) {
                NSLog(@".. found existing eval result for output %@; val is %@", output, val);
            }
            else if ( !nodeWantsLazyEval) {
                NSArray *result = [self evaluateOutput:output withContext:innerCtx];
                if (result) {
                    val = result;

                    if (_resultsCache)
                        [_resultsCache setObject:result forKey:[NSValue valueWithPointer:output]];
                } else {
                    NSLog(@"** %s: output %@ returned nil (node '%@')", __func__, output, [[output owner] name]);
                }
            }
        }
        [inputValues addObject:(val) ? val : [NSArray array]];
    }*/
    
    // evaluate the node
    // (returned list is retained, but it's the caller's duty to release it)
    LACArrayListPtr resultsList = [node evaluateOutputAtIndex:outputIndex inputLists:inputLists context:innerCtx];
    
    // finished, let node clean up its eval state
    if (nodeNeedsPrePostEval) {
        [node didEvaluateWithContext:(id)innerCtx];
        _currCtx = nil;
    }
    innerCtx = nil;
    
    if ([node delegate]) {
        resultsList = [node delegateEvalResult:resultsList
                            outputIndex:outputIndex
                            inputLists:inputLists
                            context:evalCtx];
    }
    
    // log info about the eval state, if requested.
    // (in CL2, this info will be displayed in the stream overlay window)
    if (_enableEvalLog) {
        LXInteger nodeTag = [node tag];
        NSString *nodePath = [NSString stringWithFormat:@"%ld.outputs[%ld]", (long)nodeTag, (long)outputIndex];
        
        LACOutput *output = (outputIndex >= 0 && outputIndex < [[node outputs] count]) ? [[node outputs] objectAtIndex:outputIndex] : nil;
        LXInteger resCount = LACArrayListCount(resultsList);
        
        NSMutableDictionary *logDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithLong:resCount], @"resultListCount",
                                            nil];
        if (output) {
            [logDict setObject:[output name] forKey:@"outputName"];
        }
        if (resCount > 0) {
            LXInteger n = MIN(resCount, 16);
            NSMutableArray *infoArr = [NSMutableArray arrayWithCapacity:n];
            
            for (i = 0; i < n; i++) {
                id obj = LACArrayListObjectAt(resultsList, i);
                NSString *type = LACTypeIDFromObject(obj);
                id indexName = LACArrayListIndexNameAt(resultsList, i);                
                if ([indexName length] == 0)
                    indexName = [NSNumber numberWithLong:i];  //[NSString stringWithFormat:@"%ld", (long)outputIndex];
                
                NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:indexName, @"indexName", type, @"type", nil];
                
                if ([obj isKindOfClass:[NSString class]]) {
                    [infoDict setObject:[[obj copy] autorelease] forKey:@"stringValue"];
                } else if ([obj isKindOfClass:[NSData class]]) {
                    [infoDict setObject:[NSNumber numberWithLong:[obj length]] forKey:@"length"];
                } else if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
                    [infoDict setObject:[NSNumber numberWithLong:[obj count]] forKey:@"length"];
                } else if ([obj respondsToSelector:@selector(doubleValue)]) {
                    [infoDict setObject:[NSNumber numberWithDouble:[obj doubleValue]] forKey:@"doubleValue"];
                }
                [self _logExtraInfoAboutEvalResultObject:obj inDictionary:infoDict];
                
                [infoArr addObject:infoDict];
            }
            [logDict setObject:infoArr forKey:@"resultListInfoArray"];
        }
        
        [_evalLog setObject:logDict forKey:nodePath];
    }
    

    for (i = 0; i < inputsCount; i++) {
        LACArrayListRelease(inputLists[i]);
    }

    _evalDepth--;    
    if (_evalDepth == 0 && _resultsCache) {
        [_resultsCache release];
        _resultsCache = nil;
    }

    //NSLog(@"--- evaldepth %i", _evalDepth);
    return resultsList;
}


@end
