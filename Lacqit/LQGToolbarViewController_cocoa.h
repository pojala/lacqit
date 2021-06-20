//
//  LQGToolbarViewController.h
//  Lacqit
//
//  Created by Pauli Ojala on 29.12.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGToolbarViewController_cocoa : LQGCommonUIController {

    NSMutableArray *_buttonViews;
    
    NSArray *_toolInfoDicts;
    
    LXInteger _selItem;
}

- (id)init;

- (NSArray *)toolbarItems;
- (void)setToolbarItems:(NSArray *)itemDicts;

- (LXInteger)indexOfSelectedItem;
- (NSString *)identifierOfSelectedItem;

- (void)setIndexOfSelectedItem:(LXInteger)index;
- (void)selectItemWithIdentifier:(NSString *)item;


- (NSArray *)buttonViews;

- (void)toolbarButtonAction:(id)sender;

@end
