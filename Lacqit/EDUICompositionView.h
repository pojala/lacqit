//
//  EDUICompositionView.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "EDUICompViewController.h"


@class EDUICompNodeView, EDUICompInputView;
@class LQGradient;


extern const int EDUICompViewMultipleSelected;   // constant returned by -selectedNode method

typedef enum {
	EDUILeft = 1,
	EDUIRight,
	EDUIUp,
	EDUIDown
} EDUIDirection;


@interface EDUICompositionView : NSView {

    IBOutlet EDUICompViewController *_controller;

    NSMutableArray		*_connectors;
    NSMutableArray		*_selection;
    
    BOOL                _spacebarIsPressed;
    BOOL                _mouseDown;
    BOOL                _shouldStartPan, _didPan;
    NSPoint             _mouseLocation;
    NSRect              _originalBounds;
    NSPoint             _originalBgOffset;
    
	BOOL				_enableHoverSel;
    BOOL                _enableShakeLoose;
    BOOL                _isBoxSelecting;
    BOOL                _clearSelOnResignFirstResp;
    NSRect              _selectionBox;
    NSMutableArray      *_connectorsWithinSelection;  // list of connectors that are part of the selection (so they can be excluded from drop-on)
    
    BOOL                _makingConnection;
    EDUICompInputView    *_makingConnectionFromOutput;
    EDUICompInputView    *_inputViewToBeConnected;   // this input's name is displayed
    NSInteger           _inputViewToConnectLabelDisplayPosition;
    
    NSColor             *_bgColor;
    CGFloat             _bgAlpha;
    NSPoint             _bgOffset;
    NSDictionary        *_inputLabelAttribs;
    NSRect              _contentBounds;
    LQGradient          *_topGradient;
    double              _topGradH;
	
	NSMenu				*_contextMenu;  // right-click context menu for the comp background
	BOOL				_contextMenuWasInited;
	
	id					_currConn;
	BOOL				_clickedOnConnectorNote;
	BOOL				_connectorNotesVisible;
	id					_currEditedNodeView;
	NSTextField			*_nameEditor;

    BOOL                _debugInfoEnabled;
    
    NSArray             *_dragPboardTypes;
	NSPoint				_prevDragPoint;
	id					_prevDragConnector;
    
    NSArray             *_allOutputs;  // temporary state while within output tracking loop
}

//+ (NSDictionary *)inputLabelTextAttributes;

- (void)setConnectorsArray:(NSMutableArray *)connectors;

- (NSRect)contentBounds;
- (void)setContentBounds:(NSRect)bounds;

- (BOOL)connectorNotesVisible;
- (void)setConnectorNotesVisible:(BOOL)flag;
- (BOOL)hoverSelectionEnabled;
- (void)setHoverSelectionEnabled:(BOOL)flag;
- (BOOL)shakeLooseEnabled;
- (void)setShakeLooseEnabled:(BOOL)flag;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)color;

// visual decoration for a shadow at the top
- (void)setTopGradient:(LQGradient *)gradient height:(double)gradH;

- (void)refreshAppearance;
- (NSDictionary *)inputLabelTextAttributes;

// selection
- (id)selectedNode;
- (NSMutableArray *)selection;

- (void)mouseEnteredNodeView:(EDUICompNodeView *)nodeView;
- (void)replaceSelection:(NSMutableArray *)newSelection;
- (void)addToSelection:(EDUICompNodeView *)nodeView;
- (void)removeFromSelection:(EDUICompNodeView *)nodeView;
- (void)clearSelection;
- (void)selectAll;
- (void)shakeSelectionLoose;
- (void)duplicateSelectionOnDrag;
- (void)walkSelectionWithinTree:(EDUIDirection)dir;

- (void)startSelectionMoveAtPoint:(NSPoint)point;
- (void)moveSelectionToPoint:(NSPoint)point;
- (void)endSelectionMoveAtPoint:(NSPoint)point;

- (void)connectNodeIntoActiveContextMenuConnector:(id)node;

// this method can be used for selection update;
// it differs from -addToSelection in that it doesn't send a notification the controller's modelDelegate
- (void)reselectNode:(id)node;

- (void)initiateConnectionFromOutput:(EDUICompInputView *)inputView;
- (void)initiateConnectionSwitchFromInput:(EDUICompInputView *)inputView;
- (BOOL)makingConnection;
- (void)finishConnectionToInput:(EDUICompInputView *)inputView;
- (void)trackMouseForConnectionWithEvent:(NSEvent *)theEvent fromOutputAtIndex:(int)outpIndex inNodeView:(EDUICompNodeView *)outpNodeView;

- (void)trackMouseForOutputsWithCallbackTarget:(id)target;  // target needs to respond to callback methods (in category below)
- (void)trackMouseForZoomingWithEvent:(NSEvent *)theEvent;

- (void)disconnectInput:(EDUICompInputView *)input;
- (NSPoint)originForNewNodeView;

- (void)makeInputLabelTextAttributes;

- (BOOL)debugInfoEnabled;
- (void)setDebugInfoEnabled:(BOOL)flag;

- (void)setSupportedPboardTypesForDragReceive:(NSArray *)array;
- (NSArray *)supportedPboardTypesForDragReceive;

- (void)setNote:(NSString *)newNote forConnector:(EDUICompConnector *)conn;

- (void)showNameEditorForNodeView:(EDUICompNodeView *)nodeView;

- (void)recalcContentBounds;
- (void)controllerDidRecreateNodeViews;
- (void)controllerDidResetNodeGraph;

- (void)setClearsSelectionQuietlyWhenResignsFirstResponder:(BOOL)f;

@end


@interface NSObject ( EDUICompositionViewCallbackMethods )

- (void)mouseEnteredOutputView:(EDUICompInputView *)view withEvent:(NSEvent *)event;
- (void)mouseExitedOutputView:(EDUICompInputView *)view withEvent:(NSEvent *)event;

@end
