//
//  LQNSColorAdditions.h
//  PixelMath
//
//  Created by Pauli Ojala on 19.11.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQLXBasicFunctions.h"
#import <Lacefx/LXBasicTypes.h>


@interface NSColor (LQNSColorAdditions)

// --- RGBA strings and LXRGBA conversions ---
- (NSString *)rgbaString;
+ (NSColor *)colorWithRGBAString:(NSString *)str;

- (BOOL)getRGBAValuesIntoArray:(CGFloat *)arr;

+ (NSColor *)colorWithRGBA:(LXRGBA)rgba;
- (LXRGBA)rgba;

+ (NSColor *)colorWithRGBA_sRGB:(LXRGBA)rgba;
- (LXRGBA)rgba_sRGB;

// --- HTML/CSS style ---
// supports rgba(), rgb(), #fffff formats
+ (NSColor *)colorWithHTMLFormattedString:(NSString *)str;
- (NSString *)htmlFormattedString;

+ (NSColor *)colorWithHTMLFormattedSRGBString:(NSString *)str;  // converts sRGB values to Apple calibrated colorspace as needed
- (NSString *)htmlFormattedSRGBString;

@end
