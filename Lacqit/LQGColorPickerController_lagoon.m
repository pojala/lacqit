//
//  LQGColorPickerController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGColorPickerController_lagoon.h"


#define COLORMAX 65535.0
    

static void colorValueChanged(GtkColorButton *widget, gpointer controller)
{
    GdkColor color = { 0, 0, 0 };
    gtk_color_button_get_color (GTK_COLOR_BUTTON(widget), &color);
    
    guint16 alpha = gtk_color_button_get_alpha (GTK_COLOR_BUTTON(widget));
    
    LXRGBA rgba;
    rgba.r = color.red / COLORMAX;
    rgba.g = color.green / COLORMAX;
    rgba.b = color.blue / COLORMAX;
    rgba.a = alpha / COLORMAX;
    
    [(id)controller _newRGBAValueForColorButton:rgba];
}


@implementation LQGColorPickerController_lagoon

- (void)dealloc
{
    [_hboxWidget release];
    _hboxWidget = nil;

    [super dealloc];
}


- (NSString *)label
{
    if (_label) {
        return [NSString stringWithUTF8String:gtk_label_get_text (GTK_LABEL(_label))];
    } else
        return @"";
}
    
- (void)setLabel:(NSString *)label
{
    if (_label) {
        gtk_label_set_text (GTK_LABEL(_label), [label UTF8String]);
    }
}

- (LXRGBA)rgbaValue {
    return _rgba;
}

- (void)setRGBAValue:(LXRGBA)rgba
{
    _rgba = rgba;
    
    if (_colorButton) {
        // TODO
    }
}


- (void)_newRGBAValueForColorButton:(LXRGBA)c
{
    ///NSLog(@"new color: %f, %f, %f, %f", c.r, c.g, c.b, c.a);

    _rgba = c;
    
    if (_delegate)
        [_delegate valuesDidChangeInViewController:self];
}


- (void)loadView
{
    if (_hboxWidget) return;

    const int padding = 12;
    GtkWidget *hbox = gtk_hbox_new (FALSE, padding);

    _hboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:hbox];
    
    {
        GtkWidget *label = gtk_label_new ("Color Picker");
        
        gtk_widget_show (label);
        gtk_box_pack_start (GTK_BOX(hbox), label, FALSE, FALSE, 0);
        
        _label = label;
    }
    
    {
        GtkWidget *colorButton = gtk_color_button_new();
        
        gtk_color_button_set_use_alpha (GTK_COLOR_BUTTON(colorButton), TRUE);
        
        g_signal_connect (G_OBJECT(colorButton), "color-set", G_CALLBACK(colorValueChanged), (gpointer)self);
        
        gtk_widget_show (colorButton);
        gtk_box_pack_start (GTK_BOX(hbox), colorButton, FALSE, FALSE, 0);
        
        _colorButton = colorButton;
    }
    
}


- (id)nativeView {
    return _hboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}

@end
