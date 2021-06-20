//
//  LQSplitView.m
//  PixelMath
//
//  Created by Pauli Ojala on 9.9.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQSplitView.h"
#import "LQGradient.h"


@implementation LQSplitView

- (void)setSplitterStyle:(LQSplitterStyle)style {
    _style = style; }
    
- (LQSplitterStyle)splitterStyle {
    return (LQSplitterStyle)_style; }

- (void)setTaperStyle:(LQSplitterTaperStyle)style {
    _taperStyle = style; }
    
    
- (void)setContentResizingMask:(LXUInteger)mask {
    _contentResMask = mask; }
    
    
- (void)setHorizontalDividerFraction:(CGFloat)newFract
{
    NSRect topFrame, bottomFrame;
    NSView *topSubView;
    NSView *bottomSubView;
    CGFloat totalHeight;
    
    if ([[self subviews] count] < 2)
        return;
    
    topSubView = [[self subviews] objectAtIndex:0];
    bottomSubView = [[self subviews] objectAtIndex:1];
    topFrame = [topSubView frame];
    bottomFrame = [bottomSubView frame];
    totalHeight = NSHeight(bottomFrame) + NSHeight(topFrame);
    bottomFrame.size.height = newFract * totalHeight;
    topFrame.size.height = totalHeight - NSHeight(bottomFrame);
    [topSubView setFrame:topFrame];
    [bottomSubView setFrame:bottomFrame];
    
    [self adjustSubviews];
    [self setNeedsDisplay:YES];
}

- (void)setFixedDimension:(double)d forElementAtIndex:(LXInteger)index
{
    if (index == 0) {
        _firstElDim = d;
        _secondElDim = -1.0;
    } else {
        _firstElDim = -1.0;
        _secondElDim = d;    
    }
    
    [self adjustSubviews];
    [self setNeedsDisplay:YES];    
}

- (void)adjustSubviews
{
    NSRect bounds = [self bounds];
    
    if (_style == LQInvisibleSplitterStyle) {
        ///NSLog(@"%s, %@, %i", __func__, NSStringFromRect(bounds), [self isFlipped]);

        NSView *topView = [[self subviews] objectAtIndex:0];
        NSView *bottomView = [[self subviews] objectAtIndex:1];
        
        BOOL isVertical = [self isVertical];
        
        if ( !isVertical) {
            BOOL resizeTopView = (_contentResMask == LQSplitViewResizeFirst) ? YES : NO;

            // TODO: LQSplitViewResizeEqually isn't implemented

            NSRect frame1 = [topView frame];
            NSRect frame2 = [bottomView frame];
        
            ///NSLog(@"frame1 %@, frame2 %@", NSStringFromRect(frame1), NSStringFromRect(frame2));
            
            frame1.origin = bounds.origin;
            frame1.size.width = bounds.size.width;
            frame1.size.height = (resizeTopView) ? ceil(bounds.size.height - frame2.size.height) : frame1.size.height;

            BOOL noFixedDims = (_firstElDim == 0.0 && _secondElDim == 0.0);
            BOOL frame1IsFixed = (_firstElDim > -0.00001 && !noFixedDims);
            BOOL frame2IsFixed = (frame1IsFixed) ? NO : (_secondElDim > -0.00001 && !noFixedDims);
            if (frame1IsFixed)
                frame1.size.height = _firstElDim;
            
            if (frame2IsFixed)
                resizeTopView = YES;
            
            //NSLog(@"   fixed dim: %f, %f (%i, %i)", _firstElDim, _secondElDim, frame1IsFixed, frame2IsFixed);
            
            frame2.origin.y = frame1.size.height;
            frame2.size.height = (frame2IsFixed) ? _secondElDim : (( !resizeTopView || frame1IsFixed) ? ceil(bounds.size.height - frame2.origin.y) : frame2.size.height);
            frame2.size.width = bounds.size.width;
            
            ///if (frame2IsFixed) NSLog(@"  ---> %@, %@", NSStringFromRect(frame1), NSStringFromRect(frame2));
            
            [topView setFrame:frame1];
            [bottomView setFrame:frame2];
        }
    }
    else
        [super adjustSubviews];
}

- (CGFloat)dividerThickness  // is defined as CGFloat starting with 10.5 AppKit
{
    switch (_style) {
        default:
            if ([self isVertical])
                return 4.0;
            else
                return 3.0;
     
        case LQThinSplitterStyle:
            return 1.0;
            
        case LQInvisibleSplitterStyle:
            return 0.0;
    }
}

- (void)drawDividerInRect:(NSRect)rect
{
    if (_style == LQInvisibleSplitterStyle)
        return;

    BOOL isVertical = [self isVertical];
    double shadAlpha = 0.31; //(isVertical) ? 0.55 : 0.55
	NSColor *shadowColor;
    
    if (_style == LQThinSplitterStyle) {
        shadowColor = [NSColor colorWithDeviceRed:0.1 green:0.094 blue:0.12 alpha:0.56];
        
        switch (_taperStyle) {
            case 0:
                [shadowColor set];
                /*
                if (isVertical) {
                    rect.origin.x += rect.size.width - 1;
                    rect.size.width = 1;
                } else {
                    rect.origin.y += rect.size.height - 1;
                    rect.size.height = 1;
                }*/
                
                NSRectFill(rect);
                break;
                
            case LQStartFadeTaperStyle: {
                //NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
                
                NSColor *c1 = [NSColor colorWithDeviceRed:0.31 green:0.3094 blue:0.312 alpha:0.0];
                NSColor *c2 = [NSColor colorWithDeviceRed:0.1 green:0.094 blue:0.12 alpha:0.97];
                
                LQGradient *gradient = [LQGradient gradientWithBeginningColor:c1 endingColor:c2];
                //gradient = [gradient gradientByAddingColorStop:c2 atPosition:0.1];
                                
            
                double taperH = 2.4;
                double taperOffset = 0.0;
                [gradient fillRect:NSMakeRect(rect.origin.x, rect.origin.y,  rect.size.width+taperH-1.0, taperH)
                          angle:90.0];
                          
                [c2 set];
                [[NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x, rect.origin.y + taperH,  rect.size.width, rect.size.height - taperH)]
                          fill];
                          
                /*
                NSBezierPath *path = [NSBezierPath bezierPath];
                [path moveToPoint:rect.origin];
                [path lineToPoint:(isVertical) ? NSMakePoint(rect.origin.x, rect.origin.y + rect.size.height)
                                               : NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y)];
        
                [path setLineWidth:0.8];
                [path stroke];
                */
                break;
            }
        }
        return;  // -- early exit (thin divider style drawn)
    }
    
    shadowColor = [NSColor colorWithDeviceRed:0.1 green:0.094 blue:0.12 alpha:shadAlpha];
    
    double thickness = [self dividerThickness];


    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    /*NSCompositingOperation prevCompOp = [ctx compositingOperation];

    [ctx setCompositingOperation:NSCompositeCopy];
    [[NSColor colorWithDeviceRed:0.403 green:0.4 blue:0.408 alpha:1.0] set];
    NSRectFill(rect);
    
    [ctx setCompositingOperation:prevCompOp];
  */  

    double hiliteAlpha = 0.3;
	NSColor *hiliteColor = [NSColor colorWithDeviceRed:0.98 green:0.98 blue:0.99 alpha:hiliteAlpha];
	NSColor *middleColor = [NSColor colorWithDeviceRed:0.32 green:0.32 blue:0.33 alpha:0.4]; //[NSColor colorWithDeviceRed:0.4 green:0.4 blue:0.42 alpha:0.4];
	NSBezierPath *path;

	if (isVertical) {
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x, rect.origin.y, 1.0, rect.size.height)];
		[hiliteColor set];
		[path fill];
		
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x+thickness-1, rect.origin.y, 1.0, rect.size.height)];
		[shadowColor set];
		[path fill];
		
		path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
							rect.origin.x+0.5,  rect.origin.y + rect.size.height*0.5 - 1.5,
							3.0, 3.0) ];
		[shadowColor set];
		[path fill];
		
		path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
							rect.origin.x+2.0,  rect.origin.y + rect.size.height*0.5 - 1.5,
							2.0, 3.0) ];
		[hiliteColor set];
		[path fill];

	}
	else {
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x, rect.origin.y+0.5, rect.size.width, 1.0)];
		[hiliteColor set];
		[path fill];
		
		/*path = [NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, 1.0)];
		[middleColor set];
		[path fill];	*/
		
		path = [NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x, rect.origin.y+thickness-1, rect.size.width, 1.0)];
		[shadowColor set];
		[path fill];	

		path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
							rect.origin.x + rect.size.width*0.5 - 1.5, rect.origin.y+0.5 - ((thickness < 6) ? 1.0 : 0.0),
							3.0, 3.0) ];
		[((thickness < 6) ? [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.4] : shadowColor) set];
		[path fill];
		
		path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
							rect.origin.x + rect.size.width*0.5 - 1.5, rect.origin.y+2.5 - ((thickness < 6) ? 2.0 : 0.0),
							3.0, 2.0) ];
		[hiliteColor set];
		[path fill];
	}
	
}


@end
