//
//  LQThemedBox.m
//  Lacqit
//
//  Created by Pauli Ojala on 23.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQThemedBox.h"
#import "LQNSBezierPathAdditions.h"
#import "LQGradient.h"


@interface NSFont (ElCapitanAdditions)
+ (NSFont *)systemFontOfSize:(CGFloat)fontSize weight:(CGFloat)weight;
@end

#define FONTWEIGHT_MEDIUM 0.23
#define FONTWEIGHT_SEMIBOLD 0.3



@implementation LQThemedBox

- (void)dealloc
{
    [_boxGradient release];
    [super dealloc];
}

/*
- (void)awakeFromNib
{
    [super awakeFromNib];
#ifdef __COCOTRON__
    NSLog(@"awake, box %p, boxtype %i, bordertype %i, title '%@', tint %i", self, [self boxType], [self borderType], [self title], _interfaceTint);
#endif
}
*/

- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    if (tint != _interfaceTint) {
        _interfaceTint = tint;
        [self setNeedsDisplay:YES];
    }
}

- (LQInterfaceTint)interfaceTint {
    return _interfaceTint; }


- (void)setControlSize:(LXUInteger)controlSize
{
    if (controlSize != _lq_controlSize) {
        _lq_controlSize = controlSize;
        [self setNeedsDisplay:YES];
    }
}

- (LXUInteger)controlSize {
    return (_lq_controlSize > 0) ? _lq_controlSize : NSMiniControlSize;
}


- (void)drawRect:(NSRect)rect
{
    if ([self isHidden]) return;

    NSRect bounds = [self bounds];
    const LXUInteger boxType = [self boxType];
    const LXUInteger borderType = [self borderType];
    LXUInteger controlSize = [self controlSize];
    const BOOL isFloater = (_interfaceTint == kLQFloaterTint);
    const BOOL isFlipped = [self isFlipped];
    const double xMargin = 4;
    const double yMargin = 3;
    
    ///NSLog(@"%s, %p: bounds %@, boxtype %i, bordertype %i, title '%@', tint %i", __func__, self, NSStringFromRect(bounds), boxType, borderType, [self title], _interfaceTint);
    
    if (boxType == NSBoxSeparator) {
        //NSLog(@"separator box, bounds %@, bordertype %i, interfaceTint %i", NSStringFromRect(bounds), (int)borderType, (int)_interfaceTint);
    
        NSColor *borderColor = (isFloater) ? [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.93 alpha:0.5]
                                           : [NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.7];
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(bounds.origin.x, 0.5 + round(bounds.origin.y + bounds.size.height/2.0))];
        [path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width,  0.5 + round(bounds.origin.y + bounds.size.height/2.0))];
        [borderColor set];
        [path stroke];
        return;  // ---
    }

    NSString *title = [self title];
    NSSize titleSize = NSZeroSize;
    NSPoint titlePoint = NSZeroPoint;
        
    if ([title length] > 0 && [self titlePosition] != NSNoTitle) {
        NSColor *titleColor = (isFloater) ? [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.9]
                                          : //[NSColor colorWithDeviceRed:0.08 green:0.17 blue:0.38 alpha:0.95];
        [NSColor colorWithDeviceRed:0.08 green:0.13 blue:0.31 alpha:0.8];

        // special case for 10-point font
        LXFloat fontSize = (_lq_controlSize == 0) ? 10.0 : [NSFont systemFontSizeForControlSize:controlSize];
        
        NSFont *font = ([[NSFont class] respondsToSelector:@selector(systemFontOfSize:weight:)]) ? [NSFont systemFontOfSize:fontSize weight:FONTWEIGHT_SEMIBOLD] : [NSFont boldSystemFontOfSize:fontSize];

        NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                titleColor, NSForegroundColorAttributeName,
                                                font, NSFontAttributeName,
                                                nil];
    
        titleSize = [title sizeWithAttributes:titleAttrs];
        
        titlePoint = NSMakePoint(bounds.origin.x + xMargin, (isFlipped) ? yMargin : (bounds.size.height - titleSize.height - yMargin));
        
        [title drawAtPoint:titlePoint withAttributes:titleAttrs];
    }
    
    NSPoint borderStartPoint;
    NSPoint borderEndPoint;

    borderStartPoint = NSMakePoint(titlePoint.x, titlePoint.y + ((isFlipped) ? titleSize.height+2 : -2));
    borderStartPoint.y += 0.5;
        
    borderEndPoint = NSMakePoint(borderStartPoint.x + bounds.size.width - xMargin*2, borderStartPoint.y);
    
    if (borderType != NSNoBorder && titleSize.height > 0) {
        NSColor *borderColor = (isFloater) ? [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.68]
                                           : //[NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.5];
        [NSColor colorWithDeviceRed:0.08 green:0.11 blue:0.25 alpha:0.33];
    
        [borderColor set];
        
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:borderStartPoint];
        [path lineToPoint:borderEndPoint];
        
        [path setLineWidth:0.7];
        [path stroke];
    }
    
    if (borderType != NSNoBorder && !isFloater) {
        if ( !_boxGradient) {
            LQGradient *grad = [[[LQGradient alloc] init] autorelease];
        
            NSColor *c0 = [NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.06];
            NSColor *c1 = [NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.05];
            NSColor *c2 = [NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.022];
            NSColor *c3 = [NSColor colorWithDeviceRed:0.11 green:0.14 blue:0.32 alpha:0.0];
        
            grad = [grad gradientByAddingColorStop:c0 atPosition:0.0];
            grad = [grad gradientByAddingColorStop:c1 atPosition:MIN(0.2, 12.0 / bounds.size.height)];
            grad = [grad gradientByAddingColorStop:c2 atPosition:1.0 - MIN(0.2, 12.0 / bounds.size.height)];
            grad = [grad gradientByAddingColorStop:c3 atPosition:1.0];
            
            _boxGradient = [grad retain];
        }
        
        NSRect gradRect;
        gradRect.origin = borderStartPoint;
        gradRect.size.width = borderEndPoint.x - borderStartPoint.x;
        gradRect.size.height = borderEndPoint.y + 8;
        gradRect.origin.y = 1.0;
        
        gradRect = NSInsetRect(gradRect, 0, 2);
        
#ifdef __COCOTRON__
        [_boxGradient fillRect:gradRect angle:90];
#else
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:gradRect rounding:5];

        [_boxGradient fillBezierPath:path angle:90];
#endif
    }
}

@end
