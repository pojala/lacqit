//
//  LQListView.m
//  PixelMath
//
//  Created by Pauli Ojala on 2.4.2007.
//  Copyright 2007 Lacquer Oy. All rights reserved.
//

#import "LQListView.h"


@implementation LQListView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _items =   [[NSMutableArray arrayWithCapacity:32] retain];
		_itemVis = [[NSMutableArray arrayWithCapacity:32] retain];
        
        _selectedIndex = -1;
    }
    return self;
}

- (void)dealloc {
	[_items release];
	[_itemVis release];
	[super dealloc];
}


#pragma mark --- packing subviews ---

- (BOOL)isFlipped {
	return YES; }

- (void)repackSubviews
{
    NSArray *oldSubviews = [[[self subviews] copy] autorelease];  // must copy array to prevent -removeFromSuperview from possibly mutating it
    [oldSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	
	LXInteger count = [_items count];
	double h = 0.0;
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
    
    double w = [self frame].size.width;

	LXInteger i;
	for (i = 0; i < count; i++) {
		NSView *item = [_items objectAtIndex:i];
		BOOL vis = [[_itemVis objectAtIndex:i] boolValue];
		
		if (vis) {
			NSSize frameSize = [item frame].size;
			NSRect newFrame = NSMakeRect(0, h,  frameSize.width, frameSize.height);
            
            if ([item autoresizingMask] & NSViewWidthSizable) {
                newFrame.size.width = w;
            }
						
			[item setFrame:newFrame];
			[arr addObject:item];
			h += frameSize.height;
			
			//NSLog(@"  .. visible item at idx %ld is %@: frame %@", (long)i, item, NSStringFromRect(newFrame));
		}
	}
	
	NSRect frame = [self frame];
	frame.size.height = h;
	[self setFrame:frame];
    
    //NSLog(@"... %@: frame is %@, in window %@", self, NSStringFromRect(frame), NSStringFromRect([self convertRect:[self bounds] toView:nil]));
	
	NSEnumerator *en = [arr objectEnumerator];
	NSView *item;
	while (item = [en nextObject]) {
		[self addSubview:item];
	}
    [[self superview] setNeedsDisplay:YES];
    
    if (_selectedIndex >= count)
        _selectedIndex = count;
}


#pragma mark --- accessors ---

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }


- (void)addItem:(NSView *)item {
	if ( !item) return;
	
	[_items addObject:item];
	[_itemVis addObject:[NSNumber numberWithBool:YES]];
	//[self repackSubviews];
}

- (void)insertItem:(NSView *)item atIndex:(LXInteger)index {
    if ( !item) return;
    
    [_items insertObject:item atIndex:index];
    [_itemVis insertObject:[NSNumber numberWithBool:YES] atIndex:index];
	//[self repackSubviews];
}

- (void)removeItemAtIndex:(LXInteger)index
{
    if (index < 0 || index == NSNotFound || index >= [_items count])
        return;
        
    [_items removeObjectAtIndex:index];
    [_itemVis removeObjectAtIndex:index];
    //[self repackSubviews];
}


- (LXInteger)numberOfItems {
	return [_items count]; }
	
- (LXInteger)indexOfItem:(NSView *)item {
	LXInteger index = [_items indexOfObject:item];
	return index;
}

- (NSView *)itemAtIndex:(LXInteger)index {
	return [_items objectAtIndex:index];
}

- (void)setVisible:(BOOL)f forItem:(NSView *)item {
	LXInteger index = [_items indexOfObject:item];
	if (index != NSNotFound) {
		[_itemVis replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:f]];
    } else {
        NSLog(@"** %s: can't find item: %@", __func__, item);
    }

    //[self repackSubviews];
}

- (void)setVisible:(BOOL)f forItemAtIndex:(LXInteger)index {
	if (index != NSNotFound && index >= 0)
		[_itemVis replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:f]];	

    //[self repackSubviews];
}

- (BOOL)isVisibleForItem:(NSView *)item {
    LXInteger index = [_items indexOfObject:item];
    if (index != NSNotFound && index >= 0)
        return [[_itemVis objectAtIndex:index] boolValue];
    else
        return NO;
}

- (void)setSelectedIndex:(LXInteger)index {
    _selectedIndex = index;
    [self setNeedsDisplay:YES];
}

- (LXInteger)selectedIndex {
    return _selectedIndex; }

- (void)setDrawsHorizontalLines:(BOOL)f {
    _drawsHorizLines = f; }
    
- (BOOL)drawsHorizontalLines {
    return _drawsHorizLines; }


#pragma mark --- events ---

- (LXInteger)itemAtPoint:(NSPoint)p
{
    NSEnumerator *itemEnum = [_items objectEnumerator];
    LXInteger n = 0;
    id item;
    while (item = [itemEnum nextObject]) {
        NSRect frame = [item frame];
        if (frame.origin.y <= p.y && (frame.origin.y + frame.size.height) > p.y)
            return n;
        n++;
    }
    return NSNotFound;
}

- (void)mouseDown:(NSEvent *)event
{
    if ([_delegate respondsToSelector:@selector(listView:itemClickedAtIndex:)]) {
        LXInteger item = [self itemAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
    
        if (item != NSNotFound) {
            [_delegate listView:self itemClickedAtIndex:item];
        }
    }
    else [super mouseDown:event];
}


#pragma mark --- drawing ---

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = [self bounds];
    BOOL doesAutoresizeHoriz = ([self autoresizingMask] & NSViewWidthSizable);

    if (_drawsHorizLines) {
        LXInteger count = [_items count];
        LXInteger i;
        for (i = 1; i < count; i++) {
            NSRect frame = [[_items objectAtIndex:i] frame];
            
            frame.origin.y += 0.5;
            
            if (doesAutoresizeHoriz) {
                frame.size.width = bounds.size.width;
            }
            
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint:frame.origin];
            [path lineToPoint:NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y)];

            [[NSColor colorWithDeviceRed:0.103 green:0.1 blue:0.11 alpha:0.18] set];            
            [path stroke];
        }
    }

    if (_selectedIndex >= 0) {
        NSRect frame = [[_items objectAtIndex:_selectedIndex] frame];
        
        //NSLog(@"painting rect: %@", NSStringFromRect(frame));
        
        frame = NSInsetRect(frame, 0.0, 2.0);
        
        [[NSColor colorWithDeviceRed:0.55 green:0.55 blue:0.58 alpha:1.0] set];
        NSRectFill(frame);        
    }
}

@end
