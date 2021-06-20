//
//  LQLacefxViewBaseMixin.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQLacefxViewBaseMixin.h"
#import "LQXCell.h"


@implementation LQLacefxViewBaseMixin

- (id)initWithView:(id)view
{
    self = [super init];
    
    _view = view;
    
    _cells = [[NSMutableArray arrayWithCapacity:32] retain];
    
    _attributes = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_cells release];
    [_attributes release];
    
    _view = nil;

    [super dealloc];
}

- (void)setValue:(id)value forUIContextAttribute:(NSString *)key
{
    if ( !value)
        [_attributes removeObjectForKey:key];
    else {
        [_attributes setObject:value forKey:key];
    }
}

- (id)valueForUIContextAttribute:(NSString *)key
{
    return [_attributes objectForKey:key];
}


- (void)addCell:(LQXCell *)cell {
    [_cells addObject:cell];
}

- (void)removeCell:(LQXCell *)cell {
    long index = [_cells indexOfObject:cell];
    if (index != NSNotFound) {
        [_cells removeObjectAtIndex:index];
    }
}


- (LQXCell *)cellNamed:(NSString *)name {
    NSEnumerator *cellEnum = [_cells objectEnumerator];
    id cell;
    while (cell = [cellEnum nextObject]) {
        if ([[cell name] isEqualToString:name])
            return cell;
    }
    return nil;
}

- (NSArray *)cells {
    return _cells; }
    
    
- (void)setCellDelegate:(id)del {
    _cellDelegate = del; }
    
- (id)cellDelegate {
    return _cellDelegate; }



#pragma mark --- events ---

- (BOOL)handleMouseDownInCells:(NSEvent *)event
{
    if ([_cellDelegate respondsToSelector:@selector(handleMouseDownInCells:inLacefxView:)]) {
        if ([_cellDelegate handleMouseDownInCells:event inLacefxView:_view])
            return YES;
    }

    if ([_cells count] < 1)
        return NO;
    
    NSPoint pos = [_view convertPoint:[event locationInWindow] fromView:nil];
    BOOL didHandle = NO;
    
    NSEnumerator *cellEnum = [_cells objectEnumerator];
    LQXCell *cell;
    while (cell = [cellEnum nextObject]) {
        NSRect frame = [cell frame];
        
        if (NSPointInRect(pos, frame)) {
            NSPoint posInCell = NSMakePoint(pos.x + frame.origin.x,  pos.y + frame.origin.y);
        
            if ([cell handleMouseDown:event location:posInCell]) {
                _activeTrackingCell = cell;
                didHandle = YES;
            }
        }
    }
    return didHandle;
}

- (BOOL)handleMouseDraggedInCells:(NSEvent *)event
{
    if ([_cellDelegate respondsToSelector:@selector(handleMouseDraggedInCells:inLacefxView:)]) {
        if ([_cellDelegate handleMouseDraggedInCells:event inLacefxView:_view])
            return YES;
    }

    BOOL didHandle = NO;
    
    if (_activeTrackingCell) {
        NSPoint pos = [_view convertPoint:[event locationInWindow] fromView:nil];
        NSRect frame = [_activeTrackingCell frame];
        NSPoint posInCell = NSMakePoint(pos.x + frame.origin.x,  pos.y + frame.origin.y);
    
        [_activeTrackingCell handleMouseDragged:event location:posInCell];    
        didHandle = YES;
    }
    return didHandle;
}

- (BOOL)handleMouseUpInCells:(NSEvent *)event
{
    if ([_cellDelegate respondsToSelector:@selector(handleMouseUpInCells:inLacefxView:)]) {
        if ([_cellDelegate handleMouseUpInCells:event inLacefxView:_view])
            return YES;
    }

    BOOL didHandle = NO;
    
    if (_activeTrackingCell) {
        NSPoint pos = [_view convertPoint:[event locationInWindow] fromView:nil];
        NSRect frame = [_activeTrackingCell frame];
        NSPoint posInCell = NSMakePoint(pos.x + frame.origin.x,  pos.y + frame.origin.y);
    
        if ([_activeTrackingCell handleMouseUp:event location:posInCell]) {
            _activeTrackingCell = nil; 
        }
        didHandle = YES;
    }
    return didHandle;
}

@end
