//
//  LQXCollectionView.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LQLacefxView.h"
@class LQXLabel, LQBitmap;
@class LQCollectionItem;


typedef enum {
    kLQVerticalCollection = 0,
    kLQHorizontalCollection
} LQCollectionOrientation;


@interface LQXCollectionView : LQLACEFXVIEWBASECLASS {

    LQCollectionOrientation     _orientation;
    
    NSString                    *_title;
    
    NSMutableArray              *_items;
    
    LQXLabel                    *_titleBitmap;
    LQBitmap                     *_cornerImage;
    
    double                      _hoverWaitTime;
    BOOL                        _endHoverOnMove;
    
    NSArray                     *_itemLayout;
    double                      _layoutDim;
    double                      _scrollPos;
    
    double                      _titlePostMargin;
    
    // transient state for tracking, etc.
    NSPoint                     _lastWindowPos;
    NSTrackingRectTag           _trackingRectTag;
    NSTimer                     *_mouseTimer;
    double                      _prevMouseEventTime;
    BOOL                        _isHovering;
    long                        _hoverIndex;
    
    NSArray *_dragPboardTypes;
}

- (void)setOrientation:(LXUInteger)orientation;
- (LXUInteger)orientation;

- (NSArray *)content;
- (void)setContent:(NSArray *)content;
- (void)addItem:(LQCollectionItem *)item;
- (void)removeItem:(LQCollectionItem *)item;

- (void)setTitle:(NSString *)title;
- (NSString *)title;

- (void)setDelegate:(id)del;
- (id)delegate;

- (void)setCornerImage:(LQBitmap *)frame;


- (id)hoveredItem;
- (NSPoint)hoverLocationInWindow;
- (void)didEndHoverDisplay;  // called by delegate when it has ended the hover session on its own

- (id)itemAtPoint:(NSPoint)p;
- (NSRect)displayFrameForItem:(id)item;

- (LXInteger)indexOfItem:(id)item;
- (id)itemAtIndex:(LXInteger)index;
- (LXInteger)numberOfItems;

- (double)scrollPosition;
- (void)scrollToPosition:(double)f;

- (double)layoutDimension;

// layout values
- (double)titlePostMargin;
- (void)setTitlePostMargin:(double)f;

- (void)setSupportedPboardTypesForDragReceive:(NSArray *)array;
- (NSArray *)supportedPboardTypesForDragReceive;

@end


@interface NSObject (LQXCollectionViewDelegate)

- (NSDictionary *)previewContextForCollectionView:(LQXCollectionView *)view;

- (id)drawingObjectForCollectionItem:(LQCollectionItem *)item;

- (void)mouseHoverStartForCollectionView:(LQXCollectionView *)view;
- (void)mouseHoverEndForCollectionView:(LQXCollectionView *)view;
- (void)mouseMovedWhileHoveringForCollectionView:(LQXCollectionView *)view event:(NSEvent *)event;

- (void)mouseDownInCollectionView:(LQXCollectionView *)view event:(NSEvent *)event;
- (void)mouseUpInCollectionView:(LQXCollectionView *)view event:(NSEvent *)event;

- (double)collectionView:(LQXCollectionView *)view
          shouldScrollToPosition:(double)f;

- (BOOL)collectionView:(LQXCollectionView *)view
        shouldDrawBackgroundInSurface:(LXSurfaceRef)surface
        bounds:(LXRect)bounds;

- (void)collectionView:(LQXCollectionView *)view
        didDrawItem:(LQCollectionItem *)item
        inSurface:(LXSurfaceRef)surface
        bounds:(LXRect)bounds;

- (void)collectionViewDidPerformLayout:(LQXCollectionView *)view;

- (BOOL)collectionView:(LQXCollectionView *)view
          receivedDraggedObject:(id)drag
          atPoint:(NSPoint)p;
          
- (BOOL)collectionView:(LQXCollectionView *)view suggestsItemDrag:(id)item withEvent:(NSEvent *)event;

@end
