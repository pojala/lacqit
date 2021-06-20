//
//  EDUICompViewController.h
//  Edo
//
//  Created by Pauli Ojala on 26.4.2005.
//  Copyright 2005 Pauli Olavi Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "EDUINodeGraphConnectable.h"
#import "EDUINodeGraph.h"
@class EDUICompositionView, EDUICompNodeView, EDUICompInputView, EDUICompConnector;


// this class is meant to be instanced in Interface Builder;
// the two outlet connections are required for proper operation.
//
// on non-OSX builds, the controller should set the outlets manually,
// so they are declared public

@interface EDUICompViewController : NSObject {

    IBOutlet id                     _modelDelegate;
    IBOutlet EDUICompositionView     *_compView;

    id <NSObject, EDUINodeGraph>   _graph;

    EDUICompNodeView     *_rootNodeView;
    NSMutableArray      *_nodeViews;
    NSMutableArray      *_connectors;

    NSMutableSet        *_modifiedNodes;
    
    // a counter to keep track of when we enter model-modifying operations
    NSInteger           _inModelModif;
}

- (EDUICompositionView *)compView;

- (void)setModelDelegate:(id)delegate;
- (id)modelDelegate;

- (void)setNodeGraph:(id <NSObject, EDUINodeGraph>)graph;
- (id <NSObject, EDUINodeGraph>)nodeGraph;

- (void)setGraphZoomFactor:(double)zoomFactor;
- (void)setGraphZoomFactor:(double)zoomFactor centerAt:(NSPoint)centerPoint;

// managing compview subviews
- (NSMutableArray *)nodeViews;
- (EDUICompNodeView *)findNodeViewWithNode:(id <NSObject, EDUINodeGraphConnectable>)wantedNode;

- (void)addNodeToView:(id <NSObject, EDUINodeGraphConnectable>)node;
- (void)deleteNodeView:(EDUICompNodeView *)nodeView;
- (void)deleteSelectedNodeViews;

- (void)emptyAllViews;
- (void)refreshAppearance;
- (void)refreshCustomScaleForNodeView:(EDUICompNodeView *)nodeView;
- (void)makeNodeViews;
- (void)makeConnectors;

// modifying connections within model
- (void)addToModelConnectionFrom:(EDUICompInputView *)fromView to:(EDUICompInputView *)toView;
- (void)disconnectInput:(EDUICompInputView *)inputView;
- (void)connectNodes:(id)nodeSet betweenOutput:(EDUICompInputView *)fromView andInput:(EDUICompInputView *)toView;
- (void)willModifyModel;
- (void)finishedModifyingModel;

- (void)compViewSelectedNodesWereMoved;
- (void)compViewWasPannedByOffset:(NSPoint)offset;

// utility methods for finding interconnected groups of nodes within a set (i.e. the current selection).
// these methods are used by connectNodes:betweenOutput:andInput:, and they are also useful for implementing
// the same smarter behaviour for copy&paste, etc.
- (NSArray *)findInterconnectedNodesInSet:(NSSet *)origSet;
- (void)findEntryAndExitNodesInInterconnectedSet:(NSSet *)set
						entryNodePtr:(id<EDUINodeGraphConnectable> *)pEntryNode
						exitNodePtr:(id<EDUINodeGraphConnectable> *)pExitNode;

@end


@interface NSObject ( EDUICompViewModelDelegateCategory )

- (void)compViewWillModifyModel;
- (void)compViewDidModifyModel;

- (void)connectionsWereModifiedForNodes:(NSSet *)nodes;
- (void)compViewSelectionWasModified;
- (void)nodeViewWasReselected:(id)nodeView;

- (void)compViewNodeAbsolutePositionsDidChange;  // sent when nodes are dragged or the view is panned
- (void)compViewNodesWereRecreated;

- (NSSet *)duplicateSelection;
- (void)deleteSelection;
- (void)shakeSelectionLoose;
- (void)copySelectionToClipboard;
- (void)cutSelectionToClipboard;
- (void)pasteNodesFromClipboard;

- (void)moveCurrentTimeByFrames:(int)frames;

- (Class)nodeViewClassForNode:(id)node;  // if delegate returns nil, node view isn't created
- (BOOL)shouldAddNodeView:(EDUICompNodeView *)nodeView forNode:(id)node;

- (float)customScaleForNodeView:(EDUICompNodeView *)nodeView proposedScale:(float)sc;

- (id)customConnectorForConnectionFromOutputView:(EDUICompInputView *)outpView toInputView:(EDUICompInputView *)inpView;
- (NSArray *)customConnectorsForNodeView:(EDUICompNodeView *)nodeView;

- (BOOL)mouseDownInCompView:(NSView *)view event:(NSEvent *)event;
- (BOOL)keyDownInCompView:(NSView *)view event:(NSEvent *)event;
- (BOOL)keyUpInCompView:(NSView *)view event:(NSEvent *)event;
- (void)willShowContextMenu:(NSMenu *)menu forCompView:(NSView *)view firstTime:(BOOL)firstTime;
- (void)willShowContextMenu:(NSMenu *)menu forCompConnectorWithInputView:(EDUICompInputView *)inpView;

- (NSSet *)compViewReceivedDragOfType:(NSString *)pboardType list:(NSArray *)plist atPoint:(NSPoint)point;
- (BOOL)compViewReceivedDragOfURL:(NSURL *)url atPoint:(NSPoint)point;

- (BOOL)compViewShouldDrawContentsInRect:(NSRect)rect;
- (void)compViewCustomBackgroundDrawInRect:(NSRect)rect;

- (void)doubleClickOnNodeView:(EDUICompNodeView *)nodeView;

- (void)finishedEditingNameForNodeView:(EDUICompNodeView *)nodeView newName:(NSString *)newName;
- (BOOL)shouldEditNoteForConnector:(EDUICompConnector *)connector atPoint:(NSPoint)pos;

@end;
