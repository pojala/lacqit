//
//  LACInput.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
@class LACOutput;


@interface LACInput : NSObject <NSCopying, NSCoding> {

    NSString *_name;
    NSString *_type;
    
    id _owner;
    
    LACOutput *_connectedOutput;
    
    // UI: storing connector notes ("noodle notes")
	NSString *_connectorNote;
	float _connectorNotePos;
}

- (id)initWithName:(NSString *)name typeKey:(NSString *)str;

- (NSString *)typeKey;
- (NSString *)name;

- (void)setOwner:(id)owner;
- (id)owner;

- (BOOL)isConnected;
- (LACOutput *)connectedOutput;

- (void)connectToOutput:(LACOutput *)output;
- (void)disconnect;

// --- UI ---
- (NSString *)connectorNote;
- (float)connectorNotePosition;
- (void)setConnectorNote:(NSString *)note;
- (void)setConnectorNotePosition:(float)pos;

@end
