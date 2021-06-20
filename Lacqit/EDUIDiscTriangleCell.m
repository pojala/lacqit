//
//  EDUIDiscTriangleCell.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUIDiscTriangleCell.h"
#import "EDUINSImageAdditions.h"


@implementation EDUIDiscTriangleCell


- (id)init
{
    [super init];
    [self setImage:[EDUIDiscTriangleCell closedTriangle] ];
    [self setControlTint:NSClearControlTint];
    return self;
}

- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    //[super highlight:flag withFrame:cellFrame inView:controlView];
    if (flag) {
        NSImage *image;
        if (_isOpened)
            image = [EDUIDiscTriangleCell highlightedOpenTriangle];
        else
            image = [EDUIDiscTriangleCell highlightedTriangle];
        
        //[im compositeToPoint:cellFrame.origin operation:NSCompositeSourceOver];
        NSSize size = (image) ? [image size] : NSZeroSize;
        NSRect imRect = NSMakeRect(0, 0, size.width, size.height);
        NSRect dstRect = imRect;
        dstRect.origin = cellFrame.origin;
        [image drawInRect:dstRect fromRect:imRect operation:NSCompositeSourceOver fraction:1.0];
        
    } else {
        [controlView setNeedsDisplay:YES];
    }
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
    BOOL flag = [super trackMouse:theEvent inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
    
    if (flag) {
        [self setOpened:!_isOpened];
    }    
    return flag;
}


- (void)setOpened:(BOOL)flag {
    _isOpened = flag; 
    if (flag)
        [self setImage:[EDUIDiscTriangleCell openTriangle] ];
    else
        [self setImage:[EDUIDiscTriangleCell closedTriangle] ];
}
    
- (BOOL)isOpened {
    return _isOpened; }




+ (NSImage *)closedTriangle
{
    static NSImage *closedImage = nil;
    
    if (!closedImage)
        closedImage = [NSImage imageInBundleWithName:@"ui_disctriangle_closed.tif"];
    return closedImage;
}

+ (NSImage *)highlightedTriangle
{
    static NSImage *hiliteImage = nil;
    
    if (!hiliteImage)
        hiliteImage = [NSImage imageInBundleWithName:@"ui_disctriangle_hilite.tif"];
    return hiliteImage;    
}

+ (NSImage *)openTriangle
{
    static NSImage *openImage = nil;
    
    if (!openImage)
        openImage = [NSImage imageInBundleWithName:@"ui_disctriangle_open.tif"];
    return openImage;
}

+ (NSImage *)highlightedOpenTriangle
{
    static NSImage *hiliteImage = nil;
    
    if (!hiliteImage)
        hiliteImage = [NSImage imageInBundleWithName:@"ui_disctriangle_open_hilite.tif"];
    return hiliteImage;    
}


@end
