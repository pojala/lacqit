//
//  LQJSUtils.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSUtils.h"


NSString *LQValidateJSVariableName(NSString *str, NSString *prefixForConflict)
{
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([str length] < 1) {
        return nil;
    }
    
    str = [NSMutableString stringWithString:str];
    
    [(NSMutableString *)str replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"," withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"." withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"-" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"+" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"=" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@";" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"'" withString:@"" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"\"" withString:@"" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"/" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"%" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"&" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"?" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"*" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"(" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@")" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"[" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"]" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"{" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"}" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"<" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@">" withString:@"_" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"\r" withString:@"" options:0 range:NSMakeRange(0, [str length])];
    [(NSMutableString *)str replaceOccurrencesOfString:@"\t" withString:@"" options:0 range:NSMakeRange(0, [str length])];
    
    if ([str rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location != 0) {
        if ([prefixForConflict length] > 0) {
            [(NSMutableString *)str insertString:prefixForConflict atIndex:0];
        } else {
            return nil;
        }
    }
    
    NSArray *jsKeywords = [NSArray arrayWithObjects:@"break", @"continue", @"do", @"for", @"import", @"new", @"this",
                                                    @"void", @"case", @"default", @"else", @"function", @"in", @"return",
                                                    @"typeof", @"while", @"comment", @"delete", @"export", @"if", @"label",
                                                    @"switch", @"var", @"with", @"true", @"false", @"null",
                                                    
                                                    // keywords from Java that are reserved in JS
                                                    @"abstract", @"implements", @"protected", @"boolean", @"instanceOf", @"public",
                                                    @"byte", @"int", @"short", @"char", @"interface", @"static",
                                                    @"double", @"long", @"synchronized", @"native", @"throws",
                                                    @"final", @"transient", @"float", @"package", @"goto", @"private",
                                                    
                                                    // EcmaScript keywords
                                                    @"catch", @"enum", @"throw", @"class", @"extends", @"try",
                                                    @"const", @"finally", @"debugger", @"super",
                                                    
                                                    // API names
                                                    @"window", @"document", @"navigator",            // web browser
                                                    @"sys", @"env", @"app", @"Radi", @"rd",          // Conduit / Radi
                                                    @"eval", @"parseFloat", @"parseInt", @"setInterval", @"setTimeout",
                                                    @"Array", @"String", @"Date", @"Math", @"Number", @"Object", @"RegExp", 
                                                    nil];
                                                    
    for (NSString *word in jsKeywords) {
        if ([str isEqual:word]) {
            // if name overlaps with a keyword, insert a prefix
            if ([prefixForConflict length] > 0) {
                [(NSMutableString *)str insertString:[NSString stringWithFormat:@"%@_", prefixForConflict] atIndex:0];
                break;
            } else {
                return nil;
            }
        }
    }
    return str;
}


NSArray *LQArrayByConvertingKeyedItemsToDictionariesInArray(NSArray *inArr)
{
    if ( !inArr) return nil;

    NSMutableArray *arr = [NSMutableArray arrayWithArray:inArr];
    
    // array items may be from a source that provides custom objects; repack data into dicts if necessary
    LXUInteger count = [arr count];
    LXUInteger i;
    for (i = 0; i < count; i++) {
        id obj = [arr objectAtIndex:i];
        if ([obj respondsToSelector:@selector(keyEnumerator)] && ![obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = LQJSConvertKeyedItemsRecursively(obj);
            
            /*
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            
            if ([obj respondsToSelector:@selector(keyEnumerator)]) {
                NSEnumerator *keyEnum = [obj keyEnumerator];
                id key;
                while (key = [keyEnum nextObject]) {
                    id value = [obj valueForKey:key];
                    ///NSLog(@".. copying key %@ - value %@", key, value);
                    
                    if ([value conformsToProtocol:@protocol(NSCopying)] && [value conformsToProtocol:@protocol(NSCoding)]) {
                        [dict setObject:[[value copy] autorelease] forKey:key];
                    }
                }
            }*/
            
            if ( !dict)
                dict = [NSDictionary dictionary];
            
            [arr replaceObjectAtIndex:i withObject:dict];
        }
    }
    return arr;
}


id LQJSConvertKeyedItemsRecursively(id inObj)
{
    if ( !inObj) return nil;
    
    if ( ![inObj respondsToSelector:@selector(keyEnumerator)]) {
        if ([inObj isKindOfClass:[NSArray class]])
            return LQArrayByConvertingKeyedItemsToDictionariesInArray((NSArray *)inObj);
        else if ([inObj conformsToProtocol:@protocol(NSCopying)] && [inObj conformsToProtocol:@protocol(NSCoding)])
            return [[inObj copy] autorelease];
        else
            return nil;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSEnumerator *keyEnum = [inObj keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        id value = [inObj valueForKey:key];
        id copiedValue = nil;
        
        if ([value respondsToSelector:@selector(keyEnumerator)]) {
            copiedValue = LQJSConvertKeyedItemsRecursively(value);
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            copiedValue = LQArrayByConvertingKeyedItemsToDictionariesInArray((NSArray *)value);
        }
        else if ([value conformsToProtocol:@protocol(NSCopying)] && [value conformsToProtocol:@protocol(NSCoding)]) {
            copiedValue = [[value copy] autorelease];
        }
        
        if (copiedValue)
            [dict setObject:copiedValue forKey:key];
    }
    
    return dict;
}

