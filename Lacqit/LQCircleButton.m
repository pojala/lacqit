//
//  LQCircleButton.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.8.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQCircleButton.h"
#import "LQAppKitUtils.h"


@implementation LQCircleButton

+ (NSImage *)_backgroundCircleImage
{
    static NSImage *s_img = nil;
    if ( !s_img) {
        NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"ui_circlebutton_bg" ofType:@"png"];
        s_img = [[NSImage alloc] initWithContentsOfFile:path];
        if ( !s_img) {
            s_img = [[NSImage imageNamed:@"ui_circlebutton_bg"] retain];
        }
    }
    return s_img;
}

+ (NSImage *)_backgroundCircleImage_white
{
    static NSImage *s_img = nil;
    if ( !s_img) {
        NSString *path = [[NSBundle bundleForClass:self] pathForResource:@"ui_circlebutton_bg_white" ofType:@"png"];
        s_img = [[NSImage alloc] initWithContentsOfFile:path];
        if ( !s_img) {
            s_img = [[NSImage imageNamed:@"ui_circlebutton_bg_white"] retain];
        }
    }
    return s_img;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setInterfaceTint:kLQLightTint];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setInterfaceTint:kLQLightTint];
    }
    return self;
}

- (void)_releaseCachedMasks
{
    CGImageRelease(_bgImageMask);
    _bgImageMask = nil;
    CGImageRelease(_buttonImageMask);
    _buttonImageMask = nil;
}

- (void)dealloc
{
    [_bgImage release];
    [self _releaseCachedMasks];
    [super dealloc];
}

- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    _tint = tint;
    [_bgImage release];
    if (_tint == kLQFloaterTint) {
        _bgImage = [[[self class] _backgroundCircleImage_white] retain];
    } else {
        _bgImage = [[[self class] _backgroundCircleImage] retain];
    }
    [self setNeedsDisplay:YES];
}

- (LQInterfaceTint)interfaceTint {
    return _tint;
}

- (void)setImage:(NSImage *)image
{
    [super setImage:image];
    [self _releaseCachedMasks];
}


#pragma mark --- drawing ---

+ (NSDictionary *)_smallSizeTitleAttributes_black
{
    static NSDictionary *s_dict = nil;
    if ( !s_dict) {
        s_dict = [[NSMutableDictionary alloc] init];
        [(NSMutableDictionary *)s_dict setObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
        [(NSMutableDictionary *)s_dict setObject:[NSColor colorWithCalibratedWhite:0.0 alpha:0.85] forKey:NSForegroundColorAttributeName];
    }
    return s_dict;
}

+ (NSDictionary *)_smallSizeTitleAttributes_white
{
    static NSDictionary *s_dict = nil;
    if ( !s_dict) {
        s_dict = [[NSMutableDictionary alloc] init];
        [(NSMutableDictionary *)s_dict setObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
        [(NSMutableDictionary *)s_dict setObject:[NSColor colorWithCalibratedWhite:1.0 alpha:0.8] forKey:NSForegroundColorAttributeName];        
    }
    return s_dict;
}

+ (NSDictionary *)_smallSizeTitleAttributes_highlighted
{
    static NSDictionary *s_dict = nil;
    if ( !s_dict) {
        s_dict = [[NSMutableDictionary alloc] init];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
        [shadow setShadowBlurRadius:1.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.3]];
        
        [(NSMutableDictionary *)s_dict setObject:[NSFont systemFontOfSize:11.0] forKey:NSFontAttributeName];
        [(NSMutableDictionary *)s_dict setObject:[NSColor colorWithDeviceRed:0.4 green:0.43 blue:0.9 alpha:0.9] forKey:NSForegroundColorAttributeName];        
        [(NSMutableDictionary *)s_dict setObject:shadow forKey:NSShadowAttributeName];
    }
    return s_dict;
}


- (BOOL)isFlipped {
    return NO;
}

- (void)_recreateMaskImages
{
    [self _releaseCachedMasks];

    _bgImageMask = LQCreateGrayscaleImageFromCGImageAlpha([(NSBitmapImageRep *)[[_bgImage representations] objectAtIndex:0] CGImage]);

    NSImage *image = [self image];
    if ([[image representations] count] > 0) {
        _buttonImageMask = LQCreateGrayscaleImageFromCGImageAlpha([(NSBitmapImageRep *)[[image representations] objectAtIndex:0] CGImage]);
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    
    CGFloat imgDim = 64;  // this is the size of the background image
    CGFloat scale = 0.5;
    CGFloat targetDim = imgDim * scale;

    LQInterfaceTint tint = [self interfaceTint];
    NSString *title = [self title];
    BOOL hasTitle = ([title length] > 0);

    CGFloat opacity = (tint == kLQFloaterTint) ? 0.91 : 0.85;    
    
    double imageX = MAX(0.0, round((bounds.size.width - imgDim*scale) * 0.5));
    double y = bounds.size.height - imgDim*scale + 1;
    const double titleTopMargin = 2;
    
    NSCell *cell = [self cell];
    BOOL isHilite = [cell isHighlighted];
    
    //NSLog(@"circle x, y: %.3f, %.3f, %i, image %@", imageX, y, [self isFlipped], _bgImage);
    
    [_bgImage drawInRect:NSMakeRect(imageX, y, targetDim, targetDim)
                fromRect:NSMakeRect(0, 0, imgDim, imgDim)
                operation:NSCompositeSourceOver
                fraction:opacity];

    CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGRect targetRect = CGRectMake(imageX, y, targetDim, targetDim);
    
    NSImage *buttonImage = [self image];
    if (buttonImage) {
        if (tint != kLQFloaterTint) {
            [buttonImage drawInRect:NSMakeRect(imageX, y, targetDim, targetDim)
                        fromRect:NSMakeRect(0, 0, imgDim, imgDim)
                        operation:NSCompositeSourceOver
                        fraction:opacity];
        } else {
            if ( !_buttonImageMask) [self _recreateMaskImages];
            
            LXRGBA whiteButtonRGBA = LXMakeRGBA(1.0, 1.0, 1.0, opacity);
        
            CGContextSaveGState(ctx);
            CGContextClipToMask(ctx, targetRect, _buttonImageMask);
            CGContextSetRGBFillColor(ctx, whiteButtonRGBA.r, whiteButtonRGBA.g, whiteButtonRGBA.b, whiteButtonRGBA.a);
            CGContextFillRect(ctx, targetRect);
            CGContextRestoreGState(ctx);
        }
    }
    
    if (isHilite) {
        if ( !_bgImageMask) [self _recreateMaskImages];
        
        LXRGBA hiliteRGBA = LXMakeRGBA(0.4, 0.43, 1.0, 0.9);
        
        CGContextSaveGState(ctx);
        CGContextClipToMask(ctx, targetRect, _bgImageMask);        
        CGContextSetRGBFillColor(ctx, hiliteRGBA.r, hiliteRGBA.g, hiliteRGBA.b, hiliteRGBA.a);
        CGContextFillRect(ctx, targetRect);
        CGContextRestoreGState(ctx);

        CGContextSaveGState(ctx);
        CGContextClipToMask(ctx, targetRect, _buttonImageMask);
        CGContextSetRGBFillColor(ctx, hiliteRGBA.r, hiliteRGBA.g, hiliteRGBA.b, hiliteRGBA.a);
        CGContextFillRect(ctx, targetRect);
        CGContextRestoreGState(ctx);
    }
    
    if (hasTitle) {
        NSDictionary *attrs = nil;
        if (isHilite)
            attrs = [[self class] _smallSizeTitleAttributes_highlighted];
        else
            attrs = (tint == kLQFloaterTint) ? [[self class] _smallSizeTitleAttributes_white] : [[self class] _smallSizeTitleAttributes_black];
        
        NSSize size = [title sizeWithAttributes:attrs];
        
        if (size.width < bounds.size.width) {
            double x = MAX(0.0, round((bounds.size.width - size.width) * 0.5)) + 1.0;
            y = MAX(0.0, y - ceil(size.height) - titleTopMargin);
            [title drawAtPoint:NSMakePoint(x, y) withAttributes:attrs];
            //NSLog(@"text y: %.3f, h %.3f, ishilite %i", y, size.height, isHilite);
        }
        else {
            y -= titleTopMargin;
            [title drawInRect:NSMakeRect(0, 0, bounds.size.width, y) withAttributes:attrs];
        }
    }
}

@end
