//
//  LQNSColorAdditions.m
//  PixelMath
//
//  Created by Pauli Ojala on 19.11.2007.
//  Copyright 2007 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSColorAdditions.h"
#import "LQLXBasicFunctions.h"


@implementation NSColor (LQNSColorAdditions)

static inline CGFloat convertComponent_sRGB_to_Linear(CGFloat v)
{
    if (v <= 0.0405) {
        v /= 12.92;
    } else {
        const CGFloat a = 0.055;
        v = pow((v+a) / (1+a), 2.4);
    }
    return v;
}

static inline CGFloat convertComponent_Linear_to_sRGB(CGFloat v)
{
    if (v <= 0.0031308) {
        v *= 12.92;
    } else {
        const CGFloat a = 0.055;        
        v = (1+a) * pow(v, 1.0/2.4) - a;
    }
    return v;
}

static void convertColor_sRGB_to_AppleMacRGB(CGFloat *pr, CGFloat *pg, CGFloat *pb, CGFloat *pa, BOOL isPremult)
{
    CGFloat r = *pr;
    CGFloat g = *pg;
    CGFloat b = *pb;
    CGFloat a = *pa;

    // unpremultiply colors
    if (isPremult) {
        if (a <= 0.0) return;
        r /= a;
        g /= a;
        b /= a;
    }

    // convert to linear from gamma 2.2
    r = convertComponent_sRGB_to_Linear(r);
    g = convertComponent_sRGB_to_Linear(g);
    b = convertComponent_sRGB_to_Linear(b);
    
    // convert to gamma 1.8 from linear
    r = pow(r, 1.0/1.8);
    g = pow(g, 1.0/1.8);
    b = pow(b, 1.0/1.8);
    
    // premultiply
    if (isPremult) {
        r *= a;
        g *= a;
        b *= a;
    }
    *pr = r;
    *pg = g;
    *pb = b;
}

static void convertColor_AppleMacRGB_to_sRGB(CGFloat *pr, CGFloat *pg, CGFloat *pb, CGFloat *pa, BOOL isPremult)
{
    CGFloat r = *pr;
    CGFloat g = *pg;
    CGFloat b = *pb;
    CGFloat a = *pa;

    // unpremultiply colors
    if (isPremult) {
        if (a <= 0.0) return;
        r /= a;
        g /= a;
        b /= a;
    }

    // convert to linear from gamma 1.8
    r = pow(r, 1.8);
    g = pow(g, 1.8);
    b = pow(b, 1.8);
    
    // convert to sRGB from linear
    r = convertComponent_Linear_to_sRGB(r);
    g = convertComponent_Linear_to_sRGB(g);
    b = convertComponent_Linear_to_sRGB(b);
    
    // premultiply
    if (isPremult) {
        r *= a;
        g *= a;
        b *= a;
    }
    *pr = r;
    *pg = g;
    *pb = b;
}


- (NSString *)rgbaString
{
    CGFloat c[4];
    if ( ![self getRGBAValuesIntoArray:c])
        return @"";
    else
        return [NSString stringWithFormat:@"{ %.6f, %.6f, %.6f, %.6f }", c[0], c[1], c[2], c[3]];
}

+ (NSColor *)colorWithRGBAString:(NSString *)str
{
    if ( !str)
        return nil;
        
    return [NSColor colorWithRGBA:LXRGBAFromNSString(str)];
   /*     
    NSRange range;
	NSScanner *scanner = [NSScanner scannerWithString:str];
	NSString *s = nil;
	
    NSCharacterSet *numSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-"];
    NSCharacterSet *commaSet = [NSCharacterSet characterSetWithCharactersInString:@","];
    float c[4] = { 0.0f, 0.0f, 0.0f, 1.0f };
    int n = 0;
    
	while (n < 4 && ![scanner isAtEnd]) {
        [scanner scanUpToCharactersFromSet:numSet intoString:NULL];
        
        if ( ![scanner scanFloat:c+n])
            break;
        else
            n++;
	}
    
    return [NSColor colorWithDeviceRed:c[0] green:c[1] blue:c[2] alpha:c[3]];
    */
}


- (BOOL)getRGBAValuesIntoArray:(CGFloat *)c
{
    NSColor *color = self;
    NSString *colorSpaceName = self.colorSpaceName;
    if ([colorSpaceName isEqual:NSCalibratedRGBColorSpace] || [colorSpaceName isEqual:NSCalibratedWhiteColorSpace]) {
        color = self;
    } else {
        color = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    }
    LXInteger ccount;
    ccount = [color numberOfComponents];
    
    if (ccount > 4) {
        NSLog(@"** %s: unsupported colorspace (%@, %ld)", __func__, [self description], (long)ccount);
        return NO;
    }
    
    [color getComponents:c];
    
    if (ccount == 3) {
        c[3] = 1.0;
    }
    else if (ccount == 2) {
        c[3] = c[1];
        c[2] = c[1] = c[0];
    }
    else if (ccount == 1) {
        c[3] = 1.0;
        c[2] = c[1] = c[0];
    }
    return YES;
}

- (BOOL)getRGBAValuesIntoArray_sRGB:(CGFloat *)c
{
    NSColor *color = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
    LXInteger ccount = [color numberOfComponents];
    
    if (ccount > 4) {
        NSLog(@"** %s: unsupported colorspace (%@, %ld)", __func__, [self description], (long)ccount);
        return NO;
    }
    
    [color getComponents:c];
    
    if (ccount == 3) {
        c[3] = 1.0;
    }
    else if (ccount == 2) {
        c[3] = c[1];
        c[2] = c[1] = c[0];
    }
    else if (ccount == 1) {
        c[3] = 1.0;
        c[2] = c[1] = c[0];
    }
    return YES;
}


+ (NSColor *)colorWithRGBA:(LXRGBA)rgba
{
    //convertColor_sRGB_to_AppleMacRGB(&rgba.r, &rgba.g, &rgba.b, &rgba.a, NO);
    return [NSColor colorWithCalibratedRed:rgba.r green:rgba.g blue:rgba.b alpha:rgba.a];
}
    
- (LXRGBA)rgba
{
    CGFloat arr[4] = { 0, 0, 0, 0 };
    [self getRGBAValuesIntoArray:arr];
    return LXMakeRGBA(arr[0], arr[1], arr[2], arr[3]);
}

+ (NSColor *)colorWithRGBA_sRGB:(LXRGBA)rgba
{
#ifdef __APPLE__
    convertColor_sRGB_to_AppleMacRGB(&rgba.r, &rgba.g, &rgba.b, &rgba.a, NO);
#endif
    return [NSColor colorWithCalibratedRed:rgba.r green:rgba.g blue:rgba.b alpha:rgba.a];
}
    
- (LXRGBA)rgba_sRGB
{
    CGFloat arr[4] = { 0, 0, 0, 0 };
    [self getRGBAValuesIntoArray_sRGB:arr];

    return LXMakeRGBA(arr[0], arr[1], arr[2], arr[3]);
}


#pragma mark --- HTML style ---

static CGFloat parse8BitHexColorFromUnichar(unichar *buf)
{
    char cbuf[5] = "0x00";
    cbuf[2] = buf[0];
    cbuf[3] = buf[1];
    cbuf[4] = 0;
    return strtod(cbuf, NULL) / 255.0;
}

static CGFloat parse4BitHexColorFromUnichar(unichar ch)
{
    int n = -1;
    if (ch >= '0' && ch <= '9')
        n = ch - '0';
    else if (ch >= 'a' && ch <= 'f')
        n = 10 + (ch - 'a');
    
    if (n == -1)
        return 0.0;
    else
        return (CGFloat)(n + (n * 0x10)) / 255.0;
}


static BOOL getRGBAFromHTMLString(NSString *str, CGFloat * LXRESTRICT outR, CGFloat * LXRESTRICT outG, CGFloat * LXRESTRICT outB, CGFloat * LXRESTRICT outA)
{
    static NSCharacterSet *valueSepSet = nil;
    if ( !valueSepSet) {
        valueSepSet = [[NSCharacterSet characterSetWithCharactersInString:@",)"] retain];
    }
    
    if ( !str || [str length] < 1)
        return NO;
    
    if ([str isEqualToString:@"transparent"]) {
        *outR = *outG = *outB = *outA = 0.0;
        return YES;
    }

    CGFloat red, green, blue, alpha;
    red = green = blue = 0.0;
    alpha = 1.0;
    {
        int i;
        if ([str hasPrefix:@"rgba("] && [str length] >= 12) {
            NSScanner *scanner = [NSScanner scannerWithString:[str substringFromIndex:5]];
            for (i = 0; i < 4; i++) {
                NSString *s = nil;
                if ( ![scanner isAtEnd] && [scanner scanUpToCharactersFromSet:valueSepSet intoString:&s] && [s length] > 0) {
                    CGFloat v = [s doubleValue];
                    switch (i) {
                        case 0:  red = v / 255.0;  break;
                        case 1:  green = v / 255.0;  break;
                        case 2:  blue = v / 255.0;  break;
                        case 3:  alpha = v;  break;
                    }
                    [scanner scanCharactersFromSet:valueSepSet intoString:NULL];
                } else
                    break;
            }
        }

        else if ([str hasPrefix:@"rgb("] && [str length] >= 10) {
            NSScanner *scanner = [NSScanner scannerWithString:[str substringFromIndex:4]];
            for (i = 0; i < 3; i++) {
                NSString *s = nil;
                if ( ![scanner isAtEnd] && [scanner scanUpToCharactersFromSet:valueSepSet intoString:&s] && [s length] > 0) {
                    CGFloat v = [s doubleValue];
                    switch (i) {
                        case 0:  red = v / 255.0;  break;
                        case 1:  green = v / 255.0;  break;
                        case 2:  blue = v / 255.0;  break;
                    }
                    [scanner scanCharactersFromSet:valueSepSet intoString:NULL];
                } else
                    break;
            }
        }
        
        else if ([str hasPrefix:@"#"]) {
            str = [str lowercaseString];
            if ([str length] >= 7) {
                unichar buf[8];
                [str getCharacters:buf range:NSMakeRange(0, 7)];
            
                red   = parse8BitHexColorFromUnichar(buf+1);
                green = parse8BitHexColorFromUnichar(buf+3);
                blue  = parse8BitHexColorFromUnichar(buf+5);
                alpha = 1.0;
            } else if ([str length] == 4) {
                unichar buf[4];
                [str getCharacters:buf range:NSMakeRange(0, 4)];
                
                red   = parse4BitHexColorFromUnichar(buf[1]);
                green = parse4BitHexColorFromUnichar(buf[2]);
                blue  = parse4BitHexColorFromUnichar(buf[3]);
                alpha = 1.0;
            }
            ///NSLog(@"parsed html color %@ --> %.2f, %.2f, %.2f", str, red, green, blue);
        }
        
        else if ([str isEqual:@"black"]) {
            red = 0.0;  green = 0.0;  blue = 0.0;  alpha = 1.0;
        }
        else if ([str isEqual:@"white"]) {
            red = 1.0;  green = 1.0;  blue = 1.0;  alpha = 1.0;
        }
        else if ([str isEqual:@"red"]) {
            red = 1.0;  green = 0.0;  blue = 0.0;  alpha = 1.0;
        }
        else if ([str isEqual:@"green"]) {
            red = 0.0;  green = 1.0;  blue = 0.0;  alpha = 1.0;
        }
        else if ([str isEqual:@"blue"]) {
            red = 0.0;  green = 0.0;  blue = 1.0;  alpha = 1.0;
        }
        else if ([str isEqual:@"cyan"]) {
            red = 0.0;  green = 1.0;  blue = 1.0;  alpha = 1.0;
        }        
        else if ([str isEqual:@"magenta"]) {
            red = 1.0;  green = 0.0;  blue = 1.0;  alpha = 1.0;
        }        
        else if ([str isEqual:@"yellow"]) {
            red = 1.0;  green = 1.0;  blue = 0.0;  alpha = 1.0;
        }
    }
    *outR = red;
    *outG = green;
    *outB = blue;
    *outA = alpha;
    return YES;
}


+ (NSColor *)colorWithHTMLFormattedString:(NSString *)str
{
    CGFloat red, green, blue, alpha;
    if ( !getRGBAFromHTMLString(str, &red, &green, &blue, &alpha))
        return nil;
        
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

+ (NSColor *)colorWithHTMLFormattedSRGBString:(NSString *)str
{
    CGFloat red, green, blue, alpha;
    if ( !getRGBAFromHTMLString(str, &red, &green, &blue, &alpha))
        return nil;
    
#ifdef __APPLE__
    convertColor_sRGB_to_AppleMacRGB(&red, &green, &blue, &alpha, NO);
#endif
    
    return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}



#define CLAMP_Fto8(v_) ( (int)(255.0 * (MAX(0.0, MIN(1.0, v_)))) )

static inline NSString *htmlStringFromColors(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
    if (alpha == 1.0) {
        if (red == 0.0 && green == 0.0 && blue == 0.0)
            return @"black";
        else if (red == 1.0 && green == 1.0 && blue == 1.0)
            return @"white";
        else
            return [NSString stringWithFormat:@"#%02x%02x%02x", CLAMP_Fto8(red), CLAMP_Fto8(green), CLAMP_Fto8(blue)];
    } else if (alpha < 0.0001) {
        return @"transparent";
    } else {
        return [NSString stringWithFormat:@"rgba(%i, %i, %i, %.4f)", CLAMP_Fto8(red), CLAMP_Fto8(green), CLAMP_Fto8(blue), alpha];
    }
}

- (NSString *)htmlFormattedString
{
    BOOL chCount = 0;
    CGFloat alpha = 1.0;
    
    CGFloat red, green, blue;
    red = green = blue = 0.0;
    @try {
        NSColor *compColor = self;
        NSString *colorSpaceName = self.colorSpaceName;
        if ([colorSpaceName isEqual:NSCalibratedRGBColorSpace] || [colorSpaceName isEqual:NSCalibratedWhiteColorSpace]) {
            compColor = self;
        } else {
            compColor = [self colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
        }
        
        chCount = [compColor numberOfComponents];
        alpha = [compColor alphaComponent];
        if (chCount < 3) {
            red = green = blue = [compColor whiteComponent];
        }
        else {
            red = [compColor redComponent];
            green = [compColor greenComponent];
            blue = [compColor blueComponent];
        }
    }
    @catch (id exception) {
        ///return [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] htmlFormattedString];  // this doesn't seem to work for e.g. system colors
    }
    
    return htmlStringFromColors(red, green, blue, alpha);
}

- (NSString *)htmlFormattedSRGBString
{
    BOOL chCount = 0;
    CGFloat alpha = 1.0;
    
    CGFloat red, green, blue;
    red = green = blue = 0.0;
    @try {
        NSColor *compColor = [self colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];
        
        chCount = [compColor numberOfComponents];
        alpha = [compColor alphaComponent];
        if (chCount < 3) {
            red = green = blue = [compColor whiteComponent];
        }
        else {
            red = [compColor redComponent];
            green = [compColor greenComponent];
            blue = [compColor blueComponent];
        }
    }
    @catch (id exception) {
    }

    /*
#ifdef __APPLE__
    if ([[self colorSpaceName] isEqual:NSCalibratedRGBColorSpace]) {    // convert to sRGB
        convertColor_AppleMacRGB_to_sRGB(&red, &green, &blue, &alpha, NO);
    }
#endif
     */
    
    return htmlStringFromColors(red, green, blue, alpha);
}

@end
