//
//  LQCairoBitmapView.h
//  Lacqit
//
//  Created by Pauli Ojala on 13.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQCairoBitmap.h"


@interface LQCairoBitmapView : NSView {

    LQCairoBitmap *_bitmap;
    
    id _delegate;
    
    void *_nativeCtx;
}

- (void)setDelegate:(id)del;
- (id)delegate;

- (LQCairoBitmap *)cairoBitmap;

- (cairo_t *)lockCairoContext;
- (void)unlockCairoContext;

@end


@interface NSObject (LQCairoBitmapViewDelegateMethods)

- (BOOL)handleMouseDown:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view;
- (BOOL)handleMouseDragged:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view;
- (BOOL)handleMouseUp:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view;

- (BOOL)handleKeyDown:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view;
- (BOOL)handleKeyUp:(NSEvent *)event inCairoBitmapView:(LQCairoBitmapView *)view;

@end
