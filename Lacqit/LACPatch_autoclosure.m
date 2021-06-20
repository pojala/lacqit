//
//  LACPatch_autoclosure.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACPatch_autoclosure.h"
#import "LACMutablePatch.h"
#import "LACAutoOpenNode.h"


@interface LACPatch (PrivateMadeAvailableToCategories)

+ (NSArray *)deepCopyOfNodes:(NSArray *)nodes outMapping:(NSDictionary **)outMap;

- (id)initWithName:(NSString *)name nodesNoCopy:(NSArray *)nodes
        inputInterface:(NSDictionary *)inInt
        outputInterface:(NSDictionary *)outInt;
        
@end


@interface NSArray (FindingInstancesOfClass)
- (id)firstObjectOfExactClass:(Class)cls;
- (id)firstObjectThatIsKindOfClass:(Class)cls;
@end

@implementation NSArray (FindingInstancesOfClass)

- (id)firstObjectOfExactClass:(Class)cls
{
    NSEnumerator *enumerator = [self objectEnumerator];
    id obj;
    while (obj = [enumerator nextObject]) {
        if ([obj class] == cls)
            return obj;
    }
    return nil;
}

- (id)firstObjectThatIsKindOfClass:(Class)cls
{
    NSEnumerator *enumerator = [self objectEnumerator];
    id obj;
    while (obj = [enumerator nextObject]) {
        if ([obj isKindOfClass:cls])
            return obj;
    }
    return nil;
}

@end


@implementation LACPatch (Autoclosure)

- (void)_collectNodesIntoArray:(NSMutableArray *)array startingFromOutput:(LACOutput *)topOutput
{
    LACNode *node = [topOutput owner];
    [array addObject:node];
    
    NSEnumerator *inpEnum = [[node inputs] objectEnumerator];
    LACInput *inp;
    while (inp = [inpEnum nextObject]) {
        LACOutput *outp = [inp connectedOutput];
        if (outp)
            [self _collectNodesIntoArray:array startingFromOutput:outp];
    }
}


- (id)initAsAutoclosureFromOutput:(LACOutput *)output
{
    if ( !output || ![output owner]) {
        [self release];
        return nil;
    }
    
//- (id)initWithName:(NSString *)name nodesNoCopy:(NSArray *)nodes
//        inputInterface:(NSDictionary *)inInt
//        outputInterface:(NSDictionary *)outInt
    
    // collect nodes that will be copied into the autoclosure
    NSMutableArray *nodesToCopy = [NSMutableArray array];
    
    [self _collectNodesIntoArray:nodesToCopy startingFromOutput:output];
    
    // make a deep copy of the nodes
    NSDictionary *mapping = nil;
    NSArray *newNodes = [LACPatch deepCopyOfNodes:nodesToCopy outMapping:&mapping];
    
    // work out the interface
    NSDictionary *outInterface = nil;
    {
        int outpIndex = [output index];
        LACNode *origNode = (LACNode *)[output owner];
        LACNode *copiedNode = (LACNode *)[mapping objectForKey:[NSValue valueWithPointer:origNode]];
        
        if ( !copiedNode) {
            NSLog(@"** %s: failed, can't find copy of output's owner node '%@'", __func__, origNode);
            [self release];
            return nil;
        } else {
            LACOutput *copiedOutput = ([[copiedNode outputs] count] > outpIndex) ? [[copiedNode outputs] objectAtIndex:outpIndex] : nil;
            if ( !copiedOutput) {
                NSLog(@"** %s: failed, can't find copy of output '%@'", __func__, output);
                [self release];
                return nil;
            } else {
                outInterface = [NSDictionary dictionaryWithObject:copiedOutput forKey:@"__autoclosed__"];
            }
        }
    }
    
    NSDictionary *inInterface = nil;
    {
        LACAutoOpenNode *opener = [newNodes firstObjectThatIsKindOfClass:[LACAutoOpenNode class]];
        if (opener) {
            NSString *inputPublishName = [NSString stringWithFormat:@"__autoopened:%@__", [opener name]];
            
            inInterface = [NSDictionary dictionaryWithObject:[NSObject lacTypeID] forKey:inputPublishName];
        }
    }
    
    // ready to create the copy
    [self initWithName:[NSString stringWithFormat:@"(autoclosed from %@)", [output name]]
           nodesNoCopy:newNodes
           inputInterface:inInterface
           outputInterface:outInterface];
           
    ///NSLog(@"AUTOCLOSE: %@, in %@, out %@ -------", self, [self publishedInputInterface], [self publishedOutputInterface]);
           
    return self;
}



@end
