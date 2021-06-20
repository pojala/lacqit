//
//  LACNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 30.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACNode.h"
#import "LACNode_priv.h"
#import "LACInput.h"
#import "LACOutput.h"
#import "LACPatch.h"
#import "LACArrayListDictionary.h"


//#define DEBUGLOG(format, args...)   NSLog(format , ## args);
#define DEBUGLOG(format, args...)


@implementation LACNode


+ (NSString *)packageIdentifier
{
    return [NSString stringWithFormat:@"fi.lacquer.lac.%@", NSStringFromClass(self)];
}

+ (NSString *)proposedDefaultName {
    return @"untitled";
}    

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p -- %@>",
                        [self class], self,
                        [self name]];
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    _name = [(name) ? name : (NSString *)@"(Untitled)" retain];
    
    _centerPoint = NSMakePoint(100, 100);
    _scaleFactor = 1.0;
    
    return self;
}

- (void)disconnectOutputs
{
	NSEnumerator *outEnum = [_outputs objectEnumerator];
    LACOutput *outp;
	while (outp = [outEnum nextObject]) {
        NSSet *inps = [outp connectedInputs];
        if ([inps count] > 0) {
            NSSet *tempSet = [NSSet setWithSet:inps];
            [tempSet makeObjectsPerformSelector:@selector(disconnect)];
        }
    }
}

- (void)disconnectAll
{
    [self disconnectOutputs];
    [_inputs makeObjectsPerformSelector:@selector(disconnect)];
}

- (void)dealloc
{
    [self disconnectAll];
    [_inputs makeObjectsPerformSelector:@selector(setOwner:) withObject:nil];
    
    [_inputs release];
    [_outputs release];
    
    [_name release];
    [super dealloc];
}


- (NSArray *)inputs {
    return _inputs; }
    
- (NSArray *)outputs {
    return _outputs; }


- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag; }


- (LACInput *)primeInput {
    if ([_inputs count] < 1) {
        //NSLog(@"** %s: no inputs (%@)", __func__, self);
        return nil;
    }
    return (LACInput *)[_inputs objectAtIndex:0];
}
    
- (LACOutput *)primeOutput {
    if ([_outputs count] < 1) {
        //NSLog(@"** %s: no outputs (%@)", __func__, self);
        return nil;
    }
    return (LACOutput *)[_outputs objectAtIndex:0];
}

- (LACInput *)inputNamed:(NSString *)name
{
    LXInteger n = [_inputs count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        LACInput *input = [_inputs objectAtIndex:i];
        if ([[input name] isEqualToString:name])
            return input;
    }
    return nil;
}

- (LACOutput *)outputNamed:(NSString *)name
{
    LXInteger n = [_outputs count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        LACOutput *output = [_outputs objectAtIndex:i];
        if ([[output name] isEqualToString:name])
            return output;
    }
    return nil;
}


- (id)owner {
    return _owner; }

- (void)setOwner:(id)owner {
    _owner = owner; }

- (id)delegate {
    return _delegate; }
    
- (void)setDelegate:(id)del {
    _delegate = del; }


- (NSDictionary *)upstreamProvidedContext {
    return nil; }
    
- (NSDictionary *)downstreamRequiredContext {
    return nil; }
    
- (NSDictionary *)downstreamWillUseIfAvailableContext {
    return nil; }


#pragma mark --- evaluation utilities ---

// this is a separate method so subclasses can more easily do delegation
- (LACArrayListPtr)delegateEvalResult:(LACArrayListPtr)result
                        outputIndex:(LXInteger)outputIndex
                        inputLists:(LACArrayListPtr *)inputLists
                        context:(NSDictionary *)context
{
    if (_delegate && [_delegate respondsToSelector:@selector(willEvaluateFuncNode:proposedResult:outputIndex:inputLists:context:)]) {
        LACArrayListPtr newResult = [_delegate willEvaluateFuncNode:self
                                        proposedResult:result
                                        outputIndex:outputIndex
                                        inputLists:inputLists
                                        context:context];
                                        
        if ( !newResult || newResult == result)
            return result;
        else {
            LACArrayListRelease(result);
            return newResult;
        }
    }
    else
        return result;
}

- (LACArrayListPtr)_evalPatch:(LACPatch *)patch
                    withInputList:(LACArrayListPtr)inputList
                    outerContext:(NSDictionary *)outerCtx
{
    NSString *patchOutpBindingName = [[patch publishedOutputNamesSortedEnumerator] nextObject];
    LACOutput *innerOutput = [patch nodeOutputForOutputBinding:patchOutpBindingName];
        
    if ( !patchOutpBindingName || !innerOutput) {
        NSLog(@"%@: can't eval this patch (%@), lacks output bindings (%@, %p)", self, patch, patchOutpBindingName, innerOutput);
        return NULL;
    }

    NSString *patchInpBindingName = (inputList) ? [[patch publishedInputNamesSortedEnumerator] nextObject] : nil;
    
    if (inputList && !patchInpBindingName) {
        NSLog(@"%@: can't eval this patch (%@), lacks input bindings (%@)", self, patch, patchInpBindingName);
        return NULL;
    }

    NSMutableDictionary *innerCtx = [[self owner] innerContextFromEvalContext:outerCtx];
    
    if (inputList && inputList->count > 0) {
        [innerCtx setObject:[LACArrayListDictionary dictionaryWithArrayList:inputList forKey:patchInpBindingName]
                     forKey:kLACCtxKey_ExternalInputValues];
    }
    
    LACArrayListPtr resultList = [patch evaluateOutput:innerOutput withContext:innerCtx];
    return resultList;
}

- (BOOL)boolValueFromInputObject:(id)obj evalContext:(NSDictionary *)outerCtx
{
    BOOL f = NO;
    
    DEBUGLOG(@"%@: getting boolvalue for obj %@ (%@)", self, [obj class], obj);
    
    if ([obj isKindOfClass:[LACPatch class]]) {
        LACArrayListPtr res = [self _evalPatch:(LACPatch *)obj withInputList:NULL outerContext:outerCtx];
        
        obj = LACArrayListFirstObject(res);
        [[obj retain] autorelease];
        LACArrayListRelease(res);
    }
    
    if ([obj respondsToSelector:@selector(boolValue)]) {
        f = [obj boolValue];
    } 
    else if ([obj respondsToSelector:@selector(doubleValue)]) {
        double d = [obj doubleValue];
        f = (fabs(d) != 0.0);
    }
    
    DEBUGLOG(@"    .. %@", (f) ? @"true" : @"false");
    return f;
}
/*
- (NSArray *)arrayValueFromInputObject:(id)obj evalContext:(NSDictionary *)outerCtx
{
    if ([obj isKindOfClass:[LACPatch class]]) {
        obj = [self _evalPatch:(LACPatch *)obj withInput:nil outerContext:outerCtx];
    }

    if ( !obj)
        return [NSArray array];
        
    else if ([obj isKindOfClass:[NSArray class]])
        return obj;
    else
        return MAKEARR(obj);
}
*/

#pragma mark --- evaluation methods ---

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    return NULL;
}

+ (BOOL)usesTransientState {
    return NO; }

- (BOOL)wantsPreAndPostEvaluation {
    return NO; }

- (BOOL)wantsLazyEvaluationOfInputs {
    return NO; }

- (BOOL)wantsNotificationOnConnectionChange {
    return NO; }

- (void)willEvaluateWithContext:(NSMutableDictionary *)context {
}

- (void)didEvaluateWithContext:(NSMutableDictionary *)context {
}


#pragma mark --- visual state ---

- (NSPoint)centerPoint {
    return _centerPoint; }
    
- (void)setCenterPoint:(NSPoint)point {
    _centerPoint = point; }


- (LXFloat)scaleFactor {
    return _scaleFactor; }
    
- (void)setScaleFactor:(LXFloat)f {
    _scaleFactor = f; }


// the appearance flags are set by the comp UI for misc persistent state such as whether
// node parameters are collapsed or not.
// we don't need to care about what they are in this class, we just store them.
- (LXUInteger)nodeAppearanceFlags {
    return _appearanceFlags; }
    
- (void)setNodeAppearanceFlags:(LXUInteger)flags {
    _appearanceFlags = flags; }


#pragma mark --- recursive sorting ---

/* this group of methods is used to sort nodes before rendering.
   nodes are sorted by depth of connections, descending.
   this ensures that a node connected to an input is always rendered
   before the node that owns the input.
*/

- (void)clearSortLevel {
    _sortLevel = 0; }

- (LXInteger)sortLevel {
    return _sortLevel; }


- (LXInteger)compareSortLevelTo:(id)node
{
    LXInteger level = [node sortLevel];
    if (level == _sortLevel)
        return NSOrderedSame;
    else if (level > _sortLevel)
        return NSOrderedDescending;
    else
        return NSOrderedAscending;
}

- (void)incrementSortLevelOfConnectedNodes
{
    LXInteger newLevel = _sortLevel + 1;
    NSEnumerator *enumerator = [_inputs objectEnumerator];
    LACInput *input;
    while (input = [enumerator nextObject]) {
        LACNode *node = [[input connectedOutput] owner];
        if (node) {
            LXInteger level = [node sortLevel];
            if (level >= newLevel)
                [node setSortLevel:(level+1)];
            else
                [node setSortLevel:newLevel];
        }
    }
}

- (void)setSortLevel:(LXInteger)level {
    _sortLevel = level;
	///DEBUGLOG(@"node %@, sortlevel %i", [self name], _sortLevel);
    [self incrementSortLevelOfConnectedNodes];
}


#pragma mark --- ui bindings ---

- (NSArray *)editableBindingDescriptions
{
    return nil;
}


#pragma mark --- copying ---

- (void)_setInputs:(NSArray *)inputs
{
    [_inputs autorelease];
    _inputs = [inputs retain];
    [_inputs makeObjectsPerformSelector:@selector(setOwner:) withObject:self];
}

- (void)_setOutputs:(NSArray *)outputs
{
    [_outputs autorelease];
    _outputs = [outputs retain];
    
    LXInteger n = [_outputs count];
    LXInteger i;
    for (i = 0; i < n; i++) {
        [[_outputs objectAtIndex:i] setOwner:self index:i];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    LACNode *newNode = [[[self class] alloc] initWithName:_name];
    
    [newNode _setInputs:[[[NSArray alloc] initWithArray:_inputs copyItems:YES] autorelease]];
    [newNode _setOutputs:[[[NSArray alloc] initWithArray:_outputs copyItems:YES] autorelease]];
    
    [newNode setCenterPoint:_centerPoint];
    [newNode setScaleFactor:_scaleFactor];
    [newNode setNodeAppearanceFlags:_appearanceFlags];
    
    return newNode;
}

- (id)deepCopyWithMap:(NSMutableDictionary *)map
{
    NSAssert(map, @"can't deep copy without mapping");
    
    id key = [NSValue valueWithPointer:self];
    
    id copy;
    if ((copy = [map objectForKey:key])) {
        // found a copy already
    } else {
        copy = [self copy];
        [map setObject:[copy autorelease] forKey:key];
        
        DEBUGLOG(@"copying node %@ -- copy is %@", self, copy);
        
        if (_delegate)
            [copy setDelegate:_delegate];
        
        // copy upstream connections using map
        LXInteger inputCount = [_inputs count];
        LXInteger i;
        for (i = 0; i < inputCount; i++) {
            LACInput *inp = [_inputs objectAtIndex:i];
            LACOutput *connOut = [inp connectedOutput];
            if (connOut) {
                LXInteger outpIndex = [connOut index];
                LACNode *connNode = [connOut owner];
                
                LACNode *copyOfConnNode = [connNode deepCopyWithMap:map];
                
                LACOutput *copyOfConnOut = [[copyOfConnNode outputs] objectAtIndex:outpIndex];
                
                LACInput *copyOfInp = [[copy inputs] objectAtIndex:i];
                
                [copyOfInp connectToOutput:copyOfConnOut];
            }
        }
    }
    return copy;
}



#pragma mark --- NSCoding protocol ---

#if defined(LX64BIT) || defined(__LP64__)
 #define ENCODEINTEGER(i_, key_)    [coder encodeInt64:i_ forKey:key_]
 #define DECODEINTEGER(key_)        [coder decodeInt64ForKey:key_]
#else
 #define ENCODEINTEGER(i_, key_)    [coder encodeInt:i_ forKey:key_]
 #define DECODEINTEGER(key_)        [coder decodeIntForKey:key_]
#endif


- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSString stringWithString:_name] forKey:@"LAC::name"];
    
    [coder encodeObject:_inputs forKey:@"LAC::inputs"];
    [coder encodeObject:_outputs forKey:@"LAC::outputs"];
    
    // owner and delegate are intentionally not encoded
    
    ENCODEINTEGER(_tag, @"LAC::tag");
    
   	[coder encodePoint:_centerPoint forKey:@"LAC::UI::centerPoint"]; 
    [coder encodeDouble:_scaleFactor forKey:@"LAC::UI::scaleFactor"];
    
    ENCODEINTEGER(_appearanceFlags, @"LAC::UI::appearanceFlags");
}

- (id)initWithCoder:(NSCoder *)coder
{
	_name = [[coder decodeObjectForKey:@"LAC::name"] retain];
    
    _inputs = [[coder decodeObjectForKey:@"LAC::inputs"] retain];
    _outputs = [[coder decodeObjectForKey:@"LAC::outputs"] retain];
    
    _tag = DECODEINTEGER(@"LAC::tag");
    
    _centerPoint = [coder decodePointForKey:@"LAC::UI::centerPoint"]; 
    _scaleFactor = [coder decodeDoubleForKey:@"LAC::UI::scaleFactor"];
    
    _appearanceFlags = DECODEINTEGER(@"LAC::UI::appearanceFlags");

	return self;
}




#pragma mark --- EDUINodeGraphConnectable protocol ---

// this class doesn't use nodeType/connectionType values (although subclasses like LQStreamNode might)
// but the UI requires some values for these, so these defaults are provided
enum {
    kLACNodeDefaultType = 1
};

- (NSString *)name {
    return _name; }
    
- (LXUInteger)nodeType {
    return kLACNodeDefaultType; }

- (BOOL)acceptsMultipleOutputConnections {
    return YES; }

- (LXInteger)outputCount {
    return [_outputs count]; }


- (NSString *)nameOfOutputAtIndex:(LXInteger)index {
    return [[_outputs objectAtIndex:index] name]; }
    
- (LXUInteger)typeOfOutputAtIndex:(LXInteger)index {
    return kLACNodeDefaultConnectionType; }
     
     
- (LXInteger)inputCount {
    return [_inputs count]; }
    
- (NSString *)nameOfInputAtIndex:(LXInteger)index {
    return [[_inputs objectAtIndex:index] name]; }

- (LXUInteger)typeOfInputAtIndex:(LXInteger)index {
    return kLACNodeDefaultConnectionType; }

- (LXInteger)parameterCount {
    return 0; }    
    

- (id)connectedNodeForInputAtIndex:(LXInteger)index outputIndexPtr:(LXInteger *)outpIndex
{
    LACInput *input = (LACInput *)[_inputs objectAtIndex:index];
    LACOutput *connOut = [input connectedOutput];
    
    if (outpIndex) *outpIndex = [connOut index];
    return [connOut owner];
}

- (void)disconnectInputAtIndex:(LXInteger)index
{
    LACInput *input = (LACInput *)[_inputs objectAtIndex:index];
    [input disconnect];
}

- (void)connectInputAtIndex:(LXInteger)inpIndex toNode:(id)node outputIndex:(LXInteger)outpIndex
{
    LACInput *input = (LACInput *)[_inputs objectAtIndex:inpIndex];
    [input connectToOutput:[[(LACNode *)node outputs] objectAtIndex:outpIndex]];
    //NSLog(@"%@: connecting input %ld to %ld on %@", self, (long)inpIndex, (long)outpIndex, node);
}

- (BOOL)hasUpstreamConnectionToNode:(id)node
{
    return [self hasUpstreamConnectionToNode:node seenNodes:[NSMutableSet set]];
}

- (BOOL)hasUpstreamConnectionToNode:(id)node seenNodes:(NSMutableSet *)seenNodes
{
    if ([seenNodes containsObject:node])
        return YES;
    
    [seenNodes addObject:node];
    
    NSEnumerator *enumerator = [_inputs objectEnumerator];
    LACInput *ob;
    while (ob = [enumerator nextObject]) {
        LACNode *cnode = (LACNode *)[[ob connectedOutput] owner];
        if (cnode) {
            //NSLog(@"node '%@': upstream node '%@'...", [self name], [cnode name]);
            if ([cnode hasUpstreamConnectionToNode:node seenNodes:seenNodes])
                return YES;
        }
    }
    
    return NO;
}

// this empty method is implemented here for subclass compatibility
- (void)invalidateCaches {
}

@end
