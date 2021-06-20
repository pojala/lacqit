//
//  LQGradient.h
//
//  "CTGradient" created by Chad Weider on 2/14/07.
//  Written by Chad Weider.
//
//  Released into public domain on 4/10/08.
//  
//  Original CTGradient version: 1.8

//  Renamed to LQGradient by Pauli Ojala to avoid name collision;
//  also cleaned up to fit Lacqit code style and added Cairo support.

#import "LQUIFrameworkHeader.h"
#import "LQCairoBitmap.h"


typedef struct LQGradientElement *LQGradientElementPtr;

enum {
	kLQLinearBlendingMode,
	kLQChromaticBlendingMode,
	kLQInverseChromaticBlendingMode
};
typedef LXUInteger LQGradientBlendingMode;

enum {
    kLQLinearGradient = 0,
    kLQRadialGradient
};
typedef LXUInteger LQGradientType;



@interface LQGradient : NSObject <NSCopying, NSCoding> {

	LQGradientElementPtr _elementList;
    
	LQGradientBlendingMode _blendingMode;
    LQGradientType _gradientType;

#if (LQPLATFORM_QUARTZ)
	CGFunctionRef _gradientFunction;
#endif
}

+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;

+ (id)aquaSelectedGradient;
+ (id)aquaNormalGradient;
+ (id)aquaPressedGradient;

+ (id)unifiedSelectedGradient;
+ (id)unifiedNormalGradient;
+ (id)unifiedPressedGradient;
+ (id)unifiedDarkGradient;

+ (id)sourceListSelectedGradient;
+ (id)sourceListUnselectedGradient;

+ (id)rainbowGradient;
+ (id)hydrogenSpectrumGradient;

- (LQGradient *)gradientWithAlphaComponent:(CGFloat)alpha;

- (LQGradient *)gradientByAddingColorStop:(NSColor *)color atPosition:(CGFloat)position;	//positions given relative to [0,1]
- (LQGradient *)gradientByRemovingColorStopAtIndex:(LXUInteger)index;
- (LQGradient *)gradientByRemovingColorStopAtPosition:(CGFloat)position;

- (LQGradientBlendingMode)blendingMode;
- (LQGradientType)gradientType;
- (void)setGradientType:(LQGradientType)type;

- (LXUInteger)numberOfColorStops;
- (NSColor *)colorStopAtIndex:(LXUInteger)index;
- (CGFloat)positionOfColorStopAtIndex:(LXUInteger)index;
- (NSColor *)colorAtPosition:(CGFloat)position;

// Cairo support
- (cairo_pattern_t *)createLinearCairoPatternFromPoint:(NSPoint)p1 toPoint:(NSPoint)p2;
- (cairo_pattern_t *)createRadialCairoPatternFromPoint:(NSPoint)p1 toPoint:(NSPoint)p2 radius1:(double)radi1 radius2:(double)radi2;

// Quartz drawing
#if (LQPLATFORM_QUARTZ)
- (void)drawSwatchInRect:(NSRect)rect;
- (void)fillRect:(NSRect)rect angle:(CGFloat)angle;					//fills rect with axial gradient
																	//	angle in degrees
- (void)radialFillRect:(NSRect)rect;								//fills rect with radial gradient
																	//  gradient from center outwards
- (void)fillBezierPath:(NSBezierPath *)path angle:(CGFloat)angle;
- (void)radialFillBezierPath:(NSBezierPath *)path;
#endif

@end
