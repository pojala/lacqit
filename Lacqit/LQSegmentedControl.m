//
//  LQSegmentedControl.m
//  Edo
//
//  Created by Pauli Ojala on 17.5.2006.
//  Copyright 2006 Lacquer Oy. All rights reserved.
//

#import "LQSegmentedControl.h"
#import "LQSegmentedCell.h"


static LXInteger g_defaultInterfaceTint = kLQSystemTint;


@implementation LQSegmentedControl

+ (void)setDefaultInterfaceTint:(LQInterfaceTint)tint {
    g_defaultInterfaceTint = tint; }
    
+ (LQInterfaceTint)defaultInterfaceTint {
    return g_defaultInterfaceTint; }


- (void)resetCellClass
{
    id prevCell = [self cell];
    LQSegmentedCell *newCell = [[[LQSegmentedCell alloc] initTextCell:@""] autorelease];
    [newCell copySettingsFromCell:prevCell];
    
    [newCell setInterfaceTint:([prevCell respondsToSelector:@selector(interfaceTint)]) ? [prevCell interfaceTint] : g_defaultInterfaceTint];
    
    [self setCell:newCell];
    [self setNeedsDisplay:YES]; 
}

- (void)awakeFromNib
{
    [self resetCellClass];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self resetCellClass];
    }
    return self;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint {
    if ( ![[self cell] respondsToSelector:@selector(interfaceTint)])
        [self resetCellClass];
        
    [[self cell] setInterfaceTint:tint];
}
    
- (LQInterfaceTint)interfaceTint {
    if ( ![[self cell] respondsToSelector:@selector(interfaceTint)])
        [self resetCellClass];
        
    return [[self cell] interfaceTint];
}

- (void)setTrackingMode:(LQSegmentSwitchTracking)trackingMode {
    [[self cell] setTrackingMode:trackingMode];
}

- (LQSegmentSwitchTracking)trackingMode {
    return [[self cell] trackingMode];
}

- (void)setImage:(NSImage *)image withFixedSize:(NSSize)size opacity:(LXFloat)opacity
{
    if (image) {
        [[self cell] setImage:image forSegment:0];
        [[self cell] setFixedImageSizeEnabled:YES];
        [[self cell] setImageOpacity:opacity];
        [[self cell] setFixedImageSize:size];
    }
}


- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    ///NSLog(@"%@: frame now %@ (arg %@)", self, NSStringFromRect([self frame]), NSStringFromRect(frame));
}


- (LXInteger)_findSegmentWithEvent:(NSEvent *)event
{
    NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    
    LXInteger i;
    LXInteger segCount = [[self cell] segmentCount];
    NSRect bounds = [self bounds];
    CGFloat x = bounds.origin.x + 3.0;  // TODO: this is hardcoded also in LQSegmentedCell.m, should be in a single place
    CGFloat y = bounds.origin.y + 1.0;
    CGFloat xMargin = 1.0f;
    CGFloat segH = bounds.size.height;
    
    for (i = 0; i < segCount; i++) {
        CGFloat segW = [[self cell] widthForSegment:i] + xMargin;
        NSRect segFrame = NSMakeRect(x, y-2,  segW, segH+4);
        
        if (NSMouseInRect(p, segFrame, NO)) {
            //NSLog(@"%s, seg %i, width %.1f", __func__, i, segW);
            return i;
        }
            
        x += segW;
    }
    return -1;
}

- (void)_displayMenu:(NSMenu *)menu forSegment:(LXUInteger)seg event:(NSEvent *)event
{
    NSPoint pos = [event locationInWindow];
    NSRect frame = [self convertRect:[self bounds] toView:nil];
    
    if ( !NSMouseInRect(pos, frame, NO)) {
        return; // not in view
    }
    
    NSFont *menuFont = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    
    if ([menu respondsToSelector:@selector(setFont:)]) {
        [menu setFont:menuFont];
    }
    
    //NSLog(@"%s", __func__);

    if ([menu respondsToSelector:@selector(popUpMenuPositioningItem:atLocation:inView:)]) {  // 10.6+ API
        NSPoint posInView = [self bounds].origin;
        posInView.x += 1;
        posInView.y += [self bounds].size.height + 3;
        
        [menu popUpMenuPositioningItem:[menu itemAtIndex:0] atLocation:posInView inView:self];
        return; // --
    }
    
    pos = NSMakePoint(frame.origin.x + 2.0, frame.origin.y - 2.0);
    
#ifdef __APPLE__
    NSEvent *newEvent = [NSEvent mouseEventWithType:[event type]
                                    location:pos
                                    modifierFlags:[event modifierFlags]
                                    timestamp:[event timestamp]
                                    windowNumber:[event windowNumber]
                                    context:[event context]
                                    eventNumber:[event eventNumber]
                                    clickCount:[event clickCount]
                                    pressure:[event pressure]
                                    ];
#else
    // Cocotron has the following method
    NSEvent *newEvent = [NSEvent mouseEventWithType:[event type]
                                            location:pos
                                            modifierFlags:[event modifierFlags]
                                            window:[self window]
                                            clickCount:1
                                            deltaX:0.0
                                            deltaY:0.0];
#endif

    [NSMenu popUpContextMenu:menu withEvent:newEvent forView:self];
}

- (void)mouseDown:(NSEvent *)event
{
    if ([event modifierFlags] & NSControlKeyMask) {
        [self rightMouseDown:event];
        return; // --
    }
    
    BOOL isMomentary = ([[self cell] trackingMode] == NSSegmentSwitchTrackingMomentary);

    LXInteger seg = [self _findSegmentWithEvent:event];
    
    //NSLog(@"%s, %ld", __func__, (long)seg);
    
    if (seg >= 0 && seg != NSNotFound) {
        LQSegmentedCell *cell = [self cell];
        if ([cell respondsToSelector:@selector(setHighlightedSegment:)]) {
            [cell setHighlightedSegment:seg];
            [self setNeedsDisplay:YES];
        }
        
        //NSLog(@"%s (%p): seg %i:  ismom %i, menu %p, target %@, action %p", __func__, self, seg,
        //        isMomentary, [cell menuForSegment:seg], [cell target], [cell action]);
        
        // normally Cocoa doesn't show the menu if the cell has a target+action.
        // we override that for more predictable behaviour.
        if (isMomentary && [cell menuForSegment:seg]/* && [cell target] && [cell action]*/) {
            [self _displayMenu:[cell menuForSegment:seg] forSegment:seg event:event];
            [self setNeedsDisplay:YES];
            return;
        }
    }
    
    [super mouseDown:event];

    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event
{
    [super rightMouseDown:event];

    LXInteger seg = [self _findSegmentWithEvent:event];
    //NSLog(@"%s, tag %ld, seg %ld", __func__, (long)[self tag], (long)seg);
    if (seg >= 0) {
        LQSegmentedCell *cell = [self cell];
        
        if ([cell menuForSegment:seg])
            [self _displayMenu:[cell menuForSegment:seg] forSegment:seg event:event];
    }
}


@end
