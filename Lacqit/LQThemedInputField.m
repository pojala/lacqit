//
//  LQThemedInputField.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQThemedInputField.h"


@implementation LQThemedInputField

+ (CGFloat)fieldHeightForControlSize:(LXUInteger)controlSize
{
    switch (controlSize) {
        case NSMiniControlSize:     return 13.0;
        case NSSmallControlSize:    return 15.0;
        default:                    return 17.0;
    }
}


#define DEFAULTBGCOLOR      [NSColor colorWithDeviceRed:101./255 green:102./255 blue:103./255 alpha:0.95]
#define DEFAULTTEXTCOLOR    [NSColor colorWithDeviceRed:0.9 green:1.0 blue:0.99 alpha:0.77]

//#define LIGHTBGCOLOR        [NSColor colorWithDeviceRed:0x90/255. green:0x99/255. blue:0x9b/255. alpha:1.0]
#define LIGHTBGCOLOR        [NSColor colorWithDeviceRed:0.895 green:0.906 blue:0.82 alpha:0.77]
#define LIGHTTEXTCOLOR      [NSColor blackColor]


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSControlSize controlSize = (frame.size.height < 13.01) ? NSMiniControlSize : NSSmallControlSize;
    
        [self setEditable:YES];
        [self setBordered:NO];
        [self setBezeled:NO];
        [self setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:controlSize]]];
        [self setBackgroundColor://[NSColor colorWithDeviceRed:99./255 green:99./255 blue:88./255 alpha:0.98]];
                                           //[NSColor colorWithDeviceRed:89./255 green:89./255 blue:78./255 alpha:1.0]];
                                  DEFAULTBGCOLOR];
        [self setTextColor:DEFAULTTEXTCOLOR];
    }
    return self;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    if (tint != _interfaceTint) {
        _interfaceTint = tint;
        
        NSColor *bg;
        NSColor *fg;
        switch (tint) {
            default:    bg = DEFAULTBGCOLOR;
                        fg = DEFAULTTEXTCOLOR;
                        break;
                        
            case kLQLightTint:
                        bg = LIGHTBGCOLOR;
                        fg = LIGHTTEXTCOLOR;
                        break;
                       
            case kLQFloaterTint:
                        bg = [NSColor colorWithDeviceRed:20./255 green:20./255 blue:22./255 alpha:0.95];
                        fg = [NSColor colorWithDeviceRed:0.9 green:1.0 blue:0.99 alpha:0.8];
                        break;
        }
        
        [self setBackgroundColor:bg];
        [self setTextColor:fg];
        
        [self setNeedsDisplay:YES];
    }
}

- (LQInterfaceTint)interfaceTint {
    return _interfaceTint; }


@end
