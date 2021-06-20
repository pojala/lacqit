//
//  LQCairoBitmapView.m
//  Lacqit
//
//  Created by Pauli Ojala on 13.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQCairoBitmapView.h"


@implementation LQCairoBitmapView

- (void)_drawTestInCairoBitmap:(LQCairoBitmap *)bmp
{
    cairo_t *cr = [bmp lockCairoContext];
    
    cairo_new_path (cr);
    cairo_set_source_rgb (cr, 0.2, 0.2, 0.2);
    cairo_rectangle (cr, 0, 0, [bmp width], [bmp height]);
    cairo_fill (cr);

    cairo_new_path (cr);
    cairo_arc (cr, 128.0, 128.0, 76.8, 0, 2 * M_PI);
    cairo_clip (cr);

    cairo_new_path (cr);
    cairo_rectangle (cr, 0, 0, 256, 256);
    cairo_fill (cr);
    cairo_set_source_rgb (cr, 0, 1, 0);
    cairo_move_to (cr, 0, 0);
    cairo_line_to (cr, 256, 256);
    cairo_move_to (cr, 256, 0);
    cairo_line_to (cr, 0, 256);
    cairo_set_line_width (cr, 10.0);
    cairo_stroke (cr);

    cairo_move_to (cr, 50, 150);
    cairo_select_font_face (cr, "Arial", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size (cr, 20);
    cairo_set_source_rgba (cr, 1, 1, 1, 1);
    cairo_show_text (cr, "Jackdaws love my big sphinx of quartz");

/*
    cairo_set_source_rgba (cr, 0.7, 0.3, 0, 1);
    cairo_set_operator (cr, CAIRO_OPERATOR_SOURCE);
    cairo_paint (cr);
    cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
  */      
    [bmp unlockCairoContext];
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _bitmap = [[LQCairoBitmap alloc] initWithSize:frame.size];
        
        ///[self _drawTestInCairoBitmap:_bitmap];
        [_bitmap clear];
    }
    return self;
}

- (void)_destroyNativeContext
{
#if !defined(__LAGOON__)
    CGContextRelease((CGContextRef)_nativeCtx);
#else
    // TODO: implement on Lagoon
#endif
    _nativeCtx = NULL;
}

- (void)dealloc
{
    [self _destroyNativeContext];

    [_bitmap release];
    [super dealloc];
}

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }

- (LQCairoBitmap *)cairoBitmap {
    return _bitmap; }
    
- (cairo_t *)lockCairoContext {
    return [_bitmap lockCairoContext]; }
    
- (void)unlockCairoContext {
    [_bitmap unlockCairoContext]; }


#pragma mark --- overrides ---

- (void)setFrame:(NSRect)frame
{
    if ( !NSEqualSizes(frame.size, [_bitmap size])) {
        [_bitmap release];
        _bitmap = [[LQCairoBitmap alloc] initWithSize:frame.size];
    
        ///[self _drawTestInCairoBitmap:_bitmap];
        [_bitmap clear];
        ///NSLog(@"clearing the bitmap");
        
        [self _destroyNativeContext];
    }
    
    [super setFrame:frame];    
}


#pragma mark --- events ---

- (void)mouseDown:(NSEvent *)event
{
    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(handleMouseDown:inCairoBitmapView:)]) {
        didHandle = [_delegate handleMouseDown:event inCairoBitmapView:self];
    }
    if ( !didHandle)
        [super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event
{
    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(handleMouseDragged:inCairoBitmapView:)]) {
        didHandle = [_delegate handleMouseDragged:event inCairoBitmapView:self];
    }
    if ( !didHandle)
        [super mouseDragged:event];
}

- (void)mouseUp:(NSEvent *)event
{
    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(handleMouseUp:inCairoBitmapView:)]) {
        didHandle = [_delegate handleMouseUp:event inCairoBitmapView:self];
    }
    if ( !didHandle)
        [super mouseUp:event];
}

- (void)keyDown:(NSEvent *)event
{
    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(handleKeyDown:inCairoBitmapView:)]) {
        didHandle = [_delegate handleKeyDown:event inCairoBitmapView:self];
    }
    if ( !didHandle)
        [super keyDown:event];
}

- (void)keyUp:(NSEvent *)event
{
    BOOL didHandle = NO;
    if ([_delegate respondsToSelector:@selector(handleKeyUp:inCairoBitmapView:)]) {
        didHandle = [_delegate handleKeyUp:event inCairoBitmapView:self];
    }
    if ( !didHandle)
        [super keyUp:event];
}



#pragma mark --- drawing ---

#if !defined(__LAGOON__)
- (void)_drawUsingQuartzInRect:(NSRect)rect
{
    CGContextRef cgCtx = (CGContextRef)_nativeCtx;
    if ( !cgCtx) {
        CGColorSpaceRef cspace = CGColorSpaceCreateDeviceRGB();
        cgCtx = CGBitmapContextCreate([_bitmap buffer], [_bitmap width], [_bitmap height], 8,
                                      [_bitmap bufferRowBytes],
                                      cspace,
                                      kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
        _nativeCtx = cgCtx;                                                   
        CGColorSpaceRelease(cspace);
    }
        
    CGContextRef dstCtx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGImageRef cgImage = CGBitmapContextCreateImage(cgCtx);
    NSRect bounds = [self bounds];
    
    ///NSLog(@"cairo bounds: %@", NSStringFromRect(bounds));
    
    /*CGContextSaveGState(dstCtx);
    CGContextSetRGBFillColor(dstCtx, 0.5, 0, 0, 1);
    CGContextFillRect(dstCtx, NSRectToCGRect(bounds));
    CGContextRestoreGState(dstCtx);
    */
    
    NSRect inWin = [self convertRect:bounds toView:nil];
    if (fabsf(inWin.origin.x - roundf(inWin.origin.x)) > 0.001f ||
        fabsf(inWin.origin.y - roundf(inWin.origin.y)) > 0.001f) {
        inWin.origin.x = round(inWin.origin.x);
        inWin.origin.y = round(inWin.origin.y);
        bounds = [self convertRect:inWin fromView:nil];
    }
    
    ///NSLog(@"%s -- %@ -> in win %@", __func__, NSStringFromRect(bounds), NSStringFromRect(inWin));
    
    CGContextDrawImage(dstCtx, NSRectToCGRect(bounds), cgImage);
    
    ///CGContextFlush(dstCtx);
    CGImageRelease(cgImage);
}
#endif

- (void)drawRect:(NSRect)rect
{
#if !defined(__LAGOON__)
    [self _drawUsingQuartzInRect:rect];
#else
    // TODO: implement on Lagoon using GTK+'s native Cairo drawing
#endif
}

@end
