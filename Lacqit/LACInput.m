//
//  LACInput.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACInput.h"
#import "LACOutput.h"


@interface LACOutput (PrivateToLACInput)
- (void)didConnectToInput:(LACInput *)input;
@end


@interface NSObject (LACInputOwnerMethods)
- (void)connectionWillChangeForInput:(LACInput *)input;
- (void)connectionDidChangeForInput:(LACInput *)input;
@end


@implementation LACInput

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p -- %@.%@>",
                        [self class], self,
                        [[self owner] name], [self name]];
}

- (id)initWithName:(NSString *)name typeKey:(NSString *)str
{
    self = [super init];
    _type = [((str) ? str : (NSString *)@"id") retain];
    _name = [((name) ? name : (NSString *)@"(Untitled)") retain];
    return self;
}

- (void)dealloc
{
    if (_connectedOutput)
        [self disconnect];
    [_type release];
    [_name release];
    [super dealloc];
}

- (NSString *)typeKey {
    return _type; }
    
- (NSString *)name {
    return _name; }
    

- (void)setOwner:(id)owner {
    _owner = owner; }

- (id)owner {
    return _owner; }
    

- (BOOL)isConnected {
    return (_connectedOutput != nil); }
    
- (LACOutput *)connectedOutput {
    return _connectedOutput; }
    
- (void)_justDisconnect
{
    LACOutput *outp = _connectedOutput;
	_connectedOutput = nil;
    [outp disconnectFromInput:self];
    [outp release];
}

- (void)connectToOutput:(LACOutput *)output
{
    if (output == _connectedOutput)
        return;
        
    if ([[_owner owner] respondsToSelector:@selector(connectionWlllChangeForInput:)])
        [[_owner owner] connectionWillChangeForInput:self];

    if (_connectedOutput)
        [self _justDisconnect];
        
    _connectedOutput = [output retain];
    [output didConnectToInput:self];
    
    if ([[_owner owner] respondsToSelector:@selector(connectionDidChangeForInput:)])
        [[_owner owner] connectionDidChangeForInput:self];
}

- (void)disconnect
{
    if ( !_connectedOutput)
        return;
        
    [self connectToOutput:nil];
}


#pragma mark --- noodle notes ---

- (NSString *)connectorNote {
	return _connectorNote; }
	
- (float)connectorNotePosition {
	return _connectorNotePos; }
	
- (void)setConnectorNote:(NSString *)note {
	[_connectorNote release];
	_connectorNote = [note copy]; }
	
- (void)setConnectorNotePosition:(float)pos {
	_connectorNotePos = pos; }
    
    
    
#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    LACInput *newObj = [[[self class] alloc] initWithName:_name typeKey:_type];
    
    return newObj;
}


#pragma mark --- NSCoding protocol ---

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[NSString stringWithString:_name] forKey:@"LAC::name"];
    [coder encodeObject:[NSString stringWithString:_type] forKey:@"LAC::typeID"];
    
    [coder encodeConditionalObject:_owner forKey:@"LAC::owner"];
    
    [coder encodeObject:_connectedOutput forKey:@"LAC::connectedOutput"];

    if ([_connectorNote length] > 0) {
        [coder encodeObject:[NSString stringWithString:_connectorNote] forKey:@"LAC::connectorNote"];
        [coder encodeFloat:_connectorNotePos forKey:@"LAC::connectorNotePos"];
    }

}

- (id)initWithCoder:(NSCoder *)coder
{
	_name = [[coder decodeObjectForKey:@"LAC::name"] retain];	
    _type = [[coder decodeObjectForKey:@"LAC::typeID"] retain];
    
    _owner = [coder decodeObjectForKey:@"LAC::owner"];
    
	_connectedOutput = [[coder decodeObjectForKey:@"LAC::connectedOutput"] retain];

	if ([coder containsValueForKey:@"LAC::connectorNote"]) {
		_connectorNote = [[coder decodeObjectForKey:@"LAC::connectorNote"] retain];
		_connectorNotePos = [coder decodeFloatForKey:@"LAC::connectorNotePos"];
	}
	
	return self;
}


@end
