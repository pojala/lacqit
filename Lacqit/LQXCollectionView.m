//
//  LQXCollectionView.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQXCollectionView.h"
#import "LQCollectionItem.h"
#import "LQXLabel.h"
#import "LQDrawingProtocols.h"
#import "LQGradient_LXAdditions.h"
#import "LQBaseApplication.h"


static LXShaderRef g_headerBgShader = NULL;
static LXShaderRef g_footerShader = NULL;
static LXShaderRef g_headerTopShader = NULL;


@interface LQXCollectionView (ImplPrivate)
- (void)_recreateTitleBitmap;
- (void)_doLayout;
- (void)_stopMouseTimer;
@end

@interface LQCollectionItem (PrivateUsedByOwner)
- (void)_setCollectionView:(NSView *)view;
@end



@implementation LQXCollectionView

- (void)_setupTracking
{
/*
    if (_trackingRectTag != 0) {
        [self removeTrackingRect:_trackingRectTag];
    }

    _trackingRectTag = [self addTrackingRect:[self bounds]
                                owner:self
                                userData:nil
                                assumeInside:NO];
*/
    if ([NSApp respondsToSelector:@selector(addHoverTracking:)]) {
        [(LQBaseApplication *)NSApp addHoverTracking:self];
    }
}

- (void)_removeTracking
{
    if ([NSApp respondsToSelector:@selector(removeHoverTracking:)]) {
        [(LQBaseApplication *)NSApp removeHoverTracking:self];
    }
}


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _items = [[NSMutableArray arrayWithCapacity:32] retain];
        
        _titlePostMargin = 12.0;
        
        [self _setupTracking];
    }
    
    return self;
}

- (void)dealloc
{
    [self _removeTracking];

    [self _stopMouseTimer];
    [_items release];
    [_cornerImage release];
    [_titleBitmap release];
    [super dealloc];
}

- (void)setFrame:(NSRect)frame
{
    ///NSLog(@"%s: %@", __func__, NSStringFromRect(frame));
    [super setFrame:frame];
    ///[self _setupTrackingRect];
    [self _doLayout];
}

- (double)layoutDimension {
    return _layoutDim; }
    

#pragma mark --- layout ---

- (void)collectionItemNeedsDisplay:(LQCollectionItem *)item
{
    if ( ![_items containsObject:item]) {
        NSLog(@"** %s (%@): warning: collection item not in this view (rep obj %@)", __func__, self, [item representedObject]);
    }
    [self setNeedsDisplay:YES];
}


- (double)_calcItemsDimensionFor1DCollection
{
    const BOOL isHoriz = (_orientation == kLQHorizontalCollection);
    double dim = 0.0;
    
    NSEnumerator *enumerator = [_items objectEnumerator];
    id item;
    while (item = [enumerator nextObject]) {
        dim += (isHoriz) ? [item displayWidth] : [item displayHeight];
    }
    
    return dim;
}


#pragma mark --- accessors ---

- (void)setOrientation:(LXUInteger)orientation {
    _orientation = orientation; }
    
- (LXUInteger)orientation {
    return _orientation; }


- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }


- (void)addItem:(LQCollectionItem *)item
{
    if ( ![_items containsObject:item]) {
        [_items addObject:item];
        [item _setCollectionView:self];
    }
}

- (void)removeItem:(LQCollectionItem *)item
{
    long index = [_items indexOfObject:item];
    if (index != NSNotFound) {
        [item _setCollectionView:nil];
        [_items removeObjectAtIndex:index];
    }
}

- (NSArray *)content {
    return _items;
}

- (void)setContent:(NSArray *)content {
    NSAssert(content, @"content is nil");
    [_items release];
    _items = [content mutableCopy];
    
    [self _doLayout];
    [self setNeedsDisplay:YES];
}


- (void)setTitle:(NSString *)title
{
    if ( ![title isEqualToString:_title]) {
        [_title release];
        _title = [title copy];
        
        [self _recreateTitleBitmap];
    }
}

- (NSString *)title {
    return _title; }


- (double)titlePostMargin {
    return _titlePostMargin; }
    
- (void)setTitlePostMargin:(double)f {
    _titlePostMargin = f; }


- (void)setCornerImage:(LQBitmap *)frame {
    [_cornerImage autorelease];
    _cornerImage = [frame retain];
}

- (LXInteger)indexOfItem:(id)item {
    return [_items indexOfObject:item]; }

- (LXInteger)numberOfItems {
    return [_items count]; }
    
- (id)itemAtIndex:(LXInteger)index {
    return [_items objectAtIndex:index]; }


#pragma mark --- coordinates ---

- (id)itemAtPoint:(NSPoint)p
{
    if ( !_itemLayout || [_items count] != [_itemLayout count])
        [self _doLayout];

    NSRect bounds = [self bounds];
    const BOOL isV = (_orientation == kLQVerticalCollection);
    const double insetX = (isV) ? -10  : -10;
    const double insetY = (isV) ? -4   : -2;

    const double scrollOffset = _scrollPos * ((isV) ? bounds.size.height : bounds.size.width);

    LXInteger count = [_items count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        NSRect r = [[_itemLayout objectAtIndex:i] rectValue];
        
        // add some padding to account for margins and view boundaries
        r = //NSInsetRect(r, -8.0, -4.0);
              NSInsetRect(r, insetX, insetY);
        
        if (isV) {
            r.size.width -= 6;  // subtract some for scrollbar too
            r.origin.y -= scrollOffset;
        } else {
            r.size.height -= 12;
            r.origin.x -= scrollOffset;
        }
        
        if (NSPointInRect(p, r)) {
            break;
        }
    }
    if (i == count)
        return nil;
    else
        return [_items objectAtIndex:i];
}

- (NSRect)displayFrameForItem:(id)item
{
    if ( !_itemLayout || [_items count] != [_itemLayout count])
        [self _doLayout];

    NSRect bounds = [self bounds];
    const BOOL isV = (_orientation == kLQVerticalCollection);

    LXInteger index = [_items indexOfObject:item];
    if (index == NSNotFound) {
        return NSZeroRect;
    } else {
        NSRect rect = [[_itemLayout objectAtIndex:index] rectValue];

        const double scrollPos = [self scrollPosition];
        const double scrollOffset = scrollPos * ((isV) ? bounds.size.height : bounds.size.width);
        if (isV)
            rect.origin.y -= scrollOffset;
        else
            rect.origin.x -= scrollOffset;
        
        return rect;
    }
}



#pragma mark --- hover events ---

- (id)hoveredItem
{
    if ( !_isHovering || _hoverIndex == NSNotFound)
        return nil;
        
    if (_hoverIndex >= [_items count]) {
        NSLog(@"** %s: item %ld out of bounds (%lu)", __func__, _hoverIndex, [_items count]);
        return nil;
    }
    
    return [_items objectAtIndex:_hoverIndex];
}

- (NSPoint)hoverLocationInWindow {
    return _lastWindowPos; }
    
 
- (void)_endHover
{
    _isHovering = NO;
    //_hoverWaitTime = 1.0;  // longer wait for next hover
    
    ///[self _setupTrackingRect];
}
          
- (void)didEndHoverDisplay
{
    [[self window] makeFirstResponder:self];  // this ensures we get those mouse tracking events again
    [self _endHover];
}

- (void)_stopMouseTimer
{
        [_mouseTimer invalidate];
        [_mouseTimer release];
        _mouseTimer = nil;
}    

- (void)mouseTimerFired:(NSTimer *)timer
{
    double curTime = LQReferenceTimeGetCurrent();
    double diff = (curTime - _prevMouseEventTime);
    double hoverWaitTime = (_hoverWaitTime > 0.001) ? _hoverWaitTime : 0.2;
    
    if ( !_isHovering && diff > hoverWaitTime) {
        _prevMouseEventTime = curTime;
        
        id activeItem = [self itemAtPoint:[self convertPoint:[self hoverLocationInWindow] fromView:nil]];
        
        if (activeItem)
            _isHovering = YES;
            
        _hoverIndex = [_items indexOfObject:activeItem];
        
        ///NSLog(@"start hover, index %i, pos %@", _hoverIndex, NSStringFromPoint([self convertPoint:[self hoverLocationInWindow] fromView:nil]) );
        
        if (_hoverIndex != NSNotFound)
            [_delegate mouseHoverStartForCollectionView:self];
        
        [self _stopMouseTimer];
    }
}


// --- these hoverEntered/Inside/Exited methods are declared in LQAppHoverList.h ---

- (void)hoverEntered:(NSEvent *)event
{
    ///NSLog(@"%s", __func__);
    _lastWindowPos = [event locationInWindow];
 
    if ([_delegate respondsToSelector:@selector(mouseHoverStartForCollectionView:)]) {
        [[self window] makeFirstResponder:self];  // this ensures we get those mouse tracking events
    
        _mouseTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / 20.0)
                             target:self
                             selector:@selector(mouseTimerFired:)
                             userInfo:nil
                             repeats:YES] retain];
    }
 
    _prevMouseEventTime = LQReferenceTimeGetCurrent();
}

- (void)hoverInside:(NSEvent *)event
{
    _lastWindowPos = [event locationInWindow];

    if (_isHovering) {
        if (_endHoverOnMove) {
            [self _endHover];
            [_delegate mouseHoverEndForCollectionView:self];
        } else {
            LXInteger newHoverIndex = [_items indexOfObject:[self itemAtPoint:[self convertPoint:[self hoverLocationInWindow] fromView:nil]]];
        
            if (newHoverIndex != _hoverIndex) {
                LXInteger prevHoverIndex = _hoverIndex;
                _hoverIndex = newHoverIndex;
                
                // if we didn't really start hover previously, do it now
                if (prevHoverIndex == NSNotFound) {
                    [_delegate mouseHoverStartForCollectionView:self];
                } else {
                    [_delegate mouseMovedWhileHoveringForCollectionView:self event:event];
                }
            }
        }
    }    
    //NSLog(@"%s", __func__);
    
    _prevMouseEventTime = LQReferenceTimeGetCurrent();
}

- (void)hoverExited:(NSEvent *)event
{
    if (_isHovering) {
        [self _endHover];
        [_delegate mouseHoverEndForCollectionView:self];
    }

    ///NSLog(@"%s", __func__);
    
    if (_mouseTimer) {
        [self _stopMouseTimer];
    }
}


#pragma mark --- regular events ---

- (void)mouseDown:(NSEvent *)event
{
    BOOL didHandleInCells = [_baseMixin handleMouseDownInCells:event];
    if (didHandleInCells)
        return;

    //NSLog(@"%s, %i", __func__, _isHovering);
    if (_isHovering) {
        [_delegate mouseDownInCollectionView:self event:event];
    }
    else {  
        [self mouseEntered:event];
        
        //[super mouseDown:event];
    }
}

- (void)mouseDragged:(NSEvent *)event
{
    BOOL didHandleInCells = [_baseMixin handleMouseDraggedInCells:event];
    if (didHandleInCells)
        return;

    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(collectionView:suggestsItemDrag:withEvent:)]) {
        id item = [self itemAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
        
        //if (item) {
            didHandle = [_delegate collectionView:self suggestsItemDrag:item withEvent:event];
        //}
    }

    if ( !didHandle && !_isHovering) {
        [super mouseDragged:event];
    }
}

- (void)mouseUp:(NSEvent *)event
{
    BOOL didHandleInCells = [_baseMixin handleMouseUpInCells:event];
    if (didHandleInCells)
        return;

    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(mouseUpInCollectionView:event:)]) {
        [_delegate mouseUpInCollectionView:self event:event];
        didHandle = YES;
    }

    if ( !didHandle && !_isHovering) {
        [super mouseUp:event];
    }
}


#pragma mark --- drawing ---

- (void)_recreateTitleBitmap
{
    [_titleBitmap release];
    _titleBitmap = nil;
    
    if ([_title length] < 1)
        return;
/*    
    NSDictionary *attrs = [[self class] darkTitleTextAttributes];
    
    NSSize size = [_title sizeWithAttributes:attrs];
    size.width += 4.0;
    size.height += 4.0;  // extra room for shadow
        
    ///NSLog(@"title %@ -- texsize %.2f * %.2f", _title, size.width, size.height);
        
        
    _titleBitmap = [[LQCGBitmap alloc] initWithSize:size];
        
    [_titleBitmap lockFocus];
        [_title drawAtPoint:NSMakePoint(2, 2) withAttributes:attrs];
    [_titleBitmap unlockFocus];
    */
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[LQXLabel browserHeaderTextAttributes]];
    
    //[attrs setObject:[NSNumber numberWithInt:1] forKey:@"LQCrispFontAttributeName"];
    
    _titleBitmap = [[LQXLabel alloc] initWithString:_title attributes:attrs];
}

- (void)_createBgShaders
{
            NSColor *c1 = //[NSColor colorWithDeviceRed:0.2823 green:0.204 blue:0.204 alpha:1.0];
                          [NSColor colorWithDeviceRed:0.28 green:0.250 blue:0.340 alpha:0.5];
                           
            NSColor *c2 = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0];    
            
            g_headerBgShader = [[LQGradient gradientWithBeginningColor:c1 endingColor:c2] createLXShaderWithAngle:-90 gamma:1.0];
            
            c1 = [NSColor colorWithDeviceRed:0.28 green:0.250 blue:0.340 alpha:0.8];
            g_headerTopShader = [[LQGradient gradientWithBeginningColor:c1 endingColor:c2] createLXShaderWithAngle:-90 gamma:1.0];
            
            c1 = [NSColor colorWithDeviceRed:0.28 green:0.250 blue:0.340 alpha:0.8];
            g_footerShader = [[LQGradient gradientWithBeginningColor:c1 endingColor:c2] createLXShaderWithAngle:90 gamma:1.0];
}



- (void)drawInLXSurface:(LXSurfaceRef)lxSurface
{    
    LXVertexXYUV vertices[4];
    NSRect bounds = [self bounds];
    BOOL isV = ([self orientation] == kLQVerticalCollection);
    

    if ( !_itemLayout || [_itemLayout count] != [_items count])
        [self _doLayout];

    if ( !g_headerBgShader) {
        [self _createBgShaders];
    }

    BOOL doDraw = YES;
    if ([_delegate respondsToSelector:@selector(collectionView:shouldDrawBackgroundInSurface:bounds:)])
        doDraw = [_delegate collectionView:self shouldDrawBackgroundInSurface:lxSurface bounds:LXRectFromNSRect(bounds)];
    
    if (doDraw) {
        // background color
        LXRGBA clearColor = 
                        LXMakeRGBA(0.3176, 0.3647, 0.4312, 1); 
                        //LXMakeRGBA(0.28, 0.285, 0.32, 1);
    
        LXSurfaceClearRegionWithRGBA(lxSurface, LXSurfaceGetBounds(lxSurface), clearColor);
    }

    BOOL hasTitle = ([_title length] > 0);

    LXDrawContextRef blendDrawCtx = LXAutorelease(LXDrawContextCreate());
    LXDrawContextSetFlags(blendDrawCtx, kLXDrawFlag_UseFixedFunctionBlending_SourceIsPremult);
    
    if (hasTitle) {
        // title background gradient (at top of view)
        LXSurfaceGetQuadVerticesXYUV(lxSurface, vertices);
        vertices[2].y = vertices[0].y + 40;
        vertices[3].y = vertices[1].y + 40;
        
        LXDrawContextSetShader(blendDrawCtx, g_headerBgShader);
        LXSurfaceDrawPrimitive(lxSurface, kLXQuads, vertices, 4, kLXVertex_XYUV, blendDrawCtx);
        /*
        LXSurfaceDrawTexturedQuadWithShaderAndTransform(lxSurface, vertices, kLXVertex_XYUV, NULL, g_headerBgShader, NULL);

        // second gradient for extra thickness
        vertices[2].y = vertices[0].y + 12;
        vertices[3].y = vertices[1].y + 12;
        LXSurfaceDrawTexturedQuadWithShaderAndTransform(lxSurface, vertices, kLXVertex_XYUV, NULL, g_headerTopShader, NULL);
        */
    }


    NSDictionary *previewContext = [_delegate previewContextForCollectionView:self];
    
    
    const double scrollOffset = _scrollPos * ((isV) ? bounds.size.height : bounds.size.width);
    
    
    LXInteger count = [_items count];
    LXInteger i;
    for (i = 0; i < count; i++) {
        id item = [_items objectAtIndex:i];
        id repObj = [item representedObject];
        id drawObj = [_delegate drawingObjectForCollectionItem:item];
        
        NSRect itemRect = [[_itemLayout objectAtIndex:i] rectValue];
        LXTextureRef tex = NULL;
        
        if (isV)
            itemRect.origin.y -= scrollOffset;
        else
            itemRect.origin.x -= scrollOffset;
        
        if (NSIntersectsRect(itemRect, bounds)) {        
            LXRect itemBounds = LXRectFromNSRect(itemRect);

            NSLog(@"drawing coll %@ -- %ld: %@", self, i, drawObj);
                    
            if ([drawObj conformsToProtocol:@protocol(LQLacefxPreviewDrawing)]) {
                [(id <LQLacefxPreviewDrawing>)drawObj drawPreviewInSurface:lxSurface bounds:itemBounds context:previewContext];
            }
            else {
                if ([drawObj respondsToSelector:@selector(lxTexture)])
                    tex = [drawObj lxTexture];
                
                if (tex) {
                    LXSetQuadVerticesXYUV(vertices, itemBounds, LXUnitRect);
                    LXSurfaceDrawTexturedQuad(lxSurface, (void *)vertices, kLXVertex_XYUV, tex, NULL);
                }
            }
            
            if ([_delegate respondsToSelector:@selector(collectionView:didDrawItem:inSurface:bounds:)])
                [_delegate collectionView:self didDrawItem:item inSurface:lxSurface bounds:itemBounds];
        }
    }

    if (_cornerImage) {
        //[_cornerImage drawInLXSurface:lxSurface atPoint:LXMakePoint(bounds.origin.x, bounds.origin.y)];
        LXTextureRef tex = [_cornerImage lxTexture];
        LXSize texSize = LXTextureGetSize(tex);
        
        LXSurfaceGetQuadVerticesXYUV(lxSurface, vertices);
        vertices[2].y = vertices[3].y = texSize.h;
        
        LXSurfaceDrawTexturedQuad(lxSurface, vertices, kLXVertex_XYUV, tex, NULL);
    }

    if (hasTitle) {
        // draw title
        [_titleBitmap drawInSurface:lxSurface atPoint:NSMakePoint(6, 5)];    

        NSLog(@"drawing title '%@' - bitmap %@", _title, _titleBitmap);
        
        // draw footer gradient
        LXSurfaceGetQuadVerticesXYUV(lxSurface, vertices);
        vertices[0].y = vertices[2].y - 100;
        vertices[1].y = vertices[3].y - 100;
        
        //LXSurfaceDrawTexturedQuadWithShaderAndTransform(lxSurface, vertices, kLXVertex_XYUV, NULL, g_footerShader, NULL);
        LXDrawContextSetShader(blendDrawCtx, g_footerShader);
        LXSurfaceDrawPrimitive(lxSurface, kLXQuads, vertices, 4, kLXVertex_XYUV, blendDrawCtx);
    }

    // draw any cells that we have
    if ([[_baseMixin cells] count] > 0) {
        [self drawCellsInLXSurface:lxSurface];
    }    
}


#pragma mark --- layout and scrolling ---

- (double)scrollPosition {
    return _scrollPos; 
}

- (void)scrollToPosition:(double)f
{
    _scrollPos = MIN(1.0, MAX(0.0, f));
    
    if (_delegate && [_delegate respondsToSelector:@selector(collectionView:shouldScrollToPosition:)])
        _scrollPos = [_delegate collectionView:self shouldScrollToPosition:f];
        
    [self setNeedsDisplay:YES];
}


- (void)_doLayout
{
    NSRect bounds = [self bounds];
    BOOL isV = ([self orientation] == kLQVerticalCollection);

    NSDictionary *previewContext = [_delegate previewContextForCollectionView:self];
    
    NSMutableArray *layout = [NSMutableArray arrayWithCapacity:[_items count]];

    const double itemMargin = 8.0;    
    const double fixedDim = (isV) ? bounds.size.width : bounds.size.height;
    const double fixedOff = 4.0;
    double y = 0.0;


    LXTextureRef titleTex = [_titleBitmap lxTexture];
    if (titleTex) {
        LXSize texSize = LXTextureGetSize(titleTex);
        y += (isV) ? texSize.h : texSize.w;
        
        y += [self titlePostMargin];
    }
    
    //if ( !isV)
    //    y += 32;
    
    double itemDim = 0.0;
    
    NSEnumerator *itemEnum = [_items objectEnumerator];
    id item;
    LXInteger n = 0;
    while (item = [itemEnum nextObject]) {
        id repObj = [item representedObject];
        id drawObj = [_delegate drawingObjectForCollectionItem:item];
        
        double asp = 0.0;
        if ([drawObj respondsToSelector:@selector(previewAspectRatioInContext:)])
            asp = [drawObj previewAspectRatioInContext:previewContext];
        else if ([item respondsToSelector:@selector(displayAspectRatio)])
            asp = [item displayAspectRatio];
            
        if (asp < 0.0001)
            asp = 2.0;
            
        double itemW, itemH;
        
        if (isV) {
            itemW = fixedDim;
            itemH = fixedDim / asp;
        } else {
            itemH = fixedDim;
            itemW = fixedDim * asp;
        }
        
        // subtract margins
        itemW -= 8.0 + 16.0;
        itemH -= (8.0 / asp);

        NSRect itemRect = (isV) ? NSMakeRect(fixedOff, y,  itemW, itemH)
                                : NSMakeRect(y, fixedOff,  itemW, itemH);
        [layout addObject:[NSValue valueWithRect:itemRect]];

        itemDim = (isV) ? itemH : itemW;      
        y += itemDim;
        y += itemMargin;
        n++;
    }

    [_itemLayout release];
    _itemLayout = [layout retain];
    
    _layoutDim = y + 50.0 * n;
    ///NSLog(@"layout length: %f", _layoutDim);
    
    if ([_delegate respondsToSelector:@selector(collectionViewDidPerformLayout:)])
        [_delegate collectionViewDidPerformLayout:self];
}



#pragma mark --- drag&drop settings ---

- (void)setSupportedPboardTypesForDragReceive:(NSArray *)array
{
    [_dragPboardTypes release];
    _dragPboardTypes = [array retain];

    [self registerForDraggedTypes:_dragPboardTypes];
}


- (NSArray *)supportedPboardTypesForDragReceive
{
    return _dragPboardTypes; }


#pragma mark --- NSDraggingDestination protocol ---

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    // don't need to do anything here
}


- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    BOOL result = NO;
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSPoint mouseLocation = [sender draggingLocation];

    NSPoint p = [self convertPoint:mouseLocation fromView:nil];

    NSEnumerator *typeEnum = [[pboard types] objectEnumerator];
    id type;
    while (type = [typeEnum nextObject]) {
        ///NSLog(@"receiving drag: %@", type);
        
        id obj = [NSURL URLFromPasteboard:pboard];
        
        if ( !obj) {
            obj = [pboard stringForType:type];  // assume everything else is a string...
        }
        if (obj) {
            result = [_delegate collectionView:self receivedDraggedObject:obj atPoint:p];
            break;
        }
    }
	return result;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    // documentation says UI should be updated here if necessary
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    // documentation for Panther says this method has not yet been implemented 
}


@end
