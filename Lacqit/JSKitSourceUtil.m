//
//  JSKitSourceUtil.m
//  JSKit
//
//  Created by glenn andreas on 4/9/08.
//    Copyright (C) 2008 gandreas software. 
//    Permission is hereby granted, free of charge, to any person
//    obtaining a copy of this software and associated documentation
//    files (the "Software"), to deal in the Software without
//    restriction, including without limitation the rights to use,
//    copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the
//    Software is furnished to do so, subject to the following
//    conditions:
//
//    The above copyright notice and this permission notice shall be
//    included in all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//    OTHER DEALINGS IN THE SOFTWARE.
//

#import "JSKitSourceUtil.h"
#import <LacqJS/LQJSInterpreter.h>
#import <LacqJS/LQJSBridgeObject.h>
#import <LacqJS/JSKitObject.h>

@implementation JSKitSourceUtil
- (id) initWithSource: (NSString *) source
{
    self = [super init];
    if (self) {
	// start by sanitizing line feeds and tabs
	mySource = [[JSKitSourceUtil removeTabs: [JSKitSourceUtil sanitizeLineFeeds:source] tabWidth: 8] mutableCopy];
    }
    return self;
}
- (void) dealloc
{
    [myScanner release];
    [myInterpreter release];
    [mySource release];
    [super dealloc];
}
- (NSString *) currentSource
{
    return mySource;
}

- (void) prepScanner: (LQJSKitInterpreter *) interp;
{
    [myScanner release];
    myScanner = [[NSScanner scannerWithString: mySource] retain];
    [myScanner setCharactersToBeSkipped:[NSCharacterSet illegalCharacterSet]];
    [myInterpreter release];
    myInterpreter = [interp retain];
    myLastToken = kJSKitTokenPunctuation;
    myNextCouldBeRegex = YES;
    myLastIsDot = NO;
}

- (JSKitSourceTokenType) nextToken: (NSRange *) tokenRange;
{
    if ([myScanner isAtEnd])
	return kJSKitTokenEnd;
    JSKitSourceTokenType retval = kJSKitTokenWhiteSpace;
    NSString *token;
    double x;
    unsigned startLoc = [myScanner scanLocation];
    if ([myScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil]) { // get non-newline whitespace
	// white space doesn't change any state
	*tokenRange = NSMakeRange(startLoc, [myScanner scanLocation] - startLoc);
	return kJSKitTokenWhiteSpace;
    }
    if ([myScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil]) { // get newlines
	// white space doesn't change any state
	*tokenRange = NSMakeRange(startLoc, [myScanner scanLocation] - startLoc);
	return kJSKitTokenNewLine;
    }
    if ([myScanner scanString:@"//" intoString:nil]) { // comment to end of line
	unsigned start = [myScanner scanLocation] - 2;
	if ([myScanner scanUpToString:@"\n" intoString: nil]) { // got end of line
	    *tokenRange = NSMakeRange(start, [myScanner scanLocation] - start);
	    retval = kJSKitTokenComment;
	} else {
	    *tokenRange = NSMakeRange([myScanner scanLocation] - 2, [mySource length] - ([myScanner scanLocation] - 2));	    
	    retval = kJSKitTokenComment;
	    return retval; // went to end of file
	}
    } else if ([myScanner scanString:@"/*" intoString:nil]) { // enclosed comment
	unsigned start = [myScanner scanLocation] - 2;
	[myScanner scanUpToString:@"*/" intoString: nil];
	if ([myScanner scanString:@"*/" intoString: nil]) { // got closing comment 
	    *tokenRange = NSMakeRange(start, [myScanner scanLocation] - start);
	    retval = kJSKitTokenComment;
	} else {
	    *tokenRange = NSMakeRange(start, [mySource length] - start);
	    retval = kJSKitTokenComment;
	    return retval; // went to end of file
	}
    } else if ([myScanner scanString:@"'" intoString:nil]) { // single quote
	unsigned start = [myScanner scanLocation] - 1;
	while (1) { // get all the escaped quotes
	    unsigned unget = [myScanner scanLocation];
	    [myScanner scanUpToString:@"\\'" intoString: nil];
	    if (![myScanner scanString:@"\\'" intoString:nil]) {
		[myScanner setScanLocation:unget];
		break;
	    }
	}
	[myScanner scanUpToString:@"'" intoString: nil];
	if ([myScanner scanString:@"'" intoString: nil]) { // got closing comment 
	    *tokenRange = NSMakeRange(start, [myScanner scanLocation] - start);
	    myLastToken = retval = kJSKitTokenString;
	}
	myLastIsDot = NO;
	myNextCouldBeRegex = NO;
    } else if ([myScanner scanString:@"\"" intoString:nil]) { // double quote
	unsigned start = [myScanner scanLocation] - 1;
	while (1) { // get all the escaped quotes
	    unsigned unget = [myScanner scanLocation];
	    [myScanner scanUpToString:@"\\\"" intoString: nil];
	    if (![myScanner scanString:@"\\\"" intoString:nil]) {
		[myScanner setScanLocation:unget];
		break;
	    }
	}
	[myScanner scanUpToString:@"\"" intoString: nil];
	if ([myScanner scanString:@"\"" intoString: nil]) { // got closing comment 
	    *tokenRange = NSMakeRange(start, [myScanner scanLocation] - start);
	    myLastToken = retval = kJSKitTokenString;
	}
	myLastIsDot = NO;
	myNextCouldBeRegex = NO;
    } else if (myNextCouldBeRegex && [myScanner scanString:@"/" intoString:nil]) { // regex, only valid after punctuation  (so as to not confuse with division)
	unsigned start = [myScanner scanLocation] - 1;
	while (1) { // get all the escaped forward slashes
	    unsigned unget = [myScanner scanLocation];
	    [myScanner scanUpToString:@"\\/" intoString: nil];
	    if (![myScanner scanString:@"\\/" intoString:nil]) {
		[myScanner setScanLocation:unget];
		break;
	    }
	}
	[myScanner scanUpToString:@"/" intoString: nil];
	if ([myScanner scanString:@"/" intoString: nil]) { // got closing slash
	    // should scan for flags as well...
	    [myScanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:nil];
	    *tokenRange = NSMakeRange(start, [myScanner scanLocation] - start);
	    myLastToken = retval = kJSKitTokenRegEx;
	}
	myLastIsDot = NO;
	myNextCouldBeRegex = NO;
    } else if ([myScanner scanDouble:&x]) {
	*tokenRange = NSMakeRange(startLoc, [myScanner scanLocation] - startLoc);
	retval = kJSKitTokenNumber;
	myLastIsDot = NO;
	myNextCouldBeRegex = NO;
    } else if ([myScanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&token]) {
	if (myLastIsDot) { // we've got foo.bar, don't  higlight bar..
	    myLastIsDot = NO;
	    myLastToken = kJSKitTokenIdentifier;
	    myNextCouldBeRegex = NO;
	    return kJSKitTokenIdentifier;
	}
	static NSArray *keywords = nil;
	if (!keywords) {
	    keywords = [[NSArray arrayWithObjects:
			 @"break",
			 @"case",
			 @"continue",
			 @"default",
			 @"delete",
			 @"do",
			 @"else",
			 @"export",
			 @"for",
			 @"function",
			 @"instanceof",
			 @"import",
			 @"if",
			 @"in",
			 @"new",
			 @"return",
			 @"switch",
			 @"typeof",
			 @"var",
			 @"void",
			 @"while",
			 @"with",
			 nil] retain];
	}
	if ([keywords indexOfObject:token] != NSNotFound) {
	    *tokenRange = NSMakeRange([myScanner scanLocation] - [token length], [token length]);
	    myLastToken = retval = kJSKitTokenReserved;
	    myNextCouldBeRegex = NO;
	} else {
	    static NSArray *constants = nil;
	    if (!constants) {
		constants = [[NSArray arrayWithObjects:
			      @"this",@"true",@"false", @"null",
			      nil] retain];
	    }
	    if ([constants indexOfObject:token] != NSNotFound) {
		*tokenRange = NSMakeRange([myScanner scanLocation] - [token length], [token length]);
		myLastToken = retval = kJSKitTokenConstant;
		myNextCouldBeRegex = NO;
	    } else {
		static NSArray *types = nil;
		if (!types) {
		    types = [[NSArray arrayWithObjects:
			      @"Array",@"Boolean",@"Date",@"Function",@"Number",@"Object", @"RegExp",@"String",
			      nil] retain];
		}
		*tokenRange = NSMakeRange([myScanner scanLocation] - [token length], [token length]);
		myNextCouldBeRegex = NO;
		if ([types indexOfObject:token] != NSNotFound) {
		    myLastToken = retval = kJSKitTokenConstructor;
		} else if (myInterpreter) {
		    id value = [myInterpreter globalVariableForKey: token];
		    if (value && value != [NSNull null]) {
			if ([value isKindOfClass:[LQJSKitObject class]]) {
			    if ([value isFunction]) {
				myLastToken = retval = kJSKitTokenFunction;
			    } else if ([value isConstructor]) {
				myLastToken = retval = kJSKitTokenConstructor;
			    } else {
				myLastToken = retval = kJSKitTokenGlobal;
			    }
			} else if ([value isKindOfClass: [LQJSBridgeObject class]]) {
			    myLastToken = retval = kJSKitTokenConstructor;
			} else {
			    myLastToken = retval = kJSKitTokenGlobal;
			}
		    } else {
			myLastToken = retval = kJSKitTokenIdentifier;
		    }
		} else {
		    myLastToken = retval = kJSKitTokenIdentifier;
		}
	    }
	}
	myLastIsDot = NO;
    } else if ([myScanner scanString:@"." intoString:nil]) {
	*tokenRange = NSMakeRange([myScanner scanLocation]-1,1);
	myLastIsDot = YES;
	myLastToken = retval = kJSKitTokenOperator;
	myNextCouldBeRegex = NO;
    } else { // consume a single whatever
	static NSCharacterSet *operatorCharacterSet = nil;
	if (!operatorCharacterSet)
	    operatorCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"+-/*%<>&|?:^=!~"] retain];
	if ([myScanner scanCharactersFromSet:operatorCharacterSet intoString:&token]) {
	    static NSArray *operators = nil;
	    if (!operators)
		operators = [[NSArray arrayWithObjects:
			     @"+",@"-",@"/",@"*",@"%",
			      @"<<",@"<<<",@">>",@">>>",
			      @"&",@"|",@"^",@"&&",@"||",
			     @"=",@"==",@">=",@"<=",@"===",@"!==",
			    @"?",@":",
			      @"+=",@"-=",@"/=",@"*=",@"%=",@"<<=",@"<<<=",@">>=",@">>>=",@"|=",@"&=",@"^=",
			     nil] retain];
	    myLastIsDot = NO;
	    *tokenRange = NSMakeRange([myScanner scanLocation] - [token length], [token length]);
	    if ([operators indexOfObject:token] != NSNotFound) {
		myNextCouldBeRegex = YES;
		myLastToken = retval = kJSKitTokenOperator;
	    } else {
		myNextCouldBeRegex = NO;
		myLastToken = retval = kJSKitTokenPunctuation;
	    }
	} else {
	    static NSCharacterSet *punctCharacterSet = nil;
	    if (!punctCharacterSet)
		punctCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"()[]{};,"] retain];
	    *tokenRange = NSMakeRange([myScanner scanLocation]-1,1);
	    myLastIsDot = NO;
	    myNextCouldBeRegex = NO;
	    unichar c = [mySource characterAtIndex:[myScanner scanLocation]];
	    if ([punctCharacterSet characterIsMember:c]) {
		myLastToken = retval = kJSKitTokenPunctuation;
	    } else {
		// otherwise we really don't know
		myLastToken = retval = kJSKitTokenError;
	    }
	    if (c == '(' || c == '[' || c == ',')
		myNextCouldBeRegex = YES;
	    [myScanner setScanLocation:[myScanner scanLocation] + 1];
	}
    }
    return retval;
}

- (void) syntaxColor: (id<JSKitSyntaxColorProtocol>) colorer withInterpreter: (LQJSKitInterpreter *) interp
{
    [self prepScanner: interp];
    JSKitSourceTokenType token;
    while (1) {
	NSRange foundRange;
	token = [self nextToken:&foundRange];
	if (token == kJSKitTokenEnd)
	    break;
	if (token == kJSKitTokenWhiteSpace || token == kJSKitTokenNewLine)
	    continue;
	[colorer jskitColor:self range:foundRange withKind:token];
    }
}


- (void) reindent
{
    [self prepScanner: nil];
    JSKitSourceTokenType token;
    NSMutableString *newSource = [NSMutableString string];
    BOOL skipLeadingWhiteSpace = YES;
    int indent = 0;
    while (1) {
	NSRange foundRange;
	token = [self nextToken:&foundRange];
	if (token == kJSKitTokenEnd)
	    break;
	if (token == kJSKitTokenWhiteSpace && skipLeadingWhiteSpace) {
	    continue;
	} else if (token == kJSKitTokenNewLine) {
	    skipLeadingWhiteSpace = YES; // skip next lines white space
	} else if (token != kJSKitTokenWhiteSpace && skipLeadingWhiteSpace) {
	    // we were skipping white space, now we aren't, so add the indent
	    while (indent > 0) {
		[newSource appendString: @"    "];
		indent--;
	    }
	}
	NSString *tokenStr = [mySource substringWithRange:foundRange];
	if (token == kJSKitTokenPunctuation) {
	    // adjust indentation
	    if ([tokenStr isEqualToString:@"("] || [tokenStr isEqualToString: @"{"] || [tokenStr isEqualToString:@"["]) {
		indent++;
	    } else if ([tokenStr isEqualToString:@"]"] || [tokenStr isEqualToString: @"}"] || [tokenStr isEqualToString:@")"]) {
		indent--;
	    }
	}
	[newSource appendString:tokenStr];
    }
    [mySource setString:newSource];
}

- (void) compressCode
{
}

#pragma mark source utils
+ (NSString *) sanitizeLineFeeds: (NSString *) string
{
    if ([string rangeOfString:@"\r"].location != NSNotFound) {
	NSMutableString *retval = [string mutableCopy];
	// need to sanitize
	[retval replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0,[retval length])]; // cr-lf to lf
	[retval replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0,[retval length])]; // any left over cr to lf
	return [retval autorelease];
    } else {
	return string;
    }
}
+ (NSString *) removeTabs: (NSString *) string tabWidth: (int) width
{
    char indentChars[width+1];
    memset(indentChars, ' ', width);
    indentChars[width] = 0;
    NSString *indent = [NSString stringWithUTF8String:indentChars];

    NSMutableString *retval = [string mutableCopy];
    unsigned i;
    unsigned linePos = 0;
    // Need to track quotes to handle ignoring tabs inside single or double quoted text
    BOOL lastEscape = NO;
    unichar quote = 0;
    while (i < [retval length]) {
        unichar c = [retval characterAtIndex:i];
        if (c == '\\') {
            lastEscape = YES;
            linePos++;
        } else {
            if (c == '\t' && quote == 0) {
                // remove it
                [retval deleteCharactersInRange:NSMakeRange(i, 1)];
                unsigned newLineIndent = (linePos + width) % width;
                /*while (newLineIndent) {
                    [retval insertString:@" " atIndex:i];
                    i++;
                    newLineIndent--;
                }*/
                if (newLineIndent > 0) {
                    NSString *strToInsert = (newLineIndent >= width) ? indent : [indent substringToIndex:newLineIndent];
                    [retval insertString:strToInsert atIndex:i];
                    i += [strToInsert length];
                }
                lastEscape = NO;
                continue; // i correctly points to the next character
            } else if (c == NSNewlineCharacter || c == NSCarriageReturnCharacter || c == NSLineSeparatorCharacter || c == NSParagraphSeparatorCharacter || c == NSFormFeedCharacter) {
                linePos = 0;
            } else if (c == '\'' || c == '"') {
                if (lastEscape) { //  escaped quote changes nothing
                } else if (quote == 0) {
                    quote = c; // start of quote
                } else if (quote == c) {
                    quote = 0; // end of quote
                } else { // we're inside different quotes, so ignore this
                }
                linePos++;
            } else {
                linePos++;
            }
            lastEscape = NO;
        }
        i++;
    }
    return [retval autorelease];
}

#ifdef notyet
+ (NSString *) preprocessSource: (NSString *) source withDefines: (NSDictionary *) defines
{
    return source;
}
#endif

- (NSArray *) allIdentifiers
{
    return  [NSArray array];
}

@end
