//
//  EDUICompNodeView.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "EDUINodeGraphConnectable.h"


@class EDUICompositionView, EDUICompInputView;


typedef enum {
    EDUICompNodeParamsVisible = 1 << 0,
} EDUICompNodeAppearanceFlags;


@interface EDUICompNodeView : NSView {

    CGFloat		_rounding, _yMargin;
    CGFloat		_height, _xMidpoint;
    CGFloat		_width;
    CGFloat       _zoomFactor;

    NSPoint     _zoomingOffset;

    NSString *_label;


    id <NSObject, EDUINodeGraphConnectable>    _node;

    EDUICompositionView	*_compView;
    NSMutableArray      *_inputViews;
    NSMutableArray      *_outputViews;
    NSMutableArray      *_parameterViews;
    NSMutableArray      *_parameterLabels;
    NSView              *_discTriangleView;
    
    NSInteger           _inputCount;
    NSInteger           _outputCount;
    NSInteger           _parameterCount;
    
    BOOL                _parametersVisible;
    BOOL                _usesHorizLayout;
    BOOL                _selected;
    
    NSPoint             _firstTextLinePoint;
    double              _firstTextLineH;
    
    NSPoint             _selectionOffset;
    
    id                  _appearanceDelegate;
    NSColor             *_selColor, *_unselColor;
	BOOL				_selColorIsPattern, _unselColorIsPattern;
    BOOL                _useWhiteLabelUnsel, _useWhiteLabelSel;
	
	NSTrackingRectTag	_trackRectTag;
	NSMenu				*_contextMenu;
}

+ (NSDictionary *)nodeLabelTextAttributes;
+ (NSDictionary *)whiteNodeLabelTextAttributes;
+ (NSDictionary *)parameterLabelTextAttributes;

+ (void)setDefaultShadow:(NSShadow *)shadow;
+ (NSShadow *)defaultShadow;

- (id)initWithNode:(id <NSObject, EDUINodeGraphConnectable>)node;

- (id<NSObject, EDUINodeGraphConnectable>)node;
- (EDUICompositionView *)compView;   
- (void)setCompView:(EDUICompositionView *)compView;
- (EDUICompInputView *)inputViewAtIndex:(NSInteger)index;
- (EDUICompInputView *)outputViewAtIndex:(NSInteger)index;
- (EDUICompInputView *)parameterViewAtIndex:(NSInteger)index;
- (NSMutableArray *)inputViews;
- (NSMutableArray *)parameterViews;
- (NSMutableArray *)outputViews;
- (void)setLabel:(NSString *)label;
- (void)setZoomFactor:(float)z;
- (float)zoomFactor;

- (NSRect)rectForInputAtIndex:(NSInteger)index;
- (NSRect)rectForOutputAtIndex:(NSInteger)index;
- (NSRect)rectForParameterAtIndex:(NSInteger)index;
- (NSPoint)positionForParameterLabelAtIndex:(NSInteger)index;

- (void)disconnectAllConnections;

- (void)setSelected;
- (void)setUnselected;
- (void)setSelectionOffsetFromPoint:(NSPoint)point;
- (void)moveUsingOffsetToPoint:(NSPoint)point;

- (BOOL)usesHorizontalLayout;
- (void)setUsesHorizontalLayout:(BOOL)f;


- (void)discloseParametersAction:(id)sender;

- (void)trackMouseWithEvent:(NSEvent *)theEvent shiftDown:(BOOL)shiftDown;

- (void)resizeToShowParameters;
- (NSSize)calcFrameSizeForParamCount:(NSInteger)parameterCount;
- (void)calcDimensions;
- (void)setRounding:(CGFloat)r;

- (NSArray *)listOfVisibleParameters;

- (void)updateNodeAppearance;
- (id)appearanceDelegate;
- (void)setAppearanceDelegate:(id)provider;

- (void)refreshTrackingRectsForHoverSelection;

- (void)drawRoundedRectInPath:(NSBezierPath *)path width:(double)width height:(double)height
                                x:(double)x y:(double)y rounding:(double)rounding;

@end


@interface NSObject ( EDUICompNodeViewAppearanceDelegate )

- (NSColor *)selectedColorForNode:(id)node;
- (NSColor *)unselectedColorForNode:(id)node;

- (NSShadow *)shadowForNode:(id)node;
- (NSColor *)borderLineColorForNode:(id)node;

- (NSMenu *)contextMenuForCompNodeView:(EDUICompNodeView *)nodeView previousMenu:(NSMenu *)prevMenu;

@end

