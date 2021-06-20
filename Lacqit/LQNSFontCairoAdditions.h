//
//  LQNSFontCairoAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQNSFontAdditions.h"
#import <Cairo/cairo.h>


@interface NSFont (LQNSFontCairoAdditions)

- (cairo_scaled_font_t *)createCairoScaledFontWithContext:(cairo_t *)cr;

- (cairo_scaled_font_t *)createCairoScaledFontWithContext:(cairo_t *)cr textOffsetX:(double)offX offsetY:(double)offY;

@end
