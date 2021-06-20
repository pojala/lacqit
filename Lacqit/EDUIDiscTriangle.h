//
//  EDUIDiscTriangle.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface EDUIDiscTriangle : NSControl {

    NSColor *_color;

#if defined(__LAGOON__)
	BOOL _isOpen;
#endif
}

- (void)setOpened:(BOOL)flag;
- (BOOL)isOpened;

- (void)setColor:(NSColor *)color;
- (NSColor *)color;

@end
