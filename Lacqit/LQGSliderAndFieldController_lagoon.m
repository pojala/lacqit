//
//  LQGSliderAndFieldController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGSliderAndFieldController_lagoon.h"
#import <Lagoon/LGNativeWidget.h>
#import <Lagoon/LGWindow.h>
#import "LQNumberScrubField.h"


static void sliderValueChanged(GtkRange *range, gpointer controller)
{
    double v = gtk_range_get_value(range);
    ///NSString *name = [NSString stringWithCString:gtk_widget_get_name(GTK_WIDGET(range)) ];

    ///NSLog(@"%@: %f", name, v);

    [(id)controller _newDoubleValueForSlider:v];    
}


@implementation LQGSliderAndFieldController_lagoon

- (void)dealloc
{
    [_hboxWidget release];
    _hboxWidget = nil;

    [_lgWindow release];
    _lgWindow = nil;
    
    [super dealloc];
}


- (void)scrubFieldChangedAction:(id)sender
{
    double v = [sender doubleValue];
    
    gtk_range_set_value (GTK_RANGE(_slider), v);
    
    [_delegate valuesDidChangeInViewController:self];
}

- (void)_newDoubleValueForSlider:(double)v
{
    [_scrubField setDoubleValue:v];
    [_scrubField setNeedsDisplay:YES];
    
    [_delegate valuesDidChangeInViewController:self];
}


- (double)doubleValue {
    return (_scrubField) ? [_scrubField doubleValue] : 0.0;
}

- (void)setDoubleValue:(double)v
{
    [_scrubField setDoubleValue:v];
    
    gtk_range_set_value (GTK_RANGE(_slider), v);
}

- (void)setSliderMin:(double)smin max:(double)smax
{
    gtk_range_set_range (GTK_RANGE(_slider), smin, smax);
}

- (void)setEnabled:(BOOL)f
{
    if ([_scrubField respondsToSelector:@selector(setEnabled:)])
        [(id)_scrubField setEnabled:f];
    
    gtk_widget_set_sensitive (GTK_WIDGET(_slider), f);
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


- (void)loadView
{
    if (_hboxWidget) return;

    const int padding = 12;
    GtkWidget *hbox = gtk_hbox_new (FALSE, padding);

    _hboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:hbox];
    
    {
        GtkWidget *label = gtk_label_new ("Slider");
        
        gtk_widget_show (label);
        gtk_box_pack_start (GTK_BOX(hbox), label, FALSE, FALSE, 0);
        
        _label = label;
    }
    
    const double v = 0.5;
    
    {
        double min = 0.0;
        double max = 1.0;
        double increment = (max - min) / 20.0;    
        GtkWidget *slider = gtk_hscale_new_with_range (min, max, increment);

        gtk_scale_set_value_pos (GTK_SCALE(slider), GTK_POS_RIGHT);
        gtk_scale_set_draw_value (GTK_SCALE(slider), FALSE);
                    
        gtk_widget_set_name (slider, "(slider)");
        gtk_range_set_value (GTK_RANGE(slider), v);
     
        g_signal_connect( G_OBJECT(slider), "value-changed", G_CALLBACK(sliderValueChanged), (gpointer)self);
        
        gtk_widget_show (slider);
        gtk_box_pack_start (GTK_BOX(hbox), slider, TRUE, TRUE, 0);
        
        _slider = slider;
    }

    {
        int fieldW = 64, fieldH = 20;
        GtkWidget *layout = gtk_layout_new(NULL, NULL);
        gtk_widget_set_size_request(layout, fieldW, fieldH);
        

        LGWindow *lgWindow = [[LGWindow alloc] initWithGtkWidget:layout];
        
        LQNumberScrubField *scrubField = [[LQNumberScrubField alloc] initWithFrame:NSMakeRect(0, 0, fieldW, fieldH)];
        [scrubField setDoubleValue:v];
        //[scrubField setTag:i];
        [scrubField setTarget:self];
        [scrubField setAction:@selector(scrubFieldChangedAction:)];
        
        [[lgWindow contentView] addSubview:[scrubField autorelease]];    


        gtk_widget_show(layout);
        gtk_box_pack_start( GTK_BOX(hbox), layout, FALSE, FALSE, 0);
        
        _scrubField = scrubField;
        _lgWindow = lgWindow;
    }
}

- (id)nativeView {
    return _hboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}


@end
