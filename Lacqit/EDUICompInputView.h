//
//  EDUICompInputView.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@class EDUICompNodeView;


@interface EDUICompInputView : NSView {

    BOOL	_highlighted;
    BOOL	_connected;
    BOOL	_isOutput;
    BOOL	_isParameter;
    
    EDUICompInputView	*_connectedOutputView;      // used if this is an input
    
    int                 _outputConnectionCount;     // used if this is an output
    NSMutableArray      *_connectedInputViews;      // ""
    
    EDUICompNodeView    *_nodeView;
    NSInteger           _index;
    NSUInteger          _type;
    NSString            *_name;
    
    id                  _typeDelegate;
}

- (id)initWithFrame:(NSRect)rect inView:(EDUICompNodeView *)nodeView index:(NSInteger)index
        isOutput:(BOOL)isOutput type:(NSUInteger)type;

- (void)setNodeTypeDelegate:(id)object;
- (id)nodeTypeDelegate;

- (NSUInteger)type;
- (BOOL)isParameter;
- (NSString *)name;
- (void)setIsParameter:(BOOL)flag name:(NSString *)name;
- (void)setHighlighted:(BOOL)flag;
- (BOOL)setConnected:(BOOL)flag toOutputView:(EDUICompInputView *)inp;
- (BOOL)isConnectedInput;

- (BOOL)shouldConnectToInput:(EDUICompInputView *)inp;
- (void)didGetConnectedToInputView:(EDUICompInputView *)inp;
- (void)didGetDisconnectedFromInputView:(EDUICompInputView *)inp;

- (EDUICompNodeView *)nodeView;
- (NSInteger)index;
- (NSArray *)connectedInputViews;
- (EDUICompInputView *)connectedOutputView;

+ (NSImage *)defaultInputImage;
+ (NSImage *)highlightedInputImage;

+ (NSImage *)defaultRGBInputImage;
+ (NSImage *)highlightedRGBInputImage;

+ (NSImage *)defaultPurpleInputImage;
+ (NSImage *)highlightedPurpleInputImage;

+ (NSImage *)defaultGreenInputImage;
+ (NSImage *)highlightedGreenInputImage;

+ (NSImage *)defaultCyanInputImage;
+ (NSImage *)highlightedCyanInputImage;

+ (NSImage *)defaultBlueInputImage;
+ (NSImage *)highlightedBlueInputImage;

@end


@interface NSObject ( EDUICompInputViewNodeTypeDelegate )

- (NSImage *)imageForInputView:(EDUICompInputView *)view type:(unsigned int)type highlight:(BOOL)hilite bypassed:(BOOL)bypass;

- (BOOL)inputView:(EDUICompInputView *)inpView acceptsConnectionFrom:(EDUICompInputView *)outpView;

- (BOOL)inputView:(EDUICompInputView *)inpView acceptsConnectorDropOfType:(NSString *)pboardType list:(NSArray *)plist;

- (BOOL)outputViewDoubleClicked:(EDUICompInputView *)inpView;

- (BOOL)outputViewClickedWithModifier:(EDUICompInputView *)inpView flags:(unsigned int)modifierFlags;

@end
