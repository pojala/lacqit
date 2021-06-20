//
//  LQGCheckboxController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCheckboxController_lagoon.h"


static void checkBoxToggled(GtkToggleButton *button, gpointer controller)
{
    BOOL f = gtk_toggle_button_get_active(button) ? YES : NO;
    ///NSString *name = [NSString stringWithCString:gtk_widget_get_name(GTK_WIDGET(range)) ];

    ///NSLog(@"%@: %f", name, v);

    [(id)controller _newBoolValueForCheckbox:f];
}


@implementation LQGCheckboxController_lagoon

- (void)dealloc
{
    [_checkboxWidget release];
    _checkboxWidget = nil;

    [_label release];
    _label = nil;

    [super dealloc];
}


- (NSString *)label {
    return _label;
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    if (_checkboxWidget) {
        gtk_button_set_label( GTK_BUTTON([_checkboxWidget gtkWidget]), [_label UTF8String] );
    }
}


- (BOOL)boolValue {
    return _boolValue; }
    
- (void)setBoolValue:(BOOL)f
{
    _boolValue = f;
    if (_checkboxWidget) {
        gtk_toggle_button_set_active( GTK_TOGGLE_BUTTON([_checkboxWidget gtkWidget]), _boolValue ? TRUE : FALSE );
    }
}

- (double)doubleValue {
    return (_boolValue) ? 1.0 : 0.0; }


- (void)_newBoolValueForCheckbox:(BOOL)f
{
    _boolValue = f;
    
    [_delegate valuesDidChangeInViewController:self];
}


- (void)loadView
{
    if (_checkboxWidget) return;

    NSString *label = [self label];

    GtkWidget *checkbox = gtk_check_button_new_with_label( (label) ? [label UTF8String] : NULL );

    if ([self title])
        gtk_widget_set_name(checkbox, [[self title] UTF8String]);
        
    gtk_toggle_button_set_active( GTK_TOGGLE_BUTTON(checkbox), _boolValue ? TRUE : FALSE );
                    
    g_signal_connect( G_OBJECT(checkbox), "toggled", G_CALLBACK(checkBoxToggled), (gpointer)self);

    _checkboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:checkbox];
}


- (id)nativeView {
    return _checkboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}

@end
