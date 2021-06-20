//
//  LQGUIButton.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIControl.h"


@interface LQGUIButton : LQGUIControl {

}

+ (id)pushButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context  // this can be used to get special views for different UI contexts (e.g. floater windows)
                      target:(id)target
                      action:(SEL)action;                        

+ (id)symbolButtonWithLabel:(NSString *)str    // useful for +/- buttons
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action;
                      
+ (id)checkboxWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action;

// this is a segmented-style button with a down-pointing arrow to indicate that is has a menu.
// the menu can be nil and set later using -setMenu:
+ (id)menuButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                        menu:(NSMenu *)menu;

// a segmented-style button intended for opening a custom menu (e.g. the Conduit favorites "mega dropdown")
+ (id)menuButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action;


- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;

- (void)setLabel:(NSString *)label;
- (NSString *)label;

@end
