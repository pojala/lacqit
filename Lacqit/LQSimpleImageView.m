//
//  LQSimpleImageView.m
//  Lacqit
//
//  Created by Pauli Ojala on 13.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQSimpleImageView.h"


@implementation LQSimpleImageView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _opacity = 1.0;
    }
    return self;
}

- (void)dealloc {
    [_image release];
    [super dealloc];
}

- (void)setImage:(NSImage *)image {
    if (image != _image) {
        [_image release];
        _image = [image retain];
    }
}

- (NSImage *)image {
    return _image; }

- (void)setAlphaValue:(CGFloat)opacity {
    _opacity = opacity; }
    
- (CGFloat)alphaValue {
    return _opacity; }


- (BOOL)isOpaque {
    return NO; }
    

- (void)drawRect:(NSRect)rect
{
    if ( !_image) return;

    LXInteger align = 0;
    NSSize imSize = [_image size];
    NSRect bounds = [self bounds];
    NSRect outRect;
    
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
#if !defined(__LAGOON__)
    [ctx setCompositingOperation:NSCompositeCopy];
#endif
    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0] set];
    [[NSBezierPath bezierPathWithRect:bounds] fill];
    [ctx restoreGraphicsState];
    
    switch (align) {
        default:
            outRect.size = imSize;
            outRect.origin.x = round(bounds.origin.x + 0.5*(bounds.size.width - outRect.size.width));
            outRect.origin.y = round(bounds.origin.y + 0.5*(bounds.size.height - outRect.size.height));
            break;
    }
    
    [_image drawInRect:outRect
            fromRect:NSMakeRect(0, 0, imSize.width, imSize.height)
            operation:NSCompositeSourceOver
            fraction:_opacity];
}

@end
