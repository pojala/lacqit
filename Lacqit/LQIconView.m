//
//  LQIconView.m
//  Lacqit
//
//  Created by Pauli Ojala on 18.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQIconView.h"
#import "LQNSBezierPathAdditions.h"


static BOOL isMountainLion() {
    static int s_flag = -1;
    if (s_flag == -1) {
        s_flag = (NSClassFromString(@"NSXPCConnection") != nil);
    }
    return (s_flag) ? YES : NO;
}



@interface NSObject (LQIconViewPrivatePasteboardDelegate)

- (void)beginPrivatePasteboardDragForIconView:(LQIconView *)view
                                dragImage:(NSImage *)dragImage
                                at:(NSPoint)location
                                offset:(NSSize)dragOffset
                                event:(NSEvent *)event
                                pasteboard:(NSPasteboard *)pboard;
@end


@implementation LQIconView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _titles = [[NSMutableArray arrayWithCapacity:128] retain];
        _icons = [[NSMutableArray arrayWithCapacity:128] retain];
        _numCols = 2;
        _hiliteItem = NSNotFound;
        _autoRecalcsNumCols = YES;
        
        NSFont *titleFont = [NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]];
        NSMutableParagraphStyle *pstyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
        [pstyle setAlignment:NSCenterTextAlignment];
        
        ///NSLog(@"icon view: font is %@ (%@, %.1f)", titleFont, [titleFont displayName], [titleFont pointSize]);

		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
		[shadow setShadowBlurRadius:2.5];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.1f green:0.1f blue:0.13f alpha:0.77f]];
					
		_titleAttribs = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:titleFont, pstyle, 
										[NSColor colorWithDeviceRed:0.99 green:0.99 blue:1.0 alpha:0.98], shadow, nil]
                                    forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSParagraphStyleAttributeName, 
											NSForegroundColorAttributeName, NSShadowAttributeName, nil] ]
                                        retain];
										
		//_bgColor = [[NSColor colorWithDeviceRed:0.89 green:0.89 blue:0.894 alpha:1.0] retain];
		//_bgColor =	[[NSColor colorWithDeviceRed:0.33 green:0.33 blue:0.37 alpha:1.0] retain];
		//_bgColor =	[[NSColor colorWithDeviceRed:0.584 green:0.584 blue:0.62 alpha:1.0] retain];
		//_bgColor =	[[NSColor colorWithDeviceRed:0.5 green:0.51 blue:0.57 alpha:1.0] retain];
		
//#if defined(__LIVECONDUIT__) || defined(__CONDUITLIVE2__)
//        _bgColor =	[[NSColor colorWithDeviceRed:0.44 green:0.45 blue:0.49 alpha:1.0] retain];
//#else		
        _bgColor =	[[NSColor colorWithDeviceRed:107.0/255.0 green:112.0/255.0 blue:131.0/255.0 alpha:1.0] retain];
//#endif

//#if defined(__LIVECONDUIT__) || defined(__CONDUITLIVE2__)
//        _iconBgColor = [[NSColor colorWithDeviceRed:0.49 green:0.497 blue:0.54 alpha:1.0] retain];
//#else
		_iconBgColor = [[NSColor colorWithDeviceRed:0.53 green:0.538 blue:0.592 alpha:1.0] retain];
//#endif

        _iconBgRounding = 8.0;
        // Conduit Live: was set to 6.0
		
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[_bgColor release];
    [_iconBgColor release];
    [_titles release];
    [_icons release];
    [_titleAttribs release];
    [super dealloc];
}

- (void)awakeFromNib
{
	// set our scroll view's bg color to same as ours
	[[self enclosingScrollView] setBackgroundColor:_bgColor];

    [self reloadData];
}

- (void)setDataSource:(id)source {
	_dataSource = source;
    [self reloadData];
}

- (void)setNumberOfColumns:(LXInteger)cols {
    if (cols < 1)
        cols = 1;
    _numCols = cols; 
    [self setNeedsDisplay:YES]; }
    
- (LXInteger)numberOfColumns {
    return _numCols; }

- (void)setBackgroundColor:(NSColor *)color {
    [_bgColor autorelease];
    _bgColor = [color retain];
}

- (NSColor *)backgroundColor {
    return _bgColor; }


- (void)setDrawsBackground:(BOOL)f {
    _drawsBg = f;
    [self setNeedsDisplay:YES];
}

- (BOOL)drawsBackground {
    return _drawsBg; }



- (void)setIconBackgroundColor:(NSColor *)color {
    [_iconBgColor autorelease];
    _iconBgColor = [color retain];
}

- (NSColor *)iconBackgroundColor {
    return _iconBgColor; }

- (void)setIconBackgroundCornerRounding:(double)r {
    _iconBgRounding = r; }
    
- (double)iconBackgroundCornerRounding {
    return _iconBgRounding; }

- (void)setDrawsIconBackground:(BOOL)f {
    _drawsIconBg = f;
    [self setNeedsDisplay:YES];
}


- (void)setIconShadow:(NSShadow *)shadow {
    [_iconShadow release];
    _iconShadow = [shadow retain];
}

- (NSShadow *)iconShadow {
    return _iconShadow; }


- (BOOL)drawsIconBackground {
    return _drawsIconBg; }


- (void)setAutoRecalcsNumberOfColumns:(BOOL)f {
    _autoRecalcsNumCols = f; }

- (BOOL)autoRecalcsNumberOfColumns {
    return _autoRecalcsNumCols; }


- (id)target {
    return _target; }
    
- (void)setTarget:(id)obj {
    _target = obj; }

- (SEL)action {
    return _action; }
    
- (void)setAction:(SEL)action {
    _action = action; }

- (SEL)itemClickedAction {
    return _mouseDownAction; }
    
- (void)setItemClickedAction:(SEL)action {
    _mouseDownAction = action; }



#define TOPMARGIN 8.0
#define YMARGIN 3.0
#define LEFTMARGIN 5.0
#define RIGHTMARGIN 5.0
#define TITLEHEIGHT 48.0

- (void)_recalcColumnWidth
{
    NSRect bounds = [self bounds];
	LXInteger numCols = [self numberOfColumns];

    _colW = round((bounds.size.width - LEFTMARGIN - RIGHTMARGIN) / (double)numCols);
}

- (double)_calcListDisplayHeight
{
    if (_itemCount < 1 || [_icons count] < 1) {
        _numRows = 0;
        return 0.0;
    }

    NSRect bounds = [self bounds];
	LXInteger numCols;
	
    if (_autoRecalcsNumCols || _numCols < 1) {
        numCols = floor ((bounds.size.width - LEFTMARGIN - RIGHTMARGIN) / 60.0);
        [self setNumberOfColumns:numCols];
    } else {
        numCols = _numCols;
    }
	
    [self _recalcColumnWidth];
    
    NSSize imageSize = [(NSImage *)[_icons objectAtIndex:0] size];
    double imageH = imageSize.height;
    double asp = imageSize.width / imageSize.height;
    imageH = MIN(imageH, _colW / asp);
    
    _rowH = imageH + TITLEHEIGHT + YMARGIN;
    
    ///NSLog(@"%s (%p): row height %.3f - image h %.3f (colW %.3f -> %.3f)", __func__, self, _rowH, imageH, _colW, asp);
    
    _numRows = ceil ((double)_itemCount / (double)_numCols);
    if (_numRows < 1)
        _numRows = 1;
		    
    return (_rowH * _numRows);
}

- (void)reloadData
{
    [_titles removeAllObjects];
    [_icons removeAllObjects];
    
	if (!_dataSource)
		return;
	
    _itemCount = [_dataSource numberOfItemsInIconView:self];
    LXInteger i;
    
    for (i = 0; i < _itemCount; i++) {
        NSString *title = [_dataSource iconView:self titleForItemAtIndex:i];
        NSImage  *icon  = [_dataSource iconView:self iconForItemAtIndex:i];
        
		if (!title) title = @"<missing>";
		[_titles addObject:title];
			
		if (icon)
			[_icons addObject:icon];
		else {
			NSLog(@"*** %s: no icon for item titled %@", __func__, title);
            id defaultImage = [NSImage imageNamed:@"nodeicon_square_light"];
            if (defaultImage)
                [_icons addObject:defaultImage];
		}
    }
    
    NSRect frame = [self frame];
    frame.size.height = [self _calcListDisplayHeight];
    [self setFrame:frame];
    
    [self setNeedsDisplay:YES];
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    
    //[self _recalcColumnWidth];
    [self _calcListDisplayHeight];
    
    ///NSLog(@"%s: colW now %.3f; itemcount %i", __func__, _colW, _itemCount);
}


#pragma mark --- image operations ---

- (NSImage *)nodeIconBackgroundImageWithSize:(NSSize)bgSize offset:(NSPoint)bgOffset
{
	bgSize.width += bgOffset.x * 2.0f;
	bgSize.height += bgOffset.y * 2.0f;
	
	NSImage *bg = [[[NSImage alloc] initWithSize:bgSize] autorelease];
	[bg lockFocus];
		/*NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0f, -2.0f)];
		[shadow setShadowBlurRadius:3.5];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.1f alpha:0.5f]];			
		[shadow set];
		
		[im compositeToPoint:bgOffset operation:NSCompositeSourceOver fraction:1.0f];
		
		[shadow setShadowOffset:NSMakeSize(0.0f, 1.5f)];
		[shadow setShadowBlurRadius:1.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.1f alpha:0.5f]];
		[shadow set];
		[im compositeToPoint:bgOffset operation:NSCompositeSourceOver fraction:1.0f];
		*/

        NSRect pathRect = NSMakeRect(bgOffset.x + 0.5, bgOffset.y + 0.5 - 2,
                                     bgSize.width-bgOffset.x*2.0 - 2.0, bgSize.height-bgOffset.x*2.0 + 4.0);
        
		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:pathRect rounding:_iconBgRounding];

        [_iconBgColor set];
		[path fill];
		
		[[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.7] set];
		[path setLineWidth:0.6f];
		[path stroke];
		
		
	[bg unlockFocus];
	return bg;
}


- (NSImage *)dragImageForIcon:(NSImage *)icon
{
    if ( !icon) return nil;

	NSPoint bgOffset = NSMakePoint(4.0, 4.0);
	NSSize bgSize = (_drawsIconBg) ? NSMakeSize(55, 30) : NSMakeSize(72, 72);
	NSImage *bg = (_drawsIconBg) ? [self nodeIconBackgroundImageWithSize:bgSize offset:bgOffset] : nil;

    if (bg)
        bgSize = [bg size];

	NSImage *newIm = [[[NSImage alloc] initWithSize:bgSize] autorelease];
	
	[newIm lockFocus];
	
    if (bg) {
        //[bg compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver fraction:0.35f];
        
        NSRect imRect = NSMakeRect(0, 0, bgSize.width, bgSize.height);
        NSRect dstRect = imRect;
        [bg drawInRect:dstRect fromRect:imRect operation:NSCompositeSourceOver fraction:0.35];
    }

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(1.2f, -1.9f)];
    [shadow setShadowBlurRadius:2.0];
    [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.1f alpha:0.98f]];
    [shadow set];
    
    NSSize iconSize = [icon size];
    NSRect imRect = NSMakeRect(0, 0, iconSize.width, iconSize.height);
    NSRect dstRect = imRect;
    dstRect.origin = NSMakePoint((bgSize.width - iconSize.width) * 0.5, (bgSize.height - iconSize.height) * 0.5);
    
    //[icon compositeToPoint:iconPoint operation:NSCompositeSourceOver fraction:0.9f];
    [icon drawInRect:dstRect fromRect:imRect operation:NSCompositeSourceOver fraction:0.9];
	
	[newIm unlockFocus];
	return newIm;
}



#pragma mark --- events and dragging ---

- (LXInteger)clickedItemForViewLocation:(NSPoint)pos
{
    LXInteger row = pos.y / _rowH;
    LXInteger col = pos.x / _colW;
    if (row < 0 || col < 0)
        return -1;
        
    return (row * _numCols) + col;
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
    return NSDragOperationCopy;
}

/*
- (void)draggedImage:(NSImage *)dragImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
    [dragImage autorelease];
}
*/

- (BOOL)usePrivatePasteboard {
    return _usePrivatePasteboard;
}
    
- (void)setPrivatePasteboardName:(NSString *)name {
    _usePrivatePasteboard = ([name length] > 0) ? YES : NO;
    [_privatePbName release];
    _privatePbName = [name copy];
}


- (LXInteger)indexOfSelectedItem {
    return _hiliteItem;
}

- (void)_trackMouseForClick:(NSEvent *)event
{
    if ( !_target || !_action) return;

    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];    
    LXInteger item = [self clickedItemForViewLocation:location];

    _hiliteItem = item;
    [self setNeedsDisplay:YES];

    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ( !event || [event type] == NSLeftMouseUp) {
            break;
        }
        location = [self convertPoint:[event locationInWindow] fromView:nil];
        item = [self clickedItemForViewLocation:location];
    }
    
    if (item == _hiliteItem) {
        [_target performSelector:_action withObject:self];
    }
    
    _hiliteItem = NSNotFound;
    [self setNeedsDisplay:YES];
}

- (BOOL)_trackMouseForDragStartWithEventPtr:(NSEvent **)event
{
    NSPoint startLocation = [self convertPoint:[*event locationInWindow] fromView:nil];    

    while (1) {
        *event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        if ( !*event || [*event type] == NSLeftMouseUp) {
            break;
        }
        NSPoint location = [self convertPoint:[*event locationInWindow] fromView:nil];
        
        if (fabs(location.x - startLocation.x) >= 3.0 ||
            fabs(location.y - startLocation.y) >= 3.0) {
            return YES;
        }
    }
    return NO;
}

- (void)mouseDown:(NSEvent *)event
{
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    LXInteger item = [self clickedItemForViewLocation:location];
    
    if (item < 0 || item >= _itemCount)
        return;
        
    if (_target && _mouseDownAction) {
        _hiliteItem = item;
        [_target performSelector:_mouseDownAction withObject:self];
        _hiliteItem = NSNotFound;
    }
        
    NSPasteboard *pboard = (_usePrivatePasteboard) ? [NSPasteboard pasteboardWithName:_privatePbName]
                                                   : [NSPasteboard pasteboardWithName:NSDragPboard];
        
    BOOL okToDrag = ([_dataSource respondsToSelector:@selector(iconView:writeItems:toPasteboard:)] &&
                     [_dataSource iconView:self writeItems:[NSArray arrayWithObject:[NSNumber numberWithLong:item]] toPasteboard:pboard]);
    if ( !okToDrag) {
        [self _trackMouseForClick:event];
        return;
    }

    BOOL userDidBeginDrag = [self _trackMouseForDragStartWithEventPtr:&event];
    if ( !userDidBeginDrag) {
        if (_target && _action) {
            NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];    
            LXInteger item = [self clickedItemForViewLocation:location];
        
            [_target performSelector:_action withObject:self];
        }
        [self setNeedsDisplay:YES];
        return;
    }

    NSImage *dragImage = [self dragImageForIcon:[_icons objectAtIndex:item]];
    if ( !dragImage) return;

    NSSize dragOffset = [dragImage size];
    dragOffset.width *= 0.5;
    dragOffset.height *= 0.5;
    
    location.x -= dragOffset.width;
    location.y += dragOffset.height;
    
    if ( !_usePrivatePasteboard) {
        [self dragImage:dragImage
                at:location
                offset:dragOffset 
                event:event pasteboard:pboard source:self slideBack:YES];
    }
    else {
        [_dataSource beginPrivatePasteboardDragForIconView:self
                                dragImage:dragImage
                                at:location
                                offset:dragOffset
                                event:event
                                pasteboard:pboard];
    }
}


#pragma mark --- drawing ---

- (BOOL)isFlipped {
    return YES; }


- (void)drawRect:(NSRect)rect
{
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    NSImage *bg = nil;
	NSPoint bgOffset = NSMakePoint(6.0, 6.0);
    NSSize bgSize = NSZeroSize;
    
    if (_drawsIconBg) {
		NSSize bgSize = NSMakeSize(55, 30);
		bg = [self nodeIconBackgroundImageWithSize:bgSize offset:bgOffset];
	}

    if (_drawsBg) {
        [ctx saveGraphicsState];
        
        // fill bg
        [ctx setCompositingOperation:NSCompositeCopy];
        [_bgColor set];
        
        [[NSBezierPath bezierPathWithRect:rect] fill];
        
        [ctx restoreGraphicsState];
    }
    
    if ([_icons count] < 1)
        return;
    
    double maxIconW = _colW - 3;
    NSSize baseIconSize = [(NSImage *)[_icons objectAtIndex:0] size];
    double baseAsp = baseIconSize.width / baseIconSize.height;
    
    maxIconW = MIN(maxIconW, (_rowH - TITLEHEIGHT - YMARGIN) * baseAsp);
		
	// drop shadow at top of list
/*
	int i;
	float ratio;
	NSBezierPath *path;
	NSRect sliceRect = [self bounds];
	//sliceRect.origin.y = 
	sliceRect.size.height = 1.0f;
	
	for(i=0;i<30; i++) {
		ratio = (1.0 - ((float)i / (float)30.0)) * 0.2;
		[[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.1f alpha:ratio] set];
		path = [NSBezierPath bezierPathWithRect:sliceRect];
		[path fill];
		sliceRect.origin.y += 1.0;
	}
*/	
    // draw items
    if (_itemCount == 0 || _rowH == 0)
        return;
    
    //const BOOL isSnowLeopard = [[_icons objectAtIndex:0] respondsToSelector:@selector(drawInRect:fromRect:operation:fraction:respectFlipped:hints:)];
    
    BOOL useNewDrawing = NO;
#ifdef __APPLE__
    useNewDrawing = isMountainLion();
#endif

    LXInteger x, y;
    LXInteger i = 0;
    NSPoint p;
    for (y = 0; y < _numRows; y++) {
        for (x = 0; x < _numCols; x++) {
            p.x = x * _colW + LEFTMARGIN;
            p.y = y * _rowH + TOPMARGIN;
			
            if (bg) {
                NSSize bgSize = [bg size];
                NSPoint bgPoint = NSMakePoint(p.x + (_colW - bgSize.width)*0.5f, p.y); // + bgSize.height);
                bgPoint.y -= bgOffset.y;
                
                if ( !useNewDrawing) {
                    bgPoint.y += bgSize.height;
                    [bg compositeToPoint:bgPoint operation:NSCompositeSourceOver fraction:1.0f];
                } else {
                    NSRect imRect = NSMakeRect(0, 0, bgSize.width, bgSize.height);
                    NSRect dstRect = imRect;
                    dstRect.origin = bgPoint;
                    [bg drawInRect:dstRect fromRect:imRect operation:NSCompositeSourceOver fraction:1.0
                     respectFlipped:YES hints:nil];
                }
            }

            const BOOL isHilite = (i == _hiliteItem);

			// shadow for icon contents, for that subtle embossed look
			NSShadow *shadow = _iconShadow;
            if ( !shadow) {
                shadow = [[[NSShadow alloc] init] autorelease];
                [shadow setShadowOffset:NSMakeSize(1.3f, -1.5f)];
                [shadow setShadowBlurRadius:(isHilite) ? 4.0 : 2.0];
                [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.1f alpha:0.9f]];
            }
            
			[ctx saveGraphicsState];
			[shadow set];
			
			
			NSImage *icon = [_icons objectAtIndex:i];
            NSSize iconSize = [icon size];
            
            double compOpacity = (isHilite) ? 0.55 : 0.9;
            LXUInteger compOperation = NSCompositeSourceOver;

            double asp = iconSize.width / iconSize.height;
            
            if (iconSize.width <= maxIconW) {
                NSPoint iconPoint = NSMakePoint(p.x + (_colW - iconSize.width)*0.5f, p.y - 1.0f);
                if ( !useNewDrawing) {
                    iconPoint.y += iconSize.height;
                    [icon compositeToPoint:iconPoint operation:compOperation fraction:compOpacity];
                } else {
                    NSRect imRect = NSMakeRect(0, 0, iconSize.width, iconSize.height);
                    NSRect dstRect = imRect;
                    dstRect.origin = iconPoint;
                    [icon drawInRect:dstRect fromRect:imRect operation:compOperation fraction:compOpacity
                     respectFlipped:YES hints:nil];
                }
            }
            else {
                // scale down the icon
                double iconW = maxIconW; //MIN(maxIconW, (_rowH - TITLEHEIGHT - YMARGIN) * asp);
                NSSize iconDstSize = NSMakeSize(iconW, iconW / asp);
                NSPoint iconPoint = NSMakePoint(p.x + (_colW - iconDstSize.width)*0.5f, p.y); // + iconDstSize.height - 1.0f);
                
                if ( !useNewDrawing) {
                    [ctx saveGraphicsState];
                    
                    NSAffineTransform *trs = [NSAffineTransform transform];
                    [trs translateXBy:0.0 yBy:p.y + iconDstSize.height];
                    iconPoint.y = 0.0;
                    
                    [trs scaleXBy:1.0 yBy:-1.0];
                    [trs concat];
                    
                    [icon drawInRect:NSMakeRect(round(iconPoint.x), round(iconPoint.y), ceil(iconDstSize.width), ceil(iconDstSize.height))
                            fromRect:NSMakeRect(0, 0, iconSize.width, iconSize.height)
                            operation:compOperation
                            fraction:compOpacity];
                            
                    [ctx restoreGraphicsState];
                }
                else {
                    [icon drawInRect:NSMakeRect(round(iconPoint.x), round(iconPoint.y), ceil(iconDstSize.width), ceil(iconDstSize.height))
                            fromRect:NSMakeRect(0, 0, iconSize.width, iconSize.height)
                           operation:compOperation
                            fraction:compOpacity respectFlipped:YES hints:nil];
                }
                
                iconSize = iconDstSize;
            }
			
			// pop graphics state to get rid of shadow
			[ctx restoreGraphicsState];
            
            NSString *title = [_titles objectAtIndex:i];
            [title drawInRect:NSMakeRect(p.x+1.0f, p.y+iconSize.height+1.0f, _colW-2.0f, TITLEHEIGHT)
                                withAttributes:_titleAttribs];
                                
            if ([_dataSource respondsToSelector:@selector(iconView:drawOverlayForItemAtIndex:inRect:)]) {
                [_dataSource iconView:self drawOverlayForItemAtIndex:i inRect:NSMakeRect(p.x - LEFTMARGIN*0.5, p.y - TOPMARGIN*0.5, _colW, _rowH)];
            }
            
            i++;
            if (i >= _itemCount)
                break;
        }
    }
}

@end
