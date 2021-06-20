//
//  LQCategoryBar.m
//  Lacqit
//
//  Created by Pauli Ojala on 10.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQCategoryBar.h"
#import "LQNSBezierPathAdditions.h"


@implementation LQCategoryBar

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _controlSize = NSSmallControlSize;
    }
    return self;
}

- (void)dealloc {
	[_catNames release];
	_lx_free(_catRects);
	[super dealloc];
}

- (NSDictionary *)whiteLabelAttributes
{
    NSMutableDictionary *attrs = _whiteAttrs;
    
    if ( !attrs) {
        attrs = [[NSMutableDictionary alloc] init];
        
        double fontSize = [NSFont systemFontSizeForControlSize:(_controlSize > 0) ? _controlSize : NSSmallControlSize];
        NSFont *font = (fontSize > 9.0) ? [NSFont systemFontOfSize:fontSize] : [NSFont boldSystemFontOfSize:fontSize];
        
        ///NSLog(@"%s: font is: %@ ('%@', size %.1f)", __func__, font, [font displayName], fontSize);

        [attrs setObject:font forKey:NSFontAttributeName];    
        [attrs setObject:[NSColor colorWithDeviceRed:0.98 green:0.99 blue:1.0 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
        _whiteAttrs = attrs;
    }
    return attrs;
}

- (NSDictionary *)blackLabelAttributes
{
    NSMutableDictionary *attrs = _blackAttrs;
    
    if ( !attrs) {
        attrs = [[NSMutableDictionary alloc] init];

        double fontSize = [NSFont systemFontSizeForControlSize:(_controlSize > 0) ? _controlSize : NSSmallControlSize];
        NSFont *font = (fontSize > 9.0) ? [NSFont systemFontOfSize:fontSize] : [NSFont boldSystemFontOfSize:fontSize];

        ///NSLog(@"%s: font is: %@ ('%@', size %.1f)", __func__, font, [font displayName], fontSize);

        BOOL isDark = (_uiTint == kLQSemiDarkTint || _uiTint == kLQDarkTint);

        [attrs setObject:font forKey:NSFontAttributeName];    
        [attrs setObject:(isDark) ? [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.00 alpha:1.0]
                                  : [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.08 alpha:0.93]
                    forKey:NSForegroundColorAttributeName];
					
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0, -1.0)];
		[shadow setShadowBlurRadius:(isDark) ? 1.0 : 0.0];
		[shadow setShadowColor:(isDark) ? [NSColor colorWithDeviceRed:0.7f green:0.7f blue:0.71f alpha:0.85f]
                                        : [NSColor colorWithDeviceRed:0.9f green:0.9f blue:0.93f alpha:0.8f]
                                        ];
		[attrs setObject:shadow forKey:NSShadowAttributeName];
        _blackAttrs = attrs;
    }
    return attrs;
}

- (void)_updateUIAppearance
{
    [_whiteAttrs release];
    [_blackAttrs release];
    [self setNeedsDisplay:YES]; 
}

- (void)setInterfaceTint:(LQInterfaceTint)tint {
    if (tint != _uiTint) {
        _uiTint = tint;
        [self _updateUIAppearance];
    }
}
- (LQInterfaceTint)interfaceTint {
    return _uiTint; }
    
- (void)setControlSize:(LXUInteger)size {
    if (size != _controlSize) {
        _controlSize = size;
        [self _updateUIAppearance];
        [self setCategories:_catNames];  // updates the catRects
    }
}

- (LXUInteger)controlSize {
    return _controlSize; }


#define CATBUTTONINSET_X 10.0f
#define CATBUTTONINSET_Y 0.0f

- (void)setCategories:(NSArray *)cats
{
    [_catNames autorelease];
	_catNames = [cats retain];
	if (_catRects) _lx_free(_catRects);
	
	int count = [_catNames count];
	_catRects = _lx_malloc(count * sizeof(NSRect));
	
	int i;
	float x = 6.0f;
	float y = 8.0f;
	
	for (i = 0; i < count; i++) {
		NSString *catName = [_catNames objectAtIndex:i];
		NSSize labelSize = [catName sizeWithAttributes:[self whiteLabelAttributes]];
        
        labelSize.width = ceil(labelSize.width) - (_controlSize == NSMiniControlSize ? 5 : 1);
        labelSize.height = round(labelSize.height);
		
		_catRects[i] = NSMakeRect(x, y,  labelSize.width + 2.0f*CATBUTTONINSET_X,  labelSize.height + 2.0f*CATBUTTONINSET_Y);
		
		x += labelSize.width + 2.0f*CATBUTTONINSET_X - 0.0f;
	}
}

- (void)setActiveCategory:(LXInteger)index {
    if (index >= 0 && index < [_catNames count]) {
        _selCat = index;
        [self setNeedsDisplay:YES];
    }
}

- (LXInteger)activeCategory {
    return _selCat; }
    
- (void)setTarget:(id)target {
    _target = target; }
    
- (id)target {
    return _target; }

- (void)setAction:(SEL)action {
    _action = action; }
    
- (SEL)action {
    return _action; }
    

#pragma mark --- events ---

- (NSRect)_rectForShowMoreButtonWithOverflowCategories:(NSArray **)outArray
{
    NSRect bounds = [self bounds];
    NSRect buttonRect = NSZeroRect;
    NSArray *arr = nil;
    
    double buttonW = 24;
    double maxX = bounds.size.width - buttonW;
    double x = 0.0;
    LXInteger count = [_catNames count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        double itemW = _catRects[i].size.width;
        
        BOOL isLast = (i == count-1);
        double xOff = (isLast) ? 12 : 0;
        
        if (x + itemW > maxX + xOff) {
            buttonRect = bounds;
            buttonRect.size.width = buttonW;
            buttonRect.origin.x = maxX;
            
            arr = [_catNames subarrayWithRange:NSMakeRange(i, count-i)];
            ////NSLog(@"... %i, w %.0f; overflow categories array %@", i, itemW, arr);
            break;
        }
        x+= itemW;
    }
    if (outArray) *outArray = arr;
    return buttonRect;
}

- (void)showMoreMenuAction:(id)sender
{
    LXInteger index = [_catNames indexOfObject:[sender title]];
    NSAssert(index != NSNotFound, @"invalid menu item title");
    _selCat = index;
    
    [_target performSelector:_action withObject:self];
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];

	BOOL didClick = NO;
	LXInteger count = [_catNames count];
	LXInteger i;
    
    NSArray *menuCats = nil;
    NSRect showMoreButtonRect = [self _rectForShowMoreButtonWithOverflowCategories:&menuCats];
    
    if (showMoreButtonRect.size.width > 0 && NSMouseInRect(point, showMoreButtonRect, NO)) {
        // open the "show more" menu
        NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        
        for (i = 0; i < [menuCats count]; i++) {
            NSString *cat = [menuCats objectAtIndex:i];
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:cat action:NULL keyEquivalent:@""];
            [item setTarget:self];
            [item setAction:@selector(showMoreMenuAction:)];
			[menu addItem:[item autorelease]];
        }
        
        if ([NSMenu respondsToSelector:@selector(popUpContextMenu:withEvent:forView:withFont:)]) {
            [NSMenu popUpContextMenu:menu withEvent:event forView:self
						withFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        } else {
            [NSMenu popUpContextMenu:menu withEvent:event forView:self];
        }
        
        return;
    }
	
	for (i = 0; i < count; i++) {
		if (NSMouseInRect(point, _catRects[i], NO)) {
            _selCat = i;
            
            [_target performSelector:_action withObject:self];
            
            [self setNeedsDisplay:YES];
			didClick = YES;
			break;
		}
	}
	
	if (!didClick) {
		[super mouseDown:event];
	}
}


#pragma mark --- drawing ---

- (void)drawRect:(NSRect)rect
{
	NSBezierPath *path;
	NSRect bounds = [self bounds];

	//[[NSColor colorWithDeviceRed:0.81 green:0.81 blue:0.818 alpha:1.0] set];
	/*[[NSColor colorWithDeviceRed:0.6 green:0.6 blue:0.625 alpha:1.0] set];
	path = [NSBezierPath bezierPathWithRect:rect];
	[path fill];
	*/
	
	LXInteger i;
	float ratio = 0;
/*	float rg_src = 0.7;
	float b_src = 0.725;
	float rg_interp, b_interp;
	float rg_dest = 0.55;
	float b_dest = 0.6;
*/	
	NSRect sliceRect = bounds;
	sliceRect.origin.x += 0.5;
	sliceRect.size.width -= 1.0;
	sliceRect.size.height = 1.0;
	
	for(i = 0.0; i < bounds.size.height; i++) {
		ratio = (float)(bounds.size.height - i) / (float)bounds.size.height * 0.3;

        if (_uiTint == kLQSemiDarkTint || _uiTint == kLQDarkTint) {
            ratio = powf(ratio*1.1, 1.19);
        }
        
		if (ratio > 0.0) {
			[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.1 alpha:ratio] set];
			path = [NSBezierPath bezierPathWithRect:sliceRect];
			[path fill];
		}
		sliceRect.origin.y += 1.0f;
	}

	// reset sliceRect
	sliceRect = bounds;
	
	// draw little shadow at bottom
	sliceRect.size.height = 1.0f;
	[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.02 alpha:0.4] set];
	path = [NSBezierPath bezierPathWithRect:sliceRect];
	[path fill];
	
	sliceRect.origin.y += 1.0f;
	[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.02 alpha:0.2] set];
	path = [NSBezierPath bezierPathWithRect:sliceRect];
	[path fill];
	
	sliceRect.origin.y += 1.0f;
	sliceRect.size.height += 0.5f;
	[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.02 alpha:0.1] set];
	path = [NSBezierPath bezierPathWithRect:sliceRect];
	[path fill];
	
	// draw category buttons
	NSColor *catBgColor = [NSColor colorWithDeviceRed:0.407 green:0.49 blue:0.64 alpha:1.0];
	#pragma unused (catBgColor)
	NSColor *selCatColorBlue = [NSColor colorWithDeviceRed:0.15 green:0.35 blue:0.95 alpha:1.0];
	NSColor *selCatColorGraphite = [NSColor colorWithDeviceRed:0.382 green:0.38 blue:0.43 alpha:1.0];
	
    const BOOL isGraphite = 
#ifdef __APPLE__
                            ([NSColor currentControlTint] == NSGraphiteControlTint);
#else
                            NO;
#endif

    // the "show more" button is displayed if the categories don't fit within our bounds
    NSRect showMoreButtonRect = [self _rectForShowMoreButtonWithOverflowCategories:NULL];
    
    if (showMoreButtonRect.size.width > 0.0) {
        [[NSColor colorWithDeviceRed:0.15 green:0.15 blue:0.2 alpha:0.95] set];
        
        NSRect br = NSInsetRect(showMoreButtonRect, 6, 8);
        br.origin.y += 1;
        
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
    }
    
    LXInteger count = [_catNames count];
    for (i = 0; i < count; i++) {
        // HARDCODED: the inset of "6" is magic, it can't be changed here without modifying _rectForShowMoreButton.. to match
        if (showMoreButtonRect.size.width > 0.0 && NSIntersectsRect(NSInsetRect(showMoreButtonRect, 6, 0), _catRects[i]))
            break;
    
        if ( !NSIntersectsRect(NSInsetRect(rect, -2, -2), _catRects[i]))
            continue;
    
        path = [NSBezierPath roundButtonPathWithRect:_catRects[i] ];
            //		NSMakeRect(bounds.origin.x + 6.0, bounds.origin.y + 6.0,  90.0f, bounds.size.height - 11.0) ];
        
        if (i == _selCat) {
            NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
            [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
            [shadow setShadowBlurRadius:0.0];
            [shadow setShadowColor:(isGraphite) ? [NSColor colorWithDeviceRed:0.802f green:0.8f blue:0.805f alpha:0.7f]
                                                : [NSColor colorWithDeviceRed:0.9f green:0.9f blue:0.93f alpha:0.7f]];
            
            [[NSGraphicsContext currentContext] saveGraphicsState];
            [shadow set];
            
            [((isGraphite) ? selCatColorGraphite : selCatColorBlue) set];
            
            [path fill];
            
            [path addClip];
            
            [shadow setShadowColor:[NSColor colorWithDeviceRed:0.05 green:0.01f blue:0.05f alpha:1.0f]];
            [shadow setShadowBlurRadius:2.0];
            [shadow set];
            
            [(( !isGraphite) ? [NSColor colorWithDeviceRed:0.08 green:0.06 blue:0.5 alpha:1.0f]
                             : [NSColor colorWithDeviceRed:0.05 green:0.01 blue:0.05 alpha:1.0f]) set];
            [path setLineWidth:0.5f];
            [path stroke];
            
            [[NSGraphicsContext currentContext] restoreGraphicsState];
        } 
        
        
        NSString *name = [_catNames objectAtIndex:i];
        NSRect nameRect = NSInsetRect(_catRects[i], (_controlSize == NSMiniControlSize) ? CATBUTTONINSET_X-3 : CATBUTTONINSET_X-1,
                                                    CATBUTTONINSET_Y);
        nameRect.size.width += 2;

        if (i == _selCat) {
            [name drawInRect:nameRect withAttributes:[self whiteLabelAttributes]];
        } else {
            [name drawInRect:nameRect withAttributes:[self blackLabelAttributes]];
        }
    }
}

@end
