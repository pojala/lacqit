//
//  LQGSelectorButtonController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGSelectorButtonController_lagoon : LQGCommonUIController {

    LGNativeWidget *_hboxWidget;

    GtkWidget *_labelWidget;
    GtkWidget *_comboBox;

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


- (void)_newSelectionForComboBox:(NSInteger)v;

@end
