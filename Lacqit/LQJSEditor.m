//
//  LQJSEditor.mm
//  JSKit
//
//  Created by glenn andreas on 4/7/08.
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

#import "LQJSEditor.h"
#import "JSKitSourceUtil.h"
#import <LacqJS/LQJSInterpreter.h>
#import <LacqJS/JSKitException.h>
#import <Lacefx/LXBasicTypes.h>


extern NSLock *g_jsLock;

#define ENTERCONTEXTLOCK  [g_jsLock lock];
#define EXITCONTEXTLOCK   [g_jsLock unlock];



@implementation LQJSEditor
- (id) initWithInterpreter: (LQJSInterpreter *) interpreter textView: (NSTextView *) textView
{
    self = [super init];
    if (self) {
        myInterpreter = [interpreter retain];
        myTextView = [textView retain];
        [textView setDelegate:(id)self];
        [[textView textStorage] setDelegate:(id)self];
        
        NSFont *font = [textView font];
        if ( !font) {  // || ![font isFixedPitch]) {
            font = [NSFont userFixedPitchFontOfSize:[NSFont smallSystemFontSize]];
        }
        
        ///NSLog(@"setting textview font: %@, isfixedp %i -- editor %p, font: %@", font, [font isFixedPitch], textView, [textView font]);
        
        [textView setFont:font];
        [textView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    }
    ///NSLog(@"%s -- textview %p -- storage %p", __func__, textView, [textView textStorage]);
    return self;
}
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [myTextView setDelegate: nil];
    [myTextView release];
    [myInterpreter release];
    [super dealloc];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    // other useful selectors found in <NSResponder.h> in
    // 		@interface NSResponder (NSStandardKeyBindingMethods)
   if (aSelector == @selector(insertNewline:)) {
       // handle auto-indent
       NSRange selectedRange = [aTextView selectedRange]; // figure out the start of this line
       selectedRange.length = 0; // make sure that we work with the start of the range
       NSString *text = [aTextView string];
       LXUInteger startIndex;
       LXUInteger lineEndIndex;
       LXUInteger contentsEndIndex;
       [text getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: selectedRange];
       if (lineEndIndex > selectedRange.location)
	   lineEndIndex = selectedRange.location; // only include up to where cursor is
       NSString *thisLine = [text substringWithRange: NSMakeRange(startIndex,lineEndIndex - startIndex)];
       [aTextView insertNewline: self];
       NSScanner *scanner = [NSScanner scannerWithString:thisLine];
       [scanner setCharactersToBeSkipped:[NSCharacterSet illegalCharacterSet]];
       NSString *whiteSpace;
       if ([scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&whiteSpace]) {
	   [aTextView insertText: whiteSpace];
       }
       return YES;
//   } else if (aSelector == @selector(indent:)) {
//       NSLog(@"indent");
//   } else if (aSelector == @selector(insertTab:)) {
//       NSLog(@"insertTab");
   }
    return NO;
}
- (void) selectLine: (NSInteger) line
{
    NSString *src = [myTextView string];
    NSRange lineRange = NSMakeRange(0, 0);
    while (line > 0) {
        lineRange.location = lineRange.location + lineRange.length;
        lineRange.length = 0;
        lineRange = [src lineRangeForRange:lineRange];
        line--;
    }
    [myTextView setSelectedRange:lineRange];
    [myTextView scrollRangeToVisible:lineRange];
}

- (void)refreshSyntaxColoring
{
    NSTextStorage *storage = [myTextView textStorage];
    NSString *text = [storage string];
    
    [storage removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [text length])];
    
    if ([_delegate respondsToSelector:@selector(jsEditorShouldRefreshSyntaxColoring:)]) {
        if ( ![_delegate jsEditorShouldRefreshSyntaxColoring:self])
            return;
    }

    JSKitSourceUtil *util = [[JSKitSourceUtil alloc] initWithSource:text];
    ENTERCONTEXTLOCK
    
    @try {
        [util syntaxColor: (id<JSKitSyntaxColorProtocol>)self withInterpreter: myInterpreter];
    }
    @catch (id exc) {
        NSLog(@"** %s: %@", __func__, exc);
    }
    
    EXITCONTEXTLOCK
    [util release];
    
    if ([_delegate respondsToSelector:@selector(jsEditorDidRefreshSyntaxColoring:)]) {
        [_delegate jsEditorDidRefreshSyntaxColoring:self];
    }
}

- (void)_updateRichText:(id)unused
{
    if ( !_rtRefreshPending || (CFAbsoluteTimeGetCurrent() - _lastTextUpdateTime) < 0.4)
        return;
        
    _rtRefreshPending = NO;
    
    [self refreshSyntaxColoring];
}

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
    NSTextStorage *obj = [notification object];
    
    ///NSLog(@"%s, text len %i", __func__, [[obj string] length]);
    
    unsigned long mask = [obj editedMask];
    if (mask == NSTextStorageEditedAttributes)
        return; // don't care about attributes being edited
        
    NSString *text = [obj string];
#if 1
    // clear out attributes only for edited line
    NSRange editedRange = [obj editedRange];
    LXUInteger startIndex;
    LXUInteger lineEndIndex;
    LXUInteger contentsEndIndex;
    [text getLineStart: &startIndex end: &lineEndIndex contentsEnd: &contentsEndIndex forRange: editedRange];
    // start by clearing the attributes
    [obj removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(startIndex,contentsEndIndex-startIndex)];
#else
    // clear out coloring from entire range
    [obj removeAttribute: NSForegroundColorAttributeName range: NSMakeRange(0, [text length])];
#endif

    _rtRefreshPending = YES;
    _lastTextUpdateTime = CFAbsoluteTimeGetCurrent();
    
    [self performSelector:@selector(_updateRichText:) withObject:nil afterDelay:0.5];
}


- (void) jskitColor: (JSKitSourceUtil *)util range: (NSRange) range withKind: (JSKitSourceTokenType) tokenType
{
    NSColor *color = nil;
    switch (tokenType) {
	case kJSKitTokenIdentifier:
	    break;
	case kJSKitTokenPunctuation:
	    break;
	case kJSKitTokenComment:
	    color = [NSColor grayColor];
	    break;
	case kJSKitTokenString:
	    color = [[NSColor greenColor] blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];
	    break;
	case kJSKitTokenRegEx:
	    color = [[NSColor redColor] blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];
	    break;
	case kJSKitTokenNumber:
	    color = [NSColor colorWithCalibratedRed:0.3 green:0.0 blue:0.82 alpha:1.0];
	    break;
	case kJSKitTokenReserved:
	    color = [NSColor colorWithCalibratedRed:0.0 green:0.05 blue:0.95 alpha:1.0];
	    break;
	case kJSKitTokenConstant:  // true, false, null, this
	    color = [NSColor colorWithCalibratedRed:0.4 green:0.6 blue:0.9 alpha:1.0];
	    break;
	case kJSKitTokenFunction:
	    color = [[NSColor greenColor] blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];
	    break;
	case kJSKitTokenConstructor:
	    color = [[NSColor blueColor] blendedColorWithFraction:0.5 ofColor:[NSColor blackColor]];
	    break;	    
	case kJSKitTokenGlobal:
	    color = [NSColor brownColor];
	    break;	    
    }
    if (color) {
        [[myTextView textStorage] addAttribute:NSForegroundColorAttributeName
                                    value:color
                                    range:range];
    }
    ///printf("jskit color, tokentype %i\n", tokenType);
}

- (void) showError: (NSError *)error
{
    if ([[error domain] isEqualToString:LQJSKitErrorDomain]) {
	LQJSKitObject *jserr = [[error userInfo] objectForKey:LQJSKitErrorObjectKey];
	if ([jserr valueForKey:@"line"]) {
	    [self selectLine: [[jserr valueForKey: @"line"] intValue]];
	}
    }
}


- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }


- (void)textViewDidChangeSelection:(NSNotification *)notif
{
    if ([_delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [_delegate textViewDidChangeSelection:notif];
    }
}


@end
