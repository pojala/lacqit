//
//  LQGTextBoxController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 17.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTextBoxController_lagoon.h"


static void textViewChanged(GtkTextView *textView, gpointer controller)
{
    GtkTextBuffer *textBuffer = gtk_text_view_get_buffer( GTK_TEXT_VIEW(textView) );
    
    GtkTextIter startIter;
    GtkTextIter endIter;
    gtk_text_buffer_get_start_iter(textBuffer, &startIter);
    gtk_text_buffer_get_end_iter(textBuffer, &endIter);
    
    char *textUTF8 = gtk_text_buffer_get_text(textBuffer, &startIter, &endIter, NO);

    NSString *str = (textUTF8) ? [NSString stringWithUTF8String:textUTF8] : nil;
    
    g_free(textUTF8);
                                    
    [(id)controller _newStringValueForTextView:str];
}


@implementation LQGTextBoxController_lagoon

- (void)dealloc
{
    [_vboxWidget release];
    _vboxWidget = nil;

    [_str release];
    _str = nil;

    [super dealloc];
}


- (NSString *)stringValue {
    return _str; }
    
- (void)setStringValue:(NSString *)str
{
    [_str autorelease];
    _str = [str copy];
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag; }

- (BOOL)isMultiline {
    return _isMultiline; }

- (void)setMultiline:(BOOL)f {
    _isMultiline = f; }
    
- (BOOL)hasSaveAndRevert {
    return _hasApplyButton; }
    
- (void)setHasSaveAndRevert:(BOOL)f {
    _hasApplyButton = f; }


- (void)_newStringValueForTextView:(NSString *)str
{
    [_str autorelease];
    _str = [str retain];
    
    if ([_delegate respondsToSelector:@selector(valuesDidChangeInViewController:context:info:)])
        [_delegate valuesDidChangeInViewController:self context:@"Text::didChange" info:nil];
    else 
        [_delegate valuesDidChangeInViewController:self];    
}

- (void)loadView
{
    if (_vboxWidget) return;

    const int padding = 12;
    GtkWidget *vbox = gtk_vbox_new (FALSE, padding);

    _vboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:vbox];
    
    {
        GtkWidget *textView = gtk_text_view_new();
        
        if (_str) {
            GtkTextBuffer *textBuffer = gtk_text_view_get_buffer( GTK_TEXT_VIEW(textView) );
        
            gtk_text_buffer_set_text( GTK_TEXT_BUFFER(textBuffer), [_str UTF8String], -1);
        }
        
        
        g_signal_connect( G_OBJECT(textView), "changed", G_CALLBACK(textViewChanged), (gpointer)self);
	                  
        gtk_widget_show(textView);
        gtk_box_pack_start (GTK_BOX(vbox), textView, FALSE, FALSE, 0);
        
        _textViewWidget = textView;
    }

}


- (id)nativeView {
    return _vboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}

@end
