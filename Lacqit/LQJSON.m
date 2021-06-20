//
//  LQJSON.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSON.h"
#import "LQNSValueAdditions.h"
#import <Lacefx/LXStringUtils.h>

NSString * const kLQJSONErrorDomain = @"LQJSONErrorDomain";


@interface LQJSON (Generator)

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json error:(NSError**)error;
- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json error:(NSError**)error;
- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json error:(NSError**)error;
- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json error:(NSError**)error;

- (NSString*)indent;

@end

@interface LQJSON (Scanner)

- (BOOL)scanValue:(NSObject **)o error:(NSError **)error;

- (BOOL)scanRestOfArray:(NSMutableArray **)o error:(NSError **)error;
- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o error:(NSError **)error;
- (BOOL)scanRestOfNull:(NSNull **)o error:(NSError **)error;
- (BOOL)scanRestOfFalse:(NSNumber **)o error:(NSError **)error;
- (BOOL)scanRestOfTrue:(NSNumber **)o error:(NSError **)error;
- (BOOL)scanRestOfString:(NSMutableString **)o error:(NSError **)error;

// Cannot manage without looking at the first digit
- (BOOL)scanNumber:(NSNumber **)o error:(NSError **)error;

- (BOOL)scanHexQuad:(unichar *)x error:(NSError **)error;
- (BOOL)scanUnicodeChar:(unichar *)x error:(NSError **)error;

- (BOOL)scanIsAtEnd;

@end


enum {
    EUNSUPPORTED = 1,
    EPARSENUM,
    EPARSE,
    EFRAGMENT,
    ECTRL,
    EUNICODE,
    EDEPTH,
    EESCAPE,
    ETRAILCOMMA,
    ETRAILGARBAGE,
    EEOF,
    EINPUT
};



#pragma mark --- private utilities ---

#define skipWhitespace(c) while (isspace(*c)) c++
#define skipDigits(c) while (isdigit(*c)) c++

static NSError *err(int code, NSString *str) {
    NSDictionary *ui = [NSDictionary dictionaryWithObject:str forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:kLQJSONErrorDomain code:code userInfo:ui];
}

static NSError *errWithUnderlier(int code, NSError **u, NSString *str) {
    if (!u)
        return err(code, str);
    
    NSDictionary *ui = [NSDictionary dictionaryWithObjectsAndKeys:
                        str, NSLocalizedDescriptionKey,
                        *u, NSUnderlyingErrorKey,
                        nil];
    return [NSError errorWithDomain:kLQJSONErrorDomain code:code userInfo:ui];
}


@implementation LQJSON

// although this is a global, it's only modified in -initialize
static char ctrl[0x22];

+ (void)initialize
{
    ctrl[0] = '\"';
    ctrl[1] = '\\';
    LXInteger i;
    for (i = 1; i < 0x20; i++)
        ctrl[i+1] = i;
    ctrl[0x21] = 0;    
}

- (id)init {
    if (self = [super init]) {
        [self setMaxDepth:512];
    }
    return self;
}



#pragma mark Generator


/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p *error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param allowScalar wether to return json fragments for scalar objects
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (NSString*)stringWithObject:(id)value allowScalar:(BOOL)allowScalar error:(NSError**)error {
    _depth = 0;
    NSMutableString *json = [NSMutableString stringWithCapacity:128];
    
    NSError *err2 = nil;
    if (!allowScalar && ![value isKindOfClass:[NSDictionary class]] && ![value isKindOfClass:[NSArray class]]) {
        err2 = err(EFRAGMENT, @"Not valid type for JSON");        
        
    } else if ([self appendValue:value into:json error:&err2]) {
        return json;
    }
    
    if (error)
        *error = err2;
    return nil;
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value any instance that can be represented as a JSON fragment
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (NSString*)stringWithFragment:(id)value error:(NSError**)error {
    return [self stringWithObject:value allowScalar:YES error:error];
}

/**
 Returns a string containing JSON representation of the passed in value, or nil on error.
 If nil is returned and @p error is not NULL, @p error can be interrogated to find the cause of the error.
 
 @param value a NSDictionary or NSArray instance
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (NSString*)stringWithObject:(id)value error:(NSError**)error {
    return [self stringWithObject:value allowScalar:NO error:error];
}


- (NSString*)indent {
    return [@"\n" stringByPaddingToLength:1 + 2 * _depth withString:@" " startingAtIndex:0];
}

- (BOOL)appendValue:(id)fragment into:(NSMutableString*)json error:(NSError**)error
{
    // added -allKeys check for LacqJS compatibility; Pauli Ojala, 2009.07.15
    if ([fragment isKindOfClass:[NSDictionary class]] || [fragment respondsToSelector:@selector(allKeys)]) {
        if (![self appendDictionary:fragment into:json error:error])
            return NO;
        
    } else if ([fragment isKindOfClass:[NSArray class]]) {
        if (![self appendArray:fragment into:json error:error])
            return NO;

    } else if ([fragment isKindOfClass:[NSString class]]) {
        if (![self appendString:fragment into:json error:error])
            return NO;

    } else if ([fragment isKindOfClass:[NSNumber class]]) {
        if ('c' == *[fragment objCType])
            [json appendString:[fragment boolValue] ? @"true" : @"false"];
        else
            [json appendString:[fragment stringValue]];

    } else if ([fragment isKindOfClass:[NSNull class]]) {
        [json appendString:@"null"];

    } else if ([fragment isKindOfClass:[NSURL class]]) {  // added URL->string handling for LacqMediaCore IPC, 2011.02.08
        if (![self appendString:[fragment description] into:json error:error])
            return NO;
        
    } else {
        if (_includeUnknownObjects) {
            BOOL isValue = [fragment isKindOfClass:[NSValue class]];
            if (isValue && 0 == strcmp([fragment objCType], @encode(LXRGBA))) {
                LXRGBA rgba = [fragment rgbaValue];
                [json appendFormat:@"{ \"r\": %.4f, \"g\": %.4f, \"b\": %.4f, \"a\": %.4f }", rgba.r, rgba.g, rgba.b, rgba.a];
            }
            else if (isValue && 0 == strcmp([fragment objCType], @encode(NSPoint))) {
                NSPoint p = [fragment pointValue];
                [json appendFormat:@"{ \"x\": %f, \"y\": %f }", p.x, p.y];
            }
            else if (isValue) {
                // don't let unknown NSValues be displayed as their real type
                [json appendFormat:@"<Value: %p>", fragment];
            }
            else {
                [json appendFormat:@"<%@: %p>", NSStringFromClass([fragment class]), fragment];
            }
        }
        else {
            *error = err(EUNSUPPORTED, [NSString stringWithFormat:@"JSON serialisation not supported for %@", [fragment class]]);
            return NO;
        }
    }
    return YES;
}

- (BOOL)appendArray:(NSArray*)fragment into:(NSMutableString*)json error:(NSError**)error {
    [json appendString:@"["];
    _depth++;
    
    BOOL addComma = NO;    
    NSEnumerator *enumerator = [fragment objectEnumerator];
    id value;
    while (value = [enumerator nextObject]) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;

        if ([self humanReadable])
            [json appendString:[self indent]];
        
        if (![self appendValue:value into:json error:error]) {
            return NO;
        }
    }

    _depth--;
    if ([self humanReadable] && [fragment count])
        [json appendString:[self indent]];
    [json appendString:@"]"];
    return YES;
}

static NSString *stringKeyFromNumber(NSNumber *num)
{
    return [@"__#" stringByAppendingString:[num stringValue]];
}

static NSNumber *numberFromStringKey(NSString *str)
{
    if ([str length] > 3 && [str hasPrefix:@"__#"]) {
        NSString *numStr = [str substringFromIndex:3];
        if ([numStr rangeOfString:@"."].location == NSNotFound && [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[numStr characterAtIndex:0]]) {
            return [NSNumber numberWithInt:[numStr intValue]];
        } else {
            return [NSNumber numberWithDouble:[numStr doubleValue]];
        }
    } else
        return nil;
}

- (BOOL)appendDictionary:(NSDictionary*)fragment into:(NSMutableString*)json error:(NSError**)error
{
    const BOOL isDict = [fragment isKindOfClass:[NSDictionary class]];

    [json appendString:@"{"];
    _depth++;

    NSString *colon = [self humanReadable] ? @" : " : @":";
    BOOL addComma = NO;
    NSArray *keys = [fragment allKeys];
    if ([self sortsKeys])
        keys = [keys sortedArrayUsingSelector:@selector(compare:)];

    NSEnumerator *enumerator = [keys objectEnumerator];
    id key;
    while (key = [enumerator nextObject]) {
        if (addComma)
            [json appendString:@","];
        else
            addComma = YES;

        if ([self humanReadable])
            [json appendString:[self indent]];
        
        // 2009.10.08 -- hacky NSNumber support added by Pauli Ojala
        BOOL keyIsNumber = [key isKindOfClass:[NSNumber class]];
        if ( ![key isKindOfClass:[NSString class]] && !keyIsNumber) {
            *error = err(EUNSUPPORTED, @"JSON object key must be string");
            return NO;
        }
        
        if (![self appendString:(keyIsNumber ? stringKeyFromNumber((NSNumber *)key) : key) into:json error:error])
            return NO;

        [json appendString:colon];
        
        id value = (isDict) ? [fragment objectForKey:key] : [fragment valueForKey:key];

        if ( ![self appendValue:value into:json error:error]) {
            if ( *error == nil)
                *error = err(EUNSUPPORTED, [NSString stringWithFormat:@"Unsupported value for key '%@' in object: %@", key, value]);
            return NO;
        }
    }

    _depth--;
    if ([self humanReadable] && [keys count])
        [json appendString:[self indent]];
    [json appendString:@"}"];
    return YES;    
}

- (BOOL)appendString:(NSString*)fragment into:(NSMutableString*)json error:(NSError**)error {

    static NSMutableCharacterSet *kEscapeChars;
    if( ! kEscapeChars ) {
        kEscapeChars = [[NSMutableCharacterSet characterSetWithRange: NSMakeRange(0,32)] retain];
        [kEscapeChars addCharactersInString: @"\"\\"];
    }
    
    [json appendString:@"\""];
    
    NSRange esc = [fragment rangeOfCharacterFromSet:kEscapeChars];
    if ( !esc.length ) {
        // No special chars -- can just add the raw string:
        [json appendString:fragment];
        
    } else {
        LXUInteger length = [fragment length];
        LXUInteger i;
        for (i = 0; i < length; i++) {
            unichar uc = [fragment characterAtIndex:i];
            switch (uc) {
                case '"':   [json appendString:@"\\\""];       break;
                case '\\':  [json appendString:@"\\\\"];       break;
                case '\t':  [json appendString:@"\\t"];        break;
                case '\n':  [json appendString:@"\\n"];        break;
                case '\r':  [json appendString:@"\\r"];        break;
                case '\b':  [json appendString:@"\\b"];        break;
                case '\f':  [json appendString:@"\\f"];        break;
                default:    
                    if (uc < 0x20) {
                        [json appendFormat:@"\\u%04x", uc];
                    } else {
                        [json appendFormat:@"%C", uc];
                    }
                    break;
                    
            }
        }
    }

    [json appendString:@"\""];
    return YES;
}

#pragma mark Parser

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param repr the json string to parse
 @param allowScalar whether to return objects for JSON fragments
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (id)objectWithString:(id)repr allowScalar:(BOOL)allowScalar error:(NSError**)error {

    if (!repr) {
        if (error)
            *error = err(EINPUT, @"Input was 'nil'");
        return nil;
    }
    
    _depth = 0;
    _ch = [repr UTF8String];
    
    id o;
    NSError *err2 = nil;
    if (![self scanValue:&o error:&err2]) {
        NSLog(@"*** JSON parse error: string repr is '%@'", [repr substringToIndex:([repr length] > 100) ? 100 : [repr length]]);
        if (error)
            *error = err2;
        return nil;
    }
        
    // We found some valid JSON. But did it also contain something else?
    if (![self scanIsAtEnd]) {
        if (error)
            *error = err(ETRAILGARBAGE, @"Garbage after JSON");
        return nil;
    }

    // If we don't allow scalars, check that the object we've found is a valid JSON container.
    if (!allowScalar && ![o isKindOfClass:[NSDictionary class]] && ![o isKindOfClass:[NSArray class]]) {
        if (error)
            *error = err(EFRAGMENT, @"Valid fragment, but not JSON");
        return nil;
    }

    NSAssert1(o, @"Should have a valid object from %@", repr);
    return o;
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object can be
 a string, number, boolean, null, array or dictionary.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (id)fragmentWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr allowScalar:YES error:error];
}

/**
 Returns the object represented by the passed-in string or nil on error. The returned object
 will be either a dictionary or an array.
 
 @param repr the json string to parse
 @param error used to return an error by reference (pass NULL if this is not desired)
 */
- (id)objectWithString:(NSString*)repr error:(NSError**)error {
    return [self objectWithString:repr allowScalar:NO error:error];
}

// added by Pauli Ojala, 2009.04.22
+ (id)parseObjectFromString:(NSString *)jsonrep error:(NSError **)error
{
    LQJSON *parser = [[[self class] alloc] init];
    id obj = [parser objectWithString:jsonrep error:error];
    [[obj retain] autorelease];
    [parser release];
    return obj;
}

/*
 In contrast to the public methods, it is an error to omit the error parameter here.
 */
- (BOOL)scanValue:(NSObject **)o error:(NSError **)error
{
    skipWhitespace(_ch);
    
    switch (*_ch++) {
        case '{':
            return [self scanRestOfDictionary:(NSMutableDictionary **)o error:error];
            break;
        case '[':
            return [self scanRestOfArray:(NSMutableArray **)o error:error];
            break;
        case '"':
            return [self scanRestOfString:(NSMutableString **)o error:error];
            break;
        case 'f':
            return [self scanRestOfFalse:(NSNumber **)o error:error];
            break;
        case 't':
            return [self scanRestOfTrue:(NSNumber **)o error:error];
            break;
        case 'n':
            return [self scanRestOfNull:(NSNull **)o error:error];
            break;
        case '-':
        case '0'...'9':
            _ch--; // cannot verify number correctly without the first character
            return [self scanNumber:(NSNumber **)o error:error];
            break;
        case '+':
            *error = err(EPARSENUM, @"Leading + disallowed in number");
            return NO;
            break;
        case 0x0:
            *error = err(EEOF, @"Unexpected end of string");
            return NO;
            break;
        default:
            *error = err(EPARSE, @"Unrecognised leading character");
            return NO;
            break;
    }
    
    NSAssert(0, @"Should never get here");
    return NO;
}

- (BOOL)scanRestOfTrue:(NSNumber **)o error:(NSError **)error
{
    if (!strncmp(_ch, "rue", 3)) {
        _ch += 3;
        *o = [NSNumber numberWithBool:YES];
        return YES;
    }
    *error = err(EPARSE, @"Expected 'true'");
    return NO;
}

- (BOOL)scanRestOfFalse:(NSNumber **)o error:(NSError **)error
{
    if (!strncmp(_ch, "alse", 4)) {
        _ch += 4;
        *o = [NSNumber numberWithBool:NO];
        return YES;
    }
    *error = err(EPARSE, @"Expected 'false'");
    return NO;
}

- (BOOL)scanRestOfNull:(NSNull **)o error:(NSError **)error
{
    if (!strncmp(_ch, "ull", 3)) {
        _ch += 3;
        *o = [NSNull null];
        return YES;
    }
    *error = err(EPARSE, @"Expected 'null'");
    return NO;
}

- (BOOL)scanRestOfArray:(NSMutableArray **)o error:(NSError **)error
{
    if (_maxDepth && ++_depth > _maxDepth) {
        *error = err(EDEPTH, @"Nested too deep");
        return NO;
    }
    
    *o = [NSMutableArray arrayWithCapacity:8];
    
    for (; *_ch ;) {
        id v;
        
        skipWhitespace(_ch);
        if (*_ch == ']' && _ch++) {
            _depth--;
            return YES;
        }
        
        if (![self scanValue:&v error:error]) {
            *error = errWithUnderlier(EPARSE, error, @"Expected value while parsing array");
            return NO;
        }
        
        [*o addObject:v];
        
        skipWhitespace(_ch);
        if (*_ch == ',' && _ch++) {
            skipWhitespace(_ch);
            if (*_ch == ']') {
                *error = err(ETRAILCOMMA, @"Trailing comma disallowed in array");
                return NO;
            }
        }        
    }
    
    *error = err(EEOF, @"End of input while parsing array");
    return NO;
}

- (BOOL)scanRestOfDictionary:(NSMutableDictionary **)o error:(NSError **)error
{
    if (_maxDepth && ++_depth > _maxDepth) {
        *error = err(EDEPTH, @"Nested too deep");
        return NO;
    }
    
    *o = [NSMutableDictionary dictionaryWithCapacity:7];
    
    for (; *_ch ;) {
        id k, v;
        
        skipWhitespace(_ch);
        if (*_ch == '}' && _ch++) {
            _depth--;
            return YES;
        }    
        
        if (!(*_ch == '\"' && _ch++ && [self scanRestOfString:&k error:error])) {
            *error = errWithUnderlier(EPARSE, error, @"Object key string expected");
            return NO;
        }
        
        skipWhitespace(_ch);
        if (*_ch != ':') {
            *error = err(EPARSE, @"Expected ':' separating key and value");
            return NO;
        }
        
        // 2009.10.08 -- hacky NSNumber support added by Pauli Ojala
        NSNumber *numK = numberFromStringKey((NSString *)k);
        if (numK) k = numK;
        
        _ch++;
        if (![self scanValue:&v error:error]) {
            NSString *string = [NSString stringWithFormat:@"Object value expected for key: %@", k];
            *error = errWithUnderlier(EPARSE, error, string);
            return NO;
        }
        
        [*o setObject:v forKey:k];
        
        skipWhitespace(_ch);
        if (*_ch == ',' && _ch++) {
            skipWhitespace(_ch);
            if (*_ch == '}') {
                *error = err(ETRAILCOMMA, @"Trailing comma disallowed in object");
                return NO;
            }
        }        
    }
    
    *error = err(EEOF, @"End of input while parsing object");
    return NO;
}

- (BOOL)scanRestOfString:(NSMutableString **)o error:(NSError **)error
{
    *o = [NSMutableString stringWithCapacity:16];
    do {
        // First see if there's a portion we can grab in one go. 
        // Doing this caused a massive speedup on the long string.
        size_t len = strcspn(_ch, ctrl);
        if (len) {
            // check for 
            id t = [[NSString alloc] initWithBytesNoCopy:(char*)_ch
                                                  length:len
                                                encoding:NSUTF8StringEncoding
                                            freeWhenDone:NO];
            if (t) {
                [*o appendString:t];
                [t release];
                _ch += len;
            }
        }
        
        if (*_ch == '"') {
            _ch++;
            return YES;
            
        } else if (*_ch == '\\') {
            unichar uc = *++_ch;
            switch (uc) {
                case '\\':
                case '/':
                case '"':
                    break;
                    
                case 'b':   uc = '\b';  break;
                case 'n':   uc = '\n';  break;
                case 'r':   uc = '\r';  break;
                case 't':   uc = '\t';  break;
                case 'f':   uc = '\f';  break;                    
                    
                case 'u':
                    _ch++;
                    if (![self scanUnicodeChar:&uc error:error]) {
                        *error = errWithUnderlier(EUNICODE, error, @"Broken unicode character");
                        return NO;
                    }
                    _ch--; // hack.
                    break;
                default:
                    *error = err(EESCAPE, [NSString stringWithFormat:@"Illegal escape sequence '0x%x'", uc]);
                    return NO;
                    break;
            }
            [*o appendFormat:@"%C", uc];
            _ch++;
            
        } else if (*_ch < 0x20) {
            *error = err(ECTRL, [NSString stringWithFormat:@"Unescaped control character '0x%x'", *_ch]);
            return NO;
            
        } else {
            NSLog(@"should not be able to get here");
        }
    } while (*_ch);
    
    *error = err(EEOF, @"Unexpected EOF while parsing string");
    return NO;
}

- (BOOL)scanUnicodeChar:(unichar *)x error:(NSError **)error
{
    unichar hi, lo;
    
    if (![self scanHexQuad:&hi error:error]) {
        *error = err(EUNICODE, @"Missing hex quad");
        return NO;        
    }
    
    if (hi >= 0xd800) {     // high surrogate char?
        if (hi < 0xdc00) {  // yes - expect a low char
            
            if (!(*_ch == '\\' && ++_ch && *_ch == 'u' && ++_ch && [self scanHexQuad:&lo error:error])) {
                *error = errWithUnderlier(EUNICODE, error, @"Missing low character in surrogate pair");
                return NO;
            }
            
            if (lo < 0xdc00 || lo >= 0xdfff) {
                *error = err(EUNICODE, @"Invalid low surrogate char");
                return NO;
            }
            
            hi = (hi - 0xd800) * 0x400 + (lo - 0xdc00) + 0x10000;
            
        } else if (hi < 0xe000) {
            *error = err(EUNICODE, @"Invalid high character in surrogate pair");
            return NO;
        }
    }
    
    *x = hi;
    return YES;
}

- (BOOL)scanHexQuad:(unichar *)x error:(NSError **)error
{
    *x = 0;
    LXInteger i;
    for (i = 0; i < 4; i++) {
        unichar uc = *_ch;
        _ch++;
        int d = (uc >= '0' && uc <= '9')
        ? uc - '0' : (uc >= 'a' && uc <= 'f')
        ? (uc - 'a' + 10) : (uc >= 'A' && uc <= 'F')
        ? (uc - 'A' + 10) : -1;
        if (d == -1) {
            *error = err(EUNICODE, @"Missing hex digit in quad");
            return NO;
        }
        *x *= 16;
        *x += d;
    }
    return YES;
}

- (BOOL)scanNumber:(NSNumber **)o error:(NSError **)error
{
    const char *ns = _ch;
    
    // The logic to test for validity of the number formatting is relicensed
    // from JSON::XS with permission from its author Marc Lehmann.
    // (Available at the CPAN: http://search.cpan.org/dist/JSON-XS/ .)
    
    if ('-' == *_ch)
        _ch++;
    
    if ('0' == *_ch && _ch++) {        
        if (isdigit(*_ch)) {
            *error = err(EPARSENUM, @"Leading 0 disallowed in number");
            return NO;
        }
        
    } else if (!isdigit(*_ch) && _ch != ns) {
        *error = err(EPARSENUM, @"No digits after initial minus");
        return NO;
        
    } else {
        skipDigits(_ch);
    }
    
    // Fractional part
    if ('.' == *_ch && _ch++) {
        
        if (!isdigit(*_ch)) {
            *error = err(EPARSENUM, @"No digits after decimal point");
            return NO;
        }        
        skipDigits(_ch);
    }
    
    // Exponential part
    if ('e' == *_ch || 'E' == *_ch) {
        _ch++;
        
        if ('-' == *_ch || '+' == *_ch)
            _ch++;
        
        if (!isdigit(*_ch)) {
            *error = err(EPARSENUM, @"No digits after exponent");
            return NO;
        }
        skipDigits(_ch);
    }
    
    id str = [[NSString alloc] initWithBytesNoCopy:(char*)ns
                                            length:_ch - ns
                                          encoding:NSUTF8StringEncoding
                                      freeWhenDone:NO];
    [str autorelease];
    
    // 2009.08.26, Pauli Ojala -- changed to regular NSNumber for Cocotron compatibility
    ///if (str && (*o = [NSDecimalNumber decimalNumberWithString:str]))
    ///    return YES;
    if (str) {
        double f = [str doubleValue];
        ///NSLog(@"... parsed double from JSON: %f", f);
        *o = [NSNumber numberWithDouble:f];
        return YES;
    }
    
    *error = err(EPARSENUM, @"Failed creating decimal instance");
    return NO;
}

- (BOOL)scanIsAtEnd
{
    skipWhitespace(_ch);
    return !*_ch;
}


#pragma mark Properties

- (BOOL)humanReadable {
    return _humanReadable;
}

- (void)setHumanReadable:(BOOL)f {
    _humanReadable = f;
}

/// Whether or not to sort the dictionary keys in the output
/** The default is to not sort the keys. */
- (BOOL)sortsKeys {
    return _sortsKeys;
}

- (void)setSortsKeys:(BOOL)f {
    _sortsKeys = f;
}

/// The maximum depth the parser will go to
/** Defaults to 512. */
- (LXUInteger)maxDepth {
    return _maxDepth;
}

- (void)setMaxDepth:(LXUInteger)maxDepth {
    _maxDepth = maxDepth;
}

- (BOOL)allowsUnknownObjects {
    return _includeUnknownObjects; }
    
- (void)setAllowsUnknownObjects:(BOOL)f {
    _includeUnknownObjects = f;
}

@end
