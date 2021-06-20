//
//  LQNSScannerAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 2.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSScannerAdditions.h"


#define THISCHAR(_scanner_)  (([_scanner_ isAtEnd]) ? '\0' : [[_scanner_ string] characterAtIndex:[_scanner_ scanLocation]])

#define SKIPNEWLINE(_scanner_)  [_scanner_ scanCharactersFromSet:nlSet intoString:NULL];

#define SKIPCHAR(_scanner_)  [_scanner_ setScanLocation:[_scanner_ scanLocation]+1]


@implementation NSScanner (LQParsingAdditions)


- (BOOL)incrementLocation {
    int len = [[self string] length];
    int loc = [self scanLocation];
    if (loc < len-1) {
        [self setScanLocation:loc+1];
        return YES;
    } else
        return NO;
}

- (BOOL)decrementLocation {
    int loc = [self scanLocation];
    if (loc > 0) {
        [self setScanLocation:loc-1];
        return YES;
    } else
        return NO;
}


- (BOOL)scanQuotedLiteralIntoString:(NSString **)outStr
{
    NSScanner *scanner = self;
    NSMutableString *acc = nil;
    NSString *str = nil;
    
    // determine type of quote
    unichar quoteChar = THISCHAR(self);
    NSString *quoteStr = [NSString stringWithCharacters:&quoteChar length:1];
    
        
    if ( ![scanner incrementLocation])  // skip past beginning quote
        return NO;

    do {
        [scanner scanUpToString:quoteStr intoString:&str];
    
        if ([scanner isAtEnd]) {
            return NO;
        }
        
        // check for escaped doublequote
        int loc = [scanner scanLocation];
        unichar prevCh = (loc > 0) ? [[scanner string] characterAtIndex:loc-1] : '\0';
        SKIPCHAR(scanner);
        
        if (prevCh == '\\') {
            if ( !acc) acc = [NSMutableString string];
            [acc appendString:[str substringToIndex:[str length]-1]];
            [acc appendString:quoteStr];
        } else {
            if (outStr) *outStr = (acc) ? [acc stringByAppendingString:str] : str;
        
            ///if (outStr) NSLog(@"did scan literal: %@", *outStr);
            return YES;
        }
    } while (1);
    return NO;
}

- (BOOL)scanPossiblyQuotedLiteralIntoString:(NSString **)outStr terminators:(NSString *)terminators
{
    // this interferes with our scanning, so must remove it temporarily
    NSCharacterSet *prevSkippedChars = [[[self charactersToBeSkipped] retain] autorelease];
    [self setCharactersToBeSkipped:nil];

    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    [self scanCharactersFromSet:nlAndWhiteSet intoString:NULL];

    BOOL ret = NO;

    unichar c = THISCHAR(self);
    
    NSCharacterSet *termSet = (terminators) ? [NSCharacterSet characterSetWithCharactersInString:terminators] : nil;
    
    if (termSet && [termSet characterIsMember:c]) {
        ret = NO;
    }
    
    switch (c) {
        case 0:     ret = NO;  break;
        
        // support both types of quotes
        case '\'':
        case '"':   ret = [self scanQuotedLiteralIntoString:outStr];  break;
        
        default: {
            NSCharacterSet *limiters = nlAndWhiteSet;
            if (termSet) {
                limiters = [NSMutableCharacterSet characterSetWithCharactersInString:terminators];
                [(NSMutableCharacterSet *)limiters formUnionWithCharacterSet:nlAndWhiteSet];
            }
            ret = [self scanUpToCharactersFromSet:limiters intoString:outStr];
            break;
        }
    }
    
    if (prevSkippedChars)
        [self setCharactersToBeSkipped:prevSkippedChars];

    return ret;
}

- (BOOL)scanPossiblyQuotedLiteralIntoString:(NSString **)outStr
{
    return [self scanPossiblyQuotedLiteralIntoString:outStr terminators:nil];
}


enum {
    stateError = 0,
    listExpectingLiteralOrEnd,
    listExpectingSeparatorOrEnd,
    stateEnd
};

- (BOOL)scanPossiblyNestedListOfLiteralsIntoArray:(NSArray **)outArr
            listStartCharacter:(unichar)lstartCh
            listEndCharacter:(unichar)lendCh
            separatorCharacter:(unichar)sepCh
{
    NSScanner *scanner = self;
    NSCharacterSet *nlAndWhiteSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSMutableArray *results = nil;
    BOOL ret = NO;
    
    NSCharacterSet *prevSkippedChars = [[[scanner charactersToBeSkipped] retain] autorelease];
    [scanner setCharactersToBeSkipped:nil];

    [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];

    unichar c = THISCHAR(scanner);
    
    if (c == 0)
        goto bail;
        
    if (c != lstartCh) {
        NSString *str = nil;
        ret = [scanner scanPossiblyQuotedLiteralIntoString:&str];
        if (ret) {
            results = [NSMutableArray arrayWithObject:str];
        }
        goto bail;
    }
    
    // this is a list
    SKIPCHAR(scanner);
    
    results = [NSMutableArray array];
    
    unichar termChars[2] = { lendCh, sepCh };
    NSString *terminators = [NSString stringWithCharacters:termChars length:2];
    
    
    NSString *err = nil;
    int state = listExpectingLiteralOrEnd;
    do {
        [scanner scanCharactersFromSet:nlAndWhiteSet intoString:NULL];

        unichar c = THISCHAR(scanner);
            
        if (c == 0) {
            state = stateError;
            break;
        }
        
        switch (state) {
            case listExpectingLiteralOrEnd: {
                if (c == lendCh) {
                    state = stateEnd;
                }
                else if (c == lstartCh) {
                    NSArray *subList = nil;
                    if ( ![scanner scanPossiblyNestedListOfLiteralsIntoArray:&subList
                                        listStartCharacter:lstartCh listEndCharacter:lendCh separatorCharacter:sepCh] || !subList) {
                        state = stateError;
                        err = @"unable to scan nested list";
                    } else {
                        [results addObject:subList];
                        state = listExpectingSeparatorOrEnd;
                    }
                } else {
                    NSString *lit = nil;
                    if ( ![scanner scanPossiblyQuotedLiteralIntoString:&lit terminators:terminators]) {
                        state = stateError;
                        err = @"unable to scan literal";
                    } else {
                        [results addObject:lit];
                        ///NSLog(@"list item %i: '%@' -- char now '%c'", [results count]-1, lit, [[scanner string] characterAtIndex:[scanner scanLocation]]);
                        state = listExpectingSeparatorOrEnd;
                    }
                }
                break;
            }
                
            case listExpectingSeparatorOrEnd: {
                if (c == lendCh) {
                    state = stateEnd;
                }
                else if (c == sepCh) {
                    SKIPCHAR(scanner);
                    state = listExpectingLiteralOrEnd;
                }
                else {
                    state = stateError;
                    err = [NSString stringWithFormat:@"invalid character while expecting separator or end (0x%x)", (int)c];
                }
                break;
            }
        }
        
        if (state == stateEnd) {
            SKIPCHAR(scanner);
            break;
        }
    } while (state != stateError);
    
    
    if (err != nil) {
        NSLog(@"** %s: failed with error at location %lu: %@", __func__, (long)[scanner scanLocation], err);
        ret =  NO;
    } else
        ret = YES;
        
bail:
    if (prevSkippedChars)
        [scanner setCharactersToBeSkipped:prevSkippedChars];

    if (outArr) *outArr = results;
    return ret;
}

@end

