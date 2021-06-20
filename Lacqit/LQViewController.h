//
//  LQViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 27.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQGCocoaViewController.h"

/*
Modelled after NSViewController in OS X 10.5, but not directly compatible.
In particular I don't care about bindings/KVO.

2008.09.12 -- moved implementation to LQGViewController;
this class remains as a convenient NSViewController look-a-like
*/


@interface LQViewController : LQGCocoaViewController {

    /*IBOutlet NSView *_view;

    NSString *_nibName;
    NSBundle *_nibBundle;
    NSArray *_nibObjects;
    
    id _repObj;
    
    NSString *_title;*/
    
    ///LQGCocoaViewController *_viewCtrl;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;

- (NSString *)nibName;
- (NSBundle *)nibBundle;

// following are inherited from LQGCocoaViewController:
/*
- (void)loadView;

- (id)representedObject;
- (void)setRepresentedObject:(id)representedObject;  // is retained

- (NSString *)title;
- (void)setTitle:(NSString *)title;

- (NSView *)view;
- (void)setView:(NSView *)view;
*/
@end
