//
//  LQGSelectorButtonController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGSelectorButtonController_cocoa : LQGCommonUIController {

    // owned by view
    NSTextField *_labelField;
    NSPopUpButton *_popUpButton;
    
    // owned by self
    NSString *_label;
    NSArray *_items;
    
    LXInteger _selIndex;
}

- (void)setItemTitles:(NSArray *)items;
- (NSArray *)itemTitles;

- (void)setIndexOfSelectedItem:(LXInteger)index;
- (LXInteger)indexOfSelectedItem;

- (NSString *)titleOfSelectedItem;

@end
