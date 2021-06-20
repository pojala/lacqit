//
//  LQXCell.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
@class LQBitmap;


@interface LQXCell : NSObject {

    NSRect      _frame;

    NSString    *_name;
    id          _delegate;

    LQBitmap     *_contentBitmap;
    LXSurfaceRef _contentSurf;
}

- (id)initWithFrame:(NSRect)frame;

- (void)setDelegate:(id)del;
- (id)delegate;

- (void)setName:(NSString *)name;
- (NSString *)name;

- (void)setFrame:(NSRect)frame;
- (NSRect)frame;

- (void)setContentLQBitmap:(LQBitmap *)frame;
- (void)setContentLXSurface:(LXSurfaceRef)surface;

- (void)drawInSurface:(LXSurfaceRef)surface;

- (BOOL)handleMouseDown:(NSEvent *)event location:(NSPoint)pos;
- (BOOL)handleMouseDragged:(NSEvent *)event location:(NSPoint)pos;
- (BOOL)handleMouseUp:(NSEvent *)event location:(NSPoint)pos;

@end

