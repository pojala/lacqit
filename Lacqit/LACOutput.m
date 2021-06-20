//
//  LACOutput.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACOutput.h"


@implementation LACOutput

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p -- %@.%@ [%ld]>",
                        [self class], self,
                        [[self owner] name], [self name], (long)_index];
}

- (id)initWithName:(NSString *)name typeKey:(NSString *)str
{
    self = [super init];
    _type = [(str) ? str : (NSString *)@"id" retain];
    _name = [(name) ? name : (NSString *)@"(Untitled)" retain];
    _connectedInputs = [[NSMutableSet setWithCapacity:16] retain];
    return self;

}

/*
- (id)retain {
    if ([self retainCount] > 2) {
        NSLog(@"%s: %@ (%i)", __func__, self, [self retainCount]);    
    }
    return [super retain];
}
*/

- (void)dealloc {
    [_type release];
    [_name release];
    [_connectedInputs release];
    [super dealloc];
}

- (NSString *)typeKey {
    return _type; }
    
- (NSString *)name {
    return _name; }
    

- (void)setOwner:(id)owner index:(LXInteger)index {
    _owner = owner; 
    _index = index;
}

- (id)owner {
    return _owner; }

- (LXInteger)index {
    return _index; }
    

- (NSSet *)connectedInputs {
    return _connectedInputs; }
    
    
- (void)disconnectFromInput:(LACInput *)input
{
    [_connectedInputs removeObject:input];
}


#pragma mark --- private to input ---

- (void)didConnectToInput:(LACInput *)input
{
    [_connectedInputs addObject:input];
}


#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    LACOutput *newObj = [[[self class] alloc] initWithName:_name typeKey:_type];
    
    return newObj;
}


#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSString stringWithString:_name] forKey:@"LAC::name"];
    [coder encodeObject:[NSString stringWithString:_type] forKey:@"LAC::typeID"];
    
    [coder encodeConditionalObject:_owner forKey:@"LAC::owner"];
    
    [coder encodeInt:_index forKey:@"LAC::index"];
    
    [coder encodeObject:_connectedInputs forKey:@"LAC::connectedInputs"];
}

- (id)initWithCoder:(NSCoder *)coder
{
	_name = [[coder decodeObjectForKey:@"LAC::name"] retain];	
    _type = [[coder decodeObjectForKey:@"LAC::typeID"] retain];
    
    _owner = [coder decodeObjectForKey:@"LAC::owner"];
    
    _index = [coder decodeIntForKey:@"LAC::index"];
    
	_connectedInputs = [[coder decodeObjectForKey:@"LAC::connectedInputs"] retain];

	return self;
}


@end
