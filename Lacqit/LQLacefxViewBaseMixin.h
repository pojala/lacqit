//
//  LQLacefxViewBaseMixin.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import <Lacefx/Lacefx.h>
#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
#import "LQLXBasicFunctions.h"
#import "LQLXPixelBuffer.h"
#import "LacqitExport.h"

@class LQXCell;


@interface LQLacefxViewBaseMixin : NSObject {

    NSMutableArray  *_cells;
    
    id              _activeTrackingCell;
    
    id _view;
    id _cellDelegate;
    
    NSMutableDictionary *_attributes;
}

- (id)initWithView:(id)view;

- (void)addCell:(LQXCell *)cell;
- (void)removeCell:(LQXCell *)cell;
- (LQXCell *)cellNamed:(NSString *)name;
- (NSArray *)cells;

- (void)setCellDelegate:(id)del;
- (id)cellDelegate;

- (BOOL)handleMouseDownInCells:(NSEvent *)event;
- (BOOL)handleMouseDraggedInCells:(NSEvent *)event;
- (BOOL)handleMouseUpInCells:(NSEvent *)event;

- (void)setValue:(id)value forUIContextAttribute:(NSString *)key;
- (id)valueForUIContextAttribute:(NSString *)key;

@end


@interface NSObject (LQLacefxViewDelegateMethods)

- (void)viewFrameDidChange:(NSView *)view;
- (void)cursorUpdate:(NSEvent *)event;
- (void)updateTrackingAreasForView:(NSView *)view;

- (LXTextureRef)contentTextureForLacefxView:(id)view;

- (void)drawContentsForLacefxView:(id)view inSurface:(LXSurfaceRef)lxSurface;

- (BOOL)shouldBeginDrawForLacefxView:(id)view;
- (void)didEndDrawForLacefxView:(id)view;

- (BOOL)handleMouseDown:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleRightMouseDown:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleMouseDragged:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleMouseUp:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleScrollWheel:(NSEvent *)event inLacefxView:(id)view;

- (BOOL)handleKeyDown:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleKeyUp:(NSEvent *)event inLacefxView:(id)view;

- (BOOL)handleMagnify:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleSmartMagnify:(NSEvent *)event inLacefxView:(id)view;  // two-finger double-tap
- (BOOL)handleSwipe:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleBeginGesture:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleTouchesMovedInGesture:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleEndGesture:(NSEvent *)event inLacefxView:(id)view;

- (NSDragOperation)dragOperationForDrag:(id <NSDraggingInfo>)sender inLacefxView:(id)view didEnter:(BOOL)didEnter;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender inLacefxView:(id)view;
- (void)dragOperationExited:(id <NSDraggingInfo>)sender inLacefxView:(id)view;

@end


@interface NSObject (LQLacefxViewCellDelegateMethods)

- (BOOL)handleMouseDownInCells:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleMouseDraggedInCells:(NSEvent *)event inLacefxView:(id)view;
- (BOOL)handleMouseUpInCells:(NSEvent *)event inLacefxView:(id)view;

@end
