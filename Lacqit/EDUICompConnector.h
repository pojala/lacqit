//
//  EDUICompConnector.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
@class EDUICompInputView;

@interface EDUICompConnector : NSObject {

    EDUICompInputView	*_fromOutput;
    EDUICompInputView	*_toInput;
    BOOL		_connected;
    BOOL		_drawToFrameOrigin;
	
	BOOL		_useGradient;
	NSColor		*_startColor, *_endColor;

	BOOL		_hilite;

	NSRect		*_dropRects;
    NSInteger   _dropRectArraySize;
    NSInteger   _dropRectCount;
	BOOL		_dropRectsAreDirty;
	
	NSString	*_note;
	float		_notePos;
}

- (BOOL)isConnected;
- (void)setDrawToOrigin:(BOOL)boo;
- (void)connectFrom:(EDUICompInputView *)fromView to:(EDUICompInputView *)toView;
- (void)setInput:(EDUICompInputView *)toView;
- (void)clearConnection;
- (void)drawInPath:(NSBezierPath *)path inView:(NSView *)view noteVisible:(BOOL)showNote;

- (EDUICompInputView *)fromOutput;
- (EDUICompInputView *)toInput;
- (NSPoint)pointAtPosition:(float)pos;
- (float)positionAtPoint:(NSPoint)point;

- (void)setUseGradient:(BOOL)grad;
- (BOOL)useGradient;
- (void)setStartColor:(NSColor *)color;
- (void)setEndColor:(NSColor *)color;

- (void)setHighlighted:(BOOL)hilite;
- (BOOL)isHighlighted;

- (void)setNote:(NSString *)note;
- (NSString *)note;
- (void)setNotePosition:(float)pos;
- (float)notePosition;

- (NSRect)noteRect;
- (NSRect *)dropRectsWithCountPtr:(NSInteger *)pRectCount;

- (void)refreshAppearance;
- (void)nodesWereMoved;

@end
