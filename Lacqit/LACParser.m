//
//  LACParser.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACParser.h"
#import "LACMutablePatch.h"
#import "LACNode.h"
#import "LACInput.h"
#import "LACOutput.h"
#import "LACEmbeddedPatchNode.h"

#import "LQNSScannerAdditions.h"


//#define DEBUGLOG(format, args...)   NSLog(format , ## args);
#define DEBUGLOG(format, args...)



@interface NSString (LACParserAdditions)
- (NSString *)stringByRemovingExtraWhitespaceAtEnd;
@end

@implementation NSString (LACParserAdditions)

- (NSString *)stringByRemovingExtraWhitespaceAtEnd
{
    NSString *str = self;
    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    LXInteger n = [str length];
    while (n > 1 && [nlAndWhiteSet characterIsMember:[str characterAtIndex:n-1]])
        n--;
    str = [str substringWithRange:NSMakeRange(0, n)];
    return str;
}

@end




enum {
    declNode = 1,
    declPatch,
    declConnection
};


@implementation LACParser

- (void)dealloc
{
    [_patchClassMap release];
    [super dealloc];
}

- (LXInteger)parserVersion {
    return 0x10000; }


- (void)setPatchClass:(Class)cls forName:(NSString *)name
{
    if ( !_patchClassMap)
        _patchClassMap = [[NSMutableDictionary alloc] init];
    
    [_patchClassMap setObject:cls forKey:name];
}


#pragma mark --- parsing ---

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

+ (NSCharacterSet *)declPropCharacterSet
{
    static NSMutableCharacterSet *s_set = nil;
    if ( !s_set) {
        unichar chars[6] = { '"', '\'',  '=',  '(', '{', '<'  };
        s_set = (NSMutableCharacterSet *)[NSMutableCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:chars length:6]];
        [s_set formUnionWithCharacterSet:[[self class] newlineCharacterSet]];
        [s_set retain];
    }
    return s_set;
}

+ (NSCharacterSet *)declCharacterSet
{
    static NSMutableCharacterSet *s_set = nil;
    if ( !s_set) {
        unichar chars[2] = { '}', '"'  };
        s_set = (NSMutableCharacterSet *)[NSMutableCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:chars length:2]];
        [s_set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [s_set retain];
    }
    return s_set;
}

+ (NSCharacterSet *)propEndOrKeyCharacterSet
{
    static NSMutableCharacterSet *s_set = nil;
    if ( !s_set) {
        unichar chars[1] = { ')'  };
        s_set = (NSMutableCharacterSet *)[NSMutableCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:chars length:1]];
        [s_set formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [s_set retain];
    }
    return s_set;
}

+ (NSCharacterSet *)propKeyValueEndCharacterSet
{
    static NSCharacterSet *s_set = nil;
    if ( !s_set) {
        s_set = [NSCharacterSet characterSetWithCharactersInString:@",)"];
        [s_set retain];
    }
    return s_set;
}

+ (NSCharacterSet *)propKeyNextCharacterSet
{
    static NSCharacterSet *s_set = nil;
    if ( !s_set) {
        s_set = [NSCharacterSet characterSetWithCharactersInString:@":,)"];
        [s_set retain];
    }
    return s_set;
}

+ (NSCharacterSet *)propKeyEndCharacterSet
{
    static NSMutableCharacterSet *s_set = nil;
    if ( !s_set) {
        s_set = (NSMutableCharacterSet *)[NSMutableCharacterSet characterSetWithCharactersInString:@":,)"];
        [s_set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [s_set retain];
    }
    return s_set;
}


- (void)setDecl:(NSString *)name
{
    if ([name length] < 1)
        return;
        
    _declType = 0;
    
    if ( ![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[name characterAtIndex:0]]) {
        // if decl starts with something else than an uppercase letter, it's not a class id.
        // it can contain an optional input path after a dot, so check for that
        _declTargetName = name;
        _declType = declConnection;
    }
    else {
        if ([name isEqual:@"Patch"]
            || [name isEqual:@"Func"]
            || [name isEqual:@"Subpatch"]
            || [[_patchClassMap allKeys] containsObject:name]
            ) {
            _declType = declPatch;
            _declPatchClass = [_patchClassMap objectForKey:name];
        } else {
            _declType = declNode;
        }
    }
    
    _decl = name;

    DEBUGLOG(@"----- setDecl '%@', target %@, type %i", _decl, _declTargetName, _declType);
}

- (void)finishDecl
{
    DEBUGLOG(@"----- finished with decl: %@, %@, propcount %i ---", _decl, _declID, [_declProps count]);
    
    if (_declType == declPatch) {
        LACMutablePatch *patch = [_patchStack lastObject];
        if ( !patch) {
            NSLog(@"** %s: no patch in stack", __func__);
        } else {
            [patch setName:_declID];
            
            [_patchPropsStack addObject:_declProps];
            [_patchConnsStack addObject:[NSMutableArray array]];
            
            //_currPatchProps = _declProps;
            //_currPatchConns = [NSMutableArray array];
        }
    }
    else if (_declType == declNode) {
        NSString *ns = nil;
        NSString *clsName = _decl;
        NSRange range;
        if ((range = [clsName rangeOfString:@"::"]).location != NSNotFound) {
            ns = [clsName substringToIndex:range.location];
            clsName = [clsName substringFromIndex:range.location+range.length];
        }
        Class cls = [LACNode nodeClassNamed:clsName inNamespace:ns];
        
        if ( !cls) {  // check with the runtime as well
            NSString *className = [NSString stringWithFormat:@"LACNode_%@", _decl];
            cls = NSClassFromString(className);
        }
        
        if ( !cls) {
            NSLog(@"** couldn't find class for declaration %@", _decl);
        } else {
            LACMutablePatch *patch = [_patchStack lastObject];
            
            LACNode *newNode = [[cls alloc] initWithName:([_declID length] > 0) ? _declID : [_decl lowercaseString]];
            [patch addNode:newNode];
            [newNode release];
            
            // set node properties
            NSEnumerator *propEnum = [_declProps objectEnumerator];
            NSDictionary *propDecl;
            while (propDecl = [propEnum nextObject]) {
                if ( ![propDecl isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"** invalid object in decl property list (%@)", [propDecl class]);
                } else {
                    NSEnumerator *keyEnum = [propDecl keyEnumerator];
                    NSString *key;
                    while (key = [keyEnum nextObject]) {
                        id value = [propDecl objectForKey:key];
                        
                        if ([value isKindOfClass:[NSString class]]) {
                            if ([value isEqualToString:@"true"])
                                value = [NSNumber numberWithBool:YES];
                            else if ([value isEqualToString:@"false"])
                                value = [NSNumber numberWithBool:NO];
                        }
                        else if ([value isKindOfClass:[NSArray class]]) {
                            // FIXME: should probably do something smarter (i.e. examine method signature) for these point properties
                            if ([[key lowercaseString] rangeOfString:@"point"].location != NSNotFound) {
                                NSPoint p;
                                p.x = ([value count] > 0) ? [[value objectAtIndex:0] doubleValue] : 0.0;
                                p.y = ([value count] > 1) ? [[value objectAtIndex:1] doubleValue] : 0.0;
                                value = [NSValue valueWithPoint:p];
                            }
                        }
                    
                        DEBUGLOG(@"PROP: setting '%@' for key %@ on node %@", value, key, [newNode name]);
                        @try {
                            [newNode setValue:value forKey:key];
                        }
                        @catch (id exception) {
                            NSLog(@"*** Lac parser: unable to set property '%@' on node declared as '%@' ***", key, _decl);
                        }
                    }
                }
            }
            
            // apply pending connections
            DEBUGLOG(@"applying pending conns, count %i, patch conns is %p", [_declPendingConnSources count], [_patchConnsStack lastObject]);
            if ([_declPendingConnSources count] > 0 && newNode) {
                [[_patchConnsStack lastObject] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                            [newNode name], @"targetInput",
                                            _declPendingConnSources, @"sourceList",
                                        nil]];
            }
        }
    }
    else if (_declType == declConnection) {
        
    }
    
    _declType = 0;
    _decl = nil;
    _declID = nil;
    _declProps = nil;
    _declPendingConnSources = nil;
}

- (void)addConnectionWithSourceList:(NSArray *)list
{
    if (_declType == declNode) {
        // for a node declaration we don't necessarily know the name yet, so must delay until declaration is completed
        _declPendingConnSources = list;
    } else {
        if ([_declTargetName length] > 0 && [list count] > 0) {
            [[_patchConnsStack lastObject] addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                            _declTargetName, @"targetInput",
                                            list, @"sourceList",
                                            nil]];
        }
    }
    _declTargetName = nil;
}

- (void)enterPatchBlock
{
    Class patchCls = _declPatchClass;
    if ( !patchCls)
        patchCls = [LACMutablePatch class];
    
    LACMutablePatch *newPatch = [[[patchCls alloc] init] autorelease];


    if ([_patchStack count] < 1) {
        [_topPatches addObject:newPatch];
    }    
    [_patchStack addObject:newPatch];
    
    DEBUGLOG(@"entered block %@, stack count %i", _decl, [_patchStack count]);
    
    [self finishDecl];
}

- (void)exitPatchBlock
{
    LACMutablePatch *patch = [_patchStack lastObject];
    
    // apply properties to the finished patch. 
    // output binding properties should be applied only after connections are created
    NSMutableArray *props = [[[_patchPropsStack lastObject] retain] autorelease];
    [_patchPropsStack removeLastObject];
    
    [patch parseInputBindingsFromArray:props];
    
    DEBUGLOG(@"applied properties to top patch (%@)", patch);

    
    // apply connections to the finished patch
    NSEnumerator *connEnum = [[_patchConnsStack lastObject] objectEnumerator];
    LXInteger n = 0;
    id connDesc;
    while (connDesc = [connEnum nextObject]) {
        NSString *targetNodePath = [connDesc objectForKey:@"targetInput"];
        LACInput *target = [patch inputWithNodePath:targetNodePath];
        id sourceList = [connDesc objectForKey:@"sourceList"];
        
        DEBUGLOG(@"EXITPATCH, conn %i: target is %@ -> %p", n, targetNodePath, target);
        n++;
        
        if ( !target || !sourceList) {
            NSLog(@"** invalid object in connections list: %@", connDesc);
        } else if ( ![target owner]) {
            NSLog(@"** can't find target node (nodePath was %@)", targetNodePath);
        } else {
            NSArray *inputs = [[target owner] inputs];
            LXInteger targetIndex = [inputs indexOfObject:target];
            if (targetIndex == NSNotFound) {
                NSLog(@"** invalid target input");
            } else {
                LXInteger inputCount = [inputs count];
                
                NSEnumerator *srcEnum = [sourceList objectEnumerator];
                NSString *srcStr;
                while (srcStr = [srcEnum nextObject]) {
                    target = (targetIndex < inputCount) ? [inputs objectAtIndex:targetIndex] : nil;
                    if (target) {
                        LACOutput *source = [patch outputWithNodePath:srcStr];
                        if ( !source) {
                            NSLog(@"** couldn't find source output (%@)", srcStr);
                        } else {
                            DEBUGLOG(@"-- connecting output %@ (path '%@') to target %@ --", source, srcStr, target);
                            [target connectToOutput:source];
                        }
                    }
                    targetIndex++;
                }
            }
        }
    }
    [_patchConnsStack removeLastObject];
    
    // output bindings are applied after connections are finished
    [patch parseOutputBindingsFromArray:props];
    
    // create a node to contain this patch, if not on the main level
    if ([_patchStack count] > 1) {
        DEBUGLOG(@"...creating embpatch node, patch name '%@'", [patch name]);
        LACEmbeddedPatchNode *embNode = [[LACEmbeddedPatchNode alloc] initWithName:[patch name] patch:patch];
        
        LACMutablePatch *parent = [_patchStack objectAtIndex:[_patchStack count]-2];
        [parent addNode:embNode];
        [embNode release];
    }
    
    // done, pop stack
    ///NSLog(@"exited %@, patch has %i nodes", _patchStack, [[patch allNodes] count]);
    [_patchStack removeLastObject];    
}



#define THISCHAR(_scanner_)  (([_scanner_ isAtEnd]) ? '\0' : [[_scanner_ string] characterAtIndex:[_scanner_ scanLocation]])

#define SKIPNEWLINE(_scanner_)  [_scanner_ scanCharactersFromSet:nlSet intoString:NULL];

#define SKIPCHAR(_scanner_)  [_scanner_ setScanLocation:[_scanner_ scanLocation]+1]



- (BOOL)scanListConst:(NSScanner *)scanner
{
    _err = @"unimplemented";
    return NO;
}

enum {
    stateError = 0
};

enum {
    propStateExpectingKeyOrEnd = 1,
    propStateExpectingValue,
    propStateExpectingValueOrNextKeyOrEnd,
    propStateExpectingNextKeyOrEnd,
    propStateExpectingEnd
};


// this is an array because properties can contain many values with the same key (e.g. "bindOut")
- (BOOL)scanProperties:(NSScanner *)scanner intoArray:(NSArray **)outArr
{/*
    NSString *str = nil;
    [scanner scanUpToString:@")" intoString:&str];

    if ([scanner isAtEnd]) {
        _err = @"decl properties list is not closed";
        return NO;
    } else {
        SKIPCHAR(scanner);
        
        NSLog(@"did scan props: %@", str);
        return YES;
    }*/
    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    /*      // following is testing code for character sets (Cocotron issue 563)
    LXInteger i;
    NSMutableArray *arr = [NSMutableArray array];
    LXInteger s = 0;
    for (i = 0; i < 256; i++) {
        if ([nlAndWhiteSet characterIsMember:i]) {
            s++;
            [arr addObject:[NSNumber numberWithInt:i]];
        }
    }
    NSLog(@"nlAndWhiteSet number of ASCII chars: %i -- chars are: %@", s, arr);

    arr = [NSMutableArray array];
    s = 0;
    for (i = 0; i < 256; i++) {
        if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:i]) {
            s++;
            [arr addObject:[NSNumber numberWithInt:i]];
        }
    }
    NSLog(@"whiteSet number of ASCII chars: %i -- chars are: %@", s, arr);
    
    arr = [NSMutableArray array];
    s = 0;
    for (i = 0; i < 256; i++) {
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:i]) {
            s++;
            [arr addObject:[NSNumber numberWithInt:i]];
        }
    }
    NSLog(@"nlSet number of ASCII chars: %i -- chars are: %@", s, arr);
    */
    
    NSMutableArray *resultArr = [NSMutableArray array];
        
    LXInteger state = propStateExpectingKeyOrEnd;
    NSString *currKey = nil;
    unichar c;
    
    do {
        c = THISCHAR(scanner);
        DEBUGLOG(@"...scanning props, state %i, pos %i: '%@' (%i)", state, [scanner scanLocation], (c >= 32) ? [NSString stringWithCharacters:&c length:1] : @"<ctrl-char>", c);
    
        switch (state) {
            case propStateExpectingEnd: {
                ///NSString *sss = nil;    // 2010.04.24 -- this was testing code for a bug in Cocotron (reported as issue 561)
                ///BOOL scanRes = [scanner scanUpToString:@")" intoString:&sss];   // in Cocoa, returns NO if it's at the string position
                [scanner scanUpToString:@")" intoString:NULL];
                c = THISCHAR(scanner);
                
                switch (c) {
                    case 0:
                    default:
                        _err = @"decl properties not closed";
                        return NO;
                    case ')':
                        SKIPCHAR(scanner);
                        DEBUGLOG(@"happily exiting properties list at scanpos %i, result: %@  (scanRes: %i, sss: %@)", [scanner scanLocation], resultArr, scanRes, sss);
                        
                        if (outArr) *outArr = resultArr;
                        return YES;
                }
                break;
            }
        
            case propStateExpectingKeyOrEnd:
                [scanner scanUpToCharactersFromSet:[[self class] propEndOrKeyCharacterSet] intoString:NULL];
                c = THISCHAR(scanner);
        
                switch (c) {
                    case 0:
                    case ')':
                        state = propStateExpectingEnd;
                        break;
                        
                    default: {
                        NSString *keyName = nil;
                        if ( ![scanner scanUpToCharactersFromSet:[[self class] propKeyEndCharacterSet] intoString:&keyName])
                            state = stateError;
                        else {
                            currKey = keyName;
                            ///DEBUGLOG(@"scanned prop key: %@", keyName);
                            state = propStateExpectingValueOrNextKeyOrEnd;
                        }
                        break;
                    }
                }
                break;
                
            case propStateExpectingValueOrNextKeyOrEnd:
                [scanner scanUpToCharactersFromSet:[[self class] propKeyNextCharacterSet] intoString:NULL];
                c = THISCHAR(scanner);
                
                switch (c) {
                    case 0:
                    case ')':
                        state = propStateExpectingEnd;
                        break;
                    case ',':
                        state = propStateExpectingNextKeyOrEnd;
                        break;
                        
                    case ':': {
                        SKIPCHAR(scanner);
                        [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];
                        
                        BOOL didScan = NO;
                        id obj;
                        if (THISCHAR(scanner) == '[') {
                            didScan = [scanner scanPossiblyNestedListOfLiteralsIntoArray:&obj listStartCharacter:'[' listEndCharacter:']' separatorCharacter:','];
                        } else {
                            didScan = [scanner scanUpToCharactersFromSet:[[self class] propKeyValueEndCharacterSet] intoString:&obj];
                        }
                        
                        NSArray *list = nil;
                        if ( !didScan) {
                            _err = [NSString stringWithFormat:@"unable to parse value for property '%@'", currKey];
                            state = stateError;  
                        } else {
                            if ([obj isKindOfClass:[NSString class]])
                                obj = [obj stringByRemovingExtraWhitespaceAtEnd];
                            
                            DEBUGLOG(@"PARSEPROPS: got property contents for key '%@': '%@', scanpos %i", currKey, obj, [scanner scanLocation]);
                            NSAssert(currKey, @"no key");
                            NSAssert(obj, @"no value");
                            NSDictionary *dict = [NSDictionary dictionaryWithObject:obj forKey:currKey];
                            [resultArr addObject:dict];
                        }
                        break;
                    }
                }
                break;
                
            case propStateExpectingNextKeyOrEnd:
                [scanner scanUpToCharactersFromSet:[[self class] propKeyValueEndCharacterSet] intoString:NULL];
                c = THISCHAR(scanner);
                
                switch (c) {
                    case 0:
                    case ')':
                        state = propStateExpectingEnd;
                        break;
                        
                    case ',':
                        SKIPCHAR(scanner);
                        state = propStateExpectingKeyOrEnd;
                        break;
                }
                break;
        }
        
    } while (state != stateError);
    return NO;
}


static NSString *strFromUnichar(unichar c)
{
    return (c) ? [NSString stringWithCharacters:&c length:1] : nil;
}


enum {
    stateExpectingDecl = 1,
    stateExpectingDeclProps,
    stateExpectingBlockStart,
    stateExpectingDeclOrBlockEnd,
    stateExpectingPropsList,
    stateExpectingList,
    stateExpectingConnectionSource,
    
    stateEnd = 500
};


- (LXInteger)scanWithScanner:(NSScanner *)scanner inState:(LXInteger)state
{
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    NSCharacterSet *whiteSet = [NSCharacterSet whitespaceCharacterSet];
    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *nlSet = [[self class] newlineCharacterSet];
    NSString *str;
    unichar c;
    
    c = THISCHAR(scanner);
    DEBUGLOG(@"state %i at pos %i: '%@' (%i)", state, [scanner scanLocation], (c >= 32) ? [NSString stringWithCharacters:&c length:1] : @"<ctrl-char>", c);

    switch (state) {
        case stateExpectingDecl:
            [scanner scanUpToCharactersFromSet:[[self class] declCharacterSet] intoString:NULL];            
            c = THISCHAR(scanner);

            switch (c) {
                case 0:
                    state = stateEnd;
                    break;
                    
                case '}':
                    SKIPCHAR(scanner);
                    
                    if (_patchStack) {
                        [self exitPatchBlock];
                        state = stateExpectingDecl;
                    } else {
                        _err = @"block end is not allowed at top level";
                        state = stateError;
                    }
                    break;
                
                default: {
                    if ( ![scanner scanPossiblyQuotedLiteralIntoString:&str]) {
                    //if ( ![scanner scanUpToCharactersFromSet:nlAndWhiteSet intoString:&str])
                        _err = @"couldn't scan literal for declaration";
                        return stateError;
                    }
            
                    [self setDecl:str];
                    state = stateExpectingDeclProps;
                }
            }            
            break;
        
        case stateExpectingDeclProps:
            [scanner scanUpToCharactersFromSet:[[self class] declPropCharacterSet] intoString:NULL];
            
            c = THISCHAR(scanner);
            if (c) SKIPCHAR(scanner);
                        
            DEBUGLOG(@"expectingDeclProps at pos %i: '%@' (%i)", [scanner scanLocation], (c >= 32) ? [NSString stringWithCharacters:&c length:1] : @"<ctrl-char>", c);

            if ( !c || [nlSet characterIsMember:c]) {
                SKIPNEWLINE(scanner);
                
                if (_declType == declPatch) {
                    state = stateExpectingBlockStart;
                } else {
                    [self finishDecl];
                    state = stateExpectingDecl;
                }
            } else {
                switch (c) {
                    case '\'':  // support both types of quotes
                    case '"': {
                        NSString *lit = nil;
                        [scanner decrementLocation];
                        if ( ![scanner scanQuotedLiteralIntoString:&lit]) {
                            _err = @"couldn't scan literal";
                            return stateError;
                        }
                        else
                            _declID = lit;
                        break;
                    }
                    
                    case '<':
                        if (THISCHAR(scanner) != '-') {
                            _err = @"invalid token for connection declaration (expected <-)";
                            return stateError;
                        } else {
                            SKIPCHAR(scanner);
                            state = stateExpectingConnectionSource;
                            DEBUGLOG(@"...expecting connection source (%@)", _declID);
                        }
                        break;
                        
                    case '=':  // this is not currently implemented
                        if ( ![self scanListConst:scanner])
                            _err = @"'=' token is not allowed for declaration properties";
                            return stateError;
                        break;
                    
                    case '(': {
                        NSArray *props = nil;
                        // this is an array because properties can contain many values with the same key (e.g. "bindOut")
                        
                        if ( ![self scanProperties:scanner intoArray:&props]) {
                            _err = @"couldn't scan properties";
                            return stateError;
                        } else {
                            _declProps = props;
                        }
                        break;
                    }
                            
                    case '{':
                        if (_declType != declPatch) {
                            _err = @"block begin is not allowed for this declaration";
                            return stateError;
                        } else {
                            [self enterPatchBlock];
                            state = stateExpectingDecl;
                        }
                        break;
                        
                }
            }
            break;
            
        case stateExpectingBlockStart:
            [scanner scanUpToString:@"{" intoString:NULL];
            
            c = THISCHAR(scanner);
            
            if (c == '{') {
                [self enterPatchBlock];
                state = stateExpectingDecl;
            }
            break;            
            
        case stateExpectingConnectionSource: {
            NSArray *list = nil;
            if ( ![scanner scanPossiblyNestedListOfLiteralsIntoArray:&list
                                        listStartCharacter:'['
                                        listEndCharacter:']'
                                        separatorCharacter:','] || !list) {
                _err = @"couldn't scan literal for connection source";
                state = stateError;
            } else {
                [self addConnectionWithSourceList:list];
                
                state = stateExpectingDeclProps;
            }
        
            break;
        }
    }
    
    return state;
}


- (NSArray *)parseLacString:(NSString *)str
{
    if ( !str) return nil;

    _topPatches = [NSMutableArray array];    

    _patchStack = [NSMutableArray array];
    _patchPropsStack = [NSMutableArray array];
    _patchConnsStack = [NSMutableArray array];
    
    
    NSScanner *scanner = [NSScanner scannerWithString:str];
    
    [scanner setCharactersToBeSkipped:nil]; //[NSCharacterSet whitespaceCharacterSet]];
    
    
    LXInteger state = stateExpectingDecl;
    
    while ( ![scanner isAtEnd]) {
        state = [self scanWithScanner:scanner inState:state];
        
        if (state == stateError) {
            NSLog(@"*** Lac parse error (%@)", _err);
            break;
        }
        else if (state == stateEnd) {
            DEBUGLOG(@"%s finished", __func__);
            break;
        }
    }
    
    return _topPatches;
}

@end
