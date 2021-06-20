//
//  LQGButtonWithDetailController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGButtonWithDetailController_lagoon.h"

static void buttonClicked(GtkButton *button, gpointer controller)
{
    [(id)controller _buttonClicked];
}


@implementation LQGButtonWithDetailController_lagoon

- (void)dealloc
{
    [_hboxWidget release];
    _hboxWidget = nil;

    [_label release];
    
    [super dealloc];
}

- (NSString *)detailString {
    return @""; }
    
- (void)setDetailString:(NSString *)str
{
    // TODO
}

- (NSString *)buttonLabel {
    return _label;
}

- (void)setButtonLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    if (_buttonWidget) {
        gtk_button_set_label( GTK_BUTTON(_buttonWidget), [_label UTF8String] );
    }
}


- (void)_buttonClicked
{
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:kLQGActionContext_ButtonClicked info:nil];
}


- (void)loadView
{
    if (_hboxWidget) return;

    const int padding = 12;
    GtkWidget *hbox = gtk_hbox_new (FALSE, padding);

    _hboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:hbox];
    
    {
        GtkWidget *button = gtk_button_new_with_label( ([_label length] > 0) ? [_label UTF8String] : "Choose file..." );

        g_signal_connect( G_OBJECT(button), "clicked", G_CALLBACK(buttonClicked), (gpointer)self);
	                  
        gtk_widget_show(button);
        gtk_box_pack_start (GTK_BOX(hbox), button, FALSE, FALSE, 0);
        
        _buttonWidget = button;
    }
}

- (id)nativeView {
    return _hboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}

@end
