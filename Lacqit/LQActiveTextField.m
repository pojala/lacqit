//
//  LQActiveTextField.m
//  PixelMath
//
//  Created by Pauli Ojala on 5.1.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQActiveTextField.h"


@implementation LQActiveTextField

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [_hiliteAttrs release];
    [super dealloc];
}

- (void)setHighlightAttributes:(NSDictionary *)attrs {
    [_hiliteAttrs release];
    _hiliteAttrs = [attrs copy];
}

- (NSDictionary *)highlightAttributes {
    return _hiliteAttrs;
}


- (void)mouseDown:(NSEvent *)ev
{
    _hilite = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)ev
{
    _hilite = NO;
    
    NSPoint p = [self convertPoint:[ev locationInWindow] fromView:nil];
    
    if (NSPointInRect(p, [self bounds])) {
        [[self target] performSelector:[self action] withObject:self];
    }
    
    [self setNeedsDisplay:YES];
}

+ (NSDictionary *)highlightAttributesWithFont:(NSFont *)font
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        attribs = [[NSMutableDictionary alloc] init];

        [attribs setObject:font forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:0.3] forKey:NSForegroundColorAttributeName];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(3.0f, -2.0f)];
		[shadow setShadowBlurRadius:4.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.08f green:0.1f blue:1.0f alpha:0.85f]];
        
        [attribs setObject:shadow forKey:NSShadowAttributeName];
					
    }
    return attribs;
}

- (void)drawRect:(NSRect)rect
{
    if (_hilite) {
        NSString *str = [self stringValue];
        
        NSDictionary *attrs = (_hiliteAttrs) ? _hiliteAttrs : [[self class] highlightAttributesWithFont:[self font]];
        if ([self alignment] != NSLeftTextAlignment) {            
            NSMutableParagraphStyle *pstyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
            [pstyle setAlignment:[self alignment]];
            
            attrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            [(id)attrs setObject:pstyle forKey:NSParagraphStyleAttributeName];
        }
        
        [str drawInRect:[self bounds] withAttributes:attrs];
            
    }
    
    [super drawRect:rect];
}

@end
