//
//  JSKitSourceUtil.h
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

#import <Cocoa/Cocoa.h>

@class JSKitSourceUtil;
@class LQJSKitInterpreter;


typedef enum {
    kJSKitTokenIdentifier, // a plain identifier
    kJSKitTokenPunctuation, // commas, parens, braces, brackets, semicolon.
    kJSKitTokenOperator,
    kJSKitTokenComment, 
    kJSKitTokenString,
    kJSKitTokenRegEx,
    kJSKitTokenNumber,
    kJSKitTokenReserved, // reserved keywords
    kJSKitTokenConstant, // keywords which represent values (true, false, null, this)
    kJSKitTokenFunction,
    kJSKitTokenConstructor, //  the various types
    kJSKitTokenGlobal, // as provided by the interpreter
    kJSKitTokenError, // strange unexpected syntax
    // special (internal) token types
    kJSKitTokenWhiteSpace,
    kJSKitTokenNewLine,
    kJSKitTokenEnd, // end of file
} JSKitSourceTokenType;

/*!
 @protocol  JSKitSyntaxColorProtocol
 @abstract    Used to actually handle applying the syntax coloring to source
 @discussion  The JSKitSourceUtil can parse and color JavaScript, but since raw source has no attributes, it requires
 some other object to apply this coloring.  That object should adopt this protocol.
 */

@protocol JSKitSyntaxColorProtocol
/*!
    @method     jskitColor:range:withKind:
    @abstract   Apply syntax coloring to JavaScript source
    @discussion When the JSKitSourceUtil is asked to keyword color JavaScript, this routine is called to actually apply the corresponding color.
 Note that this could do something as simple as setting the color attributes of an attributed string, or be used to generate HTML formatted code
 that contians that code and appropriate markup.
    @param      util The JSKitSourceUtil that is parsing the source
    @param      range The range of the current keyword
    @param      tokenType What type of keyword has been parsed.
*/
- (void) jskitColor: (JSKitSourceUtil *)util range: (NSRange) range withKind: (JSKitSourceTokenType) tokenType;
@end

/*!
 @class	JSKitSourceUtil
 @abstract    Utilities for manipulating JavaScript source
 @discussion  Provides some JavaScript syntax aware source manipulation utilities
 */
@interface JSKitSourceUtil : NSObject {
    NSMutableString *mySource;
    // for scanning
    NSScanner *myScanner;
    BOOL myLastIsDot;
    BOOL myNextCouldBeRegex;
    JSKitSourceTokenType myLastToken;
    LQJSKitInterpreter *myInterpreter;
}
/*!
    @method     initWithSource:
    @abstract   Creates a source utility object for a given set of source code
 @param source	The current source
    @discussion Default initiliazer for the JavaScript savvy source code utility.  Note that this automatically santizies the line feeds and removes tabs (converting from 8 spaces per tab).
    @result     The initialized source utility object
*/
- (id) initWithSource: (NSString *) source;
/*!
    @method      currentSource
    @abstract   Get the current manipulated source
    @discussion The source utility object can maninpulate the source - this gets the current version of the manipulated source
    @result     The current source
*/
- (NSString *) currentSource;

/*!
    @method      reindent
    @abstract   "Pretty prints" the source code
    @discussion Redoes the indentation of the code, based on the program structure
*/
- (void) reindent;

/*!
    @method      compressCode
    @abstract   Removes all extra white space and comments from the code
    @discussion Used to reduce the size of the code (and slightly obfuscate it), will remove all unneeded white space and comments.[ Not yet implemented ]
*/
- (void) compressCode;


/*!
    @method      allIdentifiers
    @abstract   Finds all identifiers in the source code
    @discussion Parses the source code to find all identifiers in the code, returning a list of them
    @result     An array of identifiers (in no specified order)
*/
- (NSArray *) allIdentifiers;

/*!
    @method     syntaxColor:withInterpreter:
    @abstract   Parses the code, coloring it
 @param	colorer An object that conforms to JSKitSyntaxColorProtocol to apply the color formatting to the source
 @param interp An interpreter that will run the source code (to find out about global values, etc... - can be nil)
    @discussion Walks through the source code and tells the colorer about various tokens for it to color accordingly.
*/
- (void) syntaxColor: (id<JSKitSyntaxColorProtocol>) colorer withInterpreter: (LQJSKitInterpreter *) interp;

// Lower level JavaScript lexical parsing
/*!
    @method     prepScanner:
    @abstract   Being scanning the current source code
    @discussion Call before parsing via nextToken:, sets up internal states to be able to parse the code
    @param      interp An interpreter that will be used to find out about global values (can be nil)
*/
- (void) prepScanner: (LQJSKitInterpreter *) interp;
/*!
    @method     nextToken:
    @abstract   Get the next token from the soure
    @discussion Parses the JavaScript code for the next token
    @param      tokenRange A pointer to a range that will refer to where, in the current source, the token occurs
    @result     What kind of token was found
*/
- (JSKitSourceTokenType) nextToken: (NSRange *) tokenRange;

// Utils for source code manipulation
/*!
 @method     sanitizeLineFeeds:
 @abstract   Converts non-unix style line delimiters to unix-style line delimiters
 @param string The text to convert
 @result The sanitized string
 @discussion Coverts all MS-DOS (cr-lf) and Mac style (cr) delimiters to unix style delimiters (lf)
 */
+ (NSString *) sanitizeLineFeeds: (NSString *) string;
/*!
 @method     removeTabs:tabWidth:
 @abstract   Converts tabs to spaces
 @param string	The text to convert
 @param width	How many spaces "wide" a tab is (4 is a good value)
 @discussion Goes through the text, removing tabs and replacing them with spaces to ensure that the source code
 will line up when viewed with a mono-spaced font (regardless of the indentation value)
 @result     The converted text
 */
+ (NSString *) removeTabs: (NSString *) string tabWidth: (int) width;
//+ (NSString *) preprocessSource: (NSString *) source withDefines: (NSDictionary *) defines;

@end

