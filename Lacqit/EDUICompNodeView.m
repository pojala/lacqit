//
//  EDUICompNodeView.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUICompNodeView.h"
#import "EDUINodeGraphConnectable.h"
#import "EDUIDiscTriangle.h"
#import "EDUICompositionView.h"
#import "EDUICompInputView.h"


static NSShadow *gDefaultNodeShadow = nil;


@implementation EDUICompNodeView

+ (Class)compInputViewClass
{
    return [EDUICompInputView class];
}

+ (NSDictionary *)nodeLabelTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        NSFont *font = [NSFont systemFontOfSize:10.0];
        attribs = [ [NSMutableDictionary alloc] init];
        [attribs setObject:font forKey:NSFontAttributeName];
    }
    return attribs;
}

+ (NSDictionary *)whiteNodeLabelTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        NSFont *font = [NSFont systemFontOfSize:10.0];
        attribs = [ [NSMutableDictionary alloc] init];
        [attribs setObject:font forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.92 green:0.92 blue:0.92 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
    }
    return attribs;
}

+ (NSDictionary *)parameterLabelTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        NSFont *font = [NSFont systemFontOfSize:9.0];
        attribs = [ [NSMutableDictionary alloc] init];
        [attribs setObject:font forKey:NSFontAttributeName];    
    }
    return attribs;
}

+ (NSDictionary *)whiteParameterLabelTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        NSFont *font = [NSFont systemFontOfSize:9.0];
        attribs = [ [NSMutableDictionary alloc] init];
        [attribs setObject:font forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.92 green:0.92 blue:0.92 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
    }
    return attribs;
}

#pragma mark --- init ---

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _selected = NO;
        _selectionOffset = NSMakePoint(0.0, 0.0);
        _rounding = 12.0;
        _zoomFactor = 1.0;
        [self calcDimensions];

        /*
        _selColor = [EDUIColorController selectedItemColor];
        _unselColor = [EDUIColorController nodeColor];
        
        if (_nodeType == type_treeRoot) {
            _label = [ [NSMutableAttributedString alloc]
                        initWithString:[_rootNode type] attributes:[EDUICompNodeView nodeLabelTextAttributes]];
        }
        else {
            _label = [ [NSMutableAttributedString alloc]
                        initWithString:[_node name]
                        attributes:[EDUICompNodeView nodeLabelTextAttributes]];
        }
        */
        //NSLog(@"  %@ %@", [_node type], [_node name] );
        /*_label = [ [NSMutableAttributedString alloc]
                        initWithString:[_node name]
                        attributes:[EDUICompNodeView nodeLabelTextAttributes]];
        */
        _label = [[_node name] retain];
    }
    return self;
}

- (void)dealloc
{
#if !defined(__LAGOON__)
	if (_trackRectTag != 0) {
		[self removeTrackingRect:_trackRectTag];
		//NSLog(@"track rect removed on nodeview dealloc, %p (%@)", self, [_node name]);
		_trackRectTag = 0;
	}
#endif

    //NSLog(@"nodeview dealloc, %@", [_node name]);
    [_label release];
    [_node release];
    [_inputViews release];
    [_outputViews release];
    [_parameterViews release];
    [_parameterLabels release];
    
    [_selColor release];
    [_unselColor release];
	[_contextMenu release];
    
    [super dealloc];
}

- (id)initWithNode:(id <NSObject, EDUINodeGraphConnectable>)node
{
    NSRect frame;
    EDUIDiscTriangle *tri;
    EDUICompInputView *inp;
    NSInteger i;

    if (!node) {
        NSLog(@"*** warning: attempt to create nodeView for nil");
        [self autorelease];
        return nil;
    }

    _node = [node retain];
    
    _inputCount = [node inputCount];
    _outputCount = [node outputCount];
    _parameterCount = [node parameterCount];
    
    ///NSLog(@"node %@ (%p), inpcount %i", [node name], node, _inputCount);
    
    if ([_node respondsToSelector:@selector(nodeAppearanceFlags)]) {
        _parametersVisible = ([(id)_node nodeAppearanceFlags] & EDUICompNodeParamsVisible) ? YES : NO;
    } else
        _parametersVisible = NO;
    
    NSPoint center = NSZeroPoint;
    if ([_node respondsToSelector:@selector(centerPoint)]) {
        center = [(id<EDUINodeGraphConnectableAppearanceMethods>)_node centerPoint];
    }

    NSArray *visParams = [self listOfVisibleParameters];
    frame.size = [self calcFrameSizeForParamCount:[visParams count]];
    
    frame.origin.x = center.x - frame.size.width * 0.5;
    frame.origin.y = center.y - frame.size.height * 0.5;
    
    //NSLog(@"----- node '%@': computed frame %@; saved center %@; paramsvis %i (count %i)",
      //          [node name], NSStringFromRect(frame), NSStringFromPoint(center), _parametersVisible, (int)[visParams count]);
    
    [self initWithFrame:frame];
    
    // get scale from node, if supported
    if ([_node respondsToSelector:@selector(scaleFactor)]) {
        _zoomFactor = [(id<EDUINodeGraphConnectableAppearanceMethods>)_node scaleFactor];
    }
    
    // make parameter inputs as necessary
    if (_parameterCount > 0) {
        // node has parameters, so cast to the monstrously named formal protocol
        id <EDUINodeGraphConnectable, EDUINodeGraphConnectableParameterMethods> pnode = (id <EDUINodeGraphConnectable, EDUINodeGraphConnectableParameterMethods>)_node;
    
        // make parameter inputs - labels are made when disc triangle is actually clicked
        _parameterViews = [[NSMutableArray arrayWithCapacity:_parameterCount] retain];
        _parameterLabels = [[NSMutableArray arrayWithCapacity:_parameterCount] retain];
        
		BOOL hasParamsWithInputs = NO;
        for (i = 0; i < _parameterCount; i++) {
            /*EDUINodeValueType newType = 0;
            
            if ([param acceptsFloatMap]) {
                newType = type_floatMap;
            }
            else if ([param parameterType] == paramType_floatScalar) {
                newType = type_floatValue;
            }
            */
            NSUInteger newType = 0;
            BOOL hasInput = [pnode parameterHasInputAtIndex:i];
            
            if (hasInput) {
                newType = [pnode typeOfParameterInputAtIndex:i];
				hasParamsWithInputs = YES;
			}
                
            if (newType) {
                NSString *paramName = [pnode nameOfParameterAtIndex:i];
                inp = [ [[[[self class] compInputViewClass] alloc]
                            initWithFrame:[self rectForParameterAtIndex:i]
                            inView:self index:i isOutput:NO type:newType] autorelease];
                [inp setIsParameter:YES name:paramName];
                [_parameterViews addObject:inp];

                //NSLog(@"created param view: %@", paramName);
            }
        }
		
		if (hasParamsWithInputs) {
			tri = [ [[EDUIDiscTriangle alloc]
					initWithFrame:NSMakeRect(_width-16.0, _firstTextLinePoint.y,  10.0,10.0)] autorelease];
			[self addSubview:tri];
			[tri setTarget:self];
			[tri setAction:@selector(discloseParametersAction:) ];
			[tri setAutoresizingMask:NSViewMinYMargin];
            _discTriangleView = tri;
            
            if (_parametersVisible)
                [tri setOpened:YES];
		}
        
        [self resizeToShowParameters];
    }
    
    // make inputs
    _inputViews = [[NSMutableArray arrayWithCapacity:_inputCount] retain];
    
    for (i = 0; i < _inputCount; i++) {
        NSUInteger inputType = [_node typeOfInputAtIndex:i];
        NSString *inputName = [_node nameOfInputAtIndex:i];
        
        inp = [[[[[self class] compInputViewClass] alloc]
                    initWithFrame:[self rectForInputAtIndex:i]
                    inView:self index:i isOutput:NO type:inputType] autorelease];
        [inp setIsParameter:NO name:inputName];
        [self addSubview:inp];
        [_inputViews addObject:inp];

        //NSLog(@"created inputview: %@", inputName);
    }
    
    // make outputs
    _outputViews = [[NSMutableArray arrayWithCapacity:_outputCount] retain];
    
    for (i = 0; i < _outputCount; i++) {
        NSUInteger outputType = [_node typeOfOutputAtIndex:i];
        NSString *outputName = [_node nameOfOutputAtIndex:i];
    
        inp = [[[[[self class] compInputViewClass] alloc]
                    initWithFrame:[self rectForOutputAtIndex:i]
                    inView:self index:i isOutput:YES type:outputType] autorelease];
        [inp setIsParameter:NO name:outputName];
        [self addSubview:inp];
        [_outputViews addObject:inp];

        //NSLog(@"created outputview: %@", outputName);
    }

    return self;
}

#define INPUTINTERVAL 16.0
#define PARAMINPUTINTERVAL 16.0

- (NSRect)rectForInputAtIndex:(NSInteger)index
{
    const double c = (double)_inputCount;
    const double inputInterval = INPUTINTERVAL;
    NSRect r;
    
    if ( !_usesHorizLayout) {
        // Conduit-style vertical layout
        double x = _xMidpoint - (inputInterval/2.0)*(c-1) - 8.0;
        r = NSMakeRect(x + index*inputInterval, _height - 8.0,  16.0, 16.0);
    } else {
        // stream-style horizontal layout
        NSSize size = [self bounds].size;
        double labelH = _firstTextLineH;
        
        double y = (size.height/2.0) + (inputInterval/2.0)*(c-1) - 8.0;
        
        r =  NSMakeRect(0,  y - labelH - index*inputInterval,  16.0, 16.0);
        ///NSLog(@" input %i / %i: rect is %@ (h %.1f, labelH %.1f, y %.1f)", index, _inputCount, NSStringFromRect(r), size.height, labelH, y);
    }
    return r;
}
- (NSRect)rectForOutputAtIndex:(NSInteger)index
{
    const double c = (double)_outputCount;
    const double inputInterval = INPUTINTERVAL;
    NSRect r;
    
    if ( !_usesHorizLayout) {
        // Conduit-style vertical layout
        double x = _xMidpoint - (inputInterval/2.0)*(c-1) - 8.0;
        r = NSMakeRect(x + index*inputInterval, -2.0,  16.0, 16.0);
    } else {
        // stream-style horizontal layout
        NSSize size = [self bounds].size;
        double labelH = _firstTextLineH;
        
        double y = (size.height/2.0) + (inputInterval/2.0)*(c-1) - 8.0;
        
        r = NSMakeRect(size.width - 16.0,  y - labelH - index*inputInterval,  16.0, 16.0);
        ///NSLog(@" outp %i / %i: rect is %@ (h %.1f, labelH %.1f, y %.1f)", index, _outputCount, NSStringFromRect(r), size.height, labelH, y);
    }
    return r;
}

- (NSRect)rectForParameterAtIndex:(NSInteger)index
{
    double y = _height - 26.0 - (double)index*PARAMINPUTINTERVAL;
    return NSMakeRect(_width - 10.0, y,  16.0, 16.0);
}

- (NSPoint)positionForParameterLabelAtIndex:(NSInteger)index
{
    double x = 12.0;
    double y = _height - 24.0 - (double)index*PARAMINPUTINTERVAL;
    #if defined(__LAGOON__)
    y += 13.0;
    #endif
    
    return NSMakePoint(x, y);
}

- (void)_relayoutConnectors
{
    NSEnumerator *inpEnum = [_inputViews objectEnumerator];
    EDUICompInputView *inpView;
    NSInteger i = 0;
    while (inpView = [inpEnum nextObject]) {
        [inpView setFrame:[self rectForInputAtIndex:i++]];
    }
    
    inpEnum = [_outputViews objectEnumerator];
    i = 0;
    while (inpView = [inpEnum nextObject]) {
        [inpView setFrame:[self rectForOutputAtIndex:i++]];
    }
}


- (BOOL)usesHorizontalLayout {
    return _usesHorizLayout; }
    
- (void)setUsesHorizontalLayout:(BOOL)f
{
    if (f != _usesHorizLayout) {
        _usesHorizLayout = f;
        
        [self resizeToShowParameters];
        [self _relayoutConnectors];
        [self setNeedsDisplay:YES];
    }
}



#pragma mark --- accessors ---

- (id<NSObject, EDUINodeGraphConnectable>)node {
    return _node; }

- (NSMutableArray *)inputViews {
    return _inputViews; }

- (NSMutableArray *)parameterViews {
    return _parameterViews; }
	
- (NSMutableArray *)outputViews {
	return _outputViews; }

- (EDUICompositionView *)compView {
    return _compView; }
    
- (void)setCompView:(EDUICompositionView *)compView {
    _compView = compView; }

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label retain]; /*[ [NSMutableAttributedString alloc]
                        initWithString:label
                        attributes:[EDUICompNodeView nodeLabelTextAttributes]];*/

    [self setNeedsDisplay:YES];
}

- (EDUICompInputView *)inputViewAtIndex:(NSInteger)index {
    //NSLog(@"compnodeview inputviewatindex: %i (inputcount %i)", index, _inputCount);
    if (index >= _inputCount)
        return nil;
    return [_inputViews objectAtIndex:index];
}

- (EDUICompInputView *)outputViewAtIndex:(NSInteger)index {
    //NSLog(@"compnodeview outputviewatindex: %i (outputcount %i)", index, _outputCount);
    if (index >= _outputCount)
        return nil;
    return [_outputViews objectAtIndex:index];
}

- (EDUICompInputView *)parameterViewAtIndex:(NSInteger)index {
    EDUICompInputView *inp;
    NSEnumerator *enumerator = [_parameterViews objectEnumerator];

    while (inp = [enumerator nextObject]) {
        if ([inp index] == index)
            return inp;
    }
    return nil;
}


#pragma mark --- connection handling ---

- (void)disconnectAllConnections
{
    EDUICompInputView *inp;
    NSEnumerator *enumerator;
    
    enumerator = [_inputViews objectEnumerator];
    while (inp = [enumerator nextObject])
        [_compView disconnectInput:inp];
        
    enumerator = [_parameterViews objectEnumerator];
    while (inp = [enumerator nextObject])
        [_compView disconnectInput:inp];
        
    enumerator = [_outputViews objectEnumerator];
    while (inp = [enumerator nextObject]) {
        NSArray *conInps = [inp connectedInputViews];
        EDUICompInputView *cinp;
        NSEnumerator *enum2 = [conInps objectEnumerator];
        while (cinp = [enum2 nextObject])
            [_compView disconnectInput:cinp];
    }
}


#pragma mark --- selection handling ---

- (void)setSelected {
    _selected = YES;
    [self setNeedsDisplay:YES];
}

- (void)setUnselected {
    _selected = NO;
    [self setNeedsDisplay:YES];
}

- (void)setSelectionOffsetFromPoint:(NSPoint)point
{
    NSRect frame = [self frame];
    _selectionOffset = NSMakePoint(frame.origin.x - point.x,
                                   frame.origin.y - point.y );
}

- (void)moveUsingOffsetToPoint:(NSPoint)point
{
    NSRect oldFrame = [self frame];
    NSPoint newPoint = NSMakePoint(point.x + _selectionOffset.x,
                                   point.y + _selectionOffset.y );
    [self setFrameOrigin:newPoint];
    
    if ([_node respondsToSelector:@selector(setCenterPoint:)]) {
        // remove offset caused by zooming before setting node's origin point value
        ///NSPoint newOrig = NSMakePoint(newPoint.x + _zoomingOffset.x, newPoint.y + _zoomingOffset.y);
        ///[(id <EDUINodeGraphConnectableAppearanceMethods>)_node setOriginPoint:newOrig];
        //NSLog(@"setting origin %.2f, %.2f for node %p (yoff %.2f, frame %@)", newOrig.x, newOrig.y, _node, _zoomingOffset.y, NSStringFromRect([self frame]));
        
        NSPoint center = NSMakePoint(newPoint.x + oldFrame.size.width*0.5,  newPoint.y + oldFrame.size.height*0.5);
        
        [(id <EDUINodeGraphConnectableAppearanceMethods>)_node setCenterPoint:center];
    }
    
    [self setNeedsDisplay:YES];
    [_compView setNeedsDisplayInRect:oldFrame];
}

//
// actions
//

- (void)discloseParametersAction:(id)sender
{
    _parametersVisible = !_parametersVisible;
    
    if ([_node respondsToSelector:@selector(setNodeAppearanceFlags:)])
        [(id)_node setNodeAppearanceFlags:(_parametersVisible ? EDUICompNodeParamsVisible : 0)];
    
    NSRect oldFrame = [self frame];
        
    [self resizeToShowParameters];
    
    NSRect newFrame = [self frame];
    
    ///NSLog(@"%s: old frame %@, new frame %@ -- node %@, %i", __func__, NSStringFromRect(oldFrame), NSStringFromRect(newFrame),
    ///            _node, [_node respondsToSelector:@selector(setCenterPoint:)]);
    
    if ([_node respondsToSelector:@selector(setCenterPoint:)]) {
        NSPoint newPoint = newFrame.origin;        
        NSPoint center = NSMakePoint(newPoint.x + newFrame.size.width*0.5,  newPoint.y + newFrame.size.height*0.5);
        
        [(id <EDUINodeGraphConnectableAppearanceMethods>)_node setCenterPoint:center];
        
        ///NSLog(@".... node %@: saving center point %@", _node, NSStringFromPoint(center));
    }
}


- (void)resizeToShowParameters
{
    NSRect oldFrame = [self frame];
    NSEnumerator *enumerator;
    EDUICompInputView *inp;
    NSInteger i = 0;
    
    NSArray *visibleParams = [self listOfVisibleParameters];
    
    ///NSLog(@"%s: visible params %i (show: %i): %@", __func__, [visibleParams count], _parametersVisible, visibleParams);

    NSSize newBoundsSize = [self calcFrameSizeForParamCount:[visibleParams count]];

    double yOffset = round([self frame].size.height-oldFrame.size.height) * 0.5;
    double xOffset = round([self frame].size.width-oldFrame.size.width) * 0.5;
    
    NSRect newFrame;
    newFrame.size = NSMakeSize(newBoundsSize.width * _zoomFactor, newBoundsSize.height * _zoomFactor);
    newFrame.origin = NSMakePoint(oldFrame.origin.x - xOffset, oldFrame.origin.y - yOffset);
    
    [self setFrame:newFrame];
    [self setBoundsSize:newBoundsSize];
    
    [self calcDimensions];
    
    ///NSLog(@"%s: old frame %@, new frame %@, zoomfactor %.3f, newbounds %@", __func__, NSStringFromRect(oldFrame), NSStringFromRect([self frame]), _zoomFactor, NSStringFromSize(newBoundsSize));

    _zoomingOffset = NSMakePoint(xOffset, yOffset);

  // setting the origin point for the node like this isn't what we want
  
    /*if (yOffset != 0.0f && [_node respondsToSelector:@selector(setOriginPoint:)]) {
        NSPoint orig = [(id)_node originPoint];
        orig.y -= yOffset;
        
        NSLog(@"  ...offsetting node orig: %f (offset %f)", orig.y, yOffset);
        
        [(id)_node setOriginPoint:orig];
    }*/
    

    enumerator = [_inputViews objectEnumerator];
    i = 0;
    while (inp = [enumerator nextObject]) {
        [inp setFrameOrigin:[self rectForInputAtIndex:i].origin ];
        i++;
    }

    enumerator = [_outputViews objectEnumerator];
    i = 0;
    while (inp = [enumerator nextObject]) {
        [inp setFrameOrigin:[self rectForOutputAtIndex:i].origin ];
        i++;
    }
    
    [_parameterLabels removeAllObjects];
    
    i = 0;
    enumerator = [_parameterViews objectEnumerator];
    while (inp = [enumerator nextObject]) {
        BOOL thisParamVisible = NO;
        NSString *inpName = [inp name];
        
        [inp setFrameOrigin:[self rectForParameterAtIndex:i].origin ];
        
        if (_parametersVisible) {
            [self addSubview:inp];
            [inp setHidden:NO];
            i++;
            thisParamVisible = YES;
        }
        else {
            NSEnumerator *enum2 = [visibleParams objectEnumerator];
            NSString *name;
            while (name = [enum2 nextObject]) {
                if ([name isEqualToString:inpName]) {
                    thisParamVisible = YES;
                    break;
                }
            }
            if (thisParamVisible) {                
                // move this param's input to appropriate position
                [inp setFrameOrigin:[self rectForParameterAtIndex:i].origin ];
                
                if (![[self subviews] containsObject:inp]) {
                    [self addSubview:inp];
                    [inp setHidden:NO];
                }
                i++;
            }
            else {
                [inp removeFromSuperview];
                [inp setHidden:YES];
            }
        }
        
        if (thisParamVisible) {
            // make label for this parameter
/*            [ [NSMutableAttributedString alloc]
                    initWithString:inpName attributes:[EDUICompNodeView parameterLabelTextAttributes]];*/
            [_parameterLabels addObject:inpName];
        }
    }
    
    // move disc triangle to right place
    if (_discTriangleView) {
        [_discTriangleView setFrameOrigin:NSMakePoint(_width-16.0, _firstTextLinePoint.y+1.0)];
    }
    
    [self setNeedsDisplay:YES];
    [_compView setNeedsDisplay:YES];
}


- (NSArray *)listOfVisibleParameters
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:8];
    NSInteger i;
    
    if ( !_parametersVisible) {
        for (i = 0; i < _parameterCount; i++) {
            id pnode = _node;
            
            if ([pnode parameterHasInputAtIndex:i]) {
                LXInteger outpIndex;
                if ([pnode connectedNodeForParameterAtIndex:i outputIndexPtr:&outpIndex]) {
                    // parameter input is connected, so it should get displayed always
                    [array addObject:[pnode nameOfParameterAtIndex:i]];
                }
            }
        }
    }
    else {
        for (i = 0; i < _parameterCount; i++) {
            id pnode = _node;
            
            if ([pnode parameterHasInputAtIndex:i]) {
                [array addObject:[pnode nameOfParameterAtIndex:i]];
            }
        }
    }
    return array;
}


- (void)setZoomFactor:(float)z {
    _zoomFactor = z;
    
    //if (_parameterCount > 0) {
        [self resizeToShowParameters];
    //}
}

- (float)zoomFactor {
    return _zoomFactor; }


#pragma mark --- utilities ---

- (void)calcDimensions
{
    NSRect bounds = [self bounds];
    
    _yMargin = 6.0;
    
    CGFloat topMargin = 0; //8.0;
    
    _height = bounds.size.height - topMargin - (_usesHorizLayout ? 4.0 : 8.0);
    
    _width = bounds.size.width - (_usesHorizLayout ? 12.0 : 4.0);
    
    _xMidpoint = _width/2;
    
    //NSLog(@"%s: w %.3f, h %.3f (bounds %@, rounding %.3f, horizlayout %i)", __func__, _width, _height, NSStringFromRect(bounds), _rounding, _usesHorizLayout);
}

#define NODEVIEWWIDTH 110.0
#define NODEVIEWHEIGHT 42.0

- (NSSize)calcFrameSizeForParamCount:(NSInteger)parameterCount  // paramsVisible:(BOOL)visible
{
    NSSize size;
    size.width = NODEVIEWWIDTH;
    size.height = NODEVIEWHEIGHT;
    
    if (_inputCount > 5) {
        size.width += INPUTINTERVAL * (_inputCount - 5);
    }
    
    _firstTextLinePoint = NSMakePoint(10.0, 14.0);

    if (parameterCount > 0) {
        const double PARAMHEIGHT = 17.0;
        size.height += PARAMHEIGHT * parameterCount;
        _firstTextLinePoint.y += PARAMHEIGHT * parameterCount;
    }

    return size;
}

- (void)setRounding:(CGFloat)r {
    _rounding = r; }
    


#pragma mark --- mouse events ---

- (void)rightMouseDown:(NSEvent *)theEvent
{
	BOOL hasMenuDelegate = [_appearanceDelegate respondsToSelector:@selector(contextMenuForCompNodeView:previousMenu:)];
	
	if (hasMenuDelegate) {
		NSMenu *prevMenu = _contextMenu;
		_contextMenu = [_appearanceDelegate contextMenuForCompNodeView:self previousMenu:prevMenu];
		if (_contextMenu != prevMenu) {
			[_contextMenu retain];
			[prevMenu release];
		}
	}	
	if (_contextMenu) {
        if ([NSMenu respondsToSelector:@selector(popUpContextMenu:withEvent:forView:withFont:)]) {
            [NSMenu popUpContextMenu:_contextMenu withEvent:theEvent forView:self
						withFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        } else {
            [NSMenu popUpContextMenu:_contextMenu withEvent:theEvent forView:self];
        }
	}
}


- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL altDown = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    BOOL shiftDown = (([theEvent modifierFlags] & NSShiftKeyMask) ? YES : NO);
	BOOL commandDown = (([theEvent modifierFlags] & NSCommandKeyMask) ? YES : NO);
    BOOL ctrlDown = (([theEvent modifierFlags] & NSControlKeyMask) ? YES : NO);
    BOOL RMB = ([theEvent type] == NSRightMouseDown) ? YES : NO;
    
    if (RMB || ctrlDown)
        [self rightMouseDown:theEvent];
    
    BOOL alreadyInSelection = [[_compView selection] containsObject:self];
    
    if ([theEvent clickCount] > 1) {
        if ([_appearanceDelegate respondsToSelector:@selector(doubleClickOnNodeView:)])
            [_appearanceDelegate doubleClickOnNodeView:self];
    }
    else {
    	NSMutableArray *selection = nil;

        if (!altDown && !shiftDown && !commandDown && !alreadyInSelection)
            ///[_compView clearSelection];
            selection = [NSMutableArray array];
        else
        	selection = [NSMutableArray arrayWithArray:[_compView selection]];

        if (!altDown && !alreadyInSelection) {
            ///[_compView addToSelection:self];            
            [selection addObject:self];
        }
        else if ((shiftDown || commandDown) && !altDown && !ctrlDown) {
            ///[_compView removeFromSelection:self];
            [selection removeObject:self];
        }
        
        if (selection)
        	[_compView replaceSelection:selection];
            
        [self trackMouseWithEvent:theEvent shiftDown:(shiftDown || commandDown)];
    }
}



typedef struct {
	double time;
	NSPoint point;
} EDUICompNodeMouseEvent;


// wacom tablets return non-integral mouse locations, so we make them integral to ensure proper drawing
static inline NSPoint IntegralPoint(NSPoint p) {
    p.x = round(p.x);
    p.y = round(p.y);
    return p;
}


- (void)trackMouseWithEvent:(NSEvent *)theEvent shiftDown:(BOOL)shiftDown
{
    NSPoint curPoint = [_compView convertPoint:IntegralPoint([theEvent locationInWindow]) fromView:nil];
    NSWindow *window = [self window];
    BOOL didMove = NO;
	BOOL didShakeLoose = NO;
	float shakeTimeWindowInSecs = 2.0f;
	float shakeHorizTreshold = 100.0f;
	
	///NSLog(@"compnodeview (%p) -trackmouse: window %p, superview %p", self, window, [self superview]);
	
	// create a buffer that stores previous mouse positions and their times
	int eventBufSize = 16;
	EDUICompNodeMouseEvent *eventBuf = _lx_malloc(eventBufSize * sizeof(EDUICompNodeMouseEvent));
	int eventBufIndex = 0;
	
	// clear eventBuf with invalid values
	int n;
	for (n = 1; n < eventBufSize; n++) {
		eventBuf[n].point = NSMakePoint(-100, -100);
		eventBuf[n].time = -100;
	}

	EDUICompNodeMouseEvent *currEvent = eventBuf+eventBufIndex;
	currEvent->time = [theEvent timestamp];
	currEvent->point = curPoint;
	eventBufIndex++;

	[self retain];
	
	// start drag
	[_compView startSelectionMoveAtPoint:curPoint];
    
	BOOL didDuplicate = NO;
    BOOL didSimulateDoubleClick = NO;
    NSPoint startPoint = curPoint;
	NSPoint windowOffset = [_compView convertPoint:NSZeroPoint fromView:nil];
    while (1) {
        theEvent = [window nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
		BOOL altDown = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
        curPoint = IntegralPoint([theEvent locationInWindow]);  ///[_compView convertPoint:[theEvent locationInWindow] fromView:nil];
		curPoint.x += windowOffset.x;      // using this fixed offset instead of convertPoint:fromView:
		curPoint.y += windowOffset.y;      // avoids problems when scrollbars are hidden/unhidden

		if (!theEvent)
			break;
        if ([theEvent type] == NSLeftMouseUp) {
			// end drag; if alt wasn't used for duplication, perform a double-click (this sets the active node in Conduit)
            if (altDown && !didDuplicate) {
                if ([_appearanceDelegate respondsToSelector:@selector(doubleClickOnNodeView:)]) {
                    [_appearanceDelegate doubleClickOnNodeView:self];                
                    didSimulateDoubleClick = YES;
                }
            }
            // check if the movement was large enough to actually qualify as a drag
            if (fabs(curPoint.x - startPoint.x) > 1.9 || fabs(curPoint.y - startPoint.y) > 1.9)
                [_compView endSelectionMoveAtPoint:curPoint];
                
            break;
        }
		
		if (altDown && !didDuplicate &&
                    (fabs(curPoint.x - startPoint.x) > 4.0 || fabs(curPoint.y - startPoint.y) > 4.0)) {
            // duplicate only if distance from startpoint exceeds limit
            if ( ![[_compView selection] containsObject:self]) {
                [_compView clearSelection];
                [_compView addToSelection:self];
            }
            
			[_compView duplicateSelectionOnDrag];
			[_compView startSelectionMoveAtPoint:curPoint];
			didDuplicate = YES;
		}
		
        [_compView moveSelectionToPoint:curPoint];
        didMove = YES;
		
		// check for "shake loose" gesture using previous event times
		if (!didShakeLoose) {
			if (eventBufIndex >= eventBufSize)
				eventBufIndex = 0;
			
			double currTime = [theEvent timestamp];
			EDUICompNodeMouseEvent *currEvent = eventBuf+eventBufIndex;
			currEvent->time = currTime;
			currEvent->point = curPoint;
			
			NSInteger i;
			float min[2];
			float max[2];
			min[0] = max[0] = curPoint.x;
			min[1] = max[1] = -999;
			float *curMin = min;
			float *curMax = max;
			
			NSInteger bindex = eventBufIndex;
			BOOL foundDirChange = NO;
			NSInteger initialMovementDir = 0;
			float prevX = curPoint.x;
			
			for (i = 0; i < eventBufSize-1; i++) {
				bindex--;
				if (bindex < 0)
					bindex = eventBufSize - 1;

				EDUICompNodeMouseEvent *ev = eventBuf+bindex;
				
				if (ev->time >= (currTime-shakeTimeWindowInSecs)) {
				
					// compare current point and previous point to determine last movement direction
					float dd = prevX - ev->point.x;
					int dir = 0;
					if (dd > 0.0f)			dir = 1;
					else if (dd < 0.0f)		dir = 2;

					if (i == 0) {
						if (dir == 0)
							break;
						else
							initialMovementDir = dir;
					}
					else {
						if ( !foundDirChange && dir != 0 && dir != initialMovementDir) {
							foundDirChange = YES;
							curMin = &(min[1]);
							curMax = &(max[1]);
							*curMin = ev->point.x;
							*curMax = ev->point.x;
						}
					}
					
					float x = ev->point.x;
					prevX = x;
				
					if (dir != 0 && 
							((foundDirChange && dir != initialMovementDir) ||
							(!foundDirChange && dir == initialMovementDir))) {
						if (x > *curMax)
							*curMax = x;
						if (x < *curMin)
							*curMin = x;
					}
				}
				else  // event is older than 2 seconds, so exit loop
					break;
			}
			
			eventBufIndex++;
			
			// if horizontal motion is large enough, release node from its connections
			if (foundDirChange) {
				float diff1 = max[0] - min[0];
				float diff2 = max[1] - min[1];
				
				//NSLog(@"diff1 %f  diff2 %f", diff1, diff2);
				
				if (diff2 > shakeHorizTreshold  &&  diff1 >= diff2) {
					[_compView shakeSelectionLoose];
					didShakeLoose = YES;
				}
			}
		}
    }
	
    if (!didMove) {
        if (!shiftDown && !didSimulateDoubleClick) {
        	[_compView replaceSelection:[NSMutableArray arrayWithObject:self]];
        }
    }
	
	_lx_free(eventBuf);
	
	[self autorelease];
}


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES; }
	
	
- (void)refreshTrackingRectsForHoverSelection
{
#if !defined(__LAGOON__)
	BOOL useHover = [_compView hoverSelectionEnabled];
    ///NSLog(@"nodeview refreshtrackrects for hover, %i (%@)", useHover, [_node name]);
	
	if (_trackRectTag != 0) {
		[self removeTrackingRect:_trackRectTag];
        _trackRectTag = 0;
    }
    
	if (useHover) {
		_trackRectTag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
	} else {
		_trackRectTag = 0;
	}
#endif
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	[_compView mouseEnteredNodeView:self];
}


#pragma mark --- appearance ---


- (void)updateNodeAppearance
{
	[self refreshTrackingRectsForHoverSelection];

    ///NSLog(@"nodeview -updateNodeAppearance, node %@", [_node name]);

    [_selColor release];
    [_unselColor release];
    
    if (_appearanceDelegate) {
        //_selColor = [EDUIColorController selectedNodeColorForNode:_node];
        //_unselColor = [EDUIColorController nodeColorForNode:_node];
        _selColor = [[_appearanceDelegate selectedColorForNode:_node] retain];
        _unselColor = [[_appearanceDelegate unselectedColorForNode:_node] retain];
        
		_selColorIsPattern =   [[_selColor colorSpaceName] isEqualToString:@"NSPatternColorSpace"];
		_unselColorIsPattern = [[_unselColor colorSpaceName] isEqualToString:@"NSPatternColorSpace"];
        
		if (!_unselColorIsPattern) {
			CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0, lum;
            NS_DURING
			[_unselColor getRed:&r green:&g blue:&b alpha:&a];
            NS_HANDLER
                if ([[_unselColor colorSpaceName] isEqual:@"NSCalibratedWhite"] || [[_selColor colorSpaceName] isEqual:@"NSDeviceWhite"])
                    [_unselColor getWhite:&b alpha:&a];
                r = g = b;
            NS_ENDHANDLER
            
			lum = r*0.3 + g*0.6 + b*0.1;
			_useWhiteLabelUnsel = (lum < 0.6) ? YES : NO;
		}
		else
			_useWhiteLabelUnsel = NO;
        
		if (!_selColorIsPattern) {
			CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0, lum;
            NS_DURING
			[_selColor getRed:&r green:&g blue:&b alpha:&a];
            NS_HANDLER
                if ([[_selColor colorSpaceName] isEqual:@"NSCalibratedWhite"] || [[_selColor colorSpaceName] isEqual:@"NSDeviceWhite"])
                    [_selColor getWhite:&b alpha:&a];
                r = g = b;
            NS_ENDHANDLER

			lum = r*0.3 + g*0.6 + b*0.1;
			_useWhiteLabelSel = (lum < 0.6) ? YES : NO;
		}
		else
			_useWhiteLabelSel = NO;
    }
    else {
        // default colors in case we don't have a delegate
        _selColor = [[NSColor colorWithDeviceRed:0.74 green:0.72 blue:0.893 alpha:1.0] retain];
        _unselColor = [[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.808 alpha:1.0] retain];
        
		_selColorIsPattern = NO;
		_unselColorIsPattern = NO;
        _useWhiteLabelUnsel = NO;
        _useWhiteLabelSel = NO;
    }
}

- (id)appearanceDelegate {
    return _appearanceDelegate; }

- (void)setAppearanceDelegate:(id)provider {
    _appearanceDelegate = provider;
    
    [self updateNodeAppearance];
    
    if ([_appearanceDelegate respondsToSelector:@selector(imageForInputView:type:highlight:bypassed:)]) {
        // the delegate provides appearance for inputviews as well
        NSEnumerator *inpViewEnum = [_inputViews objectEnumerator];
        EDUICompInputView *view;
        while (view = [inpViewEnum nextObject]) {
            [view setNodeTypeDelegate:_appearanceDelegate];
        }
        
        inpViewEnum = [_parameterViews objectEnumerator];
        while (view = [inpViewEnum nextObject]) {
            [view setNodeTypeDelegate:_appearanceDelegate];
        }
        
        inpViewEnum = [_outputViews objectEnumerator];
        while (view = [inpViewEnum nextObject]) {
            [view setNodeTypeDelegate:_appearanceDelegate];
        }
    }
}


#pragma mark --- drawing ---

- (BOOL)isOpaque {
    return NO;
}

- (void)drawRoundedRectInPath:(NSBezierPath *)path width:(double)width height:(double)height
                                x:(double)x y:(double)y rounding:(double)rounding
{
    double rounding2 = rounding * 0.25;
    
    double yb = y + _yMargin;
    double yt = y + height;

    [path moveToPoint:NSMakePoint(x+rounding,   yb) ];
    [path lineToPoint:NSMakePoint(x+width-rounding,   yb) ];
    
    [path curveToPoint:NSMakePoint(x+width,   yb+rounding)
          controlPoint1:NSMakePoint(x+width-rounding2,   yb)
          controlPoint2:NSMakePoint(x+width,   yb+rounding2) ];
          
    [path lineToPoint:NSMakePoint(x+width,   yt-rounding) ];
    [path curveToPoint:NSMakePoint(x+width-rounding,   yt)
          controlPoint1:NSMakePoint(x+width,   yt-rounding2)
          controlPoint2:NSMakePoint(x+width-rounding2,   yt) ];
          
    [path lineToPoint:NSMakePoint(x+rounding,   yt) ];
    [path curveToPoint:NSMakePoint(x+2.0,   yt-rounding)
          controlPoint1:NSMakePoint(x+2.0+rounding2,   yt)
          controlPoint2:NSMakePoint(x+2.0,   yt-rounding2) ];
          
    [path lineToPoint:NSMakePoint(x+2.0,   yb+rounding) ];
    [path curveToPoint:NSMakePoint(x+rounding,   yb)
          controlPoint1:NSMakePoint(x+2.0,   yb+rounding2)
          controlPoint2:NSMakePoint(x+2.0+rounding2,   yb) ];
}


#define SELWIDTH  1.5

+ (NSShadow *)defaultShadow {
	NSShadow *shadow = gDefaultNodeShadow;
	if (shadow == nil) {
		shadow = [[NSShadow alloc] init];
		[shadow setShadowOffset:NSMakeSize(1.5, -1.5)];
		[shadow setShadowBlurRadius:5.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.05 green:0.05 blue:0.15 alpha:0.28]];	
	}
	return shadow;
}

+ (void)setDefaultShadow:(NSShadow *)shadow {
	if (gDefaultNodeShadow)
		[gDefaultNodeShadow release];
	gDefaultNodeShadow = [shadow retain];
}


- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSInteger i;
    NSEnumerator *enumerator;
    BOOL whiteLabel = NO;

    if (!_selColor || !_unselColor)
        [self updateNodeAppearance];

	if (_selColorIsPattern || _unselColorIsPattern) {
		// pattern colors are drawn in window space, need to offset the graphics context to our origin
		// so that pattern stays fixed as the node views are moved
		NSPoint phase = [self convertPoint:[self bounds].origin toView:nil];
		
		phase.y += _yMargin;
		[[NSGraphicsContext currentContext] setPatternPhase:phase];
	}
	

    BOOL isBypassed = NO;
    if ([_node respondsToSelector:@selector(useBypassedAppearance)])
        isBypassed = [(id <EDUINodeGraphConnectableAppearanceMethods>)_node useBypassedAppearance];

    double myW = _width - 2.0;
    double myH = _height - 1.0;
    double myX = (_usesHorizLayout ? 5.5 : 1.5);
    double myY = 1.5;
    
    //NSLog(@"%@: node size %.3f, %.3f", self, myW, myH);

    if (_selected) {
        [self drawRoundedRectInPath:path width:myW + (_usesHorizLayout ? 3.0 : 2.0) + SELWIDTH*2.0     ///_width+SELWIDTH*2.0
                                         height:myH + 2.0 + SELWIDTH*2.0    ///_height-1.0+SELWIDTH*2.0
                                         x:myX - 1.0 - SELWIDTH ///-SELWIDTH+0.5
                                         y:myY - 1.0 - SELWIDTH ///-SELWIDTH+0.5
                                         rounding:_rounding+2.0];
        [path closePath];
        [_selColor set];
		
        [path fill];        
        [path removeAllPoints];
    }
    
    if (_rounding > 0.0) {
        [self drawRoundedRectInPath:path width:myW
                                     height:myH
                                     x:myX
                                     y:myY
                                     rounding:_rounding];
    } else {
        [path appendBezierPathWithRect:NSInsetRect(NSMakeRect(myX, myY+_yMargin, myW+2.0, myH-_yMargin), 1.5, 1.0)];
    }
    [path closePath];
	
    if (_selected) {
        [_selColor set];
        whiteLabel = _useWhiteLabelSel;		
    }
    else {
        if (isBypassed && !_unselColorIsPattern) {
            CGFloat r, g, b, a;
            [_unselColor getRed:&r green:&g blue:&b alpha:&a];
            
            r = 0.4f + r*0.6f;
            g = 0.4f + g*0.6f;
            b = 0.4f + b*0.6f;
            a = 0.55f;
            
            NSColor *bypassColor = [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
            [bypassColor set];
        }
        else {
            [_unselColor set];
        }
        whiteLabel = _useWhiteLabelUnsel;
    }
	
	// check if node wants to choose label color itself
	if ([_node respondsToSelector:@selector(useWhiteLabelTextWhenSelected:)])
		whiteLabel = [(id <EDUINodeGraphConnectableAppearanceMethods>)_node useWhiteLabelTextWhenSelected:_selected];
    
    NSShadow *shadow = nil;
    if ([_appearanceDelegate respondsToSelector:@selector(shadowForNode:)]) {
        shadow = [_appearanceDelegate shadowForNode:_node];
    } else {
        if ( !isBypassed) {
            shadow = [[self class] defaultShadow];
        }
	}

    // set a shadow for the drawing (only if node is not bypassed)
    if (shadow)
        [NSGraphicsContext saveGraphicsState];
    
    [shadow set];
    [path fill];
	
	// pop graphics state, to get rid of shadow
    if (shadow)
        [NSGraphicsContext restoreGraphicsState];
    
    // draw border line
    NSColor *borderColor = nil;
    if ([_appearanceDelegate respondsToSelector:@selector(borderLineColorForNode:)])
        borderColor = [_appearanceDelegate borderLineColorForNode:_node];
    if (borderColor == nil) {
        borderColor = (isBypassed) ? [NSColor colorWithDeviceRed:0.2 green:0.2 blue:0.2 alpha:0.6] : [NSColor blackColor];
    }
    [borderColor set];
    [path setLineWidth:0.7 / _zoomFactor];
    [path stroke];

    // draw label
    NSDictionary *dict;
    if (whiteLabel)
        dict = [[self class] whiteNodeLabelTextAttributes];
    else
        dict = [[self class] nodeLabelTextAttributes];

    BOOL useSmallText = NO;
    double smallTextFontSize = 9.0;
    if ( !_usesHorizLayout) {
        // hardcoded length to use smaller text
        useSmallText = ([_label length] > 12);
        smallTextFontSize = ([_label length] > 16) ? 8.0 : smallTextFontSize;
    } else {
        double textW = [_label sizeWithAttributes:dict].width;
        double maxW = [self bounds].size.width - 50;
        if (textW > maxW) {
            useSmallText = YES;
            smallTextFontSize = (textW > maxW*1.3) ? 8.0 : smallTextFontSize;
        }
    }
    
    if (useSmallText) {        
        NSString *fontName = [[dict objectForKey:NSFontAttributeName] fontName];
        BOOL isBoldFont = [[fontName lowercaseString] rangeOfString:@"bold"].location != NSNotFound;
        
        dict = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        [(NSMutableDictionary *)dict setObject:(isBoldFont) ? [NSFont boldSystemFontOfSize:smallTextFontSize] : [NSFont systemFontOfSize:smallTextFontSize]
                                        forKey:NSFontAttributeName];
    }

    [_label drawInRect:NSMakeRect(_firstTextLinePoint.x, _firstTextLinePoint.y,
                                  _width - _firstTextLinePoint.x - ((_usesHorizLayout) ? 7.0 : 14.0), 13.0)
            withAttributes:dict];

    enumerator = [_parameterLabels objectEnumerator];
    i = 0;

    if (whiteLabel)
        dict = [[self class] whiteParameterLabelTextAttributes];
    else
        dict = [[self class] parameterLabelTextAttributes];
    
    NSString *plabel;
    while (plabel = [enumerator nextObject]) {
        [plabel drawAtPoint:[self positionForParameterLabelAtIndex:i] withAttributes:dict];
        i++;
    }

/*
    // draw inputs
    enumerator = [_inputs objectEnumerator];
    c = [_inputs count];
    x = _xMidpoint - inputInterval*(c-1) + (inputInterval/2)*((c-1)%2);
    while (ob = [enumerator nextObject]) {
        [self drawInputAtOrigin:NSMakePoint(x, _height+_rounding) ];
        x += inputInterval;
    }
    // draw outputs
    enumerator = [[_node outputs] objectEnumerator];
    c = [[_node outputs] count];
    x = _xMidpoint - inputInterval*(c-1) + (inputInterval/2)*((c-1)%2);
    while (ob = [enumerator nextObject]) {
        [self drawInputAtOrigin:NSMakePoint(x, 6.0) ];
        x += inputInterval;
    }
*/    
}

/*
- (void)drawInputAtOrigin:(NSPoint)origin
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    float r = 5.0;
    float k = 0.5523 * r;
    
    [path moveToPoint:NSMakePoint(origin.x - r, origin.y) ];
    [path curveToPoint:NSMakePoint(origin.x, origin.y + r)
          controlPoint1:NSMakePoint(origin.x - r, origin.y + k)
          controlPoint2:NSMakePoint(origin.x - k, origin.y + r) ];
    [path curveToPoint:NSMakePoint(origin.x + r, origin.y)
          controlPoint1:NSMakePoint(origin.x + k, origin.y + r)
          controlPoint2:NSMakePoint(origin.x + r, origin.y + k) ];
          
    [path curveToPoint:NSMakePoint(origin.x, origin.y - r)
          controlPoint1:NSMakePoint(origin.x + r, origin.y - k)
          controlPoint2:NSMakePoint(origin.x + k, origin.y - r) ];
    [path curveToPoint:NSMakePoint(origin.x - r, origin.y)
          controlPoint1:NSMakePoint(origin.x - k, origin.y - r)
          controlPoint2:NSMakePoint(origin.x - r, origin.y - k) ];
    [path closePath];
    
    [[NSColor colorWithDeviceRed:0.65 green:0.7 blue:0.78 alpha:1.0] set];
    [path fill];
    [path setLineWidth:0.7];
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0] set];
    [path stroke];
}
*/

@end
