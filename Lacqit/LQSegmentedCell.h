//
//  LQSegmentedCell.h
//  Edo
//
//  Created by Pauli Ojala on 17.5.2006.
//  Copyright 2006 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"


@interface LQSegmentedCell : NSSegmentedCell {

    LXInteger       _highlightSeg;
    CGFloat         _opacity;
    
    BOOL            _useFixedImageSize;
    NSSize          _imageSize;
    
    BOOL            _drawsMenuIndicator;
    
    LQInterfaceTint _lqTint;
    NSColor *_selC;
    NSImage *_selCImage;
    NSColor *_baseC;
    NSImage *_baseCImage;
    NSShadow *_selShad;
    NSShadow *_hiliteShad;
    NSShadow *_outlineShad;
}

@property (getter=isBordered) BOOL bordered;

- (void)copySettingsFromCell:(NSSegmentedCell *)cell;

- (void)setHighlightedSegment:(LXInteger)index;

- (void)setImageOpacity:(CGFloat)op;
- (void)setFixedImageSize:(NSSize)size;
- (void)setFixedImageSizeEnabled:(BOOL)flag;

- (void)setDrawsMenuIndicator:(BOOL)f;

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end
