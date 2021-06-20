//
//  LQJSBridge_StreamNodeBase.m
//  LacqMediaCore
//
//  Created by Pauli Ojala on 9.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_StreamNodeBase.h"
#import "LQStreamPatch.h"
#import "LQStreamNode.h"


@implementation LQJSBridge_StreamNodeBase

- (id)initWithNode:(id)node
{
    if ( !node) {
        NSLog(@"** %@: tried to init without node object", [self class]);
        [self release];
        return nil;
    }
    
    self = [super initInJSContext:[[[node owner] jsInterpreter] context]
                        withOwner:nil];
    if (self) {
        ///NSLog(@"%s, %@", __func__, node);
        _node = node;
    }
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@", __func__, self);
    [super dealloc];
}

+ (NSString *)constructorName {
    return @"<StreamNodeBase>";  // can't be constructed
}

+ (NSArray *)objectPropertyNames {
    return [NSArray arrayWithObjects:@"tag", @"id", @"classPackageID", @"nodeEvents", @"persistentData", @"bypassed", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName {
    return ([propertyName isEqualToString:@"persistentData"] || [propertyName isEqualToString:@"bypassed"])
                    ? YES : NO;
}

- (LQStreamNode *)streamNode {
    return _node; }

- (LXInteger)tag {
    return [_node tag]; }
    
- (NSString *)id {
    return [_node name]; }

- (NSString *)classPackageID {
    return [[_node class] packageIdentifier]; }
    
- (NSArray *)nodeEvents {
    NSArray *arr = [_node nodeEventNames];
    return (arr) ? arr : [NSArray array];
}

- (id)persistentData {
    id data = [_node nodeScriptData];
    if ( !data) {
        data = [self emptyProtectedJSObject];
        [data setProtected:NO];
    }
    return data;
}
    
- (void)setPersistentData:(id)data {
    if ([data isKindOfClass:[LQJSBridgeObject class]]) {
        NSLog(@"** node '%@' persistentData property: invalid object type (%@)", [_node name], [data class]);
        return;
    }
    [_node setNodeScriptData:data];
}

- (BOOL)isBypassed {
    if ([_node respondsToSelector:@selector(isBypassed)]) {
        return [_node isBypassed];
    } else
        return NO;
}


- (void)postNodeWasModifiedNotificationWithInfo:(NSDictionary *)info  // currently ignored
{
    // this notif name is actually defined in LacqMediaCore's LQStreamUIConstants.h, so use a string constant here
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LQStreamNodeWasModifiedNotification"
                                            object:_node
											userInfo:nil];
}

- (void)setBypassed:(BOOL)f {
    if ([_node respondsToSelector:@selector(setBypassed:)]) {
        if (f != [_node isBypassed]) {
            [_node setBypassed:f];
            
            [self performSelectorOnMainThread:@selector(postNodeWasModifiedNotificationWithInfo:) withObject:nil waitUntilDone:NO];
        }
    }
}


#pragma mark --- functions ---

+ (NSArray *)objectFunctionNames {
    return [NSArray arrayWithObjects:@"observeNodeEvent", nil];
}

- (id)lqjsCallObserveNodeEvent:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 3) {
        NSLog(@"** js call observeNodeEvent(): too few arguments");
        return nil;
    }
    
    NSString *eventName = [args objectAtIndex:0];
    if ( ![eventName isKindOfClass:[NSString class]] || [eventName length] < 1)
        return nil;
    
    id node = [args objectAtIndex:1];
    if ( ![node respondsToSelector:@selector(streamNode)]) {
        NSLog(@"** js call observeNodeEvent() (%@): observer is not a node (%@, %@)", self, eventName, node);
        return nil;
    }
    
    id callback = [args objectAtIndex:2];
    if ( ![callback respondsToSelector:@selector(isFunction)] || ![callback isFunction]) {
        NSLog(@"** js call observeNodeEvent() (%@): callback is not a function (%@, %@)", self, eventName, node);
        return nil;
    }
    
    id jsInterpreter = [[_node owner] jsInterpreter];
    
    callback = [jsInterpreter recontextualizeObject:callback];
    
    BOOL ok = [_node addObserverNode:[node streamNode] forEventName:eventName jsCallback:callback];
    
    return [NSNumber numberWithBool:ok];
}

@end
