//
//  LQGSelectorButtonController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGSelectorButtonController_lagoon.h"


static void comboBoxChanged(GtkComboBox *comboBox, gpointer controller)
{
	NSInteger v = gtk_combo_box_get_active(comboBox);
    
    [(id)controller _newSelectionForComboBox:v];
}


@implementation LQGSelectorButtonController_lagoon

- (void)dealloc
{
    [_hboxWidget release];
    _hboxWidget = nil;

    [_label release];
    [_items release];
    [super dealloc];
}


- (NSString *)label {
    return _label;
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    if (_labelWidget) {
        gtk_label_set_label( GTK_LABEL(_labelWidget), [_label UTF8String] );
    }
}

- (void)_recreateComboBox
{
    if (_comboBox) {
        gtk_widget_destroy(_comboBox);
        _comboBox = NULL;
    }

    GtkWidget *comboBox = gtk_combo_box_new_text();

    NSEnumerator *itemEnum = [_items objectEnumerator];
    NSString *item;
    while (item = [itemEnum nextObject]) {
        gtk_combo_box_append_text( GTK_COMBO_BOX(comboBox), [item UTF8String] );
    }
    
    gtk_combo_box_set_active( GTK_COMBO_BOX(comboBox), _selIndex );

    //gtk_widget_set_size_request(comboBox, 100, 20);
        
    g_signal_connect( G_OBJECT(comboBox), "changed", G_CALLBACK(comboBoxChanged), (gpointer)self);

    gtk_widget_show(comboBox);
    gtk_box_pack_start( GTK_BOX([_hboxWidget gtkWidget]), comboBox, FALSE, FALSE, 0);

    _comboBox = comboBox;
}

- (void)setItemTitles:(NSArray *)items
{
    [_items release];
    _items = [items copy];
    
    [self _recreateComboBox];
}

- (NSArray *)itemTitles {
    return _items; }
    

- (void)setIndexOfSelectedItem:(LXInteger)index
{
    _selIndex = index;
    
    if (_comboBox)
        gtk_combo_box_set_active( GTK_COMBO_BOX(_comboBox), _selIndex);
}

- (LXInteger)indexOfSelectedItem {
    return _selIndex; }
    
- (NSString *)titleOfSelectedItem {
    return [_items objectAtIndex:_selIndex];
}


- (double)doubleValue {
    return _selIndex; }
    
- (void)setDoubleValue:(double)f {
    LXInteger index = lround(f);
    
    if (index >= 0 && index < [_items count]) {
        [self setIndexOfSelectedItem:index];
    }
}


- (void)_newSelectionForComboBox:(NSInteger)v
{
    _selIndex = v;
    
    [_delegate valuesDidChangeInViewController:self];
}


- (void)loadView
{
    if (_hboxWidget) return;

    const int padding = 12;
    GtkWidget *hbox = gtk_hbox_new (FALSE, padding);

    _hboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:hbox];
    
    {
        GtkWidget *label = gtk_label_new (_label ? [_label UTF8String] : NULL);
        
        gtk_widget_show (label);
        gtk_box_pack_start (GTK_BOX(hbox), label, FALSE, FALSE, 0);
        
        _labelWidget = label;
    }
    
    [self _recreateComboBox];
}

- (id)nativeView {
    return _hboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}


@end
