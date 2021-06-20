//
//  LQGListController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListController_lagoon.h"
#import <Lagoon/LGNativeWidget.h>


@implementation LQGListController_lagoon

- (id)init
{
    self = [super init];

    GtkWidget *vbox = gtk_vbox_new (FALSE, 0);
    
    gtk_widget_show (vbox);
    
    _listWidget = [[LGNativeWidget alloc] initWithGtkWidget:vbox];

/*
    LGNativeWidget *scrollWidget = [LGNativeWidget scrollWindowWidgetForWidget:_listWidget
                                        hasHorizontalScroller:NO
                                        hasVerticalScroller:YES];

    _scrollWidget = [scrollWidget retain];
*/
    return self;
}

- (void)dealloc
{
    gtk_container_remove (GTK_CONTAINER([_container gtkWidget]), [_scrollWidget gtkWidget]);
    _container = nil;

    [_listWidget release];
    _listWidget = nil;

    [_scrollWidget release];
    _scrollWidget = nil;
    
    [super dealloc];
}

- (void)loadView {
    // view is already created in -init
}


- (void)addViewController:(LQGViewController *)viewCtrl
{
    @try {
        [super addViewController:viewCtrl];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    GtkWidget *vbox = [_listWidget gtkWidget];
    
    GtkWidget *itemWidget = [(LGNativeWidget *)[viewCtrl nativeView] gtkWidget];
    gtk_widget_show (GTK_WIDGET(itemWidget));
    
    gtk_box_pack_start (GTK_BOX(vbox), itemWidget,  FALSE, TRUE, 0);
}


- (void)setVisible:(BOOL)f forViewController:(LQGViewController *)viewCtrl
{
    // TODO
}

- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index
{
    // TODO
}

- (void)repack
{
    // TODO
}


- (id)nativeContainer {
    return _container; }
    
- (void)setNativeContainer:(id)cnt
{
    if (cnt != _container) {        
        GtkWidget *wid = (_scrollWidget) ? [_scrollWidget gtkWidget] : [_listWidget gtkWidget];

        // remove from previous container
        GtkWidget *superwidget = [_container gtkWidget];
        gtk_container_remove (GTK_CONTAINER(superwidget), wid);
        superwidget = NULL;
    
        _container = cnt;

        if (_container) {
            NSAssert1([_container isKindOfClass:[LGNativeWidget class]], @"invalid container (%@)", _container);
            
            superwidget = [_container gtkWidget];
            gtk_container_add (GTK_CONTAINER(superwidget), wid);
        }
    }
}
    
- (id)nativeView {
    return _listWidget; //_scrollWidget;
}


@end
