//
//  LQSplitView.h
//  PixelMath
//
//  Created by Pauli Ojala on 9.9.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


/*
2008.05.05
-- the contentResizeMask only works when using InvisibleSplitterStyle  -- TODO: fix
*/

enum {
    LQStandardSplitterStyle = 0,
    LQThinSplitterStyle,
    LQInvisibleSplitterStyle,
};
typedef LXUInteger LQSplitterStyle;

enum {
    LQSplitViewResizeEqually = 0,  // not currently implemented as expected
    LQSplitViewResizeFirst,
    LQSplitViewResizeSecond
};
typedef LXUInteger LQSplitterResizeMask;

// "tapering" applies a few pixels of transparent rounding to the splitter's start
enum {
    LQNoTaperStyle = 0,
    LQStartFadeTaperStyle
};
typedef LXUInteger LQSplitterTaperStyle;


@interface LQSplitView : NSSplitView {

    LXUInteger _style;
    LXUInteger _taperStyle;
    LXUInteger _contentResMask;
    
    double _firstElDim;
    double _secondElDim;
}

- (void)setSplitterStyle:(LQSplitterStyle)style;
- (LQSplitterStyle)splitterStyle;

- (void)setHorizontalDividerFraction:(CGFloat)newFract;

- (void)setFixedDimension:(double)d forElementAtIndex:(LXInteger)index;

- (void)setContentResizingMask:(LXUInteger)mask;

- (void)setTaperStyle:(LQSplitterTaperStyle)style;

@end
