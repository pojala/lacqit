//
//  LACParser.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LACPatch.h"


@interface LACParser : NSObject {

    NSString *_decl;
    LXInteger _declType;
    Class _declPatchClass;
    id _declTargetName;
    NSString *_declID;
    NSArray *_declProps;
    
    NSArray *_declPendingConnSources;
        
    NSMutableArray *_patchStack;
    
    //NSArray *_currPatchProps;  // properties for the patch are parsed only when its contents are known
    //NSMutableArray *_currPatchConns;  // same for connections
    
    NSMutableArray *_patchPropsStack;
    NSMutableArray *_patchConnsStack;
    
    NSMutableArray *_topPatches;
    
    NSString *_err;
    
    NSMutableDictionary *_patchClassMap;
}

- (LXInteger)parserVersion;

- (NSArray *)parseLacString:(NSString *)str;

- (void)setPatchClass:(Class)cls forName:(NSString *)name;

@end
