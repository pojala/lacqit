//
//  LacqitTestView.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LacqitTestView.h"
#import <Lacefx/Lacefx.h>
#import <Cairo/cairo.h>

#import <Lacqit/LQCairoBitmap.h>
#import <Lacqit/LQCGBitmap.h>
#import <Lacqit/LQLacefxView.h>
#import <Lacqit/LQLXPixelBuffer.h>
#import <Lacqit/LQTimeFunctions.h>


@implementation LacqitTestView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    
        _cairoBitmap = [[LQCairoBitmap alloc] initWithSize:NSMakeSize(256, 256)];
        
        _cgBitmap = [[LQCGBitmap alloc] initWithSize:NSMakeSize(200, 200)];
        
        _pixbuf = [[LQLXPixelBuffer alloc] initWithContentsOfFile:@"/Users/pauli/Pictures/monteu-01-512.png"
                                                    properties:nil
                                                    error:NULL];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    
}


#pragma mark --- lacefx view delegate ---

- (void)_drawTestInCairoBitmap
{
    NSAssert(_cairoBitmap, @"no bitmap");
    cairo_t *cr = [_cairoBitmap lockCairoContext];

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

    /*
    cairo_move_to (cr, 50, 150);
    cairo_select_font_face (cr, "Arial", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
    cairo_set_font_size (cr, 20);
    cairo_set_source_rgba (cr, 1, 1, 1, 1);
    cairo_show_text (cr, "Jackdaws love my big sphinx of quartz");
*/
/*
    cairo_set_source_rgba (cr, 0.7, 0.3, 0, 1);
    cairo_set_operator (cr, CAIRO_OPERATOR_SOURCE);
    cairo_paint (cr);
    cairo_set_operator (cr, CAIRO_OPERATOR_OVER);
  */      
    [_cairoBitmap unlockCairoContext];
}

- (void)_drawTestInCGBitmap
{
    [_cgBitmap lockFocus];
    
    [[NSColor colorWithDeviceRed:1.0 green:0.3 blue:0.0 alpha:1.0] set];
    NSRectFill(NSMakeRect(0, 0, 200, 200));
    
    [_cgBitmap unlockFocus];
}

- (void)drawContentsForLacefxView:(LQLacefxView *)view inSurface:(LXSurfaceRef)lxSurface
{
    NSRect bounds = [view bounds];
    int i;

    LXSurfaceClearRegionWithRGBA(lxSurface, LXMakeRect(0, 0, bounds.size.width, bounds.size.height), LXMakeRGBA(0.3, 0.3, 0.3, 1));
    /*
    #define TESTITERATIONS 1
    
    for (i = 0; i < TESTITERATIONS; i++)
        [self _drawTestInCairoBitmap];
    
    
    [self _drawTestInCGBitmap];
    
    [_cairoBitmap drawInLXSurface:lxSurface atPoint:LXMakePoint(50, 50)];
    
    [_cgBitmap drawInLXSurface:lxSurface atPoint:LXMakePoint(300, 50)];
    */
    
    LXInteger testW = 900;
    LXInteger testH = 630;
    
    LXPixelBufferRef pixbuf = [_pixbuf lxPixelBuffer];
    
    double ts1 = LQReferenceTimeGetCurrent();
    LXPixelBufferRef scaled = LXPixelBufferCreateScaled(pixbuf, testW, testH, NULL);
    double ts2 = LQReferenceTimeGetCurrent();
    NSLog(@"scaled in %.3f ms", 1000*(ts2-ts1));
    
    LXTextureRef texture = LXPixelBufferGetTexture(scaled, NULL);
    
    if (texture) {
        LXVertexXYUV vertices[4];
        LXSetQuadVerticesXYUV(vertices, LXMakeRect(0, 0, testW, testH), LXUnitRect);
    
        LXSurfaceDrawTexturedQuad(lxSurface, vertices, kLXVertex_XYUV, texture, NULL);
    }
    LXPixelBufferRelease(scaled);
}

@end
