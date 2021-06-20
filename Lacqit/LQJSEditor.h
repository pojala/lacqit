//
//  LQJSEditor.h
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

#import <Cocoa/Cocoa.h>


@class LQJSInterpreter;


/*!
    @class       LQJSEditor 
    @superclass  NSObject
    @abstract    A simple JavaScript editor support object
    @discussion  Create one of these and "attach" it to a text view, and it will automatically add
 keyword coloring, simple auto-indendation, etc...
*/
@interface LQJSEditor : NSObject {
    LQJSInterpreter *myInterpreter;
    NSTextView *myTextView;
    
    id _delegate;
    
    BOOL _rtRefreshPending;
    double _lastTextUpdateTime;
}

/*!
    @method     initWithInterpreter:textView:
    @abstract   Create a JavaScript editor support object.
    @discussion Creates the object which hooks into a given text view, for a given interpreter
    @param      interpreter The interpreter to use - note that it asks this interpreter for various keywords
 to support keyword coloring that include interpreter specific globals
    @param      textView The NSTextView that will be the editor
    @result     The initialized object
*/
- (id) initWithInterpreter: (LQJSInterpreter *) interpreter textView: (NSTextView *) textView; 
/*!
    @method     showError:
    @abstract   Selects the line of the error
    @discussion When a JavaScript error occurs, this routine can take that error and select the corresponding source code
    @param      error The JavaScript error
*/
- (void) showError: (NSError *)error;


// added by Pauli Ojala, 2010.03.10.
// selected textview delegate methods are forwarded to this delegate.
// also has new delegate methods below.
- (void)setDelegate:(id)del;
- (id)delegate;

- (void)refreshSyntaxColoring;

@end

@interface NSObject (LQJSEditorDelegate)
- (BOOL)jsEditorShouldRefreshSyntaxColoring:(LQJSEditor *)editor;
- (void)jsEditorDidRefreshSyntaxColoring:(LQJSEditor *)editor;
@end
