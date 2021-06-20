//
//  LQNSFontCairoAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSFontCairoAdditions.h"

#ifdef __APPLE__
#import <Cairo/CairoQuartz.h>
#endif


@implementation NSFont (LQNSFontCairoAdditions)

- (cairo_scaled_font_t *)createCairoScaledFontWithContext:(cairo_t *)cr
{
    return [self createCairoScaledFontWithContext:cr textOffsetX:0.0 offsetY:0.0];
}

- (cairo_scaled_font_t *)createCairoScaledFontWithContext:(cairo_t *)cr textOffsetX:(double)offX offsetY:(double)offY
{
    const double pointSize = [self pointSize];
    
    cairo_font_face_t *cairoFontFace = NULL;
#ifdef __APPLE__
    {
    CGFontRef cgFont = [self lq_createCGFontRef];
    cairoFontFace = cairo_quartz_font_face_create_for_cgfont(cgFont);
    CGFontRelease(cgFont);
    }
    
#else
    // could use Cocotron's internal methods...
    // first get the CTFont from the NSFont (in Cocotron, there's an internal _ctFont field).
    // then cast it to KTFont and call method: -(Win32Font *)createGDIFontSelectedInDC:(HDC)dc
    // followed by Win32Font's: -(HFONT)fontHandle,
    // then Cairo's: cairo_win32_font_face_create_for_hfont()

    #warning "Needs implementation on non-Apple platform"
    NSLog(@"*** %s: not implemented on this platform", __func__);
    return NULL;
#endif
    
    cairo_scaled_font_t *cairoScaledFont = NULL;
    {
    cairo_font_options_t *cairoFontOptions = cairo_font_options_create();

    cairo_matrix_t fontMatrix;
    cairo_matrix_init_identity(&fontMatrix);

    cairo_matrix_translate(&fontMatrix, offX, offY);

    cairo_matrix_scale(&fontMatrix, pointSize, pointSize);
    
    cairo_matrix_t ctm;
    cairo_get_matrix(cr, &ctm);
    
    cairoScaledFont = cairo_scaled_font_create(cairoFontFace, &fontMatrix, &ctm, cairoFontOptions);
    
    cairo_font_options_destroy(cairoFontOptions);
    }

    cairo_font_face_destroy(cairoFontFace);
    cairoFontFace = NULL;

    return cairoScaledFont;
}

@end
