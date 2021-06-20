//
//  LQGListItemWrapperController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 17.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListItemWrapperController_lagoon.h"


static void buttonClicked(GtkButton *button, gpointer controller)
{
    NSInteger tag = 0;
    const char *label = gtk_button_get_label( GTK_BUTTON(button) );
    if (label) {
        tag = (0 == strcmp(label, "+")) ? 1 : 0;
    }
    
    [(id)controller _buttonClickedWithTag:tag];
}


@implementation LQGListItemWrapperController_lagoon

- (void)dealloc
{
    [_containedCtrl release];
    
    [_hboxWidget release];
    
    [super dealloc];
}


- (void)setContainedViewController:(LQGCommonUIController *)viewCtrl
{
    [_containedCtrl autorelease];
    _containedCtrl = [viewCtrl retain];
}

- (LQGCommonUIController *)containedViewController {
    return _containedCtrl; }

- (void)_buttonClickedWithTag:(NSInteger)tag
{
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)]) {
        [_delegate actionInViewController:self context:(tag == 1) ? kLQGActionContext_AddButtonClicked : kLQGActionContext_DeleteButtonClicked info:nil];
    }
}



- (void)loadView
{
    if (_hboxWidget) return;

    const int padding = 12;
    GtkWidget *hbox = gtk_hbox_new (FALSE, padding);

    _hboxWidget = [[LGNativeWidget alloc] initWithGtkWidget:hbox];
    
    {
        GtkWidget *button = gtk_button_new_with_label("+");

        g_signal_connect( G_OBJECT(button), "clicked", G_CALLBACK(buttonClicked), (gpointer)self);
	                  
        gtk_widget_show(button);
        gtk_box_pack_end (GTK_BOX(hbox), button, FALSE, FALSE, 0);
        
        _addButton = button;
    }
    {
        GtkWidget *button = gtk_button_new_with_label("-");

        g_signal_connect( G_OBJECT(button), "clicked", G_CALLBACK(buttonClicked), (gpointer)self);
	                  
        gtk_widget_show(button);
        gtk_box_pack_end (GTK_BOX(hbox), button, FALSE, FALSE, 0);
        
        _delButton = button;
    }
}

- (id)nativeView {
    return _hboxWidget;
}

- (void)setNativeView:(id)view {
    [NSException raise:NSGenericException format:@"%s shouldn't be called (%p)", __func__, self];
}

@end
