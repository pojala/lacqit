//
//  LQGViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LacqitExport.h"
#import "LQUIConstants.h"

/*
A view controller that manages a native view: on Mac this means an NSView, on Lagoon this means an LGNativeWidget.

This is an abstract superclass: concrete subclasses provide platform-specific implementation.

On Mac, implementations can piggyback on LQGCocoaViewController to load nibs.
On Lagoon, it would be nice to provide a GtkBuilder loader.
*/


// style attributes
LACQIT_EXPORT_VAR NSString * const kLQGStyle_Font;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_ForegroundColor;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_PaddingTop;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_PaddingLeft;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_PaddingRight;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_PaddingBottom;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_MarginLeft;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_MarginRight;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_MarginTop;
LACQIT_EXPORT_VAR NSString * const kLQGStyle_MarginBottom;


@interface LQGViewController : NSObject {

    IBOutlet NSView *_view;  // provided here in base class so IB finds it
    NSArray *_nibObjects;
        
    NSString *_resName;
    NSBundle *_resBundle;

    id _repObj;
    id _delegate;
    id _enclosingVC;
    
    NSString *_name;
    NSString *_title;
    
    void *__res1;
    void *__res2;
}

// on Mac, the resource name is a nib name; on Lagoon it is probably empty (views are usually created programmatically)
- (id)initWithResourceName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

// views are not necessarily instantiated when the controller is inited, so this must be always called before using the view
- (void)loadView;

- (NSString *)resourceName;
- (NSBundle *)resourceBundle;

- (id)representedObject;
- (void)setRepresentedObject:(id)representedObject;  // is retained

- (NSString *)name;
- (void)setName:(NSString *)name;  // never user-visible

- (NSString *)title;
- (void)setTitle:(NSString *)title;  // can be shown in e.g. tabview's tabs

- (id)delegate;
- (void)setDelegate:(id)del;

- (id)enclosingViewController;

- (id)findEnclosingViewControllerWithNameContainingSubstring:(NSString *)substr;

// on Mac this is always an NSView; on Lagoon it's usually an LGNativeWidget
- (id)nativeView;
- (void)setNativeView:(id)view;

// implementation-specific display attributes (e.g. for a Cocoa view that needs to be placed at an offset within its container)
- (id)nativeStyleAttributes;

@end


@interface NSObject (LQGViewControllerDelegate)

// this message is _not_ sent by default.
// view controller subclasses may send it to the delegate as a convenience for implementing target/action.
- (void)valuesDidChangeInViewController:(LQGViewController *)viewCtrl;

// allows for more fine-grained control over complex view controllers (not sent by all classes)
- (void)valuesDidChangeInViewController:(LQGViewController *)viewCtrl context:(NSString *)context info:(NSDictionary *)info;

// action can be click on a button or something else
- (void)actionInViewController:(LQGViewController *)viewCtrl context:(NSString *)context info:(NSDictionary *)info;

@end
