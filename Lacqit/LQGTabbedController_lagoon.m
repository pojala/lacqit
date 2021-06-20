//
//  LQGTabbedController_lagoon.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTabbedController_lagoon.h"
#import "LQGViewController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGTabbedController (PrivateToSubclasses)
- (id)initWithNativeContainer:(id)container;
@end


@implementation LQGTabbedController_lagoon

- (id)initWithNativeContainer:(id)container
{
    self = [super initWithNativeContainer:container];

    _container = (LGNativeWidget *)container;

    GtkWidget *notebook = gtk_notebook_new();
    _tabView = [[LGNativeWidget alloc] initWithGtkWidget:notebook];

    gtk_widget_show (notebook);

    if (container) {
        NSAssert1([container isKindOfClass:[LGNativeWidget class]], @"invalid container (%@)", container);

        GtkWidget *superwidget = [_container gtkWidget];
        gtk_container_add (GTK_CONTAINER(superwidget), [_tabView gtkWidget]);
    }
    
    return self;
}

- (void)dealloc
{
    gtk_container_remove (GTK_CONTAINER([_container gtkWidget]), [_tabView gtkWidget]);
    _container = nil;
        
    [_tabView release];
    _tabView = nil;
    
    [super dealloc];
}


- (void)selectTabAtIndex:(LXInteger)index
{
    @try {
        [super selectTabAtIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    GtkWidget *notebook = [_tabView gtkWidget];
    
    gtk_notebook_set_current_page (GTK_NOTEBOOK(notebook), index);
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
    
    GtkWidget *notebook = [_tabView gtkWidget];
    
    GtkWidget *pageWidget = [[viewCtrl nativeView] gtkWidget];
    gtk_widget_show (GTK_WIDGET(pageWidget));


    GtkWidget *scroll = gtk_scrolled_window_new (NULL, NULL);    
    
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW(scroll),
                                    (NO) ? GTK_POLICY_AUTOMATIC : GTK_POLICY_NEVER,
                                    (YES) ? GTK_POLICY_ALWAYS : GTK_POLICY_NEVER);
                                    
    gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW(scroll), pageWidget);

    gtk_scrolled_window_set_shadow_type (GTK_SCROLLED_WINDOW(scroll), GTK_SHADOW_NONE);
    gtk_widget_show (scroll);

    GtkWidget *viewport = gtk_bin_get_child (GTK_BIN(scroll));
    gtk_viewport_set_shadow_type (GTK_VIEWPORT(viewport), GTK_SHADOW_NONE);


    GtkWidget *labelWidget = gtk_label_new ([[viewCtrl title] UTF8String]);
    
    //GtkWidget *testWidget = gtk_label_new ("testi testi ämyri");
    //gtk_widget_show(testWidget);
    
    gtk_notebook_append_page (GTK_NOTEBOOK(notebook),
                              scroll,
                              labelWidget);
}

- (void)removeViewControllerAtIndex:(LXInteger)index
{
    @try {
        [super removeViewControllerAtIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    GtkWidget *notebook = [_tabView gtkWidget];
    
    gtk_notebook_remove_page (GTK_NOTEBOOK(notebook), index);
}

- (void)insertViewController:(LQGViewController *)viewCtrl atIndex:(LXInteger)index
{
    if (index == [_viewControllers count]) {
        [self addViewController:viewCtrl];
        return;
    }

    @try {
        [super insertViewController:viewCtrl atIndex:index];
    }
    @catch (id exception) {
        NSLog(@"** %s: failed (%@)", __func__, exception);
        return;
    }
    
    GtkWidget *notebook = [_tabView gtkWidget];
    
    GtkWidget *pageWidget = [[viewCtrl nativeView] gtkWidget];
    gtk_widget_show (GTK_WIDGET(pageWidget));


    GtkWidget *scroll = gtk_scrolled_window_new (NULL, NULL);    
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW(scroll),
                                    (NO) ? GTK_POLICY_AUTOMATIC : GTK_POLICY_NEVER,
                                    (YES) ? GTK_POLICY_ALWAYS : GTK_POLICY_NEVER);
                                    
    gtk_scrolled_window_add_with_viewport (GTK_SCROLLED_WINDOW(scroll), pageWidget);
    gtk_widget_show (scroll);
    
    NSLog(@"scrolled");
    
    GtkWidget *labelWidget = gtk_label_new ([[viewCtrl title] UTF8String]);
    
    gtk_notebook_insert_page (GTK_NOTEBOOK(notebook),
                              scroll, //pageWidget,
                              labelWidget,
                              index);

}


- (id)nativeContainer {
    return _container; }
    
- (void)setNativeContainer:(id)cnt
{
    if (cnt != _container) {        
        GtkWidget *notebook = [_tabView gtkWidget];

        // remove from previous container
        GtkWidget *superwidget = [_container gtkWidget];
        gtk_container_remove (GTK_CONTAINER(superwidget), notebook);
        superwidget = NULL;
    
        _container = cnt;

        if (_container) {
            NSAssert1([_container isKindOfClass:[LGNativeWidget class]], @"invalid container (%@)", _container);
            
            superwidget = [_container gtkWidget];
            gtk_container_add (GTK_CONTAINER(superwidget), notebook);
        }
    }
}

- (id)nativeView {
    return _tabView; }
    

@end
