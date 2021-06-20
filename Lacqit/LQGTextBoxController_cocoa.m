//
//  LQGTextFieldController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTextBoxController_cocoa.h"
#import "LQFlippedView.h"
#import "LQSegmentedControl.h"

#if defined(__APPLE__)
#import "LQJSEditor.h"
#endif


#define TAG_PARAMTEXTVIEW 512532



@implementation LQGTextBoxController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [_editor release];
    [super dealloc];
}

- (NSString *)label {
    return (_label) ? _label : [_labelField stringValue];
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    [_labelField setStringValue:(_label) ? _label : @""];
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag;
}

- (BOOL)isMultiline {
    return _isMultiline; }

- (void)setMultiline:(BOOL)f {
    _isMultiline = f; }
    
- (BOOL)hasSaveAndRevert {
    return _hasApplyButton; }
    
- (void)setHasSaveAndRevert:(BOOL)f {
    _hasApplyButton = f; }

- (void)setEnabled:(BOOL)f {
    [_textView setEnabled:f]; }

- (BOOL)isSecure {
    return _isSecure; }

- (void)setSecure:(BOOL)f {
    _isSecure = f; }


- (NSString *)stringValue {
    return _str; }

- (void)setStringValue:(NSString *)str
{
    [_str autorelease];
    _str = [str copy];

    if ([_textView respondsToSelector:@selector(setString:)])
        [_textView setString:str];
    else if ([_textView respondsToSelector:@selector(setStringValue:)])
        [_textView setStringValue:str];
}


#pragma mark --- text delegate ---

- (void)_takeStringFromTextObj:(id)obj
{
    NSString *str = nil;
    
    if ([obj respondsToSelector:@selector(string)]) {
        str = [obj string];
    } else if ([obj respondsToSelector:@selector(stringValue)]) {
        str = [obj stringValue];
    }
    
    [_str autorelease];
    _str = (str) ? [str copy] : [@"" retain];
}

- (void)textDidChange:(NSNotification *)notif
{
    //if (_isMultiline)
    //    return; // disabled for multiline text
    
    id textObj = [notif object];
    
    [self _takeStringFromTextObj:textObj];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)])
        [_delegate valuesDidChangeInViewController:self context:@"Text::didChange" info:nil];
    else 
        [_delegate valuesDidChangeInViewController:self];
}

- (void)textDidEndEditing:(NSNotification *)notif
{
    id textObj = [notif object];

    [self _takeStringFromTextObj:textObj];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)])
        [_delegate valuesDidChangeInViewController:self context:@"Text::didEndEditing" info:nil];
    else 
        [_delegate valuesDidChangeInViewController:self];
}

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
    id textObj = [notif object];
    
    [self _takeStringFromTextObj:textObj];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)])
        [_delegate valuesDidChangeInViewController:self context:@"Text::didEndEditing" info:nil];
    else
        [_delegate valuesDidChangeInViewController:self];
}


#pragma mark --- actions ---

- (void)openTextEditorAction:(id)sender
{
    ///NSLog(@"%s: %@", __func__, theEdit);
}

- (void)applyTextChangesAction:(id)sender
{
    [self _takeStringFromTextObj:_textView];

    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)])
        [_delegate valuesDidChangeInViewController:self context:@"Text::saveChangesAction" info:nil];
    else 
        [_delegate valuesDidChangeInViewController:self];
}

- (void)singleLineTextParamAction:(id)sender
{
    [self textDidChange:[NSNotification notificationWithName:NSTextDidChangeNotification object:sender]];
}


#pragma mark --- view creation ---

- (void)loadView
{
    if (_textView) return;

    id val = nil;
    BOOL isMultiline = _isMultiline;
    BOOL hasLabel = [[self label] length] > 0;
    double textHeight = (isMultiline) ? 180.0 : 18.0;
    
    double defaultW = 300;
    double x =       ((val = [_styleDict objectForKey:kLQGStyle_PaddingLeft])) ? [val doubleValue] : 8.0;
    double rMargin = ((val = [_styleDict objectForKey:kLQGStyle_PaddingRight])) ? [val doubleValue] : 8.0;
    double y =       ((val = [_styleDict objectForKey:kLQGStyle_MarginTop])) ? [val doubleValue] : 8.0;
    double w = round(defaultW - x - rMargin);
    double labelH = 12.0;
    NSSize labelSize = NSMakeSize(60, labelH);


    NSRect viewRect = NSMakeRect(0, 0, defaultW, textHeight + (hasLabel ? 26 : 12));

    [_view autorelease];
    _view = [[(hasLabel ? [LQFlippedView class] : [NSView class]) alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];


    if (hasLabel) {
        NSAttributedString *attrLabel = [[[NSAttributedString alloc] initWithString:[self label] attributes:[self labelAttributes]] autorelease];
        
        NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(x,  y-1.0,
                                                                               labelSize.width+4.0,  labelH)];
        [nameField setEditable:NO];
        [nameField setStringValue:(NSString *)attrLabel];
        [nameField setAlignment:NSLeftTextAlignment];
        [nameField setBezeled:NO];
        [nameField setDrawsBackground:NO];
        [nameField setAutoresizingMask:(NSViewMinYMargin | NSViewMaxXMargin)];
        
        [_view addSubview:[nameField autorelease]];
        
        _labelField = nameField;
        y += labelH + 4;
    } else {
        _labelField = nil;
    }
    
    
    NSString *defaultText = (_str) ? _str : @"";
    NSRect textRect = NSMakeRect(x, y, w, textHeight);
    
    const double scrollbarW = 16.0;  // HARDCODED
    
    id textView = [[(isMultiline ? [NSTextView class] : (_isSecure ? [NSSecureTextField class] : [NSTextField class])) alloc]
                   initWithFrame:(isMultiline) ? NSMakeRect(0, 0, textRect.size.width - scrollbarW, textRect.size.height) : textRect];
    
    if (isMultiline) {
        if ([textView respondsToSelector:@selector(setRichText:)])
            [textView setRichText:NO];
        if ([textView respondsToSelector:@selector(setAutomaticQuoteSubstitutionEnabled:)])
            [textView setAutomaticQuoteSubstitutionEnabled:NO];
    }
    
    /*NSFont *mlFont;
     mlFont = [NSFont fontWithName:@"Lucida Sans Typewriter" size:9.0]; //[NSFont fontWithName:@"Monaco" size:9.0];
     if ( !mlFont) {
     mlFont = [NSFont userFixedPitchFontOfSize:9.0];
     }*/
    
    NSFont *monofont = [NSFont userFixedPitchFontOfSize:10.0]; //[NSFont fontWithName:@"Menlo" size:10.0];
    if ( !monofont)
        monofont = [NSFont fontWithName:@"Lucida Sans Typewriter" size:10.0];;
    if ( !monofont)
        monofont = [NSFont userFixedPitchFontOfSize:10.0];
    
    
    [textView setFont:(isMultiline) ? monofont : [NSFont systemFontOfSize:10.0]];

    LQInterfaceTint tint = [LQSegmentedControl defaultInterfaceTint];
    NSColor *bgC = nil;
    switch (tint) {
        case kLQDarkTint:
            bgC = [NSColor colorWithDeviceRed:0.91 green:0.91 blue:0.91 alpha:1.0];
            break;
        case kLQSemiDarkTint:
            bgC = [NSColor colorWithDeviceRed:0.93 green:0.93 blue:0.93 alpha:1.0];
            break;
        default:
            bgC = [NSColor whiteColor];
            break;
    }
    
    [textView setBackgroundColor:bgC];
    
    if ([textView respondsToSelector:@selector(setTag:)])
        [textView setTag:TAG_PARAMTEXTVIEW];
    
    [textView setDelegate:(id)self];
    
    if ([textView respondsToSelector:@selector(setTarget:)]) {
        [textView setTarget:self];
        [textView setAction:@selector(singleLineTextParamAction:)];
    }
    
    if ([textView respondsToSelector:@selector(setDefaultParagraphStyle:)]) {
        NSMutableParagraphStyle *pstyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [pstyle setDefaultTabInterval:4.0];
        
#if !defined(__COCOTRON__)
        [textView setDefaultParagraphStyle:pstyle];
#endif
    }
    
    [(NSView *)textView setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable)];
    
    _textView = textView;
    
    [self setStringValue:defaultText];
    
    
    NSView *packedTextBox = textView;
    
    // pack into scrollview if multiline
    if (isMultiline) {
        BOOL wantsApplyButton = _hasApplyButton; // TODO   ([param textParameterFlags] & PixMathTextParameterHasApplyButton) ? YES : NO;
        BOOL wantsOpenEditorButton = NO;
        NSRect scrollFrame = textRect;
        NSButton *button;
        
        if (wantsApplyButton) {
            const double buttonH = 22;
            scrollFrame.origin.y += buttonH;
            scrollFrame.size.height -= buttonH;
            
            button = [[NSButton alloc] initWithFrame:NSMakeRect(textRect.origin.x, textRect.origin.y, 90, 18)];
            [button setTitle:@"Save Changes"];
            [button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
            [button setBezelStyle:NSRoundedBezelStyle];
            [[button cell] setControlSize:NSMiniControlSize];
            [button setTarget:self];
            [button setAction:@selector(applyTextChangesAction:)];
            [button setTag:710];
            [_view addSubview:[button autorelease]];
        }
        if (wantsOpenEditorButton) {
            button = [[NSButton alloc] initWithFrame:NSMakeRect(textRect.origin.x + 100, textRect.origin.y, 90, 18)];
            [button setTitle:@"Open Editor..."];
            [button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
            [button setBezelStyle:NSRoundedBezelStyle];
            [[button cell] setControlSize:NSMiniControlSize];
            [button setTarget:self];
            [button setAction:@selector(openTextEditorAction:)];
            [button setTag:720];
            [_view addSubview:[button autorelease]];
        }
        
        [textView setAllowsUndo:YES];

#if !defined(__COCOTRON__)
        NSMutableParagraphStyle *pstyle = [[[textView defaultParagraphStyle] mutableCopy] autorelease];
        pstyle.minimumLineHeight = 13.0;
        [textView setDefaultParagraphStyle:pstyle];
#endif
        
        [textView setHorizontallyResizable:YES];
        //[[textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
        //[[textView textContainer] setWidthTracksTextView:NO];
        
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:scrollFrame];
        [scrollView setHasHorizontalScroller:YES];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setDocumentView:[textView autorelease]];
        [scrollView setAutoresizingMask:(NSViewMinYMargin | NSViewWidthSizable | NSViewHeightSizable)];
        
#if !defined(__COCOTRON__)
        [[scrollView verticalScroller] setControlSize:NSSmallControlSize];
        [[scrollView horizontalScroller] setControlSize:NSSmallControlSize];
#endif
        
        packedTextBox = scrollView;
    }

    [_view addSubview:[packedTextBox autorelease]];
}


- (void)attachScriptEditorWithClass:(Class)cls interpreter:(id)interpreter
{
    if ( !_textView) {
        NSLog(@"** %s: view is not loaded yet", __func__);
        return;
    }
    [_editor release];
    
#if defined(__APPLE__)
    _editor = [[cls alloc] initWithInterpreter:interpreter textView:_textView];
#endif
}

@end
