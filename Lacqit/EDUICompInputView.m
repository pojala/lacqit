//
//  EDUICompInputView.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUICompInputView.h"
#import "EDUICompNodeView.h"
#import "EDUICompositionView.h"
#import "EDUINodeGraphConnectable.h"
#import "EDUINSImageAdditions.h"


@implementation EDUICompInputView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _highlighted = NO;
        _connected = NO;
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame inView:(EDUICompNodeView *)nodeView index:(NSInteger)index isOutput:(BOOL)isOutput
                                  type:(NSUInteger)type
{
    self = [super initWithFrame:frame];
    if (self) {
        _highlighted = NO;
        _connected = NO;
        _outputConnectionCount = 0;
        _nodeView = nodeView;
        _index = index;
        _isOutput = isOutput;
        if (isOutput)
            _connectedInputViews = [[NSMutableArray arrayWithCapacity:3] retain];
        _isParameter = NO;
        _type = type;
        _name = nil;
        //NSLog(@"edocompinputview init: type %i", type);
    }
    return self;
}

- (void)dealloc {
    if (_isOutput)
        [_connectedInputViews autorelease];
    if (_name)
        [_name release];
    [super dealloc];
}

#pragma mark --- accessors ---

- (void)setNodeTypeDelegate:(id)object {
    _typeDelegate = object; }
    
- (id)nodeTypeDelegate {
    return _typeDelegate; }


- (NSUInteger)type {
    return _type; }

- (BOOL)isParameter {
    return _isParameter; }

- (NSString *)name {
    return _name; }
    
- (void)setIsParameter:(BOOL)val name:(NSString *)name {
    _isParameter = val;
    _name = [name retain];
}

- (void)setHighlighted:(BOOL)boo {
    _highlighted = boo; }

- (BOOL)setConnected:(BOOL)shouldConnect toOutputView:(EDUICompInputView *)inp
{
    if ([[inp nodeView] isEqual:_nodeView])
        return NO;
    
    if (shouldConnect && !_connected) {
        if ([inp shouldConnectToInput:self]) {
            _connected = YES;
            _connectedOutputView = inp;
            [inp didGetConnectedToInputView:self];
            return YES;
        }
        return NO;
    }
    if (!shouldConnect && _connected) {
        _connected = NO;
        [_connectedOutputView didGetDisconnectedFromInputView:self];
        _connectedOutputView = nil;
        return YES;
    }
    return NO;
}

- (BOOL)shouldConnectToInput:(EDUICompInputView *)inp
{
    // checks that input's owner node isn't in connection tree -
    // having a node connected to itself should never happen
    id <EDUINodeGraphConnectable> inpNode = [[inp nodeView] node];
    id <EDUINodeGraphConnectable> outpNode = [_nodeView node];
    
    if ( ![outpNode hasUpstreamConnectionToNode:inpNode] ) {
        if ( [_typeDelegate respondsToSelector:@selector(inputView:acceptsConnectionFrom:)] ) {
            // the delegate decides whether inputs can connect
            return [_typeDelegate inputView:inp acceptsConnectionFrom:self];
        }
        else {
            // no delegation, just check for type match
            NSUInteger inpType = [inp type];
            if (_type == inpType)
                return YES;
        }
    }
    
    return NO;
}

- (void)didGetConnectedToInputView:(EDUICompInputView *)inp {
    _outputConnectionCount++;
    [_connectedInputViews addObject:inp];
    _connected = YES;
}

- (void)didGetDisconnectedFromInputView:(EDUICompInputView *)inp
{
    if (_outputConnectionCount > 0) {
        _outputConnectionCount--;
        [_connectedInputViews removeObject:inp];
    }
    if (_outputConnectionCount < 1) {
        _connected = NO;
        _highlighted = NO;
        [self setNeedsDisplay:YES];
    }
}

- (EDUICompNodeView *)nodeView {
    return _nodeView; }

- (NSInteger)index {
    return _index; }

- (NSArray *)connectedInputViews {
    return _connectedInputViews; }

- (EDUICompInputView *)connectedOutputView {
	if (_connected)
		return _connectedOutputView;
	else
		return nil;
}

- (BOOL)isConnectedInput {
    if (_connectedOutputView && _connected)
        return YES;
    else
        return NO;
}



#pragma mark --- mouse tracking ---


- (void)mouseDown:(NSEvent *)theEvent
{
    NSUInteger modifierFlags = [theEvent modifierFlags];
    BOOL ctrlDown = ((modifierFlags & NSControlKeyMask) ? YES : NO);
    BOOL shiftDown = ((modifierFlags & NSShiftKeyMask) ? YES : NO);
    BOOL altDown = ((modifierFlags & NSAlternateKeyMask) ? YES : NO);
    BOOL RMB = ([theEvent type] == NSRightMouseDown) ? YES : NO;
    EDUICompInputView *prevConnected;
    #pragma unused (prevConnected)

    ///NSLog(@"%@ - mousedown: point %@", self, NSStringFromPoint([self convertPoint:[theEvent locationInWindow] fromView:nil]));

    if (_isOutput) {
        if (! [[_nodeView node] acceptsMultipleOutputConnections]) {
            if (_connected) {
                // our owner node doesn't allow multiple connections from an output, 
                // so disconnect previous connection
                [[_nodeView compView] disconnectInput:[_connectedInputViews objectAtIndex:0]];
            }
        }
    
        if (RMB || ctrlDown) {
            [[_nodeView compView] initiateConnectionFromOutput:self];
            return;
        }
        
        BOOL track = YES;
        if ([theEvent clickCount] == 2) {
            if ([_typeDelegate respondsToSelector:@selector(outputViewDoubleClicked:)]) 
                track = [_typeDelegate outputViewDoubleClicked:self];
        }
        if (shiftDown || altDown) {
            if ([_typeDelegate respondsToSelector:@selector(outputViewClickedWithModifier:flags:)])
                track = [_typeDelegate outputViewClickedWithModifier:self flags:modifierFlags];
        }
        if (track)
            [[_nodeView compView] trackMouseForConnectionWithEvent:theEvent fromOutputAtIndex:_index inNodeView:_nodeView];
    }
    else {
        if (_connected) {
            if (RMB || ctrlDown) {
                //[[_nodeView compView] disconnectInput:self];
                [[_nodeView compView] initiateConnectionSwitchFromInput:self];
                return;
            }
            NSInteger index = [_connectedOutputView index];
            EDUICompNodeView *nodeView = [[_connectedOutputView nodeView] retain];
            
            // track mouse until it's outside our rect, in which case we'll disconnect
            BOOL shouldSwitchConn = NO;
            NSRect bounds = [self bounds];
            while (1) {
                theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
                if (!theEvent || [theEvent type] == NSLeftMouseUp)
                    break;
                NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
                if (!NSMouseInRect(pos, bounds, NO)) {
                    shouldSwitchConn = YES;
                    break;
                }
            }
            if (shouldSwitchConn) {
                [[_nodeView compView] disconnectInput:self];
                [[_nodeView compView] trackMouseForConnectionWithEvent:theEvent fromOutputAtIndex:index
                                                                                inNodeView:nodeView];
            }
            [nodeView release];
        }
        else {
            [[_nodeView compView] finishConnectionToInput:self];
        }
    }
}



#pragma mark --- drawing ---

+ (NSImage *)defaultInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput"] retain];
    return image;
}

+ (NSImage *)highlightedInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_hilite"] retain];
    return image;
}

+ (NSImage *)defaultRGBInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_rgb.tif"] retain];
    return image;
}

+ (NSImage *)highlightedRGBInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_rgb_hilite.tif"] retain];
    return image;
}

+ (NSImage *)defaultPurpleInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_purple.tif"] retain];
    return image;
}

+ (NSImage *)highlightedPurpleInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_purple_hilite.tif"] retain];
    return image;
}

+ (NSImage *)defaultGreenInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_green.tif"] retain];
    return image;
}

+ (NSImage *)highlightedGreenInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_green_hilite.tif"] retain];
    return image;
}

+ (NSImage *)defaultCyanInputImage
{
    static NSImage *image = nil;
    
    if (!image) {
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_cyan.tif"] retain];
    }
    return image;
}


+ (NSImage *)highlightedCyanInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_cyan_hilite.tif"] retain];
    return image;
}

+ (NSImage *)defaultBlueInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_blue.tif"] retain];
    return image;
}


+ (NSImage *)highlightedBlueInputImage
{
    static NSImage *image = nil;
    
    if (!image)
        image = [[NSImage imageInBundleWithName:@"ui_compnodeinput_blue_hilite.tif"] retain];
    return image;
}



- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
    return YES; }



- (void)drawRect:(NSRect)rect
{
    NSImage *image;
    BOOL hilite = (_highlighted || _connected);
    
	BOOL isBypassed = NO;
	id node = [_nodeView node];
    if ([node respondsToSelector:@selector(useBypassedAppearance)])
        isBypassed = [node useBypassedAppearance];
	
    if (_typeDelegate) {
        image = [_typeDelegate imageForInputView:self type:_type highlight:hilite bypassed:isBypassed];
    }
    else {
        if (hilite)
            image = [EDUICompInputView highlightedInputImage];
        else
            image = [EDUICompInputView defaultInputImage];
    }

    NSRect bounds = [self bounds];
	NSSize size = (image) ? [image size] : NSZeroSize;
	NSRect imRect = NSMakeRect(0, 0, size.width, size.height);
	NSPoint point = bounds.origin;
	
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
    [ctx setImageInterpolation:NSImageInterpolationHigh];
    
    ///NSLog(@"%s (%p): bounds %@; frame %@, superview %@", __func__, self, NSStringFromRect(bounds), NSStringFromRect([self frame]), NSStringFromRect([[self superview] frame]));
    
	if (_typeDelegate || !isBypassed) { // if we have a delegate for the image, assume that it has taken care of the bypass look
		//[image compositeToPoint:bounds.origin operation:NSCompositeSourceOver];
        NSRect dstRect = bounds;
		[image drawInRect:dstRect fromRect:imRect operation:NSCompositeSourceOver fraction:1.0];
	} else {
		//[image compositeToPoint:point operation:NSCompositeSourceOver fraction:0.6];
        NSRect dstRect = bounds;
		[image drawInRect:bounds fromRect:imRect operation:NSCompositeSourceOver fraction:0.6];
	}
    
    [ctx restoreGraphicsState];
}

@end
