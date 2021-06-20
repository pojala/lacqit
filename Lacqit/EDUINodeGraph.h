//
//  EDUINodeGraph.h
//  Edo
//
//  Created by Pauli Ojala on 9.4.2005.
//  Copyright 2005 Pauli Olavi Ojala. All rights reserved.
//

#import "LQUIFrameworkHeader.h"



@protocol EDUINodeGraph

- (NSArray *)allNodes;
- (NSEnumerator *)nodeEnumerator;

@end


@protocol EDUINodeGraphOptionalMethods

- (void)setCompBackgroundColor:(NSColor *)c;
- (NSColor *)compBackgroundColor;

- (unsigned int)numberOfCompBackgroundRects;
- (NSRect)compBackgroundRectAtIndex:(int)index compView:(NSView *)view;
- (NSString *)nameOfCompBackgroundRectAtIndex:(int)index compView:(NSView *)view;
- (NSColor *)colorOfCompBackgroundRectAtIndex:(int)index compView:(NSView *)view;

- (void)setGlobalScaleFactor:(double)z;
- (double)globalScaleFactor;

- (BOOL)nodeGraphWantsRootNodeView;

@end
