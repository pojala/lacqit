//
//  LQJSMinifier.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSMinifier.h"
#import <Lacefx/LXBasicTypes.h>


/* jsmin.c
   2008-08-03

Copyright (c) 2002 Douglas Crockford  (www.crockford.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

The Software shall be used for Good, not Evil.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

#include <stdlib.h>
#include <stdio.h>

// JSMin modified by Pauli Ojala, 2009.08.04.
// for Obj-C wrapper, the minifier must use a state object instead of static vars.
// also replaced putc/getc with NSString calls
//
typedef struct {
    int a;
    int b;
    int lookahead;  // start state: EOF
    
    NSString *inStr;
    size_t inStrLen;
    size_t cursor;
    NSMutableString *outStr;
    
    NSString *error;
} LQJSMinState;


static inline int jsm_getc(LQJSMinState *state)
{
    int c = EOF;
    if (state->cursor < state->inStrLen) {
        c = [state->inStr characterAtIndex:state->cursor++];
    }
    return c;
}

static inline int jsm_putc(LQJSMinState *state, int c)
{
    unichar uc = c;
    [state->outStr appendString:[NSString stringWithCharacters:&uc length:1]];
    return c;
}


/* isAlphanum -- return true if the character is a letter, digit, underscore,
        dollar sign, or non-ASCII character.
*/

static int
isAlphanum(int c)
{
    return ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
        (c >= 'A' && c <= 'Z') || c == '_' || c == '$' || c == '\\' ||
        c > 126);
}


/* get -- return the next character from stdin. Watch out for lookahead. If
        the character is a control character, translate it to a space or
        linefeed.
*/

static int
get(LQJSMinState *state)
{
    int c = state->lookahead;
    state->lookahead = EOF;
    if (c == EOF) {
        //c = getc(stdin);
        c = jsm_getc(state);
    }
    if (c >= ' ' || c == '\n' || c == EOF) {
        return c;
    }
    if (c == '\r') {
        return '\n';
    }
    return ' ';
}


/* peek -- get the next character without getting it.
*/

static int
peek(LQJSMinState *state)
{
    state->lookahead = get(state);
    return state->lookahead;
}


/* next -- get the next character, excluding comments. peek() is used to see
        if a '/' is followed by a '/' or '*'.
*/

static int
next(LQJSMinState *state)
{
    int c = get(state);
    if  (c == '/') {
        switch (peek(state)) {
        case '/':
            for (;;) {
                c = get(state);
                if (c <= '\n') {
                    return c;
                }
            }
        case '*':
            get(state);
            for (;;) {
                switch (get(state)) {
                case '*':
                    if (peek(state) == '/') {
                        get(state);
                        return ' ';
                    }
                    break;
                case EOF:
                    //fprintf(stderr, "Error: JSMIN Unterminated comment.\n");
                    //exit(1);
                    state->error = @"Minifier: unterminated comment.";
                    return EOF;
                }
            }
        default:
            return c;
        }
    }
    return c;
}


/* action -- do something! What you do is determined by the argument:
        1   Output A. Copy B to A. Get the next B.
        2   Copy B to A. Get the next B. (Delete A).
        3   Get the next B. (Delete B).
   action treats a string as a single character. Wow!
   action recognizes a regular expression if it is preceded by ( or , or =.
*/

static void
action(LQJSMinState *state, int d)
{
    switch (d) {
    case 1:
        jsm_putc(state, state->a);
    case 2:
        state->a = state->b;
        if (state->a == '\'' || state->a == '"') {
            for (;;) {
                jsm_putc(state, state->a);
                state->a = get(state);
                if (state->a == state->b) {
                    break;
                }
                if (state->a == '\\') {
                    jsm_putc(state, state->a);
                    state->a = get(state);
                }
                if (state->a == EOF) {
                    state->error = @"Minifier: unterminated string literal.";
                    return;
                }
            }
        }
    case 3:
        state->b = next(state);
        if (state->b == '/' && (state->a == '(' || state->a == ',' || state->a == '=' ||
                            state->a == ':' || state->a == '[' || state->a == '!' ||
                            state->a == '&' || state->a == '|' || state->a == '?' ||
                            state->a == '{' || state->a == '}' || state->a == ';' ||
                            state->a == '\n')) {
            jsm_putc(state, state->a);
            jsm_putc(state, state->b);
            for (;;) {
                state->a = get(state);
                if (state->a == '/') {
                    break;
                }
                if (state->a =='\\') {
                    jsm_putc(state, state->a);
                    state->a = get(state);
                }
                if (state->a == EOF) {
                    state->error = @"Minifier: unterminated regex literal.";
                    return;
                }
                jsm_putc(state, state->a);
            }
            state->b = next(state);
        }
    }
}


/* jsmin -- Copy the input to the output, deleting the characters which are
        insignificant to JavaScript. Comments will be removed. Tabs will be
        replaced with spaces. Carriage returns will be replaced with linefeeds.
        Most spaces and linefeeds will be removed.
*/

static void
jsmin(LQJSMinState *state)
{
    state->a = '\n';
    action(state, 3);
    while (state->a != EOF && !state->error) {
        switch (state->a) {
        case ' ':
            if (isAlphanum(state->b)) {
                action(state, 1);
            } else {
                action(state, 2);
            }
            break;
        case '\n':
            switch (state->b) {
            case '{':
            case '[':
            case '(':
            case '+':
            case '-':
                action(state, 1);
                break;
            case ' ':
                action(state, 3);
                break;
            default:
                if (isAlphanum(state->b)) {
                    action(state, 1);
                } else {
                    action(state, 2);
                }
            }
            break;
        default:
            switch (state->b) {
            case ' ':
                if (isAlphanum(state->a)) {
                    action(state, 1);
                    break;
                }
                action(state, 3);
                break;
            case '\n':
                switch (state->a) {
                case '}':
                case ']':
                case ')':
                case '+':
                case '-':
                case '"':
                case '\'':
                    action(state, 1);
                    break;
                default:
                    if (isAlphanum(state->a)) {
                        action(state, 1);
                    } else {
                        action(state, 3);
                    }
                }
                break;
            default:
                action(state, 1);
                break;
            }
        }
    }
}


@implementation LQJSMinifier

- (id)init
{
    self = [super init];
    
    _state = _lx_calloc(1, sizeof(LQJSMinState));
    
    return self;
}

- (void)dealloc
{
    _lx_free(_state);
    [super dealloc];
}

- (NSString *)minifyJavaScript:(NSString *)inStr withErrorDescription:(NSString **)outError
{
    if ( !inStr || [inStr length] < 1) return nil;
    
    LQJSMinState *state = (LQJSMinState *)_state;
    memset(state, 0, sizeof(LQJSMinState));
    
    state->lookahead = EOF;
    state->inStr = inStr;
    state->inStrLen = [inStr length];
    state->cursor = 0;
    state->outStr = [NSMutableString stringWithCapacity:state->inStrLen];
    
    jsmin(state);
    
    state->inStr = nil;
    
    if (state->error) {
        *outError = state->error;
        return nil;
    } else {
        return state->outStr;
    }
}

@end
