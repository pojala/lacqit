//
//  EDUICompViewController.m
//  Edo
//
//  Created by Pauli Ojala on 26.4.2005.
//  Copyright 2005 Pauli Olavi Ojala. All rights reserved.
//

#import "EDUICompViewController.h"
#import "EDUICompositionView.h"
#import "EDUICompNodeView.h"
#import "EDUICompInputView.h"
#import "EDUICompConnector.h"
#import "EDUINodeGraphConnectable.h"
#import "EDUINodeGraph.h"


#define EDUI_PATCH_SUPPORT


@implementation EDUICompViewController

- (id)init {
    self = [super init];
    
    _modifiedNodes = [[NSMutableSet setWithCapacity:8] retain];
    
    return self;
}

- (void)dealloc {
    [_modifiedNodes release];
    
    [_nodeViews autorelease];
    [_connectors autorelease];
    [_rootNodeView autorelease];
    
    [_graph autorelease];

    [super dealloc];
}


#pragma mark --- accessors ---

- (EDUICompositionView *)compView {
    return _compView; }

- (void)setModelDelegate:(id)delegate {
    _modelDelegate = delegate; }

- (id)modelDelegate {
    return _modelDelegate; }
    

- (void)setNodeGraph:(id <NSObject, EDUINodeGraph>)graph
{
    [_graph autorelease];
    _graph = [graph retain];

    [_compView controllerDidResetNodeGraph];
    
    if (graph == nil) {
        [self emptyAllViews];
        return;
    }
    
    [self makeNodeViews];
    [_compView setNeedsDisplay:YES];
}


- (id <NSObject, EDUINodeGraph>)nodeGraph {
    return _graph; }


- (NSMutableArray *)nodeViews {
    return _nodeViews; }


- (void)refreshCustomScaleForNodeView:(EDUICompNodeView *)nodeView
{
    id node = (id)[nodeView node];
    LXFloat scale = [node scaleFactor];
    if (scale < 0.0001) {
        NSLog(@"** EDUICompViewController -refreshCustomScale warning: scale from node is tiny (%f), defaulting to one", scale);
        scale = 1.0f;
    }
    
    if ([_graph respondsToSelector:@selector(globalScaleFactor)])
        scale *= [(id)_graph globalScaleFactor];
    
    if ([_modelDelegate respondsToSelector:@selector(customScaleForNodeView:proposedScale:)])
        scale = [_modelDelegate customScaleForNodeView:nodeView proposedScale:scale];

    LXFloat prev = [nodeView zoomFactor];

    //NSLog(@"%s: %@ -- %.3f, prev %.3f", __func__, nodeView, scale, prev);
    
    if (scale == 0.0) {
        NSLog(@"** %s: zero scale (this may indicate patch subclass that returns zero for globalScaleFactor)", __func__);
        return;
    }
                
    if (scale != prev) {
        //NSRect prevFrame = [nodeView frame];
        [nodeView setZoomFactor:scale];
                
        [_compView setNeedsDisplay:YES];
    }
/*
	if (scale == 1.0f)
		return;
	
	NSRect nodeFrame = [nodeView frame];
	NSRect bounds = [nodeView bounds];
	NSRect scaledFrame = NSMakeRect(nodeFrame.origin.x, nodeFrame.origin.y,
									nodeFrame.size.width * scale, nodeFrame.size.height * scale);

	scaledFrame.origin.x -= (scaledFrame.size.width - nodeFrame.size.width) * 0.5;
	scaledFrame.origin.y -= (scaledFrame.size.height - nodeFrame.size.height) * 0.5;
	[nodeView setFrame:scaledFrame];
	[nodeView setBounds:bounds];
*/
}


- (void)addNodeToView:(id <NSObject, EDUINodeGraphConnectable>)node
{
    NSRect viewFrame;
    EDUICompNodeView *newNodeView;
    
    const BOOL delegateDecidesNodeClass =[_modelDelegate respondsToSelector:@selector(nodeViewClassForNode:)];
    const BOOL delegateWantsToValidateNodes = [_modelDelegate respondsToSelector:@selector(shouldAddNodeView:forNode:)];    
    
    if (delegateDecidesNodeClass) {
        Class viewClass = [_modelDelegate nodeViewClassForNode:node];
        newNodeView = [ [(EDUICompNodeView *)[viewClass alloc] initWithNode:node] autorelease];
    } else {
        newNodeView = [ [[EDUICompNodeView alloc] initWithNode:node] autorelease];
    }

    if (delegateWantsToValidateNodes) {
        BOOL ok = [_modelDelegate shouldAddNodeView:newNodeView forNode:node];
            
        if ( !ok)
            return;
    }
    
    [_nodeViews addObject:newNodeView];
    [_compView addSubview:newNodeView];
    [newNodeView setCompView:_compView];

    if ([_modelDelegate respondsToSelector:@selector(unselectedColorForNode:)])
        [newNodeView setAppearanceDelegate:_modelDelegate];

	if ([node respondsToSelector:@selector(scaleFactor)]) {
		[self refreshCustomScaleForNodeView:newNodeView];
	}

    viewFrame = [newNodeView frame];
    viewFrame.size.width += viewFrame.origin.x;
    viewFrame.size.height += viewFrame.origin.y;
    viewFrame.origin.x = viewFrame.origin.y = 0.0;
    viewFrame = NSUnionRect([_compView contentBounds], viewFrame);
    [_compView setContentBounds:viewFrame];
    //NSLog(@"content bounds: %@", NSStringFromRect(viewFrame));

    [_compView setNeedsDisplay:YES];
}


- (void)deleteNodeView:(EDUICompNodeView *)nodeView
{
    [nodeView disconnectAllConnections];
    [nodeView removeFromSuperview];
    [_nodeViews removeObject:nodeView];
}


- (void)deleteSelectedNodeViews
{
    NSEnumerator *enumerator;
    EDUICompNodeView *nodeView;
        
    enumerator = [[_compView selection] objectEnumerator];
    while (nodeView = [enumerator nextObject]) {
        [self deleteNodeView:nodeView];
    }
    [_compView clearSelection];
    [self makeConnectors];
}


- (EDUICompNodeView *)findNodeViewWithNode:(id <NSObject, EDUINodeGraphConnectable>)wantedNode
{
    NSEnumerator *enumerator = [_nodeViews objectEnumerator];
    EDUICompNodeView *nodeView;
    
    while (nodeView = [enumerator nextObject]) {
        ///NSLog(@" ....... %p (%@), looking for %p (%@)", [nodeView node], [[nodeView node] name],  wantedNode, [wantedNode name]);
        
        if ( [[nodeView node] isEqual:wantedNode] )
            return nodeView;
    }
    return nil;
}


- (void)setGraphZoomFactor:(double)newScale centerAt:(NSPoint)compCenter
{
    id comp = (id)_graph;
    if ( ![comp respondsToSelector:@selector(globalScaleFactor)]) {
        NSLog(@"** eduicompviewctrl -setgraphzoom: this graph doesn't implement -globalScaleFactor");
        return;
    }
    
    double prevScale = [comp globalScaleFactor];
    [comp setGlobalScaleFactor:newScale];

	if (fabs(prevScale) < 0.0001) {
		NSLog(@"** warning: node graph shouldn't have zero scale factor");
		prevScale = 1.0;
	}
	
    // translate nodes' origin points for zoom effect
    double dsc = newScale / prevScale;
    if (fabs(dsc-1.0) > 0.001) {
        ///NSLog(@"..zoom scale: %f, comp center %f, %f", dsc, compCenter.x, compCenter.y);
        
        /*
        NSEnumerator *nodeEnum = [[comp allNodes] objectEnumerator];
        id node;
        while (node = [nodeEnum nextObject]) {
            NSPoint nodeOrig = [node originPoint];
            nodeOrig.x = (nodeOrig.x - compCenter.x) * dsc + compCenter.x;
            nodeOrig.y = (nodeOrig.y - compCenter.y) * dsc + compCenter.y;
            [node setOriginPoint:nodeOrig];
        }
        NSPoint rootOrig = [comp originPoint];
        rootOrig.x = (rootOrig.x - compCenter.x) * dsc + compCenter.x;
        rootOrig.y = (rootOrig.y - compCenter.y) * dsc + compCenter.y;
        [comp setOriginPoint:rootOrig];
        */
        NSEnumerator *nodeEnum = [[comp allNodes] objectEnumerator];
        id node;
        while (node = [nodeEnum nextObject]) {
            NSPoint nodeCenter = [node centerPoint];
            nodeCenter.x = (nodeCenter.x - compCenter.x) * dsc + compCenter.x;
            nodeCenter.y = (nodeCenter.y - compCenter.y) * dsc + compCenter.y;
            [node setCenterPoint:nodeCenter];
        }
        
        if ([comp respondsToSelector:@selector(setCenterPoint:)]) {
            NSPoint rootCenter = [comp centerPoint];
            rootCenter.x = (rootCenter.x - compCenter.x) * dsc + compCenter.x;
            rootCenter.y = (rootCenter.y - compCenter.y) * dsc + compCenter.y;
            [comp setCenterPoint:rootCenter];
        }

        [_compView setBoundsOrigin:NSMakePoint(0, 0)];
        //[_compView recalcContentBounds];
        [_compView refreshAppearance];
        [self makeNodeViews];
    }
}

- (void)setGraphZoomFactor:(double)newScale
{
	if ([_graph respondsToSelector:@selector(globalScaleFactor)] && newScale == [(id)_graph globalScaleFactor])
		return;

    NSRect compBounds = [_compView visibleRect]; //[_compView bounds];    
    
    NSPoint compCenter = NSMakePoint(compBounds.origin.x+compBounds.size.width*0.5, compBounds.origin.y+compBounds.size.height*0.5);

    [self setGraphZoomFactor:newScale centerAt:compCenter];
}


#pragma mark --- modifying model connections ---

- (void)_willModifyModel
{
    if ([_modelDelegate respondsToSelector:@selector(compViewWillModifyModel)]) {
        if (_inModelModif == 0) {
            [_modelDelegate compViewWillModifyModel];
        }
        _inModelModif++;
    }
}

- (void)willModifyModel
{
    [self _willModifyModel];
}

- (void)addToModelConnectionFrom:(EDUICompInputView *)fromView to:(EDUICompInputView *)toView
{
    //NSLog(@"%s -- will modify model", __func__);
    [self _willModifyModel];

    id<EDUINodeGraphConnectable> fromNode = [[fromView nodeView] node];
    id<EDUINodeGraphConnectable> toNode = [[toView nodeView] node];
    /*
    EDUINodeOutput *fromOutput = [[fromNode outputs] objectAtIndex:[fromView index] ];
    EDUINodeInput *toInput; 
    
    if ([toView isParameter])
        toInput = [ [[toNode parameters] objectAtIndex:[toView index]] parameterInput];
    else
        toInput = [[toNode inputs] objectAtIndex:[toView index] ];
        
    if ([toInput isConnected])
        [toInput disconnect];
    
    [toInput connectToOutput:fromOutput];
    */
    
    int inpIndex = [toView index];
    int outpIndex = [fromView index];

    if ([toView isParameter]) {
        id pnode = toNode;
        [pnode disconnectParameterAtIndex:inpIndex];
        [pnode connectParameterAtIndex:inpIndex toNode:fromNode outputIndex:outpIndex];
    }
    else {
        [toNode disconnectInputAtIndex:inpIndex];
        [toNode connectInputAtIndex:inpIndex toNode:fromNode outputIndex:outpIndex];
    }
                
    [_modifiedNodes addObject:fromNode];
    [_modifiedNodes addObject:toNode];
}

- (void)disconnectInput:(EDUICompInputView *)inputView
{
    ///NSLog(@"%s -- will modify model", __func__);
    [self _willModifyModel];

    id<NSObject, EDUINodeGraphConnectable> toNode = [[inputView nodeView] node];
    id<NSObject, EDUINodeGraphConnectable> outputNode;
    /*
    EDUINodeInput *input;
    
    if ([inputView isParameter])
        input = [ [[toNode parameters] objectAtIndex:[inputView index]] parameterInput];
    else
        input = [[toNode inputs] objectAtIndex:[inputView index] ];
    outputNode = [input connectedNode];
    
    [input disconnect];
    */
    
    LXInteger inpIndex = [inputView index];
    LXInteger outpIndex;
    if ([inputView isParameter]) {
        id pnode = toNode;
        outputNode = (id<NSObject, EDUINodeGraphConnectable>)[pnode connectedNodeForParameterAtIndex:inpIndex
                                                                    outputIndexPtr:&outpIndex];
        [pnode disconnectParameterAtIndex:inpIndex];
    }
    else {
        outputNode = (id<NSObject, EDUINodeGraphConnectable>)[toNode connectedNodeForInputAtIndex:inpIndex
                                                                    outputIndexPtr:&outpIndex];
        [toNode disconnectInputAtIndex:inpIndex];
    }

    [self makeConnectors];
    
    if (toNode)
        [_modifiedNodes addObject:toNode];
    if (outputNode)
        [_modifiedNodes addObject:outputNode];
}

- (void)finishedModifyingModel
{
    [_modelDelegate connectionsWereModifiedForNodes:(_modifiedNodes) ? [NSSet setWithSet:_modifiedNodes] : [NSSet set]];
    [_modifiedNodes removeAllObjects];
    
    if ([_modelDelegate respondsToSelector:@selector(compViewDidModifyModel)]) {
        if (_inModelModif > 0) {
            [_modelDelegate compViewDidModifyModel];
            _inModelModif = 0;
        } else {
            NSLog(@"*** %s: it looks like matching _willModifyModel call was never made", __func__);
        }
    }
}


- (void)compViewSelectedNodesWereMoved
{
    if ([_modelDelegate respondsToSelector:@selector(compViewNodeAbsolutePositionsDidChange)])
        [_modelDelegate compViewNodeAbsolutePositionsDidChange];
}

- (void)compViewWasPannedByOffset:(NSPoint)offset
{
    NSEnumerator *enumerator = [_nodeViews objectEnumerator];
    EDUICompNodeView *nodeView;
    while (nodeView = [enumerator nextObject]) {
        [nodeView setSelectionOffsetFromPoint:NSZeroPoint];
        [nodeView moveUsingOffsetToPoint:offset];
    }
    
    NSRect bounds = [_compView bounds];
    bounds.origin = NSZeroPoint;
    [_compView setBounds:bounds];
    
    [_compView recalcContentBounds];
    
    [_compView setNeedsDisplay:YES];
    
    if ([_modelDelegate respondsToSelector:@selector(compViewNodeAbsolutePositionsDidChange)])
        [_modelDelegate compViewNodeAbsolutePositionsDidChange];
}


// this is an utility method used by -connectNodes:betweenOutput:andInput: method;
// returns an array containing sets of interconnected nodes (i.e. if all nodes are interconnected, returns the original set)
- (NSArray *)findInterconnectedNodesInSet:(NSSet *)origSet
{
	NSMutableArray *sets = [NSMutableArray arrayWithCapacity:16];
	EDUICompNodeView *nodeView, *nv2;
	
	NSEnumerator *origSetEnum = [origSet objectEnumerator];
	while (nodeView = [origSetEnum nextObject]) {
		id<EDUINodeGraphConnectable> node = [nodeView node];

		NSMutableSet *set = nil;
		// check if this node is already within a set
		NSEnumerator *setEnum = [sets objectEnumerator];
		id s;
		while (s = [setEnum nextObject]) {
			if ([s containsObject:node]) {
				set = (NSMutableSet *)s;
				break;
			}
		}
		if (set == nil) {
			// no existing set found, create a new set for this node
			set = [NSMutableSet setWithCapacity:16];
			[sets addObject:set];
			[set addObject:node];

			// iterate through other nodes to find those that belong in this set
			NSEnumerator *enum2 = [origSet objectEnumerator];
			while (nv2 = [enum2 nextObject]) {
				id<EDUINodeGraphConnectable> otherNode = [nv2 node];
				if (otherNode != node) {
					if ([node hasUpstreamConnectionToNode:otherNode] || [otherNode hasUpstreamConnectionToNode:node]) {
						[set addObject:otherNode];
						///NSLog(@"added to set: %@ (%@)", [otherNode name], [node name]);
					}
				}
			}
		}
	}
	return sets;
}

// this is an utility method used by -connectNodes:betweenOutput:andInput: method
- (void)findEntryAndExitNodesInInterconnectedSet:(NSSet *)set
						entryNodePtr:(id<EDUINodeGraphConnectable> *)pEntryNode
						exitNodePtr:(id<EDUINodeGraphConnectable> *)pExitNode
{
	id<EDUINodeGraphConnectable> entryNode = nil;
	id<EDUINodeGraphConnectable> exitNode = nil;
	int setCount = [set count];
	int c = -1;
	
	if (setCount == 1) {
		entryNode = exitNode = [set anyObject];
	}
	else {
		NSEnumerator *setEnum = [set objectEnumerator];
		id<EDUINodeGraphConnectable> node, node2;
		while (node = [setEnum nextObject]) {
			int upstreamNodes = 0;
			
			// for each node in set, count how many upstream nodes they have
			NSEnumerator *enum2 = [set objectEnumerator];
			while (node2 = [enum2 nextObject]) {
				if (node2 != node) {
					if ([node hasUpstreamConnectionToNode:node2])
						upstreamNodes++;
				}
			}
			
			///NSLog(@"node: %@, upstream connections %i", [node name], upstreamNodes);
			
			if (upstreamNodes == 0 && entryNode == nil) {
				// this is the entry node
				entryNode = node;
			}
			if (upstreamNodes > c) {
				// this could be the exit node
				exitNode = node;
				c = upstreamNodes;
			}
		}
	}
	
	///NSLog(@"entry node name: %@, exit node: %@", [entryNode name], [exitNode name]);
	
	*pEntryNode = entryNode;
	*pExitNode = exitNode;
}


- (void)connectNodes:(id)nodeSet betweenOutput:(EDUICompInputView *)startView
								 andInput:(EDUICompInputView *)endView
{
    ///NSLog(@"%s -- will modify model", __func__);
    [self _willModifyModel];

    id<EDUINodeGraphConnectable> startNode = [[startView nodeView] node];
    id<EDUINodeGraphConnectable> endNode = [[endView nodeView] node];
    int startIndex = [startView index];
    int endIndex = [endView index];

	NSArray *interconnectedNodes = [self findInterconnectedNodesInSet:nodeSet];
	NSEnumerator *setEnum = [interconnectedNodes objectEnumerator];
	NSSet *interconnSet;
	while (interconnSet = [setEnum nextObject]) {
		id<EDUINodeGraphConnectable, NSObject> entryNode = nil;
		id<EDUINodeGraphConnectable, NSObject> exitNode = nil;
		[self findEntryAndExitNodesInInterconnectedSet:interconnSet entryNodePtr:&entryNode exitNodePtr:&exitNode];

		if ([entryNode inputCount] > 0) {		
			// this selected node has inputs; check if we can connect
			EDUICompNodeView *nodeView = [self findNodeViewWithNode:entryNode];
			EDUICompInputView *ourInp = [nodeView inputViewAtIndex:0];
			
			if ([startView shouldConnectToInput:ourInp]) {
				[entryNode disconnectInputAtIndex:0];
				[entryNode connectInputAtIndex:0 toNode:startNode outputIndex:startIndex];
			}
		}
		
		if ([exitNode outputCount] > 0) {
			// this selected node has outputs; need to check if we're connecting to a parameter or not
			EDUICompNodeView *nodeView = [self findNodeViewWithNode:exitNode];
			EDUICompInputView *ourOut = [nodeView outputViewAtIndex:0];
			
			if ([ourOut shouldConnectToInput:endView]) {
				if ([endView isParameter]) {
					id pendnode = endNode;
					[pendnode disconnectParameterAtIndex:endIndex];
					[pendnode connectParameterAtIndex:endIndex toNode:exitNode outputIndex:0];
				}
				else {
					[endNode disconnectInputAtIndex:endIndex];
					[endNode connectInputAtIndex:endIndex toNode:exitNode outputIndex:0];
				}
			}
		}
		
		[_modifiedNodes addObject:entryNode];
		[_modifiedNodes addObject:exitNode];
	}
    
	[self makeConnectors];

    [_modifiedNodes addObject:startNode];
    [_modifiedNodes addObject:endNode];
}


/*
- (void)detachNodesFromTree:(NSSet *)nodeSet
{
	NSEnumerator *nodeViewEnum = [nodeSet objectEnumerator];
	EDUICompNodeView *nodeView;
	while (nodeView = [nodeViewEnum nextObject]) {
		id<EDUINodeGraphConnectable> node = [nodeView node];
		
		int inpCount = [node inputCount];
		int outpCount = [node outputCount];
		
		if (inpCount > 0) {
			// this selected node has inputs
			[node disconnectInputAtIndex:0];
		}
		
		if (outpCount > 0) {
			// node has outputs; get an array containing the first output's downstream connections
			int numDownConns = [node numberOfConnectedNodesForOutputAtIndex:0];
			int *downInpIndexes = _lx_malloc(numDownConns * sizeof(int));
			NSMutableArray *downNodes = [node connectedNodesForOutputAtIndex:0 inputIndexesArray:downInpIndexes];
			
			int i;
			for (i = 0; i < numDownConns; i++) {
				id downNode = [downNodes objectAtIndex:i];
				int diIndex = downInpIndexes[i];
				
				[downNode disconnectInputAtIndex:diIndex];
			}
			
			_lx_free(downInpIndexes);
		}
		
		[_modifiedNodes addObject:node];
	}
	
	[self makeConnectors];

    [_modifiedNodes addObject:startNode];
    [_modifiedNodes addObject:endNode];
}
*/



#pragma mark --- updating view ---

- (void)emptyAllViews
{
    [_rootNodeView release];
    [_rootNodeView removeFromSuperview];
    _rootNodeView = nil;

    [_nodeViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_nodeViews release];
    _nodeViews = nil;
    
    [_connectors release];
    [_compView setConnectorsArray:nil];
    _connectors = nil;
}

- (void)refreshAppearance
{
    [_nodeViews makeObjectsPerformSelector:@selector(updateNodeAppearance)];
	[_connectors makeObjectsPerformSelector:@selector(refreshAppearance)];
    [_compView refreshAppearance];
}

- (void)makeNodeViews
{
    // recreating the view with hover selection enabled caused crashing, so here's the workaround
	BOOL hoverEnabled = [_compView hoverSelectionEnabled];
	if (hoverEnabled)
		[_compView setHoverSelectionEnabled:NO];
    
    EDUICompNodeView *nodeView = nil;
    id <NSObject, EDUINodeGraphConnectable> node = nil;
    NSEnumerator *enumerator;
    NSRect newFrame = NSMakeRect(0, 0, 0, 0);
    NSPoint oldRootOrigin;
    BOOL hasOldRoot = NO;
    

    if (_graph == nil || _compView == nil)
        return;


    const BOOL delegateDecidesNodeClass = [_modelDelegate respondsToSelector:@selector(nodeViewClassForNode:)];
    const BOOL delegateWantsToValidateNodes = [_modelDelegate respondsToSelector:@selector(shouldAddNodeView:forNode:)];    
    const BOOL delegateProvidesNodeColor = [_modelDelegate respondsToSelector:@selector(unselectedColorForNode:)];
    const BOOL rootProvidesCenterPoint = [_graph respondsToSelector:@selector(centerPoint)];

    // maintain previous selection if possible
    id prevSelection = [_compView selectedNode];
    if ([prevSelection isKindOfClass:[NSNumber class]]) {
        // multiple selection
        prevSelection = nil;
    }
    if (prevSelection) {
        if ( !(prevSelection == _graph) &&
             ![[_graph allNodes] containsObject:prevSelection] ) {
            // selection is not the comp root, or a node in the composition
            prevSelection = nil;
        }
    }
    
    
    if ( !rootProvidesCenterPoint && _rootNodeView) {
        oldRootOrigin = [_rootNodeView frame].origin;
        hasOldRoot = YES;
    }
    
    // --- init node view array ---
    [_nodeViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_nodeViews release];
    _nodeViews = [[NSMutableArray arrayWithCapacity:8] retain];
    
    // --- make root view ---
    [_rootNodeView removeFromSuperview];
    [_rootNodeView release];
    _rootNodeView = nil;

    if ([_graph respondsToSelector:@selector(nodeGraphWantsRootNodeView)] && [(id)_graph nodeGraphWantsRootNodeView]) {
        // create a root node view
        nodeView = nil;
        
        if (delegateDecidesNodeClass) {
            Class viewClass = [_modelDelegate nodeViewClassForNode:_graph];
            if (viewClass)
                nodeView = [(EDUICompNodeView *)[viewClass alloc] initWithNode:(id <NSObject, EDUINodeGraphConnectable>)_graph];
        } else {
            nodeView = [[EDUICompNodeView alloc] initWithNode:(id <NSObject, EDUINodeGraphConnectable>)_graph];
        }
        
        if (nodeView) {
            [_compView addSubview:nodeView];
            [nodeView setCompView:_compView];
            [nodeView setLabel:@"Output"];
            _rootNodeView = nodeView;

            if ( !rootProvidesCenterPoint) {
                if (hasOldRoot)
                    [_rootNodeView setFrameOrigin:oldRootOrigin];
                else {
                    // center root node view horizontally
                    NSRect viewBounds = [_compView bounds];
                    NSRect nodeViewFrame = [_rootNodeView frame];
                    [_rootNodeView setFrameOrigin:
                                NSMakePoint(viewBounds.size.width*0.5 - nodeViewFrame.size.width*0.5,
                                            nodeViewFrame.origin.y) ];
                }
            }

            if (delegateProvidesNodeColor)
                [_rootNodeView setAppearanceDelegate:_modelDelegate];

            // --- set scale factor for root node ---
            double rootScale = 1.0;
            if ([_graph respondsToSelector:@selector(globalScaleFactor)])
                rootScale *= [(id)_graph globalScaleFactor];

            if ([_modelDelegate respondsToSelector:@selector(customScaleForNodeView:proposedScale:)]) {
                rootScale = [_modelDelegate customScaleForNodeView:_rootNodeView proposedScale:rootScale];
            }
            if (rootScale != 1.0)
                [_rootNodeView setZoomFactor:rootScale];
            
            [_nodeViews addObject:_rootNodeView];
        }
    }

    // --- make node views ---    
    enumerator = [_graph nodeEnumerator];
    
    while (node = [enumerator nextObject]) {
        nodeView = nil;
        NSRect viewFrame;
        
        if (delegateDecidesNodeClass) {
            Class viewClass = [_modelDelegate nodeViewClassForNode:node];
            if (viewClass)
                nodeView = [[(EDUICompNodeView *)[viewClass alloc] initWithNode:node] autorelease];
        }
        else {
            nodeView = [ [[EDUICompNodeView alloc] initWithNode:node] autorelease];
        }
        
        if (delegateWantsToValidateNodes) {
            BOOL ok = [_modelDelegate shouldAddNodeView:nodeView forNode:node];
            
            if ( !ok)
                nodeView = nil;
        }
        
        if (nodeView) {
            [_nodeViews addObject:nodeView];
            [_compView addSubview:nodeView];
            [nodeView setCompView:_compView];
            [nodeView refreshTrackingRectsForHoverSelection];
            
            if (delegateProvidesNodeColor)
                [nodeView setAppearanceDelegate:_modelDelegate];
            
            if ([node respondsToSelector:@selector(scaleFactor)]) {
                [self refreshCustomScaleForNodeView:nodeView];
            }
            
            viewFrame = [nodeView frame];
            viewFrame.size.width += viewFrame.origin.x;
            viewFrame.size.height += viewFrame.origin.y;
            viewFrame.origin.x = viewFrame.origin.y = 0.0;
            newFrame = NSUnionRect(newFrame, viewFrame);
        }
    }

    [_compView setContentBounds:newFrame];
    
    [self makeConnectors];
    
    // reselect previous selection, if it's within the same comp
    if (prevSelection) {
        [_compView reselectNode:prevSelection];
    } else {
        [_compView clearSelection];
    }
    
    // re-enable hover mode if it was disabled at start of this method
	if (hoverEnabled)
		[_compView setHoverSelectionEnabled:YES];
        
    [_compView controllerDidRecreateNodeViews];
    
    if ([_modelDelegate respondsToSelector:@selector(compViewNodesWereRecreated)])
        [_modelDelegate compViewNodesWereRecreated];
}


- (void)makeConnectors
{
    EDUICompNodeView *nodeView;
    id <NSObject, EDUINodeGraphConnectable> node;
    NSEnumerator *enumerator;

    const BOOL delegateReplacesConnectors = [_modelDelegate respondsToSelector:@selector(customConnectorForConnectionFromOutputView:toInputView:)];
	const BOOL delegateDoesCustomConnectors = [_modelDelegate respondsToSelector:@selector(customConnectorsForNodeView:)];

    ///NSLog(@"---makeconnectors, nodecount %i", [_nodeViews count]);
    
    [_connectors release];
    _connectors = [[NSMutableArray arrayWithCapacity:64] retain];
    enumerator = [_nodeViews objectEnumerator];
    while (nodeView = [enumerator nextObject]) {
        int i, inputCount, paramCount;
    
        node = [nodeView node];
        ///NSLog(@"  ... node %@, inpcount %i", [node name], [node inputCount]);
        
        inputCount = [node inputCount];
        for (i = 0; i < inputCount; i++) {
            EDUICompConnector *conn = nil;
            EDUICompInputView *inpView = nil, *outpView = nil;
            /*
            EDUINodeInput *inp = [inputs objectAtIndex:i];
            int outputIndex = [[inp connectedOutput] index];
            EDUINode *connectedNode = [inp connectedNode];
            */
            
            LXInteger outputIndex;
            id connectedNode = [node connectedNodeForInputAtIndex:i outputIndexPtr:&outputIndex];
            EDUICompNodeView *wantedNodeView = [self findNodeViewWithNode:connectedNode];
            
            //NSLog(@"input found, name %@; connode %@", [inp name], [connectedNode name]);
            
            if (wantedNodeView != nil) {
                inpView = [nodeView inputViewAtIndex:i];
                outpView = [wantedNodeView outputViewAtIndex:outputIndex];
                //NSLog(@"compwindowcontroller makeconnectors: connection inpindex %i outpindex %i", i, outputIndex);
                
                if (delegateReplacesConnectors) {
                    conn = [_modelDelegate customConnectorForConnectionFromOutputView:outpView toInputView:inpView];
                }
                if ( !conn) {
                    conn = [[[EDUICompConnector alloc] init] autorelease];
                    [conn connectFrom:outpView to:inpView];
                }
				
				if ([node respondsToSelector:@selector(connectorNoteForInputAtIndex:positionPtr:)]) {
					LXFloat pos = 0.0f;
					NSString *note = [(id)node connectorNoteForInputAtIndex:i positionPtr:&pos];
					[conn setNote:note];
					[conn setNotePosition:pos];
				}
				
                [_connectors addObject:conn];
                [inpView setConnected:YES toOutputView:outpView];
            }
            else {
                //NSLog(@"makeconnectors: nodeview not found");
            }
        }

        paramCount = [node parameterCount];
        for (i = 0; i < paramCount; i++) {
            EDUICompConnector *conn;
            EDUICompInputView *inpView, *outpView;
            /*
            EDUINodeInput *inp = [[parameters objectAtIndex:i] parameterInput];
            int outputIndex;
            EDUICompNodeView *wantedNodeView;
            EDUINode *connectedNode;

            if (inp != nil) {
                outputIndex = [[inp connectedOutput] index];
                connectedNode = [[inp connectedOutput] ownerNode];
            */
            
            id pnode = node;
            
            if ([pnode parameterHasInputAtIndex:i]) {
                LXInteger outputIndex;
                id connectedNode = [pnode connectedNodeForParameterAtIndex:i outputIndexPtr:&outputIndex];
                EDUICompNodeView *wantedNodeView = [self findNodeViewWithNode:connectedNode];
                
                if (wantedNodeView != nil) {
                    inpView = [nodeView parameterViewAtIndex:i];
                    outpView = [wantedNodeView outputViewAtIndex:outputIndex];
                    //NSLog(@"  (param)inpindex %i outpindex %i; inp origin %f %f", i, outputIndex);
                    conn = [ [[EDUICompConnector alloc] init] autorelease];

					if ([node respondsToSelector:@selector(connectorNoteForParameterInputAtIndex:positionPtr:)]) {
						LXFloat pos = 0.0f;
						NSString *note = [(id)node connectorNoteForParameterInputAtIndex:i positionPtr:&pos];
						[conn setNote:note];
						[conn setNotePosition:pos];
					}

                    [conn connectFrom:outpView to:inpView];
                    [_connectors addObject:conn];
                    [inpView setConnected:YES toOutputView:outpView];
                }
            }
        }
		
		if (delegateDoesCustomConnectors) {
			NSArray *conns = [_modelDelegate customConnectorsForNodeView:nodeView];
			if (conns)
				[_connectors addObjectsFromArray:conns];
		}

    }
	
    [_compView setConnectorsArray:_connectors];
    [_compView setNeedsDisplay:YES];
}


@end
