//
//  LQOverflowBox.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQOverflowBox.h"


@implementation LQOverflowBox

- (void)dealloc
{
    [_overflowMenu release];
    [super dealloc];
}

- (double)contentOverflowMinWidth {
    return _contentMinW; }
    
- (void)setContentOverflowMinWidth:(double)w {
    //NSLog(@"%s: %.1f", __func__, w);
    if (w >= 0.0 && _contentMinW != w) {
        _contentMinW = w;
        [self setFrame:[self frame]];
        [self setNeedsDisplay:YES];
    }
}

- (NSMenu *)overflowMenu {
    return _overflowMenu; }
    
- (void)setOverflowMenu:(NSMenu *)menu {
    [_overflowMenu autorelease];
    _overflowMenu = [menu retain];
}

- (NSString *)overflowLabel {
    return _overflowLabel; }
    
- (void)setOverflowLabel:(NSString *)str {
    [_overflowLabel release];
    _overflowLabel = [str copy];
    [self setNeedsDisplay:YES];
}


- (NSRect)_rectForShowMoreButton
{
    if (_contentMinW <= 0.0) return NSZeroRect;

    NSRect bounds = [self bounds];
    
    if (bounds.size.width < _contentMinW) {
        double buttonW = 24;
        double buttonH = 24;
        
        return NSMakeRect(bounds.origin.x + bounds.size.width - buttonW,
                          round(bounds.origin.y + bounds.size.height*0.5 - buttonH*0.5),
                          buttonW,
                          buttonH);
    } else
        return NSZeroRect;
}

- (void)setFrame:(NSRect)frame
{
    if (frame.size.width < 24) return;

    [super setFrame:frame];
    
    NSRect showMoreButtonRect = [self _rectForShowMoreButton];
    
    ///NSLog(@"%s: %@ -- %@", __func__, NSStringFromRect(frame), NSStringFromRect(showMoreButtonRect));
    
    BOOL hideSubviews = (showMoreButtonRect.size.width > 0.0);
    
    NSEnumerator *subviewEnum = [[self subviews] objectEnumerator];
    id view;
    while (view = [subviewEnum nextObject]) {
        [view setHidden:hideSubviews];
    }
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    if ([self bounds].size.width > _contentMinW) {
        [super resizeSubviewsWithOldSize:oldBoundsSize];
    }
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
    NSRect showMoreButtonRect = [self _rectForShowMoreButton];
    
    if (showMoreButtonRect.size.width > 0 && NSMouseInRect(point, showMoreButtonRect, NO)) {
        if ( !_overflowMenu) {
            NSLog(@"** overflow menu not set for %@", self);
        } else {
            [NSMenu popUpContextMenu:_overflowMenu withEvent:event forView:self
						withFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        }
    } else {
        [super mouseDown:event];
    }
}

- (NSDictionary *)overflowLabelAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if ( !attribs) {
        attribs = [[NSMutableDictionary alloc] init];
        [attribs setObject:[NSFont boldSystemFontOfSize:kLQUIDefaultFontSize] forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.2 green:0.19 blue:0.22 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
					
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:1.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.2]];
		
		[attribs setObject:shadow forKey:NSShadowAttributeName];

    }
    return attribs;
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    NSRect showMoreButtonRect = [self _rectForShowMoreButton];
    NSBezierPath *path = nil;
    
    if (showMoreButtonRect.size.width > 0.0) {
        NSRect bounds = [self bounds];

        [[NSColor colorWithDeviceRed:0.15 green:0.15 blue:0.2 alpha:0.95] set];
        
        NSRect br = NSInsetRect(showMoreButtonRect, 6, 8);
        
        ///NSLog(@"%s: %@", __func__, NSStringFromRect(showMoreButtonRect));
        
        path = [NSBezierPath bezierPath];
        double lw = 4;
        double aw = 5;
        [path moveToPoint:NSMakePoint(br.origin.x, br.origin.y)];
        [path lineToPoint:NSMakePoint(br.origin.x + lw, br.origin.y)];
        [path lineToPoint:NSMakePoint(br.origin.x + lw + aw, br.origin.y + br.size.height*0.5)];
        [path lineToPoint:NSMakePoint(br.origin.x + lw, br.origin.y + br.size.height)];
        [path lineToPoint:NSMakePoint(br.origin.x, br.origin.y + br.size.height)];
        [path lineToPoint:NSMakePoint(br.origin.x + aw, br.origin.y + br.size.height*0.5)];
        [path fill];
        
        if ([_overflowLabel length] > 0) {
            NSDictionary *attrs = [self overflowLabelAttributes];
            NSSize labelSize = [_overflowLabel sizeWithAttributes:attrs];
            labelSize.width = ceil(labelSize.width);
            
            if (bounds.size.width > labelSize.width + showMoreButtonRect.size.width) {
                [_overflowLabel drawAtPoint:NSMakePoint(showMoreButtonRect.origin.x - labelSize.width,
                                                        1 + round(showMoreButtonRect.origin.y + showMoreButtonRect.size.height*0.5 - labelSize.height*0.5))
                                withAttributes:attrs];
            }
        }
    }
}


@end
