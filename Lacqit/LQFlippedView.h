//
//  LQFlippedView.h
//  PixelMath
//
//  Created by Pauli Ojala on 13.8.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQFlippedView : NSView {

    BOOL _drawsBg;
    NSColor *_bgColor;
    
    LXInteger _tag;
}

- (void)setDrawsBackground:(BOOL)f;
- (BOOL)drawsBackground;

- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

- (void)setTag:(LXInteger)tag;
- (LXInteger)tag;

@end
