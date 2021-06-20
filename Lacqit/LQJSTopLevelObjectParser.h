//
//  LQJSTopLevelObjectParser.h
//  Lacqit
//
//  Created by Pauli Ojala on 30.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LacqitExport.h"

/*
   This parser recognizes four types of top-level JS object declarations: functions, strings, arrays and objects.
*/


// keys in the dictionaries returned by +parseObjectBodiesFromString.. method.
// each object is parsed to a dict with these keys: JSON and string objects will have empty functionArgs.
LACQIT_EXPORT_VAR NSString * const kLQJSObjectIdentifierKey;
LACQIT_EXPORT_VAR NSString * const kLQJSObjectTypeKey;
LACQIT_EXPORT_VAR NSString * const kLQJSObjectBodyKey;
LACQIT_EXPORT_VAR NSString * const kLQJSObjectFunctionArgsKey;


@interface LQJSTopLevelObjectParser : NSObject {

    NSMutableArray *_topLevelObjs;
    
    NSString *_currentDecl;
    NSString *_currentDeclFunctionArgs;
    NSString *_currentDeclType;
    LXInteger _defDepth;
    NSCharacterSet *_defCharSet;
    NSMutableString *_defBody;
    BOOL _defIsJSON;
    
    NSString *_err;
}

+ (NSArray *)parseObjectBodiesFromString:(NSString *)js error:(NSError **)outError;

+ (BOOL)inParsedObjectBodies:(NSArray *)objs
                     getType:(NSString **)outType
                     andBody:(id *)outBody
               forIdentifier:(NSString *)ident;

@end
