//
//  LQJSTopLevelObjectParser.m
//  Lacqit
//
//  Created by Pauli Ojala on 30.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSTopLevelObjectParser.h"
#import "LQModelConstants.h"


NSString * const kLQJSObjectIdentifierKey = @"identifier";
NSString * const kLQJSObjectBodyKey = @"body";
NSString * const kLQJSObjectTypeKey = @"type";
NSString * const kLQJSObjectFunctionArgsKey = @"functionArgs";



@implementation LQJSTopLevelObjectParser

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [_err release];
    [_topLevelObjs release];
    
    [_defBody release];
    [_defCharSet release];
    [_currentDecl release];
    [_currentDeclFunctionArgs release];
    [_currentDeclType release];
    
    [super dealloc];
}


enum {
    stateError = 0,
    
    stateExpectingDeclOrComment = 1,
    
    stateExpectingCommentEndAtNewline = 100,
    stateExpectingCommentEndAtCloseMarker,
    
    stateExpectingAssignment = 200,
    stateExpectingJSON,
    stateExpectingStartOfDef,
    stateExpectingEndOfDefOrComment,
    
    stateEnd = 5000
};


#define THISCHAR(_scanner_)  (([_scanner_ isAtEnd]) ? '\0' : [[_scanner_ string] characterAtIndex:[_scanner_ scanLocation]])

#define SKIPNEWLINE(_scanner_)  [_scanner_ scanCharactersFromSet:nlSet intoString:NULL];

#define SKIPCHAR(_scanner_)  [_scanner_ setScanLocation:[_scanner_ scanLocation]+1]

+ (NSCharacterSet *)newlineCharacterSet
{
    static NSCharacterSet *s_set = nil;
    if ( !s_set) {
        unichar chars[5] = { 0x0A, 0x0B, 0x0C, 0x0D,  0x85 };
        s_set = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:chars length:5]];
        [s_set retain];
    }
    return s_set;
}


#define SETERRORSTATE(str_)  _err = [str_ retain];  state = stateError;


- (int)scanWithScanner:(NSScanner *)scanner inState:(int)state
{
    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    unichar c;
    
    switch (state) {
        case stateExpectingDeclOrComment:
            [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
            
            c = THISCHAR(scanner);            
            if (c == 0) {
                state = stateEnd;
            }
            else if (c == ';') {
                SKIPCHAR(scanner);
                state = stateExpectingDeclOrComment;
            }
            else if (c == 'v') {
                if ([scanner scanString:@"var" intoString:NULL]) {
                    SETERRORSTATE(@"The var keyword is not supported at the top level - please declare JavaScript objects without var.");
                }
            }
            else if (c == '/') {
                SKIPCHAR(scanner);
                
                c = THISCHAR(scanner);
                if (c == '/') {
                    state = stateExpectingCommentEndAtNewline;
                } else if (c == '*') {
                    state = stateExpectingCommentEndAtCloseMarker;
                } else {
                    SETERRORSTATE(([NSString stringWithFormat:@"Unexpected character following slash (expected to open comment, but got '%c')", (char)c]));
                }
            }
            else {
                NSString *decl = nil;
                [scanner scanUpToCharactersFromSet:nlAndWhiteSet intoString:&decl];
                
                [_currentDecl release];
                _currentDecl = [decl retain];
                
                state = stateExpectingAssignment;
            }
            break;

        case stateExpectingCommentEndAtNewline:
            [scanner scanUpToCharactersFromSet:[[self class] newlineCharacterSet] intoString:NULL];
            state = stateExpectingDeclOrComment;
            break;
            
        case stateExpectingCommentEndAtCloseMarker: {
            NSString *str = nil;
            [scanner scanUpToString:@"*/" intoString:(_defDepth > 0) ? &str : NULL];
            c = THISCHAR(scanner);
            
            if (c != '*') {
                SETERRORSTATE(@"Comment opened with /* is never closed");
            } else {
                SKIPCHAR(scanner);
                
                c = THISCHAR(scanner);
                if (c == '/') {
                    SKIPCHAR(scanner);
                    if (_defDepth > 0) {
                        [_defBody appendString:str];
                        [_defBody appendString:@"*/"];
                        state = stateExpectingEndOfDefOrComment;
                    } else {
                        state = stateExpectingDeclOrComment;
                    }
                } else {
                    if (_defDepth > 0) {
                        [_defBody appendString:str];
                        [_defBody appendString:@"*"];
                    }
                    state = stateExpectingCommentEndAtCloseMarker;
                }
            }            
            break;
        }
            
        case stateExpectingAssignment:
            [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
            c = THISCHAR(scanner);
            
            if (c != '=') {
                SETERRORSTATE(([NSString stringWithFormat:@"Expected assignment after '%@' but got character '%c'", _currentDecl, (char)c]));
            } else {
                SKIPCHAR(scanner);
                BOOL declIsJSON = ([_currentDecl rangeOfString:@"__json_"].location == 0) ||
                                  ([_currentDecl rangeOfString:@"this.__json_"].location == 0);
                
                state = (declIsJSON) ? stateExpectingJSON : stateExpectingStartOfDef;
            }
            break;
        
        case stateExpectingJSON:
            [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
            c = THISCHAR(scanner);
            
            if (c != '[' && c != '{') {
                SETERRORSTATE(([NSString stringWithFormat:@"Expected JSON content for '%@' but got character '%c'", _currentDecl, (char)c]));
            } else {
                SKIPCHAR(scanner);
                
                [_currentDeclType release];
                _currentDeclType = [((c == '[') ? @"Array" : @"Object") retain];
            
                _defCharSet = [[NSCharacterSet characterSetWithCharactersInString:(c == '[') ? @"[]/" : @"{}/"] retain];
                _defDepth = 1;
                _defBody = [[NSMutableString alloc] initWithCapacity:128];
                
                _defIsJSON = YES;
                [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                state = stateExpectingEndOfDefOrComment;
            }
            break;
            
        case stateExpectingStartOfDef:
            [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
            
            if ( ![scanner scanString:@"function" intoString:NULL]) {
                c = THISCHAR(scanner);
                
                if (c == '[' || c == '{') {
                    state = stateExpectingJSON;
                }
                else {
                    if (c == '"' || c == '\'') {
                        // scanning a single string
                        SKIPCHAR(scanner);
                        NSMutableString *fullStr = [NSMutableString string];
                        NSString *str = nil; 
                        NSString *endMarker = (c == '"') ? @"\"" : @"'";
                        BOOL ok = YES;
                        BOOL gotEnd = NO;
                        
                        while (ok && !gotEnd) {
                            if ( ![scanner scanUpToString:endMarker intoString:&str]) {
                                SETERRORSTATE(([NSString stringWithFormat:@"Unterminated string body for '%@'", _currentDecl]));
                                ok = NO;
                            } else if ([[scanner string] characterAtIndex:[scanner scanLocation]-1] == '\\') {
                                // character is escaped; continue looking
                                [fullStr appendString:[str substringToIndex:[str length]-1]];
                                [fullStr appendString:endMarker];
                                SKIPCHAR(scanner);
                            } else {
                                [fullStr appendString:str];
                                SKIPCHAR(scanner);
                                gotEnd = YES;
                            }
                        }                    
                        if (gotEnd) {
                            [_topLevelObjs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        fullStr,  kLQJSObjectBodyKey,
                                                                        @"String", kLQJSObjectTypeKey,
                                                                        [[_currentDecl copy] autorelease],  kLQJSObjectIdentifierKey,
                                                                        nil]];
                            [_currentDecl release];
                            _currentDecl = nil;
                            [_currentDeclFunctionArgs release];
                            _currentDeclFunctionArgs = nil;
                            
                            state = stateExpectingDeclOrComment;
                        }
                    } else if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:c]) {
                        double v = 0.0;
                        if (c == 'f') {
                            if ([scanner scanString:@"false" intoString:NULL]) {
                                [_topLevelObjs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [NSNumber numberWithBool:NO], kLQJSObjectBodyKey,
                                                          @"Boolean", kLQJSObjectTypeKey,
                                                          [[_currentDecl copy] autorelease],  kLQJSObjectIdentifierKey,
                                                          nil]];
                                [_currentDecl release];
                                _currentDecl = nil;
                                [_currentDeclFunctionArgs release];
                                _currentDeclFunctionArgs = nil;
                                
                                state = stateExpectingDeclOrComment;
                            } else {
                                SETERRORSTATE(([NSString stringWithFormat:@"Expected constant value for '%@'", _currentDecl]));
                            }
                        }
                        else if (c == 't') {
                            if ([scanner scanString:@"true" intoString:NULL]) {
                                [_topLevelObjs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          [NSNumber numberWithBool:YES], kLQJSObjectBodyKey,
                                                          @"Boolean", kLQJSObjectTypeKey,
                                                          [[_currentDecl copy] autorelease],  kLQJSObjectIdentifierKey,
                                                          nil]];
                                [_currentDecl release];
                                _currentDecl = nil;
                                [_currentDeclFunctionArgs release];
                                _currentDeclFunctionArgs = nil;
                                
                                state = stateExpectingDeclOrComment;
                            } else {
                                SETERRORSTATE(([NSString stringWithFormat:@"Expected constant value for '%@'", _currentDecl]));
                            }
                        }
                        else if ([scanner scanDouble:&v]) {
                            ///NSLog(@"scanned value %f for key %@ - scan now at char '%c'", v, _currentDecl, (char)THISCHAR(scanner));
                            [_topLevelObjs addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        [NSNumber numberWithDouble:v], kLQJSObjectBodyKey,
                                                                        @"Number", kLQJSObjectTypeKey,
                                                                        [[_currentDecl copy] autorelease],  kLQJSObjectIdentifierKey,
                                                                        nil]];
                            [_currentDecl release];
                            _currentDecl = nil;
                            [_currentDeclFunctionArgs release];
                            _currentDeclFunctionArgs = nil;
                            
                            state = stateExpectingDeclOrComment;
                        } else {
                            SETERRORSTATE(([NSString stringWithFormat:@"Expected a numeric constant for '%@'", _currentDecl]));
                        }
                    } else {
                        SETERRORSTATE(([NSString stringWithFormat:@"Expected function keyword or a string for '%@' but got character '%c'", _currentDecl, (char)c]));
                    }
                }
            } else {
                [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
                c = THISCHAR(scanner);
                
                if (c != '(') {
                    SETERRORSTATE(([NSString stringWithFormat:@"expected opening parenthesis after function keyword (%@)", _currentDecl]));
                } else {
                    SKIPCHAR(scanner);
                    
                    NSString *argsStr = nil;
                    BOOL didScan = [scanner scanUpToString:@")" intoString:&argsStr];
                    
                    if ( !didScan) {
                        c = THISCHAR(scanner);
                        if (c == ')') {
                            argsStr = @"";
                            didScan = YES;
                        } else {
                            SETERRORSTATE(([NSString stringWithFormat:@"expected closing parenthesis for function arguments (%@)", _currentDecl]));
                        }
                    }
                    if (didScan) {
                        [_currentDeclFunctionArgs release];
                        _currentDeclFunctionArgs = [argsStr retain];
                        [_currentDeclType release];
                        _currentDeclType = [@"Function" retain];
                        
                        if ( ![scanner scanUpToString:@"{" intoString:NULL]) {
                            SETERRORSTATE(([NSString stringWithFormat:@"expected body for function (%@)", _currentDecl]));
                        } else {
                            SKIPCHAR(scanner);
                            [scanner scanCharactersFromSet:[[self class] newlineCharacterSet] intoString:NULL]; // skip newlines at start of function body

                            _defCharSet = [[NSCharacterSet characterSetWithCharactersInString:@"{}/"] retain];
                            _defDepth = 1;
                            _defBody = [[NSMutableString alloc] initWithCapacity:128];
                            state = stateExpectingEndOfDefOrComment;
                        }
                    }
                }
            }
            break;
        
        case stateExpectingEndOfDefOrComment: {
            NSString *str = nil;
            BOOL didScan = [scanner scanUpToCharactersFromSet:_defCharSet intoString:&str];
            
            if ( !didScan) {
                c = THISCHAR(scanner);
                if (c == '/') {
                    if ([scanner scanString:@"/*" intoString:&str]) {
                        [_defBody appendString:@"/*"];
                        state = stateExpectingCommentEndAtCloseMarker;
                    } else {
                        [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                        SKIPCHAR(scanner);
                        state = stateExpectingEndOfDefOrComment;
                    }
                }
                else if ([_defCharSet characterIsMember:c]) {
                    str = @"";
                    didScan = YES;
                } else {
                    SETERRORSTATE(([NSString stringWithFormat:@"expected end of body for definition '%@'", _currentDecl]));
                }
            }
            if (didScan) {
                [_defBody appendString:str];
                c = THISCHAR(scanner);
                
                if (c == '/') {
                    if ([scanner scanString:@"/*" intoString:NULL]) {
                        [_defBody appendString:@"/*"];
                        state = stateExpectingCommentEndAtCloseMarker;
                    } else {
                        [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                        SKIPCHAR(scanner);
                        state = stateExpectingEndOfDefOrComment;
                    }
                }
                else if (c == '{' || c == '[') {
                    SKIPCHAR(scanner);
                    _defDepth++;
                    [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                    state = stateExpectingEndOfDefOrComment;
                }
                else {
                    SKIPCHAR(scanner);
                    _defDepth--;
                    
                    if (_defDepth > 0) {
                        [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                        state = stateExpectingEndOfDefOrComment;
                    } else {
                        // this function or JSON body has ended
                        if (_defIsJSON) {
                            [_defBody appendString:[NSString stringWithCharacters:&c length:1]];
                        }

                        NSAssert(_defBody, @"no body");
                        NSAssert(_currentDecl, @"no decl");
                        NSDictionary *topLevelDef = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                    _defBody,  kLQJSObjectBodyKey,
                                                                    [[_currentDecl copy] autorelease],  kLQJSObjectIdentifierKey,
                                                                    _currentDeclType, kLQJSObjectTypeKey,
                                                                    (_defIsJSON) ? _currentDeclFunctionArgs : @"",  kLQJSObjectFunctionArgsKey,
                                                                    nil];
                        [_topLevelObjs addObject:topLevelDef];
                        
                        _defIsJSON = NO;
                        [_defBody release];
                        _defBody = nil;
                        [_defCharSet release];
                        _defCharSet = nil;
                        [_currentDecl release];
                        _currentDecl = nil;
                        [_currentDeclFunctionArgs release];
                        _currentDeclFunctionArgs = nil;
                        [_currentDeclType release];
                        _currentDeclType = nil;
                        
                        state = stateExpectingDeclOrComment;
                    }
                }
            }
            break;
        }
    }
    
    return state;
}

- (NSArray *)parseObjectsFromString:(NSString *)js error:(NSError **)outError
{
    NSScanner *scanner = [NSScanner scannerWithString:js];
    
    [scanner setCharactersToBeSkipped:nil];
    
    [_topLevelObjs release];
    _topLevelObjs = [[NSMutableArray alloc] initWithCapacity:32];
    
    [_err release];
    _err = nil;
    
    LXInteger state = stateExpectingDeclOrComment;
    
    while ( ![scanner isAtEnd]) {
        NSAutoreleasePool *pool = [NSAutoreleasePool new];
        
        state = [self scanWithScanner:scanner inState:state];
        
        [pool drain];
        
        ////if ( ![scanner isAtEnd]) printf("scanposition %i (%s)\n", [scanner scanLocation], [[_str substringWithRange:NSMakeRange([scanner scanLocation], 1)] UTF8String]);
        
        if (state == stateError) {
            LXInteger pos = [scanner scanLocation];
            NSString *aroundPos = [js substringWithRange:NSMakeRange(pos, MIN(20, [js length]-pos))];
            NSRange range;
            if ((range = [aroundPos rangeOfString:@" " options:NSBackwardsSearch]).location != NSNotFound && range.location > 0) {
                aroundPos = [aroundPos substringToIndex:range.location];
            }
            
            NSLog(@"*** JS toplevel parser error at position %ld ('%@'..): %@", (long)pos, aroundPos, _err);
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Before \"%@ ...\":  %@", aroundPos, _err]
                                                            forKey:NSLocalizedDescriptionKey];
            if (outError) *outError = [NSError errorWithDomain:kLQErrorDomain code:728000 userInfo:userInfo];
            break;
        }
        else if (state == stateEnd) {
            break;
        }
    }
    
    return (state != stateError) ? _topLevelObjs : nil;
}

+ (NSArray *)parseObjectBodiesFromString:(NSString *)js error:(NSError **)outError
{
    id parser = [[self alloc] init];
    NSArray *result = [parser parseObjectsFromString:js error:outError];    
    
    [[result retain] autorelease];
    [parser release];
    return result;
}

+ (BOOL)inParsedObjectBodies:(NSArray *)objs
                     getType:(NSString **)outType
                     andBody:(id *)outBody
               forIdentifier:(NSString *)ident
{
    for (id obj in objs) {
        if ([[obj valueForKey:kLQJSObjectIdentifierKey] isEqualToString:ident]) {
            if (outBody) *outBody = [obj valueForKey:kLQJSObjectBodyKey];
            if (outType) *outType = [obj valueForKey:kLQJSObjectTypeKey];
            return YES;
        }
    }
    return NO;
}

@end
