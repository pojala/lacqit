//
//  EDUIDiscTriangleCell.h
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface EDUIDiscTriangleCell : NSActionCell {

    BOOL        _isOpened;
}

+ (NSImage *)closedTriangle;
+ (NSImage *)highlightedTriangle;
+ (NSImage *)openTriangle;
+ (NSImage *)highlightedOpenTriangle;

- (void)setOpened:(BOOL)flag;
- (BOOL)isOpened;

@end
