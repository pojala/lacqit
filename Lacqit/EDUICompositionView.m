//
//  EDUICompositionView.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUICompositionView.h"
#import "EDUICompNodeView.h"
#import "EDUICompConnector.h"
#import "EDUICompInputView.h"
#import "EDUICompViewController.h"
#import "EDUINodeGraphConnectable.h"
#import "LQNSColorAdditions.h"
#import "LQGradient.h"

#if defined(__LAGOON__)
#include <math.h>
#endif


const int EDUICompViewMultipleSelected = -101;


@implementation EDUICompositionView

- (void)_createDefaultContextMenu
{
	[_contextMenu release];
	_contextMenu = [[NSMenu alloc] initWithTitle:@"<compViewContextMenu>"];
	_contextMenuWasInited = NO;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selection = [[NSMutableArray arrayWithCapacity:32] retain];
        _connectors = nil;
        _connectorsWithinSelection = [[NSMutableArray arrayWithCapacity:32] retain];
        _makingConnection = NO;
        _bgColor = [[NSColor colorWithDeviceRed:0.65 green:0.65 blue:0.654 alpha:1.0] retain];
        _bgAlpha = 1.0;
		_connectorNotesVisible = YES;
        _enableShakeLoose = YES;
        
        [self makeInputLabelTextAttributes];
		
		[self _createDefaultContextMenu];
    }
    return self;
}

- (void)dealloc {
    [_selection release];
    [_connectors release];
    [_connectorsWithinSelection release];
    [_dragPboardTypes release];
    [_bgColor release];
    [_inputLabelAttribs release];
	[_contextMenu release];
    [super dealloc];
}

- (void)awakeFromNib {
    /*
    // register for drag'n'drop action
    [self registerForDraggedTypes:[NSArray arrayWithObject:EDUIImageSourcePboardType]];
    [self registerForDraggedTypes:[NSArray arrayWithObject:EDUIOperatorPboardType]];
    */
    
    _debugInfoEnabled = NO;
}

#pragma mark --- accessors ---

- (NSMutableArray *)selection {
    return _selection; }

- (void)setConnectorsArray:(NSMutableArray *)connectors {
    if (_connectors) {
        [_connectors release];
        _connectors = nil;
    }
    _connectors = [connectors retain];
}


- (BOOL)debugInfoEnabled {
    return _debugInfoEnabled; }
    
- (void)setDebugInfoEnabled:(BOOL)flag {
    _debugInfoEnabled = flag;
    [self setNeedsDisplay:YES];
}

- (NSColor *)backgroundColor {
	return _bgColor; }

- (void)setBackgroundColor:(NSColor *)color
{
    [_bgColor release];
    _bgColor = [color retain];
    
    CGFloat alpha = -1.0;
    
    NSString *colorSpaceName = _bgColor.colorSpaceName;
    if ([colorSpaceName isEqualToString:NSPatternColorSpace]) {
        alpha = 1.0;
    }
    
    if (alpha < 0.0)
        alpha = [_bgColor rgba].a;
    _bgAlpha = alpha;
}

- (void)setTopGradient:(LQGradient *)gradient height:(double)gradH {
    [_topGradient autorelease];
    _topGradient = [gradient retain];
    _topGradH = gradH;
}

- (BOOL)connectorNotesVisible {
	return _connectorNotesVisible; }
	
- (void)setConnectorNotesVisible:(BOOL)flag {
	_connectorNotesVisible = flag; }
	
- (BOOL)hoverSelectionEnabled {
	return _enableHoverSel; }

- (void)setHoverSelectionEnabled:(BOOL)flag {
	_enableHoverSel = flag;
	if (flag && ![[self window] acceptsMouseMovedEvents])
		[[self window] setAcceptsMouseMovedEvents:YES];
        
	[[_controller nodeViews] makeObjectsPerformSelector:@selector(refreshTrackingRectsForHoverSelection)];
}

- (BOOL)shakeLooseEnabled {
    return _enableShakeLoose; }
    
- (void)setShakeLooseEnabled:(BOOL)flag {
    _enableShakeLoose = flag; }


#pragma mark --- managing content size ---

- (NSRect)contentBounds
{
    return _contentBounds;
}

- (void)setContentBounds:(NSRect)rect
{
    _contentBounds = rect;
    
#if !defined(__LAGOON__)
	if ([[self superview] isKindOfClass:[NSClipView class]]) {
		NSRect superFrame = [[self superview] frame];
		rect = NSUnionRect(superFrame, rect);
		[self setFrame:rect];
                
        //NSLog(@"contentbounds %@, clipframe %@", NSStringFromRect(rect), NSStringFromRect(frameInSelf));
        
        if (rect.origin.x < 0.0 || rect.origin.y < 0.0) {
            [self setBoundsOrigin:rect.origin];
        }
	}
    //[self setFrame:[self frame]];
#endif
}

- (void)recalcContentBounds
{
	NSEnumerator *nodeEnum = [[_controller nodeViews] objectEnumerator];
	NSView *node = [nodeEnum nextObject];
	if (!node)
		return;
	NSRect rect = [node frame];
	
	while (node = [nodeEnum nextObject]) {
		rect = NSUnionRect(rect, [node frame]);
	}
    
	[self setContentBounds:rect];
}


- (void)setFrame:(NSRect)frameRect
{
    frameRect.size.width  = fmax(_contentBounds.size.width, frameRect.size.width);
    frameRect.size.height = fmax(_contentBounds.size.height, frameRect.size.height);

    [super setFrame:frameRect];
}

#if !defined(__LAGOON__)
- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    NSSize newSize = [[self superview] bounds].size;
    NSSize frameSize = [self frame].size;

//    NSLog(@"rs:   w %f  h %f", oldBoundsSize.width, oldBoundsSize.height);
//    NSLog(@"rs:   w %f  h %f", [[self superview] bounds].size.width, [[self superview] bounds].size.height);
    if (oldBoundsSize.width < frameSize.width) {
        oldBoundsSize.width += newSize.width - oldBoundsSize.width;
        if (newSize.width > frameSize.width) {
            oldBoundsSize.width -= newSize.width - frameSize.width;
        }
    }
    if (oldBoundsSize.height < frameSize.height) {
        oldBoundsSize.height += newSize.height - oldBoundsSize.height;
        if (newSize.height > frameSize.height) {
            oldBoundsSize.height -= newSize.height - frameSize.height;
        }
    }

    [super resizeWithOldSuperviewSize:oldBoundsSize];
    //[self setFrame:[[self superview] bounds]];
}
#endif


#pragma mark --- event handling ---

- (BOOL)acceptsFirstResponder {
    return YES; }

- (void)setClearsSelectionQuietlyWhenResignsFirstResponder:(BOOL)f
{
    _clearSelOnResignFirstResp = f;
}

- (BOOL)resignFirstResponder {
    if (_clearSelOnResignFirstResp) {
        [_selection makeObjectsPerformSelector:@selector(setUnselected) ];
        [_selection removeAllObjects];
        // don't notify the delegate
    }
    return YES;
}

- (void)keyDown:(NSEvent *)event {
    //BOOL shiftDown = (([event modifierFlags] & NSShiftKeyMask) ? YES : NO);
    NSString *chars = [event charactersIgnoringModifiers];
    unichar space = ' ';
    unichar firstChar = ([chars length] > 0) ? [chars characterAtIndex:0] : 0;

    if (firstChar == space) {        
        if (_mouseDown && !_spacebarIsPressed) {
            // initiate pan
            _shouldStartPan = YES;
        }
        _spacebarIsPressed = YES;
        return;
    }
	else {
		switch ([event keyCode]) {
			case 123:  // left arrow key
				[self walkSelectionWithinTree:EDUILeft];
				return;
				
			case 124:  // right arrow key
				[self walkSelectionWithinTree:EDUIRight];
				return;
				
			case 125:  // down arrow key
				[self walkSelectionWithinTree:EDUIDown];
				return;
				
			case 126:  // up arrow key
				[self walkSelectionWithinTree:EDUIUp];
				return;
		}
	}
    
    if ([[_controller modelDelegate] respondsToSelector:@selector(keyDownInCompView:event:)]) {
        BOOL didHandle = [[_controller modelDelegate] keyDownInCompView:self event:event];
        if (didHandle) return;
    }

    [super keyDown:event];
}


- (void)keyUp:(NSEvent *)event {
    NSString *chars = [event charactersIgnoringModifiers];
    unichar space = ' ';
    unichar firstChar = ([chars length] > 0) ? [chars characterAtIndex:0] : 0;
    
    if (firstChar == space) {
        _spacebarIsPressed = NO;
    }

    if ([[_controller modelDelegate] respondsToSelector:@selector(keyUpInCompView:event:)]) {
        [[_controller modelDelegate] keyUpInCompView:self event:event];
    }    
}


#pragma mark --- standard Cocoa actions ---

- (IBAction)selectAll:(id)sender {
	[self selectAll];
	[self setNeedsDisplay:YES];
}

- (IBAction)cut:(id)sender {
    if ([[_controller modelDelegate] respondsToSelector:@selector(cutSelectionToClipboard)]) {
        [[_controller modelDelegate] cutSelectionToClipboard];
    } else {
        [[self nextResponder] tryToPerform:_cmd with:sender];
    }
}

- (IBAction)copy:(id)sender {
    if ([[_controller modelDelegate] respondsToSelector:@selector(copySelectionToClipboard)]) {
        [[_controller modelDelegate] copySelectionToClipboard];
    } else {
        [[self nextResponder] tryToPerform:_cmd with:sender];
    }
}

- (IBAction)paste:(id)sender {
    if ([[_controller modelDelegate] respondsToSelector:@selector(pasteNodesFromClipboard)]) {
        [[_controller modelDelegate] pasteNodesFromClipboard];
    } else {
        [[self nextResponder] tryToPerform:_cmd with:sender];
    }
}

- (IBAction)delete:(id)sender
{
    if ([[_controller modelDelegate] respondsToSelector:@selector(deleteSelection)]) {
        [[_controller modelDelegate] deleteSelection];
    } else {
        [_controller deleteSelectedNodeViews];
    }
}

/*
- (IBAction)undo:(id)sender {
    if ([[_controller modelDelegate] respondsToSelector:@selector(undo:)]) {
        [[_controller modelDelegate] undo:sender];
    }
}

- (IBAction)redo:(id)sender {
    if ([[_controller modelDelegate] respondsToSelector:@selector(redo:)]) {
        [[_controller modelDelegate] redo:sender];
    }
}
*/



#pragma mark --- drawing ---


static NSRect AbsoluteRect(NSRect selRect)
{
    if (selRect.size.width < 0.0f) {
        selRect.origin.x += selRect.size.width;
        selRect.size.width = -selRect.size.width;
    }
    if (selRect.size.height < 0.0f) {
        selRect.origin.y += selRect.size.height;
        selRect.size.height = -selRect.size.height;
    }
    return selRect;
}


- (BOOL)isOpaque {
    return NO;
}

- (void)drawRect:(NSRect)rect
{
    //NSLog(@"%s: %@, subviews %ld", __func__, NSStringFromRect(rect), (long)[[self subviews] count]);

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
    
    [ctx setPatternPhase:NSMakePoint(-_bgOffset.x, -_bgOffset.y)];
    
    if (_bgAlpha > 0.01) {
#if !defined(__LAGOON__)
            // if this window is transparent and we're on 10.4+, draw bg color in "copy" mode so it can be an alpha value
            if ([[NSGraphicsContext currentContext] respondsToSelector:@selector(setCompositingOperation:)]
                && [[self window] alphaValue] < 1.0
                ) {
                [ctx setCompositingOperation:NSCompositeCopy];
                
                [_bgColor set];
                CGContextFillRect([ctx graphicsPort], NSRectToCGRect(rect));
            } else
#endif
            {
                [_bgColor set];
                //NSRectFill(rect);
                [[NSBezierPath bezierPathWithRect:rect] fill];
            }
    }
  
    [ctx restoreGraphicsState];
    
    id del = [_controller modelDelegate];
    
    if ([del respondsToSelector:@selector(compViewShouldDrawContentsInRect:)]) {
        // this can be used to short-circuit drawing, when the delegate knows that the area being updated isn't important
        // (e.g. covered by a UI element that gets updated for every frame during playback)
        if ( ![del compViewShouldDrawContentsInRect:rect]) {
            return;
        }
    }
  
    if ([del respondsToSelector:@selector(compViewCustomBackgroundDrawInRect:)]) {
        // let the delegate do custom drawing first
        [del compViewCustomBackgroundDrawInRect:rect];
    }

    // let the composition draw background rects of its own    
    id comp = (id)[_controller nodeGraph];
    if ([comp respondsToSelector:@selector(numberOfCompBackgroundRects)]) {
        NSAssert([comp respondsToSelector:@selector(compBackgroundRectAtIndex:compView:)], @"must implement -compBackgroundRectAtIndex");
        BOOL doesName =  [comp respondsToSelector:@selector(nameOfCompBackgroundRectAtIndex:compView:)];
        BOOL doesColor = [comp respondsToSelector:@selector(colorOfCompBackgroundRectAtIndex:compView:)];
        int n = [comp numberOfCompBackgroundRects];
        int i;
        for (i = 0; i < n; i++) {
            NSRect r = [comp compBackgroundRectAtIndex:i compView:self];
            NSString *name = doesName  ? [comp nameOfCompBackgroundRectAtIndex:i compView:self] : @"";
            #pragma unused (name)
            
            NSColor *color = doesColor ? [comp colorOfCompBackgroundRectAtIndex:i compView:self] :
                                         [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.35];
                                         
            NSBezierPath *path = [NSBezierPath bezierPathWithRect:r];

            [color set];
            [path fill];
            
            // TODO: print name in corner of rect
        }
    }
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSEnumerator *enumerator = [_connectors objectEnumerator];
    EDUICompConnector *conn;
    while (conn = [enumerator nextObject]) {
        #if (0)
		// debug code for drawing the "drop rects" for each connector
		/*
		NSInteger dropRectCount = 0;
		NSRect *dropRects = [conn dropRectsWithCountPtr:&dropRectCount];
		[[NSColor colorWithDeviceRed:0.5 green:0.6 blue:0.45 alpha:1.0] set];
		NSInteger s;
		//NSLog(@"will draw connector rects, %i", dropRectCount);
		for (s = 0; s < dropRectCount; s++) {
			//NSLog(@" ... rect %@", NSStringFromRect(dropRects[s]));
			NSRectFill(dropRects[s]);
		}
		*/
        #endif
        
        [conn drawInPath:path inView:self noteVisible:_connectorNotesVisible];
    }
	
    [path setLineWidth:0.7];
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0] set];
    [path stroke];
    
    if (_inputViewToBeConnected) {
        NSPoint origin = [self convertPoint:[_inputViewToBeConnected frame].origin
                                fromView:[_inputViewToBeConnected nodeView]];

        
        switch (_inputViewToConnectLabelDisplayPosition) {
            case EDUILeft: {
                NSSize labelSize = [[_inputViewToBeConnected name] sizeWithAttributes:_inputLabelAttribs];
                origin.x -= labelSize.width;
                break;
            }
            case EDUIUp:
            default:
                origin.y += 15.0;
                origin.x += 8.0;
                break;
            case EDUIRight:
                origin.x += 15.0;
                origin.y += 8.0;
                break;
        }
        
#if !defined(__LAGOON__)
/*        NSMutableAttributedString *label = [[[NSMutableAttributedString alloc]
                                                        initWithString:[_inputViewToBeConnected name] 
                                                        attributes:_inputLabelAttribs]
                                                autorelease];*/
        [[_inputViewToBeConnected name] drawAtPoint:origin withAttributes:_inputLabelAttribs];
#else
        origin.y += 16.0;  // this should most likely be fixed in Lagoon instead (NSStringAdditions)...
        
        NSString *label = [_inputViewToBeConnected name];
        [label drawAtPoint:origin withAttributes:_inputLabelAttribs];        
#endif                                  
    }
    
    if (_isBoxSelecting) {
        NSRect selRect = AbsoluteRect(_selectionBox);
        NSInsetRect(selRect, 0.5f, 0.5f);
				
		NSBezierPath *selPath = [NSBezierPath bezierPathWithRect:selRect];
        
        [[NSColor colorWithDeviceRed:145.0/255.0 green:175.0/255.0 blue:235.0/255.0 alpha:0.6] set];
        [selPath fill];
	
        [selPath setLineWidth:0.5];
        [[NSColor colorWithDeviceRed:0.9 green:0.95 blue:1.0 alpha:1.0] set];
        [selPath stroke];
    }
    
#if !defined(__LAGOON__)
    // decorate with gradient at top
    if (_topGradient && _topGradH != 0.0) {
        NSRect bounds = [self visibleRect];
        double gradH = _topGradH; //bounds.size.height * 0.5;
    
        NSRect gradRect = NSMakeRect(bounds.origin.x, bounds.origin.y + bounds.size.height - _topGradH,
                                     bounds.size.width, gradH);
                                     
        [_topGradient fillRect:gradRect angle:-90.0];
    }
#endif

    /*
    if (_debugInfoEnabled) {
        NSEnumerator *subEnum = [[self subviews] objectEnumerator];
        EDUICompNodeView *nodeView;
        while (nodeView = [subEnum nextObject]) {
            EDUIOpNode *node = [nodeView node];
            if ([node isKindOfClass:[EDUIOpNode class]]) {
                BOOL nr = [node needsRendering];
                if (nr) {
                    NSString *str = [NSString stringWithFormat:@"NR"];
                    NSPoint pt = [node originPoint];
                    pt.y -= 4.0f;
                    [str drawAtPoint:pt withAttributes:[EDUICompositionView inputLabelTextAttributes]];
                }
            }
        }
    }
    */
}

- (void)refreshAppearance
{
    [self makeInputLabelTextAttributes];
}

- (NSDictionary *)inputLabelTextAttributes {
    return _inputLabelAttribs; }
    
- (void)makeInputLabelTextAttributes
{
    if (_inputLabelAttribs)
        [_inputLabelAttribs release];
        
    NSMutableDictionary *attribs;
	BOOL colorIsSolid = (   [[_bgColor colorSpaceName] isEqualToString:NSDeviceRGBColorSpace]
                         || [[_bgColor colorSpaceName] isEqualToString:NSCalibratedRGBColorSpace]);
    float r = colorIsSolid ? [_bgColor redComponent]   : 0.7;
    float g = colorIsSolid ? [_bgColor greenComponent] : 0.7;
    float b = colorIsSolid ? [_bgColor blueComponent]  : 0.7;
    float lum, sRadius, sAlpha;
    float lumT = 0.7;
    NSColor *textColor, *sColor;
    
    // calculate approximate background luminance value,
    // so we can set the shadow radius and alpha to suitable values
    lum = 0.3*r + 0.6*g + 0.1*b;
    if (lum > lumT) {
        sAlpha = 1.0;
        sRadius = 4.0;
        textColor = [NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:1.0];
        sColor = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:sAlpha];
    }
    else {
        sAlpha = 0.96;
        sRadius = 3.0;
        textColor = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        sColor = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:sAlpha];
    }

    id comp = (id)[_controller nodeGraph];
    double scale = 1.0;
    if ([comp respondsToSelector:@selector(globalScaleFactor)])
        scale = [comp globalScaleFactor];


    NSFont *font = [NSFont boldSystemFontOfSize:round(9.0 * scale)];  ///[NSFont fontWithName:@"Lucida Grande Bold" size:9.0 * scale];
    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowBlurRadius:sRadius];
    [shadow setShadowColor:sColor];
    
    attribs = [ [NSMutableDictionary alloc] init];
    [attribs setObject:font forKey:NSFontAttributeName];
    [attribs setObject:textColor forKey:NSForegroundColorAttributeName];
    [attribs setObject:shadow forKey:NSShadowAttributeName];
    
    _inputLabelAttribs = attribs;
}

- (void)displayNameForInputView:(EDUICompInputView *)input withPosition:(NSInteger)pos
{
    if (input != nil) {
        _inputViewToBeConnected = input;
        _inputViewToConnectLabelDisplayPosition = pos;
	} else {
        [[_inputViewToBeConnected nodeView] setNeedsDisplay:YES];
        _inputViewToBeConnected = nil;
    }
}


#pragma mark --- selection methods ---


- (void)reselectNode:(id)node
{
    [_selection removeAllObjects];
    EDUICompNodeView *nodeView = [_controller findNodeViewWithNode:node];
    if (nodeView) {
        [_selection addObject:nodeView];
        [nodeView setSelected];
    }
}

- (void)mouseEnteredNodeView:(EDUICompNodeView *)nodeView
{
	if (_enableHoverSel) {
		// clear selection
		[_selection makeObjectsPerformSelector:@selector(setUnselected) ];
		[_selection removeAllObjects];

		[self addToSelection:nodeView];
	}
}

- (void)replaceSelection:(NSMutableArray *)selection
{
    EDUICompNodeView *nodeView;

    if ([selection isEqualToArray:_selection]) {
        if ([[_controller modelDelegate] respondsToSelector:@selector(nodeViewWasReselected:)]) {
            for (nodeView in _selection) {
                [[_controller modelDelegate] nodeViewWasReselected:nodeView];
            }
        }
        return;
    }

    for (nodeView in _selection) {
		[nodeView setUnselected];
	}

	[_selection release];
	_selection = [selection retain];
	
    for (nodeView in _selection) {
		[nodeView setSelected];
	}
    
	[[_controller modelDelegate] compViewSelectionWasModified];
}

- (void)addToSelection:(EDUICompNodeView *)nodeView
{
    if ( !nodeView)
        return;
    
    if ([_selection containsObject:nodeView]) {
        if ([[_controller modelDelegate] respondsToSelector:@selector(nodeViewWasReselected:)]) {
            [[_controller modelDelegate] nodeViewWasReselected:nodeView];
        }
        return;
    }

    [_selection addObject:nodeView];
    [nodeView setSelected];
    
    [[_controller modelDelegate] compViewSelectionWasModified];
}

- (void)removeFromSelection:(EDUICompNodeView *)nodeView
{
    if ( !nodeView || ![_selection containsObject:nodeView])
        return;

    [_selection removeObject:nodeView];
    [nodeView setUnselected];
    
    [[_controller modelDelegate] compViewSelectionWasModified];
}

- (id)selectedNode
{
    EDUICompNodeView *nodeView;
    
    if ([_selection count] < 1)
        return nil;
    if ([_selection count] > 1)
        return [NSNumber numberWithInt:EDUICompViewMultipleSelected];
    
    nodeView = [_selection objectAtIndex:0];

/*    
    if (nil == (node = (EDUINode *)[nodeView node])) {
        // nodeView is root, because it returns nil
        return _composition;
    }
    else 
        return node;*/
    return [nodeView node];
}

- (void)clearSelection
{
    if ([_selection count] > 0) {
        [_selection makeObjectsPerformSelector:@selector(setUnselected) ];
        [_selection removeAllObjects];
    
        [[_controller modelDelegate] compViewSelectionWasModified];
    }
}

- (void)selectAll
{
	[_selection addObjectsFromArray:[_controller nodeViews]];
	[_selection makeObjectsPerformSelector:@selector(setSelected) ];
	
	[[_controller modelDelegate] compViewSelectionWasModified];
}


- (void)highlightConnectorsForDropAtPoint:(NSPoint)point
{
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    EDUICompConnector *conn;

	BOOL needsRedraw = NO;
	BOOL found = NO;

    while (conn = [connEnum nextObject]) {
		NSInteger dropRectCount = 0;
		NSRect *dropRects = [conn dropRectsWithCountPtr:&dropRectCount];

		BOOL connIsHilite = [conn isHighlighted];

		NSInteger s;
		for (s = 0; s < dropRectCount; s++) {
			
			if (NSMouseInRect(point, dropRects[s], NO)) {
                BOOL isInSelection = [_connectorsWithinSelection containsObject:conn];
            
				// highlight connector
				if ( !connIsHilite && !isInSelection) {
					[conn setHighlighted:YES];
					needsRedraw = YES;
				}
				found = YES;
			}
			if (found)  break;
		}
		if (found)  break;

		// unhighlight connector
		if (connIsHilite) {
			[conn setHighlighted:NO];
			needsRedraw = YES;
		}
    }
	
	if (needsRedraw)
		[self setNeedsDisplay:YES];
}

- (EDUICompConnector *)connectorAtPoint:(NSPoint)point
{
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    EDUICompConnector *conn;

	BOOL found = NO;

    while (conn = [connEnum nextObject]) {
		NSInteger dropRectCount = 0;
		NSRect *dropRects = [conn dropRectsWithCountPtr:&dropRectCount];

		NSInteger s;
		for (s = 0; s < dropRectCount; s++) {
			
			if (NSMouseInRect(point, dropRects[s], NO)) {
				found = YES;
				break;
			}
		}
		if (found)  break;
    }
	
	if (found)
		return conn;
	else
		return nil;
}


- (void)startSelectionMoveAtPoint:(NSPoint)point
{
    [_connectorsWithinSelection removeAllObjects];

    // collect list of all inputs/outputs associated with selected nodes
    NSMutableArray *selInpViews = [NSMutableArray arrayWithCapacity:32];

    NSEnumerator *selEnum = [_selection objectEnumerator];
    id ob;
    while (ob = [selEnum nextObject]) {
        // set selection offset for nodes to be dragged
        [ob setSelectionOffsetFromPoint:(NSPoint)point];
        
        [selInpViews addObjectsFromArray:[ob inputViews]];
        [selInpViews addObjectsFromArray:[ob outputViews]];
        [selInpViews addObjectsFromArray:[ob parameterViews]];
    }
    
    // create list of connectors associated with selected nodes
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    id conn;
    while (conn = [connEnum nextObject]) {
        EDUICompInputView *from = [conn fromOutput];
        EDUICompInputView *to = [conn toInput];
        
        if ([selInpViews containsObject:from] || [selInpViews containsObject:to])
            [_connectorsWithinSelection addObject:conn];
    }
}


- (void)moveSelectionToPoint:(NSPoint)point
{
    NSEnumerator *selEnumerator = [_selection objectEnumerator];
    EDUICompNodeView *selObj;
    NSRect newFrame = [self contentBounds];
	NSRect viewFrame;
    
	[self highlightConnectorsForDropAtPoint:point];
	
    while (selObj = [selEnumerator nextObject]) {
        [selObj moveUsingOffsetToPoint:point];
        
		// add the moved nodeview's new frame into our content bounds, so scrollbars can be properly refreshed
        viewFrame = [selObj frame];
        viewFrame.size.width += viewFrame.origin.x;
        viewFrame.size.height += viewFrame.origin.y;
        viewFrame.origin.x = viewFrame.origin.y = 0.0;
        newFrame = NSUnionRect(newFrame, viewFrame);        // TODO: resize should go through all nodeviews?
    }
	///[self setContentBounds:newFrame];
	[self recalcContentBounds];
	
	// refresh connectors
	[_connectors makeObjectsPerformSelector:@selector(nodesWereMoved)];
    
    [_controller compViewSelectedNodesWereMoved];

    [self setNeedsDisplay:YES];
}

- (void)endSelectionMoveAtPoint:(NSPoint)point
{
	// check for selection drop on a connector
	EDUICompConnector *dropConn = [self connectorAtPoint:point];
	
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    EDUICompConnector *conn;
    while (conn = [connEnum nextObject]) {
		// unhighlight all connectors
		[conn setHighlighted:NO];
	}

	if (dropConn && ![_connectorsWithinSelection containsObject:dropConn]) {
		EDUICompInputView *from = [dropConn fromOutput];
		EDUICompInputView *to   = [dropConn toInput];
		
		[_controller connectNodes:_selection betweenOutput:from andInput:to];
		[_controller finishedModifyingModel];
		[_controller makeNodeViews];

		/*
		id fromNode =   [[from nodeView] node];
		id toNode   =   [[to nodeView] node];
		int fromIndex = [from index];
		int toIndex   = [to index];
		
		[[_controller modelDelegate] dropSelectionOnConnectionFromNode:fromNode fromIndex:fromIndex
																toNode:toNode   toIndex:toIndex];
		*/
	}
	
    [_connectorsWithinSelection removeAllObjects];
    
	if (_enableHoverSel)
		[[_controller nodeViews] makeObjectsPerformSelector:@selector(refreshTrackingRectsForHoverSelection)];
}

// this method removes the selection from its connected inputs and outputs;
// it's called when the user does a "horizontal shake" gesture (in EDUICompNodeView -trackMouseWithEvent method)
- (void)shakeSelectionLoose
{
    if (!_enableShakeLoose)
        return;
    
	[[_controller modelDelegate] shakeSelectionLoose];

	if (_enableHoverSel)
		[[_controller nodeViews] makeObjectsPerformSelector:@selector(refreshTrackingRectsForHoverSelection)];
}


// this method is called when the user drags node(s) with Alt key pressed;
// it duplicates the selection and reselects the newly created nodes
- (void)duplicateSelectionOnDrag
{
	NSSet *newNodes = [[_controller modelDelegate] duplicateSelection];
	NSEnumerator *enumerator = [newNodes objectEnumerator];
	id<NSObject, EDUINodeGraphConnectable> node;
		
    [_selection makeObjectsPerformSelector:@selector(setUnselected) ];
    [_selection removeAllObjects];
    
	while (node = [enumerator nextObject]) {
		EDUICompNodeView *nodeView = [_controller findNodeViewWithNode:node];
		[_selection addObject:nodeView];
		[nodeView setSelected];
	}
	
	[self setNeedsDisplay:YES];
    [[_controller modelDelegate] compViewSelectionWasModified];
	
	if (_enableHoverSel)
		[[_controller nodeViews] makeObjectsPerformSelector:@selector(refreshTrackingRectsForHoverSelection)];
}


- (void)walkSelectionWithinTree:(EDUIDirection)dir
{
	if ([_selection count] == 1) {
		EDUICompNodeView *currSel = (EDUICompNodeView *)[_selection objectAtIndex:0];
		EDUICompNodeView *wantedNodeView = nil;
		int downInpIndex = 0;
		BOOL downInpIsParam = NO;
		
		if (dir == EDUIUp) {
			if ([[currSel inputViews] count] > 0) {
				EDUICompInputView *inpView = [[currSel inputViews] objectAtIndex:0];
				if ([inpView isConnectedInput]) {
					wantedNodeView = [[inpView connectedOutputView] nodeView];
				}
			}
		}
		else {
			if ([[currSel outputViews] count] > 0) {
				EDUICompInputView *outpView = [[currSel outputViews] objectAtIndex:0];
				if ([[outpView connectedInputViews] count] > 0) {
					EDUICompInputView *downInp = (EDUICompInputView *)[[outpView connectedInputViews] objectAtIndex:0];
					wantedNodeView = [downInp nodeView];
					downInpIndex = [downInp index];
					downInpIsParam = [downInp isParameter];
				}
			}
		}
		
		if (wantedNodeView && (dir == EDUILeft || dir == EDUIRight)) {
			// continue searching - currently we have the downstream node, look for left/right nodes
			BOOL foundLateral = NO;
			int inpCount = [[wantedNodeView inputViews] count];
			int i;
			
			if (downInpIsParam) {
			
			}
			else {
				i = 0;
				int max = downInpIndex;
				if (dir == EDUIRight) {
					i = downInpIndex + 1;
					max = inpCount;
				}
				if (i < inpCount) {
					for (; i < max; i++) {
						EDUICompInputView *inp = [[wantedNodeView inputViews] objectAtIndex:i];
						if ([inp isConnectedInput]) {
							wantedNodeView = [[inp connectedOutputView] nodeView];
							foundLateral = YES;
							break;
						}
					}
				}
			}
			
			if (!foundLateral)
				wantedNodeView = nil;
		}
		
		if (wantedNodeView) {
			// we found a node in the requested direction, so change selection
			[_selection makeObjectsPerformSelector:@selector(setUnselected) ];
			[_selection removeAllObjects];
			[self addToSelection:wantedNodeView];
		}
	}
}


#if !defined(__LAGOON__)

#pragma mark --- noodle notes and node renaming ---


#define NODENAMEEDITORTAG 154542

- (void)showNameEditorForNodeView:(EDUICompNodeView *)nodeView
{
	NSRect frame = [nodeView frame];
	frame.origin.x += 8.0f;
	frame.size.width -= 16.0f;
	frame.origin.y = frame.origin.y + frame.size.height - 29.0f;
	frame.size.height = 16.0f;

	_currEditedNodeView = nodeView;

	NSTextField *field = [[[NSTextField alloc] initWithFrame:frame] autorelease];
	[field setBezeled:YES];
	[field setBordered:YES];
	[field setBackgroundColor:[NSColor colorWithDeviceRed:0.88 green:0.88 blue:0.88 alpha:1.0]];
	[field setFont:[NSFont systemFontOfSize:10.0]];
	[field setDelegate:(id<NSObject,NSTextFieldDelegate>)self];
	[field setTag:NODENAMEEDITORTAG];
	[self addSubview:field];
	[[self window] makeFirstResponder:field];
	_nameEditor = field;
}

- (void)_showNoteEditorForConnector:(EDUICompConnector *)conn editPoint:(NSPoint)editPoint
{
	float xoff = 16.0f;
	float yoff = -8.0f;
	NSTextField *field = [[[NSTextField alloc] initWithFrame:NSMakeRect(editPoint.x + xoff, editPoint.y + yoff,  120.0, 17.0)]
								autorelease];
	
	[field setBezeled:YES];
	[field setBordered:NO];
	[field setBackgroundColor:[NSColor colorWithDeviceRed:0.88 green:0.88 blue:0.88 alpha:1.0]];
	[field setFont:[NSFont systemFontOfSize:11.0]];
	[field setDelegate:(id<NSObject,NSTextFieldDelegate>)self];
	[self addSubview:field];
	[[self window] makeFirstResponder:field];
	_nameEditor = field;
}

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
	NSTextField *field = [notif object];
	NSString *newNote = [field stringValue];
	int tag = [field tag];

	[field removeFromSuperview];
	_nameEditor = nil;
	
	//NSLog(@"done edit, %@", newNote);

	if (tag == NODENAMEEDITORTAG) {
		// editor was for a node name
		[[_controller modelDelegate] finishedEditingNameForNodeView:_currEditedNodeView newName:newNote];
		_currEditedNodeView = nil;
	}
	else {
		// editor was for a noodle
		if ([newNote length] < 1)
			newNote = nil;
			
		[self setNote:newNote forConnector:_currConn];
		_currConn = nil;
	}
	[self setNeedsDisplay:YES];
}

#endif // !__LAGOON__


- (void)setNote:(NSString *)newNote forConnector:(EDUICompConnector *)conn
{
	[conn setNote:newNote];
	
	EDUICompInputView *inp = [conn toInput];
	id node = [[inp nodeView] node];
	int inpIndex = [inp index];
	if ([inp isParameter]) {
		if ([node respondsToSelector:@selector(setConnectorNote:forParameterInputAtIndex:)]) {
			[node setConnectorNote:newNote forParameterInputAtIndex:inpIndex];
			[node setConnectorNotePosition:[conn notePosition] forParameterInputAtIndex:inpIndex];
		}
	} else {
		// this input is not a parameter input
		if ([node respondsToSelector:@selector(setConnectorNote:forInputAtIndex:)]) {
			[node setConnectorNote:newNote forInputAtIndex:inpIndex];
			[node setConnectorNotePosition:[conn notePosition] forInputAtIndex:inpIndex];
		}
	}
}

- (void)getNoteEditorForConnector:(EDUICompConnector *)conn atMouseLocation:(BOOL)atMouse
{
	float pos;
	if (atMouse) {
		pos = [conn positionAtPoint:_mouseLocation];
		[conn setNotePosition:pos];
	} else
		pos = [conn notePosition];

	NSPoint editPoint = [conn pointAtPosition:pos];

    BOOL doContinue = YES;
    if ([[_controller modelDelegate] respondsToSelector:@selector(shouldEditNoteForConnector:atPoint:)])
        doContinue = [[_controller modelDelegate] shouldEditNoteForConnector:conn atPoint:editPoint];

    if (doContinue) {
        #if !defined(__LAGOON__)
        [self _showNoteEditorForConnector:conn editPoint:editPoint];
        
        #else
        NSLog(@"** %s: not implemented (Lagoon UI controller is expected to handle the note editing in the delegate method)", __func__);
        #endif
    }
}


- (void)setConnectorNoteAction:(id)sender
{
	[self getNoteEditorForConnector:(EDUICompConnector *)_currConn atMouseLocation:YES];
}

- (void)editConnectorNoteAction:(id)sender
{
	[self getNoteEditorForConnector:(EDUICompConnector *)_currConn atMouseLocation:NO];
}

- (void)deleteConnectorNoteAction:(id)sender
{
	[self setNote:nil forConnector:_currConn];
	_currConn = nil;
	[self setNeedsDisplay:YES];
}


- (void)connectNodeIntoActiveContextMenuConnector:(id)node
{
	if (!_currConn) {
		NSLog(@"** %s: currConn == nil", __func__);
		return;
	}
	EDUICompNodeView *newNodeView = [_controller findNodeViewWithNode:node];
	EDUICompInputView *from = [_currConn fromOutput];
	EDUICompInputView *to   = [_currConn toInput];
	
	NSMutableSet *setOfViews = [NSMutableSet setWithObject:newNodeView];
	[_controller connectNodes:setOfViews betweenOutput:from andInput:to];
	[_controller finishedModifyingModel];
	[_controller makeNodeViews];
}


#pragma mark --- mouse handling ---

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	EDUICompConnector *conn = [self connectorAtPoint:location];
	if (conn) {
		_currConn = conn;
		_mouseLocation = location;
		
		NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		NSMenuItem *item;
		if ([conn note]) {
			item = [[NSMenuItem alloc] initWithTitle:@"Edit Note" action:NULL keyEquivalent:@"" ];
			[item setEnabled:YES];
			[item setTarget:self];
			[item setAction:@selector(editConnectorNoteAction:)];
			[menu addItem:[item autorelease]];
			
			item = [[NSMenuItem alloc] initWithTitle:@"Delete Note" action:NULL keyEquivalent:@"" ];
			[item setEnabled:YES];
			[item setTarget:self];
			[item setAction:@selector(deleteConnectorNoteAction:)];
			[menu addItem:[item autorelease]];
		}
		else {
			item = [[NSMenuItem alloc] initWithTitle:@"Add Note" action:NULL keyEquivalent:@"" ];
			[item setEnabled:YES];
			[item setTarget:self];
			[item setAction:@selector(setConnectorNoteAction:)];
			[menu addItem:[item autorelease]];
		}

		id delegate = [_controller modelDelegate];
		if ([delegate respondsToSelector:@selector(willShowContextMenu:forCompConnectorWithInputView:)]) {
			EDUICompInputView *inp = [_currConn toInput];
			[delegate willShowContextMenu:menu forCompConnectorWithInputView:inp];
		}
        
        if ([NSMenu respondsToSelector:@selector(popUpContextMenu:withEvent:forView:withFont:)]) {
            [NSMenu popUpContextMenu:menu withEvent:theEvent forView:self
						withFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        } else {
            [NSMenu popUpContextMenu:menu withEvent:theEvent forView:self];
        }
	}
	else {
		// clicked on background
		BOOL firstTime = (_contextMenuWasInited) ? NO : YES;
		
		id delegate = [_controller modelDelegate];
		if ([delegate respondsToSelector:@selector(willShowContextMenu:forCompView:firstTime:)]) {
			[delegate willShowContextMenu:_contextMenu forCompView:self firstTime:firstTime];
		}
		_contextMenuWasInited = YES;
        
        if ([NSMenu respondsToSelector:@selector(popUpContextMenu:withEvent:forView:withFont:)]) {
            [NSMenu popUpContextMenu:_contextMenu withEvent:theEvent forView:self
						withFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        } else {
            [NSMenu popUpContextMenu:_contextMenu withEvent:theEvent forView:self];
        }
	}
}

#if !defined(__COCOTRON__)
- (void)otherMouseDown:(NSEvent *)theEvent
{
    BOOL ctrlDown = (([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO);
    BOOL cmdDown  = (([theEvent modifierFlags] & NSCommandKeyMask) ? YES : NO);
	int buttonNumber = [theEvent buttonNumber];
    
	if (buttonNumber == 2) {
        if (ctrlDown || cmdDown)
            [self trackMouseForZoomingWithEvent:theEvent];
        else {
            // middle button press acts same as spacebar pressed, i.e. start pan
            
            if (_mouseDown && !_spacebarIsPressed) {
                _shouldStartPan = YES;
            }
            _spacebarIsPressed = YES;
            [self mouseDown:theEvent];
        }
	}
}
#endif

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	[self mouseDragged:theEvent];
}

#if !defined(__COCOTRON__)
- (void)otherMouseUp:(NSEvent *)theEvent
{
	if ([theEvent buttonNumber] == 2) {
		_spacebarIsPressed = NO;
	}
    [self mouseUp:theEvent];
}
#endif


- (void)mouseDown:(NSEvent *)theEvent
{
    ///BOOL altDown = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    ///BOOL shiftDown = (([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO);
    BOOL ctrlDown = (([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO);
    BOOL RMB = ([theEvent type] == NSRightMouseDown) ? YES : NO;
    
    if (RMB || ctrlDown)
        [self rightMouseDown:theEvent];

#if !defined(__LAGOON__)
	if (_nameEditor) {
		// remove editor if user clicks outside it
		if ([[self subviews] containsObject:_nameEditor]) {
			[_nameEditor removeFromSuperview];
			_nameEditor = nil;
			return;
		}
	}
#endif

    _mouseLocation = [theEvent locationInWindow];
    
	/*
    if ([theEvent clickCount] > 1) {
        NSLog(@"compositionview doubleclick");
    }
    */
	
    
    if (_spacebarIsPressed) {
        // initiate pan
        //_mouseLocation.x -= [self frame].origin.x;
        //_mouseLocation.y -= [self frame].origin.y;
                
        _originalBounds = [self bounds];
        _shouldStartPan = NO;
    }
    
	// check if the mouse click is on a connector note
	_clickedOnConnectorNote = NO;
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    EDUICompConnector *conn;
	NSRect connNoteRect;
	NSPoint pointInView = [self convertPoint:_mouseLocation fromView:nil];

    while (conn = [connEnum nextObject]) {
		if ([conn note]) {
			// if connector has a note, check if the mouse click is within it
			connNoteRect = [conn noteRect];
			if (NSMouseInRect(pointInView, connNoteRect, NO)) {
				_currConn = conn;
				_clickedOnConnectorNote = YES;
				break;
			}
		}
    }
	
    // let the delegate handle this click if it wants
    if ([[_controller modelDelegate] respondsToSelector:@selector(mouseDownInCompView:event:)]) {
        BOOL didHandle = [[_controller modelDelegate] mouseDownInCompView:self event:theEvent];
        if (didHandle)
            return;
    }
    
	// clear selection if necessary
	if (!_spacebarIsPressed && !_clickedOnConnectorNote)
        [self clearSelection];
    
    _makingConnection = NO;             // if a connection is being made from an output (by rmb-clicking),
    _makingConnectionFromOutput = nil;   // the user can cancel by clicking the background

    _mouseDown = YES;
}


- (void)mouseUp:(NSEvent *)theEvent
{
    _mouseDown = NO;

	if (_clickedOnConnectorNote) {
		EDUICompInputView *inp = [_currConn toInput];
		id node = [[inp nodeView] node];
		int inpIndex = [inp index];
		if ([inp isParameter]) {
			if ([node respondsToSelector:@selector(setConnectorNotePosition:forParameterInputAtIndex:)]) {
				[node setConnectorNotePosition:[_currConn notePosition] forParameterInputAtIndex:inpIndex];
			}
		} else {
			// this input is not a parameter input
			if ([node respondsToSelector:@selector(setConnectorNotePosition:forInputAtIndex:)]) {
				[node setConnectorNotePosition:[_currConn notePosition] forInputAtIndex:inpIndex];
			}
		}
		_clickedOnConnectorNote = NO;
	}

    if (_isBoxSelecting) {
        _isBoxSelecting = NO;
        [self setNeedsDisplay:YES];
    }
    // check if the view was panned with spacebar
    if (_didPan) {
        _didPan = NO;
        
        NSRect newBounds = [self bounds];
        if ( !NSEqualRects(_originalBounds, newBounds)) {
            NSPoint offset = NSMakePoint(_originalBounds.origin.x - newBounds.origin.x, _originalBounds.origin.y - newBounds.origin.y);
            
            // invalidate connectors' cached drop rects
            [_connectors makeObjectsPerformSelector:@selector(nodesWereMoved)];
            
            [_controller compViewWasPannedByOffset:offset];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (_clickedOnConnectorNote) {
		NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		float pos = [_currConn positionAtPoint:location];
		[_currConn setNotePosition:pos];
		
		[self setNeedsDisplay:YES];
	}
    else if (_spacebarIsPressed && _mouseDown) {
        NSPoint location = [theEvent locationInWindow];
        NSRect bounds = [self bounds];
        _didPan = YES;

        if (_shouldStartPan) {
            _mouseLocation = location;
            _originalBounds = bounds;
            _originalBgOffset = _bgOffset;
            _shouldStartPan = NO;
        }
        else {
            bounds.origin.x = _originalBounds.origin.x - (location.x - _mouseLocation.x);
            bounds.origin.y = _originalBounds.origin.y - (location.y - _mouseLocation.y);
            
            _bgOffset.x = _originalBgOffset.x - (location.x - _mouseLocation.x);
            _bgOffset.y = _originalBgOffset.y - (location.y - _mouseLocation.y);

            [self setBounds:bounds];            
            [self setNeedsDisplay:YES];
            
            // this is not the right method to call, but it does the right thing
            // (informing the model delegate that it needs to update its overlays)
            [_controller compViewSelectedNodesWereMoved];
        }
    }
    else if (_mouseDown) {
        NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        if (!_isBoxSelecting) {
            // start box selection mode
            _isBoxSelecting = YES;
            
            NSPoint orig = [self convertPoint:_mouseLocation fromView:nil];
            _selectionBox.origin.x = orig.x;
            _selectionBox.origin.y = orig.y;
        }
        
        _selectionBox.size.width =  location.x - _selectionBox.origin.x;        
        _selectionBox.size.height = location.y - _selectionBox.origin.y;
        
        NSEnumerator *nodeViewEnum = [[self subviews] objectEnumerator];
        EDUICompNodeView *nodeView;
        NSRect frame;
        NSRect selRect = AbsoluteRect(_selectionBox);
        
        while (nodeView = [nodeViewEnum nextObject]) {
            frame = [nodeView frame];
            frame = NSInsetRect(frame, 4.0f, 6.0f);   // inset a bit to make selection more "snappy"
            
            if (NSContainsRect(selRect, frame)) {
                if (![_selection containsObject:nodeView])
                    [self addToSelection:nodeView];
            }
            else {
                if ([_selection containsObject:nodeView])
                    [self removeFromSelection:nodeView];            
            }
        }
        
        [self setNeedsDisplay:YES];
    }
}

- (void)initiateConnectionFromOutput:(EDUICompInputView *)inputView
{
    _makingConnection = YES;
    _makingConnectionFromOutput = inputView;
    //NSLog(@"init connection");
}

- (void)initiateConnectionSwitchFromInput:(EDUICompInputView *)inputView
{
    //NSLog(@"TODO: edocompview initiateconnectionswitch");
}


- (BOOL)makingConnection {
    return _makingConnection; }

    
- (void)finishConnectionToInput:(EDUICompInputView *)inputView
{
    EDUICompConnector *tempConn;
    
    if (!_makingConnection)
        return;
    
    if ([inputView setConnected:YES toOutputView:_makingConnectionFromOutput]) {
        tempConn = [[EDUICompConnector alloc] init];
        [tempConn connectFrom:_makingConnectionFromOutput to:inputView];
        [_connectors addObject:[tempConn autorelease]];
        
        [_controller addToModelConnectionFrom:_makingConnectionFromOutput to:inputView];
        [_controller finishedModifyingModel];
    }
    [_makingConnectionFromOutput setHighlighted:NO];
    [_makingConnectionFromOutput setNeedsDisplay:YES];
    [inputView setHighlighted:NO];
    [inputView setNeedsDisplay:YES];
    
    [self setNeedsDisplay:YES];
    _makingConnection = NO;
    _makingConnectionFromOutput = nil;
}


- (NSMutableArray *)_collectAllNodeOutputViews
{
    NSEnumerator *enumerator, *outputEnum;
    EDUICompNodeView *nodeView;
    EDUICompInputView *outputView;

    NSMutableArray *allOutputs = [NSMutableArray arrayWithCapacity:32];
    enumerator = [[_controller nodeViews] objectEnumerator];
    while (nodeView = [enumerator nextObject]) {
        outputEnum = [[nodeView outputViews] objectEnumerator];
        while (outputView = [outputEnum nextObject])
            [allOutputs addObject:outputView];
    }
    return allOutputs;
}


- (void)trackMouseForOutputsWithCallbackTarget:(id)target
{
    NSEnumerator *outputEnum;
    EDUICompInputView *outputView, *hitView;
    EDUICompInputView *prevHit = nil;
    NSPoint curPoint;
    NSEvent *theEvent;

    // creates list of all outputs in the composition
    _allOutputs = [[self _collectAllNodeOutputViews] retain];
    
    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		if (!theEvent)
			break;
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        outputEnum = [_allOutputs objectEnumerator];
        while (outputView = [outputEnum nextObject]) {
            hitView = (EDUICompInputView *)[outputView hitTest:[[outputView superview]
                                                                    convertPoint:curPoint
                                                                    fromView:self]
                                                        ];
            if (hitView != nil && hitView != prevHit) {
                [target mouseEnteredOutputView:hitView withEvent:theEvent];
                prevHit = hitView;
            }
            else if (hitView == nil && prevHit) {
                [target mouseExitedOutputView:prevHit withEvent:theEvent];
                prevHit = nil;
            }
        }
    }

    [_allOutputs release];    
    _allOutputs = nil;
}


- (void)trackMouseForZoomingWithEvent:(NSEvent *)theEvent
{
    id comp = (id)[_controller nodeGraph];
    if ( ![comp respondsToSelector:@selector(globalScaleFactor)]) {
        NSLog(@"eduicompview -trackmouseforzoom: this graph doesn't implement -globalScaleFactor");
        return;
    }

    NSPoint p = [theEvent locationInWindow];

	double zoomAmount = 0.03;
    
    NSUInteger eventMask = (NSLeftMouseDraggedMask | NSLeftMouseUpMask);
#if !defined(__COCOTRON__)
    eventMask |= (NSOtherMouseDraggedMask | NSOtherMouseUpMask);
#endif

    while (1) {
        theEvent = [[self window] nextEventMatchingMask:eventMask];
		if (!theEvent)
			break;
        if ([theEvent type] == NSLeftMouseUp
#if !defined(__COCOTRON__)
         || [theEvent type] == NSOtherMouseUp
#endif
        )
            break;
        
        NSPoint newP = [theEvent locationInWindow];
        float offY = newP.y - p.y;
        
        if (fabsf(offY) > 0.001) {
            float oldScale = [comp globalScaleFactor];
            double m = 1.0 + zoomAmount * offY;
            double newScale = oldScale * m;
            
            // sanity limits
            if (newScale >= 0.1 && newScale <= 3.0) {
                [_controller setGraphZoomFactor:newScale];
                [self setNeedsDisplay:YES];
            }
        }
        p = newP;
    }
}


  // this method is called by an inputview when it's clicked;
  // handles connecting output->input, and disconnecting
- (void)trackMouseForConnectionWithEvent:(NSEvent *)theEvent fromOutputAtIndex:(int)outpIndex inNodeView:(EDUICompNodeView *)outpNodeView
{
    EDUICompConnector *tempConn;
    EDUICompInputView *tempInput;
    NSPoint curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSEnumerator *enumerator, *inputEnum;
    EDUICompNodeView *aNodeView;
    EDUICompInputView *anInputView, *prevHighlighted = nil;
    EDUICompInputView *hitView = nil;
    NSMutableArray *allInputs;

    const BOOL delegateReplacesConnectors = [[_controller modelDelegate] respondsToSelector:@selector(customConnectorForConnectionFromOutputView:toInputView:)];

    // must double-check that we have the proper node view object
    // (the one we were given as argument might have been wiped out by the controller!)
    outpNodeView = [_controller findNodeViewWithNode:[outpNodeView node]];
    EDUICompInputView *inputView = [outpNodeView outputViewAtIndex:outpIndex];

    [inputView retain];
    [inputView setHighlighted:YES];
    [inputView setNeedsDisplay:YES];

    const BOOL isHoriz = [outpNodeView usesHorizontalLayout];
    double yOffsetForDst = (isHoriz) ? 0.0 : -16.0;
    ///NSLog(@"%s: is horiz %i", __func__, isHoriz);
    
    tempInput = [[EDUICompInputView alloc]
                    initWithFrame:NSMakeRect(curPoint.x, curPoint.y + yOffsetForDst,  16.0, 16.0)
                    inView:nil index:0 isOutput:NO type:0];    
    

    tempConn = (delegateReplacesConnectors) ? [[_controller modelDelegate] customConnectorForConnectionFromOutputView:inputView toInputView:tempInput]
                                            : [[[EDUICompConnector alloc] init] autorelease];    
    [tempConn retain];
    
    if ( !delegateReplacesConnectors) {
        [tempConn connectFrom:inputView to:tempInput];
    }
    
    [tempConn setDrawToOrigin:YES];
    [_connectors addObject:tempConn];
    
    [self addSubview:tempInput];
    [tempInput setHidden:YES];
    
    // creates list of all inputs in the composition; used for testing connections
    allInputs = [[NSMutableArray arrayWithCapacity:32] retain];
    enumerator = [[_controller nodeViews] objectEnumerator];
    while (aNodeView = [enumerator nextObject]) {
        inputEnum = [[aNodeView inputViews] objectEnumerator];	// add inputs
        while (anInputView = [inputEnum nextObject])
            [allInputs addObject:anInputView];
        inputEnum = [[aNodeView parameterViews] objectEnumerator]; // add parameter inputs
        while (anInputView = [inputEnum nextObject])
            [allInputs addObject:anInputView];
    }

    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		if (!theEvent)
			break;
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil ];
        BOOL highlight = NO;
        
        inputEnum = [allInputs objectEnumerator];
        while (anInputView = [inputEnum nextObject])
        {
            /*hitView = (EDUICompInputView *)[anInputView hitTest:[[anInputView superview]
                                                                    convertPoint:curPoint
                                                                    fromView:self ] ];
            */
            NSRect hitRect = [self convertRect:[anInputView bounds] fromView:anInputView];
            
            // let's enlargen hitRect to make the inputs easier to hit
            float xOff = -10;
            float yOff = -8;
            float wOff = 20;
            float hOff = 14;
            int inpCount = [[[anInputView nodeView] inputViews] count];
            if (inpCount > 1) {
                int index = [anInputView index];
                if (index == 0) {
                    wOff = 12;
                } else if (index == inpCount-1) {
                    xOff = -4; wOff = 14;
                } else {
                    xOff = -3;  wOff = 8;
                }
            }            
            hitRect.origin.x += xOff;
            hitRect.origin.y += yOff;
            hitRect.size.width += wOff;
            hitRect.size.height += hOff;
            hitView = NSMouseInRect(curPoint, hitRect, NO) ? anInputView : nil;
                                    
            if (hitView != nil) {
                highlight = YES;
                /*
                if ([hitView isParameter]) {
                    EDUICompNodeView *nodeView = [hitView nodeView];
                    NSEnumerator *enumerator = [[nodeView listOfVisibleParameters] objectEnumerator];
                    NSString *hitInputName = [hitView name];
                    NSString *name;
                    
                    BOOL visible = NO;
                    while (name = [enumerator nextObject]) {
                        if ([name isEqualToString:hitInputName]) {
                            visible = YES;
                            break;
                        }
                    }
                    if (!visible) {
                        highlight = NO;
                    }
                }
                */
                // above is old code, not necessary anymore now that hidden inputviews are truly setHidden
                if (highlight) {
                    [hitView setHighlighted:YES];
                    [hitView setNeedsDisplay:YES];
                }
                break;
            }
        }
        if (![hitView isEqual:prevHighlighted]) {
            if (prevHighlighted != nil) {
                [prevHighlighted setHighlighted:NO];
                [prevHighlighted setNeedsDisplay:YES];
                prevHighlighted = nil;
                [self displayNameForInputView:nil withPosition:0];
            }
        }
        prevHighlighted = hitView;
        if (highlight) {
            NSInteger labelPosition = (isHoriz) ? EDUILeft : (([hitView isParameter]) ? EDUIRight : EDUIUp);
        	[self displayNameForInputView:hitView withPosition:labelPosition];
            
            //NSLog(@"highlighted hitview: %@ (name %@, isParam %i - labelpos %i)", hitView, [hitView name], [hitView isParameter], labelPosition);
        }

        /*NSRect visRect = [self visibleRect];
        curPoint.x -= visRect.origin.x;
        curPoint.y -= visRect.origin.y;*/
        
        curPoint.y += yOffsetForDst;    // offset by input height
        [tempInput setFrameOrigin:curPoint];
        
        [self setNeedsDisplay:YES];
    }

    [inputView setHighlighted:NO];
    [inputView setNeedsDisplay:YES];
    [inputView release];

    [hitView setHighlighted:NO];
    [hitView setNeedsDisplay:YES];

    [self displayNameForInputView:nil withPosition:0];    
    
    [_connectors removeLastObject];
    [tempConn release];
    [tempInput removeFromSuperview];
    [tempInput release];
    [allInputs release];
    
    if (hitView != nil) {
        BOOL didModify = NO;
    
        if ([hitView isConnectedInput]) {
            [hitView setConnected:NO toOutputView:nil];
            [_controller disconnectInput:hitView];
            didModify = YES;
        }
        if ([hitView setConnected:YES toOutputView:inputView]) {
            ///tempConn = [[[EDUICompConnector alloc] init] autorelease];
            
            tempConn = (delegateReplacesConnectors) ? [[_controller modelDelegate] customConnectorForConnectionFromOutputView:inputView toInputView:tempInput]
                                                    : [[[EDUICompConnector alloc] init] autorelease];
            
            [tempConn connectFrom:inputView to:hitView];
            [_connectors addObject:tempConn];
            [_controller addToModelConnectionFrom:inputView to:hitView];
            didModify = YES;
        }
        if (didModify) {
            [_controller finishedModifyingModel];        
        }
    }

    [self setNeedsDisplay:YES];
}



- (void)disconnectInput:(EDUICompInputView *)input
{
    [input setConnected:NO toOutputView:nil];
    [_controller disconnectInput:input];
    [_controller finishedModifyingModel];
}

- (NSPoint)originForNewNodeView
{
    NSPoint point = [self bounds].origin;
    point.x += 10.0;
    point.y += 10.0;
    return point;
}


#pragma mark --- messages from the viewcontroller ---

- (void)controllerDidRecreateNodeViews
{
    // if a list of outputs has been cached (which is done in -trackMouseForOutputs...), must recreate it
    if (_allOutputs) {
        [_allOutputs release];
        _allOutputs = [[self _collectAllNodeOutputViews] retain];
    }
    
    if ([_connectorsWithinSelection count] > 0) {
		[_connectorsWithinSelection removeAllObjects];  // not sure if this is the right thing to do here?
		
        ///NSLog(@"** warning: compview nodeviews were recreated while selection was active, should recreate the selection conn list");
    }
}

- (void)controllerDidResetNodeGraph
{
    [self setBoundsOrigin:NSMakePoint(0, 0)];
	
	[self _createDefaultContextMenu];  // the new node graph may want a different context menu
}


#pragma mark --- drag&drop settings ---

- (void)setSupportedPboardTypesForDragReceive:(NSArray *)array
{
    [_dragPboardTypes release];
    _dragPboardTypes = (array) ? [array copy] : [NSArray array];

#if !defined(__LAGOON__)
    [self registerForDraggedTypes:_dragPboardTypes];
#endif
}


- (NSArray *)supportedPboardTypesForDragReceive
{
    return _dragPboardTypes; }


#if !defined(__LAGOON__)

#pragma mark --- NSDraggingDestination protocol ---

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	_prevDragPoint = NSMakePoint(-99999, -99999);
	_prevDragConnector = nil;
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	// check for drop on noodles
	if ([[_controller modelDelegate] respondsToSelector:@selector(inputView:acceptsConnectorDropOfType:list:)]) {
		NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
		
		if (NSEqualPoints(point, _prevDragPoint)) {
			return NSDragOperationCopy;  // we've already checked this point, no need to do it again
		}
		_prevDragPoint = point;
		
		EDUICompConnector *dropConn = [self connectorAtPoint:point];

		if (_prevDragConnector && _prevDragConnector != dropConn) {
			[_prevDragConnector setHighlighted:NO];
			[self setNeedsDisplay:YES];
			_prevDragConnector = nil;
		}

		if (dropConn) {
			NSPasteboard *pboard = [sender draggingPasteboard];
            NSString *pbType = [[pboard types] objectAtIndex:0];
            NSArray *plist = (NSArray *)[pboard propertyListForType:pbType];
            
            BOOL dropIsOk = [[_controller modelDelegate] inputView:[dropConn toInput]
                                                         acceptsConnectorDropOfType:pbType list:plist];
            if (dropIsOk) {
                [dropConn setHighlighted:YES];
                [self setNeedsDisplay:YES];
                _prevDragConnector = dropConn;
            }
		}
	}

    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    // don't need to do anything here
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    BOOL result = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSPoint mouseLocation = [sender draggingLocation];
    //NSPoint imageLocation = [sender draggedImageLocation];
    
    NSRect visRect = [self visibleRect];
    mouseLocation.x += visRect.origin.x;
    mouseLocation.y += visRect.origin.y;
	
	// check for drop on a connector
	EDUICompConnector *dropConn = [self connectorAtPoint:[self convertPoint:[sender draggingLocation] fromView:nil]];
	
	// unhighlight all connectors
    NSEnumerator *connEnum = [_connectors objectEnumerator];
    EDUICompConnector *conn;
    while (conn = [connEnum nextObject]) {
		[conn setHighlighted:NO];
	}

#ifdef __APPLE__  // 2010.04.26 -- not supported on Cocotron
	// special handling for URL drags
	///BOOL finished = NO;
	if ([[pboard types] containsObject:NSURLPboardType] &&
		[[_controller modelDelegate] respondsToSelector:@selector(compViewReceivedDragOfURL:atPoint:)]) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        
		result = [[_controller modelDelegate] compViewReceivedDragOfURL:fileURL atPoint:mouseLocation];
        
        return result;  // exit here
    }
#endif
	///if (finished) return YES;
	
	// iterate types
    NSEnumerator *typeEnum = [_dragPboardTypes objectEnumerator];
    NSString *pbType;
    while (pbType = [typeEnum nextObject]) {
        if ([[pboard types] containsObject:pbType]) {
            NSArray *plist = (NSArray *)[pboard propertyListForType:pbType];
            
            // offset image drop
            //mouseLocation.x = floor(mouseLocation.x) - 51.0;  // *** was 40.0 in Edo.....
            //mouseLocation.y = floor(mouseLocation.y) - 5.0;
            
            NSSet *newNodes =
					[[_controller modelDelegate] compViewReceivedDragOfType:pbType list:plist atPoint:mouseLocation];
			
			BOOL dropIsOk = NO;
			if (dropConn) {
				dropIsOk = [[_controller modelDelegate] inputView:[dropConn toInput]
															 acceptsConnectorDropOfType:pbType list:plist];
			}
			
			if (dropIsOk && newNodes && [newNodes count] > 0) {
				EDUICompInputView *from = [dropConn fromOutput];
				EDUICompInputView *to   = [dropConn toInput];
				
				// get nodeviews for the newly created nodes
				NSMutableSet *setOfViews = [NSMutableSet setWithCapacity:[newNodes count]];
				NSEnumerator *nodeEnum = [newNodes objectEnumerator];
				id <NSObject, EDUINodeGraphConnectable> node;
				while (node = [nodeEnum nextObject]) {
					id nodeView = [_controller findNodeViewWithNode:node];
					if (nodeView)
						[setOfViews addObject:nodeView];
				}
				
				[_controller connectNodes:setOfViews betweenOutput:from andInput:to];
				[_controller finishedModifyingModel];
				[_controller makeNodeViews];
			}
            else if (newNodes && [newNodes count] > 0) {
                // if some nodes were created, call this anyway to trigger possible UI/undo update
                [_controller willModifyModel];
                [_controller finishedModifyingModel];
            }
            
            [[self window] makeFirstResponder:self];
            
            result = YES;
        }
    }
    return result;
    
    /*
    if ([[pboard types] containsObject:EDUIImageSourcePboardType]) {
        NSArray *plist = (NSArray *)[pboard propertyListForType:EDUIImageSourcePboardType];
        
        // offset image drop
        mouseLocation.x = floor(mouseLocation.x) - 40.0;
        mouseLocation.y = floor(mouseLocation.y) - 5.0;
        
        [_controller receiveDraggedImageSources:plist atPoint:mouseLocation];
        return YES;
    }
    else if ([[pboard types] containsObject:EDUIOperatorPboardType]) {
        NSArray *plist = (NSArray *)[pboard propertyListForType:EDUIOperatorPboardType];
    
        // offset image drop
        mouseLocation.x = floor(mouseLocation.x) - 40.0;
        mouseLocation.y = floor(mouseLocation.y) - 5.0;
    
        [_controller receiveDraggedOperators:plist atPoint:mouseLocation];
        return YES;
    }
    */
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    // documentation says UI should be updated here if necessary
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    // documentation for Panther says this method has not yet been implemented 
}

#endif // !__LAGOON__

@end
