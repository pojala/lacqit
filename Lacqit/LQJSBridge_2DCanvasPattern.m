//
//  LQJSBridge_2DCanvasPattern.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_2DCanvasPattern.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQJSBridge_Image.h"


@implementation LQJSBridge_2DCanvasPattern

- (id)initInJSContext:(JSContextRef)context patternCanvas:(LQJSBridge_2DCanvas *)pattCanvas
                                            extendMode:(cairo_extend_t)extend
{
    self = [super initInJSContext:context withOwner:nil];
    if (self) {        
        _pattSrcCanvas = [pattCanvas retain];
        _pattBitmap = [[pattCanvas cairoBitmap] retain];
        _extendMode = extend;
    }
    return self;
}

- (id)initInJSContext:(JSContextRef)context cairoBitmap:(LQCairoBitmap *)cairoBitmap
                                            extendMode:(cairo_extend_t)extend
{
    self = [super initInJSContext:context withOwner:nil];
    if (self) {
        _pattSrcCanvas = nil;
        _pattBitmap = [cairoBitmap retain];
        _extendMode = extend;
    }
    return self;
}

- (id)initInJSContext:(JSContextRef)context patternImage:(LQJSBridge_Image *)pattImage
                                            extendMode:(cairo_extend_t)extend
{
    return [self initInJSContext:context cairoBitmap:[pattImage cairoBitmap] extendMode:extend];
}


- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj;
    if (_pattSrcCanvas) {
        newObj = [[[self class] alloc] initInJSContext:dstContext patternCanvas:_pattSrcCanvas extendMode:_extendMode];
    } else {
        newObj = [[[self class] alloc] initInJSContext:dstContext cairoBitmap:_pattBitmap extendMode:_extendMode];
    }
    return [newObj autorelease];
}


- (void)dealloc
{
    if (_cairoPattern) {
        cairo_pattern_destroy(_cairoPattern);
        _cairoPattern = NULL;
    }

    [_pattBitmap release];
    _pattBitmap = nil;

    [_pattSrcCanvas release];
    _pattSrcCanvas = nil;
    ///[_pattSrcImage release];
    ///_pattSrcImage = nil;
    
    [super dealloc];
}


- (void)_createCairoPattern
{
    if ( !_pattBitmap) return;
    
    cairo_surface_t *surf = [_pattBitmap cairoSurface];
    _cairoPattern = cairo_pattern_create_for_surface(surf);
    
    cairo_pattern_set_extend(_cairoPattern, _extendMode);
}

- (cairo_pattern_t *)cairoPattern
{
    if ( !_cairoPattern)
        [self _createCairoPattern];
        
    return _cairoPattern;
}

+ (NSString *)constructorName
{
    return @"<Canvas2DPattern>"; // can't be constructed
}


+ (NSArray *)objectFunctionNames
{
    return [NSArray arrayWithObjects:@"translate",   // this is not part of the HTML 5 spec
                                     nil]; 
}

- (id)lqjsCallTranslate:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        return nil;
    }
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    
    if ( !isfinite(x) || !isfinite(y)) {
        return nil;
    }

    cairo_pattern_t *pattern = [self cairoPattern];
    cairo_matrix_t matrix;
    memset(&matrix, 0, sizeof(cairo_matrix_t));

    cairo_pattern_get_matrix(pattern, &matrix);
    
    cairo_matrix_translate(&matrix, -x, -y);  // we invert the translation because the cairo pattern matrix is from user space to pattern space
    
    cairo_pattern_set_matrix(pattern, &matrix);

    return nil;
}

@end
