//
//  LQIconView.h
//  Lacqit
//
//  Created by Pauli Ojala on 18.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQIconView : NSView {

    IBOutlet id     _dataSource;

    LXInteger       _numCols, _numRows;
    BOOL            _autoRecalcsNumCols;
    
    double          _colW, _rowH;
    
    LXInteger       _itemCount;
    NSMutableArray  *_titles;
    NSMutableArray  *_icons;
    
    NSDictionary    *_titleAttribs;
    
    BOOL            _drawsBg;
	NSColor			*_bgColor;
    
    BOOL            _drawsIconBg;
    NSColor         *_iconBgColor;
    double          _iconBgRounding;
    NSShadow        *_iconShadow;
    
    LXInteger       _hiliteItem;
    
    // workaround for FCP drag&drop compatibility problem
    BOOL _usePrivatePasteboard;
    NSString *_privatePbName;
    
    // called when an item is clicked
    id              _target;
    SEL             _action;
    SEL             _mouseDownAction;
}

- (void)setDataSource:(id)source;

- (void)reloadData;

- (void)setNumberOfColumns:(LXInteger)cols;
- (LXInteger)numberOfColumns;

- (void)setAutoRecalcsNumberOfColumns:(BOOL)f;
- (BOOL)autoRecalcsNumberOfColumns;

- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

- (void)setDrawsBackground:(BOOL)f;
- (BOOL)drawsBackground;

- (void)setIconBackgroundColor:(NSColor *)color;
- (NSColor *)iconBackgroundColor;

- (void)setIconBackgroundCornerRounding:(double)r;
- (double)iconBackgroundCornerRounding;

- (void)setDrawsIconBackground:(BOOL)f;
- (BOOL)drawsIconBackground;

- (void)setIconShadow:(NSShadow *)shadow;
- (NSShadow *)iconShadow;

- (id)target;
- (void)setTarget:(id)target;

- (SEL)action;
- (void)setAction:(SEL)action;

- (SEL)itemClickedAction;
- (void)setItemClickedAction:(SEL)action;

- (LXInteger)indexOfSelectedItem;

@end



@interface NSObject (LQIconViewDataSource)

- (LXInteger)numberOfItemsInIconView:(LQIconView *)iconView;
- (id)iconView:(LQIconView *)iconView iconForItemAtIndex:(LXInteger)index;
- (id)iconView:(LQIconView *)iconView titleForItemAtIndex:(LXInteger)index;
- (BOOL)iconView:(LQIconView *)iconView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard;

- (void)iconView:(LQIconView *)iconView drawOverlayForItemAtIndex:(LXInteger)index inRect:(NSRect)rect;

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;

@end

