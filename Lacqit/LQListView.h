//
//  LQListView.h
//  PixelMath
//
//  Created by Pauli Ojala on 2.4.2007.
//  Copyright 2007 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQListView : NSView {

	NSMutableArray			*_items;
	NSMutableArray			*_itemVis;
    
    id _delegate;
    LXInteger _selectedIndex;
    
    BOOL _drawsHorizLines;
}

- (void)setDelegate:(id)del;
- (id)delegate;

- (void)addItem:(NSView *)item;
- (void)insertItem:(NSView *)item atIndex:(LXInteger)index;
- (void)removeItemAtIndex:(LXInteger)index;

- (LXInteger)numberOfItems;
- (NSView *)itemAtIndex:(LXInteger)index;

- (void)setVisible:(BOOL)f forItem:(NSView *)item;
- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index;
- (BOOL)isVisibleForItem:(NSView *)item;

- (void)setDrawsHorizontalLines:(BOOL)f;
- (BOOL)drawsHorizontalLines;

- (void)repackSubviews;

- (void)setSelectedIndex:(LXInteger)index;
- (LXInteger)selectedIndex;

@end


@interface NSObject (LQListViewDelegate)

- (void)listView:(LQListView *)view itemClickedAtIndex:(LXInteger)index;

@end
