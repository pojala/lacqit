//
//  LQJSBridge_2DContext.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_2DContext.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQJSBridge_2DCanvasPattern.h"
#import "LQJSBridge_2DCanvasGradient.h"
#import "LQJSBridge_Color.h"
#import "LQJSBridge_Image.h"
#import "LQJSBridge_2DCanvasPixelArray.h"
#import "LQNSFontCairoAdditions.h"
#import "LQNSColorAdditions.h"

#ifdef __APPLE__
#import <Cairo/CairoQuartz.h>
#endif


NSString * const kLQJS2DCompOp_SourceAtop = @"source-atop";
NSString * const kLQJS2DCompOp_SourceIn = @"source-in";
NSString * const kLQJS2DCompOp_SourceOut = @"source-out";
NSString * const kLQJS2DCompOp_SourceOver = @"source-over";
NSString * const kLQJS2DCompOp_DstAtop = @"destination-atop";
NSString * const kLQJS2DCompOp_DstIn = @"destination-in";
NSString * const kLQJS2DCompOp_DstOut = @"destination-out";
NSString * const kLQJS2DCompOp_DstOver = @"destination-over";
NSString * const kLQJS2DCompOp_Lighter = @"lighter";
NSString * const kLQJS2DCompOp_Copy = @"copy";
NSString * const kLQJS2DCompOp_Xor = @"xor";


enum {
    kLQTextAlign_Start = 0,
    kLQTextAlign_End,
    kLQTextAlign_Left,
    kLQTextAlign_Right,
    kLQTextAlign_Center,
};

enum {
    kLQTextBaseline_Alphabetic = 0,  // this is the default according to HTML 5 spec
    kLQTextBaseline_Top,
    kLQTextBaseline_Bottom,
    kLQTextBaseline_Middle,
    kLQTextBaseline_Hanging,
    kLQTextBaseline_Ideographic,
};


@implementation LQJSBridge_2DContext

- (id)initInJSContext:(JSContextRef)context withOwnerCanvas:(LQJSBridge_2DCanvas *)canvas
{
    /*// if the canvas doesn't have an owner, it was JS constructed and will be garbage collected
    // --> we should follow its example
    // ------- removed, didn't make sense after all...
    id owner = ([canvas owner]) ? canvas : nil;
    */
    self = [super initInJSContext:context ///(owner) ? [canvas jsContextRef] : context
                        withOwner:canvas];
    
    if (self) {
        _canvas = canvas;
        
        _globalAlpha = 1.0;
        _globalCompOp = [kLQJS2DCompOp_SourceOver retain];
        _globalCompOpCairo = CAIRO_OPERATOR_OVER;
        
        _lineWidth = 1.0;
        _lineCap = [@"butt" retain];
        _lineJoin = [@"miter" retain];
        _miterLimit = 10.0;
        
        ////_createdBridgeObjs = [[NSMutableArray array] retain];
        
        _font = [[NSFont systemFontOfSize:10.0] retain];
        
        _stack = [[NSMutableArray alloc] initWithCapacity:30];
        
        //NSLog(@"%s:  Cairo DLL version is: %s", __func__, cairo_version_string());
        //NSLog(@"%s (%@): inited with canvas %p, cairoctx %p", __func__, self, _canvas, _cr);
    }
    return self;
}

#define ENTERCR \
        if ( !_cr) { \
            LQCairoBitmap *bmp_ = [_canvas cairoBitmap]; \
            _cr = [bmp_ lockCairoContext]; \
        } \
        if (_cr) { \
            cairo_t *cr = _cr;

#define EXITCR \
            cr = NULL; \
        }


- (void)finishContext
{
    if (_cr) {
        [[_canvas cairoBitmap] unlockCairoContext];
        _cr = NULL;
    }
}

- (void)dealloc
{
    [_stack release];

    if ([_fillStyle respondsToSelector:@selector(setOwner:)])
        [_fillStyle setOwner:nil];
    [_fillStyle release];
    _fillStyle = nil;

    if ([_strokeStyle respondsToSelector:@selector(setOwner:)])
        [_strokeStyle setOwner:nil];
    [_strokeStyle release];
    _strokeStyle = nil;
    
    [_globalCompOp release];
    _globalCompOp = nil;
    
    [_lineCap release];
    _lineCap = nil;
    
    [_lineJoin release];
    _lineJoin = nil;
    
    //NSLog(@"%s (%@): %p", __func__, self, _cr);
    [_font release];
    _font = nil;
    
    [_shadowColor release];
    _shadowColor = nil;
    
    [self finishContext];
    _canvas = nil;
    
    [super dealloc];
}

+ (NSString *)constructorName
{
    return @"<Canvas2DContext>"; // can't be constructed
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"globalAlpha", @"globalCompositeOperation",
                                      @"strokeStyle", @"fillStyle",
                                      @"lineWidth", @"lineCap", @"lineJoin", @"miterLimit",
                                      @"font", @"textAlign", @"textBaseline",
                                      @"shadowColor", @"shadowBlur", @"shadowOffsetX", @"shadowOffsetY",
                                      nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return YES;
}

- (void)setFont:(NSString *)fontStr {
    NSFont *newFont = [_owner cachedFontForString:fontStr]; ///[NSFont fontWithCSSFormattedString:fontStr];
    ///NSLog(@"setFont(): '%@' --> %@", fontStr, newFont);
    if (newFont) {
        [_font autorelease];
        _font = [newFont retain];
    }
}

- (NSString *)font {
    return (_font) ? [_font cssFormattedString] : @"";
}

- (NSString *)textAlign {
    switch (_textAlign) {
        default:
            return @"start";
        case kLQTextAlign_End:
            return @"end";
        case kLQTextAlign_Left:
            return @"left";
        case kLQTextAlign_Right:
            return @"right";
        case kLQTextAlign_Center:
            return @"center";
    }
}

- (void)setTextAlign:(NSString *)str {
    NSString *name = [str description];
    
    if ([name isEqualToString:@"start"]) {
        _textAlign = kLQTextAlign_Start;
    } else if ([name isEqualToString:@"end"]) {
        _textAlign = kLQTextAlign_End;
    } else if ([name isEqualToString:@"left"]) {
        _textAlign = kLQTextAlign_Left;
    } else if ([name isEqualToString:@"right"]) {
        _textAlign = kLQTextAlign_Right;
    } else if ([name isEqualToString:@"center"]) {
        _textAlign = kLQTextAlign_Center;
    }
}

- (NSString *)textBaseline {
    switch (_textBaseline) {
        default:
            return @"alphabetic";
        case kLQTextBaseline_Top:
            return @"top";
        case kLQTextBaseline_Hanging:
            return @"hanging";
        case kLQTextBaseline_Middle:
            return @"middle";
        case kLQTextBaseline_Ideographic:
            return @"ideographic";
        case kLQTextBaseline_Bottom:
            return @"bottom";
    }
}

- (void)setTextBaseline:(NSString *)str {
    NSString *name = [str description];
    
    if ([name isEqualToString:@"alphabetic"]) {
        _textBaseline = kLQTextBaseline_Alphabetic;
    } else if ([name isEqualToString:@"top"]) {
        _textBaseline = kLQTextBaseline_Top;
    } else if ([name isEqualToString:@"hanging"]) {
        _textBaseline = kLQTextBaseline_Hanging;
    } else if ([name isEqualToString:@"middle"]) {
        _textBaseline = kLQTextBaseline_Middle;
    } else if ([name isEqualToString:@"ideographic"]) {
        _textBaseline = kLQTextBaseline_Ideographic;
    } else if ([name isEqualToString:@"bottom"]) {
        _textBaseline = kLQTextBaseline_Bottom;
    }
}


- (double)globalAlpha {
    return _globalAlpha; }
    
- (void)setGlobalAlpha:(double)f {
    if (f != _globalAlpha) {
        _globalAlpha = f;
    }
}


- (NSString *)globalCompositeOperation {
    return _globalCompOp; }
    
- (void)setGlobalCompositeOperation:(NSString *)op {
    NSString *opName = [op description];
    
    [_globalCompOp release];
    _globalCompOp = [opName copy];
    
    {
        int cop = -1;
        if ([_globalCompOp isEqualToString:kLQJS2DCompOp_SourceAtop])
            cop = CAIRO_OPERATOR_ATOP;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_SourceIn])
            cop = CAIRO_OPERATOR_IN;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_SourceOut])
            cop = CAIRO_OPERATOR_OUT;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_SourceOver])
            cop = CAIRO_OPERATOR_OVER;
            
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_DstAtop])
            cop = CAIRO_OPERATOR_DEST_ATOP;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_DstIn])
            cop = CAIRO_OPERATOR_DEST_IN;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_DstOut])
            cop = CAIRO_OPERATOR_DEST_OUT;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_DstOver])
            cop = CAIRO_OPERATOR_DEST_OVER;
            
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_Lighter])
            cop = CAIRO_OPERATOR_SATURATE;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_Copy])
            cop = CAIRO_OPERATOR_SOURCE;
        else if ([_globalCompOp isEqualToString:kLQJS2DCompOp_Xor])
            cop = CAIRO_OPERATOR_XOR;
            
        if (cop != -1) {
            _globalCompOpCairo = cop;
            ENTERCR
            cairo_set_operator(cr, cop);
            EXITCR
        }
    }
}
    


- (id)strokeStyle {
    return ([_strokeStyle respondsToSelector:@selector(htmlFormattedString)]) ? [_strokeStyle htmlFormattedString]
                                                                              : (_strokeStyle) ? _strokeStyle : @"black";
}
    
- (id)fillStyle {
    return ([_fillStyle respondsToSelector:@selector(htmlFormattedString)]) ? [_fillStyle htmlFormattedString]
                                                                            : (_fillStyle) ? _fillStyle : @"black";
}
    
- (void)setStrokeStyle:(id)style
{
    if (style == _strokeStyle) return;

    /*
    if ([style isKindOfClass:[NSString class]]) {
        style = [[LQJSBridge_Color alloc] initWithHTMLFormattedString:[style lowercaseString] inJSContext:[self jsContextRef] withOwner:nil];
    }
    else*/
    if ([style isKindOfClass:[NSString class]]) {
        [_strokeStyle release];
        _strokeStyle = [[_owner cachedColorForString:style] retain]; 
                        ///[[LQJSBridge_Color alloc] initWithHTMLFormattedString:[style lowercaseString] inJSContext:[self jsContextRef] withOwner:nil];
        return;
    }

    if ([style isKindOfClass:[LQJSBridge_Color class]]) { // || [style respondsToSelector:@selector(cairoPattern)]) {
        style = [[style copyIntoJSContext:[self jsContextRef]] retain];
    }
    else [style retain];

    if ([style respondsToSelector:@selector(setOwner:)]) {
        if ([_strokeStyle respondsToSelector:@selector(setOwner:)])
            [_strokeStyle setOwner:nil];
        [_strokeStyle release];
                
        _strokeStyle = [style retain];
        if (_owner)
            [style setOwner:self];
        
        //ENTERCR
        //[self _applyStrokeStyle:cr];
        //EXITCR
        ///NSLog(@"setStrokeStyle / %p (owner %p, canvas %p):  obj %@", self, _owner, _canvas, _strokeStyle);
    }
    [style release];
}

- (void)setFillStyle:(id)style
{
    if (style == _fillStyle) return;
    
    if ([style isKindOfClass:[NSString class]]) {
        [_fillStyle release];
        _fillStyle = [[_owner cachedColorForString:style] retain]; 
                        ///[[LQJSBridge_Color alloc] initWithHTMLFormattedString:[style lowercaseString] inJSContext:[self jsContextRef] withOwner:nil];
        return;
    }
    
    if ([style isKindOfClass:[LQJSBridge_Color class]]) {
        style = [[style copyIntoJSContext:[self jsContextRef]] retain];
    }
    else [style retain];
    
    if ([style respondsToSelector:@selector(setOwner:)]) {
        if ([_fillStyle respondsToSelector:@selector(setOwner:)])
            [_fillStyle setOwner:nil];
        [_fillStyle release];
        
        _fillStyle = [style retain];
        if (_owner)
            [style setOwner:self];
    }
    [style release];
}


- (double)lineWidth {
    return _lineWidth; }
    
- (double)miterLimit {
    return _miterLimit; }
    
- (void)setLineWidth:(double)f {
    if (f > 0.0 && isfinite(f)) {
        _lineWidth = f;
        
        ENTERCR
        cairo_set_line_width(cr, _lineWidth);
        EXITCR
    }
}

- (void)setMiterLimit:(double)f {
    if (f > 0.0 && isfinite(f)) {
        _miterLimit = f;
        
        ENTERCR
        cairo_set_miter_limit(cr, _miterLimit);
        EXITCR
    }
}

    
- (NSString *)lineCap {
    return _lineCap; }
    
- (NSString *)lineJoin {
    return _lineJoin; }
        
- (void)setLineCap:(NSString *)cap {
    int ct = -1;
    if ([cap isEqualToString:@"butt"])
        ct = CAIRO_LINE_CAP_BUTT;
    else if ([cap isEqualToString:@"round"])
        ct = CAIRO_LINE_CAP_ROUND;
    else if ([cap isEqualToString:@"square"])
        ct = CAIRO_LINE_CAP_SQUARE;
    
    if (ct != -1) {
        [_lineCap release];
        _lineCap = [cap retain];
    
        ENTERCR
        cairo_set_line_cap(cr, ct);
        EXITCR
    }
}

- (void)setLineJoin:(NSString *)join {
    int ct = -1;
    if ([join isEqualToString:@"miter"])
        ct = CAIRO_LINE_JOIN_MITER;
    else if ([join isEqualToString:@"round"])
        ct = CAIRO_LINE_JOIN_ROUND;
    else if ([join isEqualToString:@"bevel"])
        ct = CAIRO_LINE_JOIN_BEVEL;

    if (ct != -1) {
        [_lineJoin release];
        _lineJoin = [join retain];
        
        ENTERCR
        cairo_set_line_join(cr, ct);
        EXITCR
    }
}


- (id)shadowColor {
    return ([_shadowColor respondsToSelector:@selector(htmlFormattedString)]) ? [_shadowColor htmlFormattedString]
                                                                              : @"rgba(0, 0, 0, 0.0)";
}

- (void)setShadowColor:(id)style
{
    if (style == _shadowColor) return;
    
    if ([style isKindOfClass:[NSString class]]) {
        [_shadowColor release];
        
        NSColor *c = [_owner cachedColorForString:style];
        if ([c rgba].a > 0.001) {
            _shadowColor = [c retain];
        } else {
            _shadowColor = nil;
        }
    }
    else if ([style isKindOfClass:[LQJSBridge_Color class]]) {
        [_shadowColor release];
        _shadowColor = [[style copyIntoJSContext:[self jsContextRef]] retain];
        return;
    }
    else {
        [_shadowColor release], _shadowColor = nil;
    }
}

- (double)shadowBlur {
    return _shadowBlur;
}

- (void)setShadowBlur:(double)f {
    if (f >= 0.0 && isfinite(f)) {
        _shadowBlur = f;
    }
}

- (double)shadowOffsetX {
    return _shadowOffset.x;
}

- (void)setShadowOffsetX:(double)f {
    if (isfinite(f)) {
        _shadowOffset.x = f;
    }
}

- (double)shadowOffsetY {
    return _shadowOffset.y;
}

- (void)setShadowOffsetY:(double)f {
    if (isfinite(f)) {
        _shadowOffset.y = f;
    }
}


#pragma mark --- methods ---

/*
Following are the functions defined for WebKit's CanvasRenderingContext2D:

    arc
    arcTo
    beginPath
    bezierCurveTo
    clearRect
    clearShadow
    clip
    closePath
    createLinearGradient
    createPattern
    createRadialGradient
    drawImage
    drawImageFromRect
    fill
    fillRect
    isPointInPath
    lineTo
    moveTo
    quadraticCurveTo
    rect
    restore
    rotate
    save
    scale
    setAlpha
    setCompositeOperation
    setFillColor
    setLineCap
    setLineJoin
    setLineWidth
    setMiterLimit
    setShadow
    setStrokeColor
    stroke
    strokeRect
    transform
    translate

-----

Following is HTML5 canvas draft API:

 readonly attribute HTMLCanvasElement canvas;

  // state
  void save(); // push state on state stack
  void restore(); // pop state stack and restore state

  // transformations (default transform is the identity matrix)
  void scale(in float x, in float y);
  void rotate(in float angle);
  void translate(in float x, in float y);
  void transform(in float m11, in float m12, in float m21, in float m22, in float dx, in float dy);
  void setTransform(in float m11, in float m12, in float m21, in float m22, in float dx, in float dy);

  // compositing
           attribute float globalAlpha; // (default 1.0)
           attribute DOMString globalCompositeOperation; // (default source-over)

  // colors and styles
           attribute DOMObject strokeStyle; // (default black)
           attribute DOMObject fillStyle; // (default black)
  CanvasGradient createLinearGradient(in float x0, in float y0, in float x1, in float y1);
  CanvasGradient createRadialGradient(in float x0, in float y0, in float r0, in float x1, in float y1, in float r1);
  CanvasPattern createPattern(in HTMLImageElement image, in DOMString repetition);
  CanvasPattern createPattern(in HTMLCanvasElement image, in DOMString repetition);

  // line caps/joins
           attribute float lineWidth; // (default 1)
           attribute DOMString lineCap; // "butt", "round", "square" (default "butt")
           attribute DOMString lineJoin; // "round", "bevel", "miter" (default "miter")
           attribute float miterLimit; // (default 10)

  // shadows
           attribute float shadowOffsetX; // (default 0)
           attribute float shadowOffsetY; // (default 0)
           attribute float shadowBlur; // (default 0)
           attribute DOMString shadowColor; // (default transparent black)

  // rects
  void clearRect(in float x, in float y, in float w, in float h);
  void fillRect(in float x, in float y, in float w, in float h);
  void strokeRect(in float x, in float y, in float w, in float h);

  // path API
  void beginPath();
  void closePath();
  void moveTo(in float x, in float y);
  void lineTo(in float x, in float y);
  void quadraticCurveTo(in float cpx, in float cpy, in float x, in float y);
  void bezierCurveTo(in float cp1x, in float cp1y, in float cp2x, in float cp2y, in float x, in float y);
  void arcTo(in float x1, in float y1, in float x2, in float y2, in float radius);
  void rect(in float x, in float y, in float w, in float h);
  void arc(in float x, in float y, in float radius, in float startAngle, in float endAngle, in boolean anticlockwise);
  void fill();
  void stroke();
  void clip();
  boolean isPointInPath(in float x, in float y);

  // text
           attribute DOMString font; // (default 10px sans-serif)
           attribute DOMString textAlign; // "start", "end", "left", "right", "center" (default: "start")
           attribute DOMString textBaseline; // "top", "hanging", "middle", "alphabetic", "ideographic", "bottom" (default: "alphabetic")
  void fillText(in DOMString text, in float x, in float y);
  void fillText(in DOMString text, in float x, in float y, in float maxWidth);
  void strokeText(in DOMString text, in float x, in float y);
  void strokeText(in DOMString text, in float x, in float y, in float maxWidth);
  TextMetrics measureText(in DOMString text);

  // drawing images
  void drawImage(in HTMLImageElement image, in float dx, in float dy);
  void drawImage(in HTMLImageElement image, in float dx, in float dy, in float dw, in float dh);
  void drawImage(in HTMLImageElement image, in float sx, in float sy, in float sw, in float sh, in float dx, in float dy, in float dw, in float dh);
  void drawImage(in HTMLCanvasElement image, in float dx, in float dy);
  void drawImage(in HTMLCanvasElement image, in float dx, in float dy, in float dw, in float dh);
  void drawImage(in HTMLCanvasElement image, in float sx, in float sy, in float sw, in float sh, in float dx, in float dy, in float dw, in float dh);

  // pixel manipulation
  ImageData createImageData(in float sw, in float sh);
  ImageData getImageData(in float sx, in float sy, in float sw, in float sh);
  void putImageData(in ImageData imagedata, in float dx, in float dy);
  void putImageData(in ImageData imagedata, in float dx, in float dy, in float dirtyX, in float dirtyY, in float dirtyWidth, in float dirtyHeight);

*/

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"save", @"restore",
    
                                     @"scale", @"rotate", @"translate", @"transform", @"setTransform",
                                     
                                     @"createPattern", @"createLinearGradient", @"createRadialGradient",
                                     
                                     @"fillRect", @"strokeRect", @"clearRect",
                                     
                                     @"beginPath", @"closePath", @"moveTo", @"lineTo", @"bezierCurveTo",
                                                   @"rect", @"arc", @"fill", @"stroke", @"clip",
                                                   
                                     @"drawImage",
                                     
                                     @"fillText", @"strokeText", @"measureText", 
                                     
                                     @"getImageData", @"putImageData",
                                     nil]; 
}

- (id)lqjsCallSave:(NSArray *)args context:(id)contextObj
{
    //NSLog(@"%s: args %@", __func__, args);
    
    // save properties that are not part of Cairo state
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:[NSNumber numberWithDouble:_globalAlpha] forKey:@"globalAlpha"];
    [dict setObject:[NSNumber numberWithInteger:_globalCompOpCairo] forKey:@"globalCompOpCairo"];
    
    if (_globalCompOp) [dict setObject:_globalCompOp forKey:@"globalCompOp"];    
    if (_font) [dict setObject:_font forKey:@"font"];
    if (_shadowColor) [dict setObject:_shadowColor forKey:@"shadowColor"];
    
    [_stack addObject:dict];

    ENTERCR
    cairo_save(cr);
    EXITCR
    return nil;
}

- (id)lqjsCallRestore:(NSArray *)args context:(id)contextObj
{
    //NSLog(@"%s: args %@", __func__, args);
    
    NSDictionary *dict = [_stack lastObject];
    [_stack removeLastObject];
    
    _globalAlpha = [[dict objectForKey:@"globalAlpha"] doubleValue];
    _globalCompOpCairo = [[dict objectForKey:@"globalCompOpCairo"] integerValue];

    [_globalCompOp release], _globalCompOp = [[dict objectForKey:@"globalCompOp"] retain];
    [_font release], _font = [[dict objectForKey:@"font"] retain];
    [_shadowColor release], _shadowColor = [[dict objectForKey:@"shadowColor"] retain];
    
    ENTERCR
    cairo_restore(cr);
    EXITCR
    return nil;
}



#define LOGFUNC(funcname_, format_, args_...) \
    NSLog(@"%@", [[NSString stringWithFormat:@"Canvas function %@(): ", funcname_] stringByAppendingString:[NSString stringWithFormat:format_ , ## args_]]);


/*  void scale(in float x, in float y);
  void rotate(in float angle);
  void translate(in float x, in float y);
  void transform(in float m11, in float m12, in float m21, in float m22, in float dx, in float dy);
  void setTransform(in float m11, in float m12, in float m21, in float m22, in float dx, in float dy);
*/
- (id)lqjsCallScale:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        LOGFUNC(@"scale", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];

    if ( !isfinite(x) || !isfinite(y)) return nil;
    
    ENTERCR
    cairo_scale(cr, x, y);
    EXITCR
    return nil;
}

- (id)lqjsCallRotate:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) {
        LOGFUNC(@"rotate", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double r = [[args objectAtIndex:0] doubleValue];

    if ( !isfinite(r)) return nil;
    
    ENTERCR
    cairo_rotate(cr, r);
    EXITCR
    return nil;
}

- (id)lqjsCallTranslate:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        LOGFUNC(@"translate", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];

    if ( !isfinite(x) || !isfinite(y)) return nil;
    
    ENTERCR
    cairo_translate(cr, x, y);
    EXITCR
    return nil;
}

- (id)lqjsCallTransform:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 6) {
        LOGFUNC(@"transform", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double m11 = [[args objectAtIndex:0] doubleValue];
    double m12 = [[args objectAtIndex:1] doubleValue];
    double m21 = [[args objectAtIndex:2] doubleValue];
    double m22 = [[args objectAtIndex:3] doubleValue];
    double dx  = [[args objectAtIndex:4] doubleValue];
    double dy  = [[args objectAtIndex:5] doubleValue];

    if ( !isfinite(m11) || !isfinite(m12) || !isfinite(m21) || !isfinite(m22) || !isfinite(dx) || !isfinite(dy)) return nil;
    
    cairo_matrix_t mat = { m11, m12, m21, m22, dx, dy };
    
    ENTERCR
    cairo_transform(cr, &mat);
    EXITCR
    return nil;
}

- (id)lqjsCallSetTransform:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 6) {
        LOGFUNC(@"setTransform", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double m11 = [[args objectAtIndex:0] doubleValue];
    double m12 = [[args objectAtIndex:1] doubleValue];
    double m21 = [[args objectAtIndex:2] doubleValue];
    double m22 = [[args objectAtIndex:3] doubleValue];
    double dx  = [[args objectAtIndex:4] doubleValue];
    double dy  = [[args objectAtIndex:5] doubleValue];

    if ( !isfinite(m11) || !isfinite(m12) || !isfinite(m21) || !isfinite(m22) || !isfinite(dx) || !isfinite(dy)) return nil;
    
    cairo_matrix_t mat = { m11, m12, m21, m22, dx, dy };
    
    ENTERCR
    cairo_set_matrix(cr, &mat);
    EXITCR
    return nil;
}



#pragma mark --- fills/strokes/paths ---

- (void)_applyFillStyle:(cairo_t *)cr
{
    id style = _fillStyle;
    
    ///NSLog(@"%s: fillstyle is %@", __func__, style);
    
    if ( !style || [style respondsToSelector:@selector(rgba)]) {
        LXRGBA rgba = (style) ? [style rgba_sRGB] : LXWhiteRGBA;
        cairo_set_source_rgba(cr, rgba.r, rgba.g, rgba.b, rgba.a);

        //NSLog(@"2dctx applyFill: %.3f, %.3f, %.3f, %.3f (%@)", rgba.r, rgba.g, rgba.b, rgba.a, style);
    }
    else if ([style respondsToSelector:@selector(cairoPattern)]) {
        ///NSLog(@"applying fill style %@, pattern is %p", style, [style cairoPattern]);
    
        cairo_set_source(cr, [style cairoPattern]);
    }
}

- (void)_applyStrokeStyle:(cairo_t *)cr
{
    id style = _strokeStyle;
    
    ///NSLog(@"%s: %@", __func__, style);
    
    if ( !style || [style respondsToSelector:@selector(rgba)]) {
        LXRGBA rgba = (style) ? [style rgba_sRGB] : LXBlackOpaqueRGBA;
        
        // apply global alpha to stroke here
        rgba.a *= _globalAlpha;
        
        cairo_set_source_rgba(cr, rgba.r, rgba.g, rgba.b, rgba.a);

        //NSLog(@"2dctx applyStroke: %.3f, %.3f, %.3f, %.3f (%@)", rgba.r, rgba.g, rgba.b, rgba.a, style);
    }
    else if ([style respondsToSelector:@selector(cairoPattern)]) {
        cairo_set_source(cr, [style cairoPattern]);
    }
}

- (id)lqjsCallCreateLinearGradient:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 4) {
        LOGFUNC(@"createLinearGradient", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x1 = [[args objectAtIndex:0] doubleValue];
    double y1 = [[args objectAtIndex:1] doubleValue];
    double x2 = [[args objectAtIndex:2] doubleValue];
    double y2 = [[args objectAtIndex:3] doubleValue];
    
    if ( !isfinite(x1) || !isfinite(y1) || !isfinite(x2) || !isfinite(y2))  return nil;
    
    double points[4] = { x1, y1, x2, y2 };
    
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    JSContextRef jsCtx = [interp jsContextRef];  ///[self jsContextRef];  //[self jsContextRefFromJSCallContextObj:contextObj];
    
    LQJSBridge_2DCanvasGradient *gradObj = [[LQJSBridge_2DCanvasGradient alloc]
                                                initInJSContext:jsCtx
                                                isRadial:NO
                                                pointData:points];                                 
    if (gradObj) {
        //[gradObj setOwner:self];
        //[_createdBridgeObjs addObject:[gradObj autorelease]];
    }
    return [gradObj autorelease];
}

- (id)lqjsCallCreateRadialGradient:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 6) {
        LOGFUNC(@"createRadialGradient", @"invalid args: %ld", (long)[args count]);
        return nil;
    }

    double x1 = [[args objectAtIndex:0] doubleValue];
    double y1 = [[args objectAtIndex:1] doubleValue];
    double r1 = [[args objectAtIndex:2] doubleValue];
    double x2 = [[args objectAtIndex:3] doubleValue];
    double y2 = [[args objectAtIndex:4] doubleValue];
    double r2 = [[args objectAtIndex:5] doubleValue];
    
    if ( !isfinite(x1) || !isfinite(y1) || !isfinite(x2) || !isfinite(y2) || !isfinite(r1) || !isfinite(r2))  return nil;
    
    double points[6] = { x1, y1, x2, y2, r1, r2 };

    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    JSContextRef jsCtx = [interp jsContextRef];  ///[self jsContextRef];  //[self jsContextRefFromJSCallContextObj:contextObj];
    
    LQJSBridge_2DCanvasGradient *gradObj = [[LQJSBridge_2DCanvasGradient alloc]
                                                initInJSContext:jsCtx
                                                isRadial:YES
                                                pointData:points];                                 
    if (gradObj) {
        //[gradObj setOwner:self];
        //[_createdBridgeObjs addObject:[gradObj autorelease]];
    }
    return [gradObj autorelease];
}

- (id)lqjsCallCreatePattern:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        LOGFUNC(@"createPattern", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    JSContextRef jsCtx = [interp jsContextRef];  ///[self jsContextRef];  //[self jsContextRefFromJSCallContextObj:contextObj];
    id sourceElement = [args objectAtIndex:0];
    NSString *repetition = [args objectAtIndex:1];
    
    // HTML5 draft spec not fully implemented: "repeat-x" and "repeat-y" are not supported by Cairo
    cairo_extend_t extendMode = CAIRO_EXTEND_REPEAT;
    if ([repetition isEqualToString:@"no-repeat"])
        extendMode = CAIRO_EXTEND_NONE;
    else if ([repetition isEqualToString:@"pad"])  // not part of HTML5 draft
        extendMode = CAIRO_EXTEND_PAD;
    else if ([repetition isEqualToString:@"reflect"])
        extendMode = CAIRO_EXTEND_REFLECT;
        
    LQJSBridge_2DCanvasPattern *patternObj = nil;
        
    if ([sourceElement isKindOfClass:[LQJSBridge_Image class]]) {
        patternObj = [[LQJSBridge_2DCanvasPattern alloc] initInJSContext:jsCtx
                                                            patternImage:(LQJSBridge_Image *)sourceElement
                                                            extendMode:extendMode];

    } else if ([sourceElement isKindOfClass:[LQJSBridge_2DCanvas class]]) {
        patternObj = [[LQJSBridge_2DCanvasPattern alloc] initInJSContext:jsCtx
                                                            patternCanvas:(LQJSBridge_2DCanvas *)sourceElement
                                                            extendMode:extendMode];
    }
    
    /*if (patternObj) {
        [patternObj setOwner:self];
        [_createdBridgeObjs addObject:[patternObj autorelease]];
    }*/
    return [patternObj autorelease];
}

- (void)_willPaint
{
    [_owner contextWillPaint];
}

- (void)_didPaint
{
    [_owner contextDidPaint];
}

- (id)lqjsCallDrawImage:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    LXInteger argCount = [args count];
    if (argCount < 3) {
        LOGFUNC(@"drawImage", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    BOOL hasSourceCoordArgs = (argCount >= 9);
    
    id sourceElement = [args objectAtIndex:0];
    double dstX = [[args objectAtIndex:(hasSourceCoordArgs) ? 5 : 1] doubleValue];
    double dstY = [[args objectAtIndex:(hasSourceCoordArgs) ? 6 : 2] doubleValue];
    
    if ( !isfinite(dstX) || !isfinite(dstY)) return nil;
        
    LQCairoBitmap *cairoBitmap;
    
    if ([sourceElement respondsToSelector:@selector(cairoBitmap)]) {
        cairoBitmap = [sourceElement cairoBitmap];  // this is implemented by both 2DCanvas and Image bridges
    } else {
        if ([sourceElement isKindOfClass:[NSArray class]] && [sourceElement count] == 0) {
            // this happens in Conduit that the argument is an empty array -- not worth printing an error
        } else {
            NSLog(@"JS call 'canvas2dContext.drawImage': source element is unsupported (class: %@)", [sourceElement class]);
            //if ([sourceElement isKindOfClass:[NSString class]]) NSLog(@"... value: '%@'", sourceElement);
        }
        return nil;
    }
    
    cairo_surface_t *surf = [cairoBitmap cairoSurface];
    if ( !surf) {
        NSLog(@"** %s: no cairo surface (bitmap is %@)", __func__, cairoBitmap);
        return nil;
    }

    int bitmapW = [cairoBitmap width];
    int bitmapH = [cairoBitmap height];
    double dstW = bitmapW;
    double dstH = bitmapH;
    double srcX = 0, srcY = 0;
    double srcW = dstW;
    double srcH = dstH;
    
    if ([args count] >= 5) {
        if (hasSourceCoordArgs) {
            srcX = [[args objectAtIndex:1] doubleValue];
            srcY = [[args objectAtIndex:2] doubleValue];
            srcW = [[args objectAtIndex:3] doubleValue];
            srcH = [[args objectAtIndex:4] doubleValue];
            if ( !isfinite(srcX) || !isfinite(srcY) || !isfinite(srcW) || !isfinite(srcH)) {
                return nil;
            }
        }
        dstW = [[args objectAtIndex:(hasSourceCoordArgs) ? 7 : 3] doubleValue];
        dstH = [[args objectAtIndex:(hasSourceCoordArgs) ? 8 : 4] doubleValue];
        if ( !isfinite(dstW) || !isfinite(dstH)) {
            return nil;
        }
    }

    ///NSLog(@"%s: drawing; %.3f, %.3f, %.3f, %.3f", __func__, dstX, dstY, dstW, dstH);

    cairo_pattern_t *pattern = cairo_pattern_create_for_surface(surf);
    cairo_pattern_set_extend(pattern, CAIRO_EXTEND_REPEAT);
        
    cairo_matrix_t matrix;
    cairo_pattern_get_matrix(pattern, &matrix);
    
    // the cairo pattern matrix is from user space to pattern space, so this is the correct order of operations
    double mscaleX = srcW / dstW;
    double mscaleY = srcH / dstH;
    cairo_matrix_scale(&matrix, mscaleX, mscaleY);

    cairo_matrix_translate(&matrix, srcX, srcY);
        
    cairo_matrix_translate(&matrix, -dstX, -dstY);  

    cairo_pattern_set_matrix(pattern, &matrix);
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);
    
    cairo_new_path(cr);
    cairo_rectangle(cr, dstX, dstY, dstW, dstH);
    cairo_clip(cr);
    
    cairo_set_source(cr, pattern);

    cairo_pattern_set_filter(pattern, CAIRO_FILTER_BILINEAR);

    if (_globalAlpha >= 1.0) {
        cairo_paint(cr);
    } else {
        cairo_paint_with_alpha(cr, _globalAlpha);
    }
    
    cairo_restore(cr);
    EXITCR
    
    cairo_pattern_destroy(pattern);
    
    [self _didPaint];
    return nil;
}

- (NSSize)_measureTextWithCurrentFont:(NSString *)text
{
    NSDictionary *textAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                            (_font) ? _font : [NSFont systemFontOfSize:10], NSFontAttributeName,
                                            nil];
    NSSize textSize = (text) ? [text sizeWithAttributes:textAttrs] : NSZeroSize;
    return textSize;
}

- (id)lqjsCallMeasureText:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) {
        return nil;
    }
    NSString *text = [args objectAtIndex:0];
    if ( ![text isKindOfClass:[NSString class]]) {
        LOGFUNC(@"measureText", @"invalid text object: %@", [text class]);
        return nil;
    }
    
    NSSize textSize = [self _measureTextWithCurrentFont:text];
    
    // this class is supposed to return a special TextMetrics object according to the HTML 5 spec, but a regular Object ought to do just as well.
    //
    // only the 'width' property is specified in HTML 5, the rest are provided because they're useful.
    id newObj = [self emptyProtectedJSObject];
    [newObj setProtected:NO];
    [newObj setValue:[NSNumber numberWithDouble:textSize.width] forKey:@"width"];
    [newObj setValue:[NSNumber numberWithDouble:textSize.height] forKey:@"height"];
    
#if !defined(__LAGOON__)
    double xHeight = [_font xHeight];
    [newObj setValue:[NSNumber numberWithDouble:xHeight] forKey:@"xHeight"];
    [newObj setValue:[NSNumber numberWithDouble:[_font ascender]] forKey:@"ascender"];
    [newObj setValue:[NSNumber numberWithDouble:[_font descender]] forKey:@"descender"];
    [newObj setValue:[NSNumber numberWithDouble:[_font capHeight]] forKey:@"capHeight"];
    [newObj setValue:[NSNumber numberWithDouble:[_font leading]] forKey:@"leading"];
#endif

    ///NSLog(@"%s: retobj is %@; size is %.3f * %.3f; font xheight is %.3f", __func__, newObj, textSize.width, textSize.height, xHeight);
    return newObj;
}

- (void)_getTextOffsetX:(double *)outX offsetY:(double *)outY withTextSize:(NSSize)textSize
{
    double textOffX = 0.0;
    double textOffY = 0.0;

    switch (_textAlign) {
        case kLQTextAlign_Start:
        case kLQTextAlign_Left:
        default: 
            break;
        case kLQTextAlign_End:
        case kLQTextAlign_Right:
            textOffX -= ceil(textSize.width);
            break;
        case kLQTextAlign_Center:
            textOffX -= round(textSize.width * 0.5);
            break;
    }
    switch (_textBaseline) {
        default:
        case kLQTextBaseline_Alphabetic:
            break;
            
        case kLQTextBaseline_Bottom: {
            // HTML 5 spec says this should align to the bottom of the "em square".
            // using the font descender value seems to work well enough for this; not sure if this is really the proper thing to do.
            // (the descender is a negative number, hence we offset by it.)
#if !defined(__LAGOON__)
            textOffY += [_font descender];
#endif
            break;
        }
        case kLQTextBaseline_Top: {
#if !defined(__LAGOON__)
            textOffY += [_font ascender];
#endif
            break;
        }
        case kLQTextBaseline_Middle: {
#if !defined(__LAGOON__)
            textOffY += [_font xHeight] * 0.5;
#endif
            break;
        }
    }
    *outX = textOffX;
    *outY = textOffY;
}

static void renderShadowBlur_inPlace(uint8_t * restrict data, LXInteger w, LXInteger h, size_t rowBytes, LXInteger blurW)
{
    const LXInteger blurD = blurW / 2;
    
    const LXInteger numPasses = 2;

    uint8_t row[w*4];
    uint8_t col[h*4];

    for (LXInteger pass = 0; pass < numPasses; pass++) {
        // horizontal blur pass     
        for (LXInteger y = 0; y < h; y++) {
            uint8_t *dstRow = data + y*rowBytes;
            memcpy(row, dstRow, w*4);
            
            LXInteger minX = blurD;
            LXInteger maxX = w - blurD;
            for (LXInteger x = minX; x < maxX; x++) {
                uint8_t * restrict dst = dstRow + x*4;
                uint8_t * restrict src = row + (x - blurD)*4;
                
                LXInteger acc_r = 0;
                LXInteger acc_g = 0;
                LXInteger acc_b = 0;
                LXInteger acc_a = 0;
                for (LXInteger k = 0; k < blurW; k++) {
                    LXInteger b = src[0];
                    LXInteger g = src[1];
                    LXInteger r = src[2];
                    LXInteger a = src[3];
                    src += 4;
                    acc_r += r;
                    acc_g += g;
                    acc_b += b;
                    acc_a += a;
                }
                dst[0] = MIN(255, acc_b / blurW);
                dst[1] = MIN(255, acc_g / blurW);
                dst[2] = MIN(255, acc_r / blurW);
                dst[3] = MIN(255, acc_a / blurW);
            }
        }

        // vertical blur pass
        for (LXInteger x = 0; x < w; x++) {
            uint8_t *dstCol = data + x*4;
            for (LXInteger y = 0; y < h; y++) {
                col[y*4 + 0] = dstCol[y*rowBytes + 0];
                col[y*4 + 1] = dstCol[y*rowBytes + 1];
                col[y*4 + 2] = dstCol[y*rowBytes + 2];
                col[y*4 + 3] = dstCol[y*rowBytes + 3];
            }
            
            LXInteger minY = blurD;
            LXInteger maxY = h - blurD;
            for (LXInteger y = minY; y < maxY; y++) {
                uint8_t * restrict dst = dstCol + y*rowBytes;
                uint8_t * restrict src = col + (y - blurD)*4;
                
                LXInteger acc_r = 0;
                LXInteger acc_g = 0;
                LXInteger acc_b = 0;
                LXInteger acc_a = 0;
                for (LXInteger k = 0; k < blurW; k++) {
                    LXInteger b = src[0];
                    LXInteger g = src[1];
                    LXInteger r = src[2];
                    LXInteger a = src[3];
                    src += 4;
                    acc_r += r;
                    acc_g += g;
                    acc_b += b;
                    acc_a += a;
                }
                dst[0] = MIN(255, acc_b / blurW);
                dst[1] = MIN(255, acc_g / blurW);
                dst[2] = MIN(255, acc_r / blurW);
                dst[3] = MIN(255, acc_a / blurW);
            }
        }
    }
}

- (id)lqjsCallFillText:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    if ([args count] < 3) {
        LOGFUNC(@"fillText", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    NSString *text = [args objectAtIndex:0];
    if ( ![text isKindOfClass:[NSString class]]) {
        LOGFUNC(@"fillText", @"invalid text object: %@", [text class]);
        return nil;
    }
    
    double x = [[args objectAtIndex:1] doubleValue];
    double y = [[args objectAtIndex:2] doubleValue];
    if ( !isfinite(x) || !isfinite(y)) return nil;
    
    double maxW = 0.0;
    if ([args count] >= 4) {
        maxW = [[args objectAtIndex:3] doubleValue];
        if ( !isfinite(maxW)) maxW = 0.0;
    }
    
    NSSize textSize = [self _measureTextWithCurrentFont:text];
    double scaleBy = 1.0;
    
    /* HTML 5 spec says:
       "If the maxWidth argument was specified and the hypothetical width of the inline box in the hypothetical line box is greater than
       maxWidth CSS pixels, then change font to have a more condensed font (if one is available or if a reasonably readable one can be
       synthesized by applying a horizontal scale factor to the font) or a smaller font, and return to the previous step." */
    if (maxW > 0.0 && textSize.width > maxW) {
        scaleBy = maxW / textSize.width;
    }
    
    double textOffX = 0.0;
    double textOffY = 0.0;
    [self _getTextOffsetX:&textOffX offsetY:&textOffY withTextSize:textSize];
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);

    NSFont *nsFont = (_font) ? _font : [NSFont systemFontOfSize:10];
    const char *textUTF8 = [text UTF8String];
    
    // is there a shadow? (per html5 spec, only source-over comp mode should produce shadows)
    if (_shadowColor && _globalCompOpCairo == CAIRO_OPERATOR_OVER) {
        LXRGBA shadowColor = [_shadowColor rgba_sRGB];
        
        cairo_save(cr);
#if 1
        double fontLineH = ceil([nsFont leading] - [nsFont descender] + [nsFont pointSize]);
        double blurW = round(_shadowBlur) * 2 - 1;
        double yMargin = ceil(_shadowBlur) + 2;
        double blurOffX = round(_shadowOffset.x);
        double blurOffY = round(_shadowOffset.y);
        
        //NSLog(@"drawing text '%@', font h %.1f, blurw %.1f, off %.1f, %.1f", text, fontLineH, blurW, blurOffX, blurOffY);
        
        NSSize shadowSize = textSize;
        shadowSize.height = fontLineH;
        shadowSize.width += blurW*2.0 + 8;
        shadowSize.height += blurW*2.0 + yMargin*2;

        cairo_surface_t *shadowSurf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, shadowSize.width, shadowSize.height);
        cairo_t *tempctx = cairo_create(shadowSurf);
        
         // testing: draw background and border line
        /*cairo_rectangle(tempctx, 0, 0, shadowSize.width, shadowSize.height);
        cairo_set_source_rgba(tempctx, 1, 0.9, 0, 1);
        cairo_fill(tempctx);
        cairo_rectangle(tempctx, 1, 1, shadowSize.width-2, shadowSize.height-2);
        cairo_set_source_rgba(tempctx, 0.9, 0, 0, 1);
        cairo_stroke(tempctx);
         */
        
        cairo_scaled_font_t *tempfont = [nsFont createCairoScaledFontWithContext:tempctx textOffsetX:0 offsetY:0];
        cairo_set_scaled_font(tempctx, tempfont);
        cairo_move_to(tempctx, blurW,
                               shadowSize.height - blurW - yMargin - [nsFont leading] + [nsFont descender]);
        
        cairo_set_source_rgba(tempctx, shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a);
        
        if (scaleBy != 1.0) cairo_scale(cr, scaleBy, scaleBy);
        cairo_show_text(tempctx, textUTF8);
        
        cairo_scaled_font_destroy(tempfont);
        
        renderShadowBlur_inPlace(cairo_image_surface_get_data(shadowSurf), shadowSize.width, shadowSize.height, cairo_image_surface_get_stride(shadowSurf), blurW);
        cairo_surface_mark_dirty(shadowSurf);
                                 
        double dstX = x + textOffX - blurW + blurOffX;
        double dstY = y + textOffY - [nsFont pointSize] - blurW + blurOffY - yMargin;
        
        cairo_set_source_surface(cr, shadowSurf, dstX, dstY);
        cairo_rectangle(cr, dstX, dstY, shadowSize.width, shadowSize.height);
        cairo_fill(cr);
        
        cairo_destroy(tempctx);        
        cairo_surface_destroy(shadowSurf);
        
#else
        cairo_scaled_font_t *cairoScaledFont = [nsFont createCairoScaledFontWithContext:cr textOffsetX:textOffX offsetY:textOffY];    
        cairo_set_scaled_font(cr, cairoScaledFont);
        cairo_set_source_rgba(cr, shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a*0.25);
        
        cairo_move_to(cr, x-1.5, y);
        cairo_show_text(cr, textUTF8);
        cairo_move_to(cr, x+1.5, y);
        cairo_show_text(cr, textUTF8);
        cairo_move_to(cr, x, y+1.5);
        cairo_show_text(cr, textUTF8);
        cairo_move_to(cr, x, y-1.5);
        cairo_show_text(cr, textUTF8);
        
        cairo_scaled_font_destroy(cairoScaledFont);
#endif
        cairo_restore(cr);
    }

    cairo_scaled_font_t *cairoScaledFont = [nsFont createCairoScaledFontWithContext:cr textOffsetX:textOffX offsetY:textOffY];    
    cairo_set_scaled_font(cr, cairoScaledFont);
    [self _applyFillStyle:cr];

    cairo_move_to(cr, x, y);
    
    if (scaleBy != 1.0) cairo_scale(cr, scaleBy, scaleBy);
    cairo_show_text(cr, textUTF8);
    
    cairo_scaled_font_destroy(cairoScaledFont);

    cairo_restore(cr);    
    EXITCR

    [self _didPaint];
    return nil;
}

- (id)lqjsCallStrokeText:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 3) {
        LOGFUNC(@"strokeText", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    NSString *text = [args objectAtIndex:0];
    if ( ![text isKindOfClass:[NSString class]]) {
        LOGFUNC(@"strokeText", @"invalid text object: %@", [text class]);
        return nil;
    }
    
    double x = [[args objectAtIndex:1] doubleValue];
    double y = [[args objectAtIndex:2] doubleValue];
    if ( !isfinite(x) || !isfinite(y)) return nil;
    
    double maxW = 0.0;
    if ([args count] >= 4) {
        maxW = [[args objectAtIndex:3] doubleValue];
        if ( !isfinite(maxW)) return nil;
        // TODO: use maxWidth
    }
    
    NSSize textSize = [self _measureTextWithCurrentFont:text];
    double textOffX = 0.0;
    double textOffY = 0.0;
    [self _getTextOffsetX:&textOffX offsetY:&textOffY withTextSize:textSize];
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);

    // text_path doesn't seem to respect the translation specified in the scaled font matrix, so I guess we have no choice but to apply it here.
    // using the font matrix just feels cleaner.
    cairo_move_to(cr, x + textOffX, y + textOffY);
    
    NSFont *nsFont = (_font) ? _font : [NSFont systemFontOfSize:10];
    cairo_scaled_font_t *cairoScaledFont = [nsFont createCairoScaledFontWithContext:cr textOffsetX:0.0 offsetY:0.0];
    
    cairo_set_scaled_font(cr, cairoScaledFont);
    [self _applyStrokeStyle:cr];
    
    cairo_text_path(cr, [text UTF8String]);
    cairo_stroke(cr);

    cairo_restore(cr);
    cairo_scaled_font_destroy(cairoScaledFont);
    
    EXITCR

    [self _didPaint];
    return nil;
}

- (id)lqjsCallFillRect:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    //NSLog(@"%s: args %@", __func__, args);
    
    if ([args count] < 4) {
        LOGFUNC(@"fillRect", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double w = [[args objectAtIndex:2] doubleValue];
    double h = [[args objectAtIndex:3] doubleValue];
    
    if ( !isfinite(x) || !isfinite(y) || !isfinite(w) || !isfinite(h))  return nil;
    if (w <= 0.0 || h <= 0.0)  return nil;
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);
    
    cairo_new_path(cr);
    cairo_rectangle(cr, x, y, w, h);

    [self _applyFillStyle:cr];
    cairo_fill(cr);
    
    cairo_restore(cr);
    EXITCR
    
    [self _didPaint];
    return nil;
}

- (id)lqjsCallStrokeRect:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    if ([args count] < 4) {
        NSLog(@"** %s: invalid args (count %lu: %@)", __func__, (long)[args count], args);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double w = [[args objectAtIndex:2] doubleValue];
    double h = [[args objectAtIndex:3] doubleValue];

    if ( !isfinite(x) || !isfinite(y) || !isfinite(w) || !isfinite(h))  return nil;
    if (w <= 0.0 || h <= 0.0)  return nil;
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);
    
    cairo_new_path(cr);
    cairo_rectangle(cr, x, y, w, h);

    ///[self _applyStrokeStyle:cr];
    cairo_stroke(cr);
    
    cairo_restore(cr);
    EXITCR
    
    [self _didPaint];
    return nil;
}

- (id)lqjsCallClearRect:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 4) {
        LOGFUNC(@"clearRect", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double w = [[args objectAtIndex:2] doubleValue];
    double h = [[args objectAtIndex:3] doubleValue];

    if ( !isfinite(x) || !isfinite(y) || !isfinite(w) || !isfinite(h))  return nil;
    if (w <= 0.0 || h <= 0.0)  return nil;
    
    [self _willPaint];
    
    ENTERCR
    cairo_save(cr);
    
    cairo_new_path(cr);
    cairo_rectangle(cr, x, y, w, h);

    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_fill(cr);
    
    cairo_restore(cr);
    EXITCR
    
    [self _didPaint];
    return nil;
}

- (id)lqjsCallBeginPath:(NSArray *)args context:(id)contextObj
{
    ENTERCR
    cairo_new_path(cr);
    EXITCR
    return nil;
}

- (id)lqjsCallClosePath:(NSArray *)args context:(id)contextObj
{
    ENTERCR
    cairo_close_path(cr);
    EXITCR
    return nil;
}

- (id)lqjsCallMoveTo:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        LOGFUNC(@"moveTo", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];

    if ( !isfinite(x) || !isfinite(y)) return nil;

    ENTERCR
    cairo_move_to(cr, x, y);
    EXITCR
    return nil;
}

- (id)lqjsCallLineTo:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 2) {
        LOGFUNC(@"lineTo", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];

    if ( !isfinite(x) || !isfinite(y)) return nil;

    ENTERCR
    cairo_line_to(cr, x, y);
    EXITCR
    return nil;
}

- (id)lqjsCallBezierCurveTo:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 6) {
        LOGFUNC(@"bezierCurveTo", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double cp1x = [[args objectAtIndex:0] doubleValue];
    double cp1y = [[args objectAtIndex:1] doubleValue];
    double cp2x = [[args objectAtIndex:2] doubleValue];
    double cp2y = [[args objectAtIndex:3] doubleValue];
    double endx = [[args objectAtIndex:4] doubleValue];
    double endy = [[args objectAtIndex:5] doubleValue];

    if ( !isfinite(cp1x) || !isfinite(cp1y) ||
         !isfinite(cp2x) || !isfinite(cp2y) ||
         !isfinite(endx) || !isfinite(endy)
         ) return nil;

    ENTERCR
    cairo_curve_to(cr, cp1x, cp1y,  cp2x, cp2y,  endx, endy);
    EXITCR
    return nil;
}

- (id)lqjsCallArcTo:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 5) {
        LOGFUNC(@"arcTo", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x1 = [[args objectAtIndex:0] doubleValue];
    double y1 = [[args objectAtIndex:1] doubleValue];
    double x2 = [[args objectAtIndex:2] doubleValue];
    double y2 = [[args objectAtIndex:3] doubleValue];
    double radius = [[args objectAtIndex:4] doubleValue];

    if ( !isfinite(x1) || !isfinite(y1) ||
         !isfinite(x2) || !isfinite(y2) ||
         !isfinite(radius)
         ) return nil;

    ENTERCR
    
    if (cairo_has_current_point(cr)) {
        double x0 = 0, y0 = 0;
        cairo_get_current_point(cr, &x0, &y0);
        
        // FIXME: arcTo is not correctly implemented; it doesn't take the midpoint into account at all
        
        double xc = (x2 - x0);
        double yc = (y2 - y0);
        double radius = 0.5 * MAX(fabs(x2 - x0), fabs(y2 - y0));
        
        double angle1 = atan2((y0 - yc), (x0 - xc));
        double angle2 = atan2((y2 - yc), (x2 - xc));
        
        cairo_arc(cr, xc, yc, radius, angle1, angle2);
    }
    EXITCR
    return nil;
}

- (id)lqjsCallRect:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 4) {
        LOGFUNC(@"rect", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double w = [[args objectAtIndex:2] doubleValue];
    double h = [[args objectAtIndex:3] doubleValue];

    if ( !isfinite(x) || !isfinite(y) || !isfinite(w) || !isfinite(h))  return nil;
    if (w <= 0.0 || h <= 0.0)  return nil;
    
    ENTERCR
    cairo_rectangle(cr, x, y, w, h);
    EXITCR
    return nil;
}

- (id)lqjsCallArc:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 6) {
        LOGFUNC(@"arc", @"invalid args: %ld", (long)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double radius = [[args objectAtIndex:2] doubleValue];
    double startAngle = [[args objectAtIndex:3] doubleValue];
    double endAngle = [[args objectAtIndex:4] doubleValue];
    BOOL antiCW = [[args objectAtIndex:5] boolValue];
    
    //NSLog(@"%s: %.3f, %.3f,  radius %.3f,  angles %.3f, %.3f,  anticw %i", __func__, x, y, radius, startAngle, endAngle, antiCW);
    
    // 2010.12.26 -- when rendering an arc with angles (0, 2*PI) and antiCW == true,
    // Cairo renders an empty arc. in web browsers, the Canvas API renders a full circle for this case.
    // I don't know what else to do except special-case it.
    
    if (antiCW && fabs((endAngle - startAngle) - 2.0*M_PI) < 0.00001) {
        antiCW = NO;
    }

    ENTERCR
    if ( !antiCW) {
        cairo_arc(cr, x, y, radius, startAngle, endAngle);
    } else {
        cairo_arc_negative(cr, x, y, radius, startAngle, endAngle);
    }
    EXITCR
    return nil;
}

- (id)lqjsCallFill:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    [self _willPaint];
    ENTERCR
    cairo_save(cr);
    
    [self _applyFillStyle:cr];
    
    if (_globalAlpha >= 1.0) {
        cairo_fill_preserve(cr);
    } else {
        cairo_clip_preserve(cr);
        cairo_paint_with_alpha(cr, _globalAlpha);
    }
    
    cairo_restore(cr);
    EXITCR
    [self _didPaint];
    return nil;
}

- (id)lqjsCallStroke:(NSArray *)args context:(id)contextObj
{
    if (_globalAlpha <= 0.0001) return nil;  // -- nothing to draw
    
    [self _willPaint];
    ENTERCR
    cairo_save(cr);
    
    [self _applyStrokeStyle:cr];
    
    cairo_set_line_width(cr, _lineWidth);
    
    /*cairo_set_source_rgba(cr, 1, 0, 0, 1);
    cairo_pattern_t *pat = cairo_get_source(cr);
    double r, g, b, a;
    if (CAIRO_STATUS_SUCCESS == cairo_pattern_get_rgba(pat, &r, &g, &b, &a)) {
        printf("... js stroke(): color is %.3f, %.3f, %.3f, %.3f\n", r, g, b, a);
    } else
        printf("... js stroke(): using pattern (%p)\n", pat);
    */
    cairo_stroke_preserve(cr);
    
    cairo_restore(cr);
    EXITCR
    [self _didPaint];
    return nil;
}

- (id)lqjsCallClip:(NSArray *)args context:(id)contextObj
{
    ENTERCR
    cairo_clip_preserve(cr);
    EXITCR
    return nil;
}

- (id)lqjsCallGetImageData:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 4) {
        LOGFUNC(@"getImageData", @"invalid args: %i", (int)[args count]);
        return nil;
    }
    
    double x = [[args objectAtIndex:0] doubleValue];
    double y = [[args objectAtIndex:1] doubleValue];
    double w = [[args objectAtIndex:2] doubleValue];
    double h = [[args objectAtIndex:3] doubleValue];
    
    if ( !isfinite(x) || !isfinite(y) || !isfinite(w) || !isfinite(h))  return nil;
    if (w <= 0.0 || h <= 0.0)  return nil;
    
    LQCairoBitmap *bitmap = [_canvas cairoBitmap];
    LXPixelBufferRef pixbuf = [bitmap lxPixelBuffer];
    if ( !pixbuf) {
        NSLog(@"** %s: no source pixbuf (bitmap is %@, canvas %@)", __func__, bitmap, _canvas);
        return nil;
    }

    NSMutableData *pixelData = [NSMutableData dataWithLength:w*h*4];
    
    LXDECLERROR(lxErr)
    if ( !LXPixelBufferGetRegionWithPixelFormatConversion(pixbuf, LXMakeRect(x, y, w, h),
                                                                [pixelData mutableBytes], w*4,
                                                                kLX_RGBA_INT8, NULL, &lxErr)) {
        NSLog(@"** %s: conversion failed with error %i / %s", __func__, lxErr.errorID, lxErr.description);
        LXErrorDestroyOnStack(lxErr);
        return nil;
    }
    
    id imageData = [self emptyProtectedJSObject];
    [imageData setProtected:NO];
    [imageData setValue:[NSNumber numberWithDouble:w] forKey:@"width"];
    [imageData setValue:[NSNumber numberWithDouble:h] forKey:@"height"];
    
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    JSContextRef jsCtx = [interp jsContextRef];
    id pixelArray = [[[LQJSBridge_2DCanvasPixelArray alloc] initWithData:pixelData inJSContext:jsCtx withOwner:nil] autorelease];
    
    [imageData setValue:pixelArray forKey:@"data"];
    
    return imageData;
}

- (id)lqjsCallPutImageData:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 3) {
        LOGFUNC(@"putImageData", @"invalid args: %i", (int)[args count]);
        return nil;
    }
    
    id imageData = [args objectAtIndex:0];
    id pixelArray = [imageData valueForKey:@"data"];
    double w = [[imageData valueForKey:@"width"] doubleValue];
    double h = [[imageData valueForKey:@"height"] doubleValue];
    double x = [[args objectAtIndex:1] doubleValue];
    double y = [[args objectAtIndex:2] doubleValue];

    if ( !isfinite(x) || !isfinite(y))  return nil;
    if (w <= 0.0 || h <= 0.0 || !isfinite(w) || !isfinite(h))  return nil;
    if ( !imageData) return nil;
    if ( ![pixelArray respondsToSelector:@selector(data)])  return nil;
    
    NSData *pixelData = [pixelArray data];
    if ([pixelData length] < w*h*4) {
        NSLog(@"** %s: pixelData size is invalid (%i, expected %i*%i*4)", __func__, (int)[pixelData length], (int)w, (int)h);
        return nil;
    }

    LQCairoBitmap *bitmap = [_canvas cairoBitmap];
    LXPixelBufferRef pixbuf = [bitmap lxPixelBuffer];
    if ( !pixbuf) {
        NSLog(@"** %s: no dst pixbuf (bitmap is %@, canvas %@)", __func__, bitmap, _canvas);
        return nil;
    }
    
    [self _willPaint];
    
    LXDECLERROR(lxErr)
    if ( !LXPixelBufferWriteRegionWithPixelFormatConversion(pixbuf, LXMakeRect(x, y, w, h),
                                                                [pixelData bytes], w*4,
                                                                kLX_RGBA_INT8, NULL, &lxErr)) {
        NSLog(@"** %s: conversion failed with error %i / %s", __func__, lxErr.errorID, lxErr.description);
        LXErrorDestroyOnStack(lxErr);
    }
    
    [self _didPaint];
    
    return nil;
}

@end
