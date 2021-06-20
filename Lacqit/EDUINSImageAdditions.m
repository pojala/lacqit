//
//  EDUINSImageAdditions.m
//  PixelMath
//
//  Created by Pauli Ojala on 27.11.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "EDUINSImageAdditions.h"
#import <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846264338327950288
#endif


//static NSBundle *gImageSearchBundle = nil;
//static NSString *gImageSearchPath = nil;
static NSMutableArray *g_searchBundles = nil;
static NSMutableArray *g_searchPaths = nil;


@implementation NSImage ( EDUINSImageAdditions )

+ (NSString *)eduiCategoryTestClassMeth
{
    return @"Hello from category (class method)";
}


+ (void)addBundleForImageSearch:(NSBundle *)bundle
{
    //[gImageSearchBundle autorelease];
    //gImageSearchBundle = [bundle retain];
    if ( !g_searchBundles)
        g_searchBundles = [[NSMutableArray alloc] init];
    
    if (bundle && ![g_searchBundles containsObject:bundle])
        [g_searchBundles addObject:bundle];
}

+ (void)addPathForImageSearch:(NSString *)path
{
    //[gImageSearchPath autorelease];
    //gImageSearchPath = [path retain];
    
    if ( !g_searchPaths)
        g_searchPaths = [[NSMutableArray alloc] init];
    
    if (path && [path length] > 0  && ![g_searchPaths containsObject:path])
        [g_searchPaths addObject:path];
}

+ (NSImage *)imageInBundleWithName:(NSString *)name
{
    static int s_warningCount = 0;
    #define MAXWARN 5

/*
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *bundlePath = [bundle resourcePath];
        
    NSString *fileName = [NSString stringWithFormat:
                                @"%@/%@", bundlePath, name];

    NSImage *image = [[NSImage alloc] initWithContentsOfFile:fileName];
    
    if (!image)
        NSLog(@"** NSImage(EDUIAdditions) -imageInBundleWithName: couldn't find image file %@", name);
    return image;
*/
	NSImage *im = nil;
	if ( !(im = [NSImage imageNamed:name]) || [im size].width < 1) {
        NSEnumerator *bundleEnum = [g_searchBundles objectEnumerator];
        id bundle;
        while (bundle = [bundleEnum nextObject]) {
            NSString *path = nil;
            if ([bundle respondsToSelector:@selector(pathForImageResource:)]) {
                path = [bundle pathForImageResource:name];
            }
            if ( !path) {
                path = [bundle pathForResource:name ofType:@"png"];
            }
            
            if (path) {
                im = [[NSImage alloc] initWithContentsOfFile:path];
            }
            if (im) {
                //NSLog(@"found image '%@' in bundle %@", name, bundle);
                break;
            }
        }
        
        if ( !im) {
            NSEnumerator *pathEnum = [g_searchPaths objectEnumerator];
            NSString *searchPath;
            while (searchPath = [pathEnum nextObject]) {
                NSString *imagePath = [searchPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", name]];
                
                im = [[NSImage alloc] initWithContentsOfFile:imagePath];
                if (im)
                    break;
            }
        }
        
        if (im) {
            [im setName:name];
        } else {
            if (s_warningCount < MAXWARN) {
                NSLog(@"** NSImage(EDUIAdditions): couldn't find image named '%@'%@", name, (s_warningCount == MAXWARN-1) ? @" (won't warn anymore)" : @"");
                NSLog(@"   search bundles: %@", g_searchBundles);
                NSLog(@"   search paths: %@", g_searchPaths);
                s_warningCount++;
            }
        }
/*    
        if ( !gImageSearchBundle) {
	        
#ifdef __WIN32__
	        NSString *bundlePath = gImageSearchPath;
	        if ([bundlePath length] > 0) {
		        NSString *imagePath = [NSString stringWithFormat:@"%@res\\%@.png", bundlePath, name];
		        //NSLog(@".... got imagepath: %@", imagePath);
		        im = [[NSImage alloc] initWithContentsOfFile:imagePath];
		        [im setName:name];
		        //NSLog(@"      image: %p", im);
		        return im;
	        }
	        else
#endif    
	        
            if (s_warningCount < MAXWARN) NSLog(@"** NSImage(EDUIAdditions) -imageInBundleWithName: bundle not set and image not found in main bundle ('%@')", name);
            s_warningCount++;
        }
        else {
            NSString *imPath;
#ifdef __APPLE__
            imPath = [gImageSearchBundle pathForImageResource:name];
#else
            imPath = [gImageSearchBundle pathForResource:name ofType:@"png"];
#endif

            if (!imPath) {
                if (s_warningCount < MAXWARN) NSLog(@"** NSImage(EDUIAdditions) -imageInBundleWithName: couldn't find image named '%@'", name);
                s_warningCount++;
            } else {
                im = [[NSImage alloc] initWithContentsOfFile:imPath];
                [im setName:name];
            }
        }
*/
	}
    #undef MAXWARN
    
	return im;
}


#if !defined(__LAGOON__)

#pragma mark --- rendering patterns ---


+ (NSImage *)checkerboardPatternImageWithColor1:(float *)col1 color2:(float *)col2 alpha:(float)alpha
{
	unsigned char r1, g1, b1, r2, g2, b2, a;
	float mul = 255.0f;
	r1 = col1[0] * mul;
	g1 = col1[1] * mul;
	b1 = col1[2] * mul;
	r2 = col2[0] * mul;
	g2 = col2[1] * mul;
	b2 = col2[2] * mul;
	a = alpha * mul;

		int w = 20;
		int h = 20;	
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
					 pixelsWide:w
					 pixelsHigh:h
					 bitsPerSample:8 samplesPerPixel:4
					 hasAlpha:YES isPlanar:NO
					 colorSpaceName:NSDeviceRGBColorSpace
					 bytesPerRow:w*4 bitsPerPixel:32];
		
		unsigned char *dstBuf = [rep bitmapData];
		int x, y;
		for (y = 0; y < h; y++) {
			unsigned char *dst = dstBuf + y*w*4;
			BOOL yon = (y >= h / 2);
            
			for (x = 0; x < w; x++) {
				BOOL xon = (x >= w / 2);
				unsigned char r, g, b;
				if ((yon || xon) && !(yon && xon)) {
					r = r1; g = g1; b = b1; }
				else {
					r = r2; g = g2; b = b2; }
					
				dst[x*4]   = r;
				dst[x*4+1] = g;
				dst[x*4+2] = b;
				dst[x*4+3] = a;
			}
		}
		
		NSImage *im = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
		[im addRepresentation:[rep autorelease]];

	return [im autorelease];
}


+ (NSImage *)diagonalStripesPatternImageWithColor1:(float *)col1 color2:(float *)col2 stripeSlant:(int)slant width:(int)stripeW
{
	unsigned char r1, g1, b1, a1, r2, g2, b2, a2;
	float mul = 255.0f;
	r1 = col1[0] * mul * col1[3];
	g1 = col1[1] * mul * col1[3];
	b1 = col1[2] * mul * col1[3];
    a1 = col1[3] * mul;
    
	r2 = col2[0] * mul * col2[3];
	g2 = col2[1] * mul * col2[3];
	b2 = col2[2] * mul * col2[3];
	a2 = col2[3] * mul;

		int w = 2 * stripeW;
		int h = w;	
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
					 pixelsWide:w
					 pixelsHigh:h
					 bitsPerSample:8 samplesPerPixel:4
					 hasAlpha:YES isPlanar:NO
					 colorSpaceName:NSDeviceRGBColorSpace
					 bytesPerRow:w*4 bitsPerPixel:32];
		
		unsigned char *dstBuf = [rep bitmapData];
		int x, y;
		for (y = 0; y < h; y++) {
			unsigned char *dst = dstBuf + y*w*4;
            int xoff = y;
            
			for (x = 0; x < w; x++) {
				unsigned char r, g, b, a;
                int sp = (slant == 0) ? x : w - x;
                
				if ( (sp >= xoff && sp < xoff+stripeW) ||
                     (sp+w >= xoff && sp+w < xoff+stripeW)
                        ) {
					r = r1; g = g1; b = b1; a = a1; }
				else {
					r = r2; g = g2; b = b2; a = a2; }
					
				dst[x*4]   = r;
				dst[x*4+1] = g;
				dst[x*4+2] = b;
				dst[x*4+3] = a;
			}
		}
		
		NSImage *im = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
		[im addRepresentation:[rep autorelease]];

	return [im autorelease];
}


+ (NSImage *)pinstripePatternImageWithRGBA1:(LXRGBA)rgba1 rgba2:(LXRGBA)rgba2 stripeHeight:(int)stripeH
{
	float r1, g1, b1, r2, g2, b2, a1, a2;
	float mul = 255.0f;
    a1 = rgba1.a;
	r1 = rgba1.r * a1;
	g1 = rgba1.g * a1;
	b1 = rgba1.b * a1;
    
    a2 = rgba2.a;
	r2 = rgba2.r * a2;
	g2 = rgba2.g * a2;
	b2 = rgba2.b * a2;

		int w = 16;
        int h = stripeH * 2;
        
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
					 pixelsWide:w
					 pixelsHigh:h
					 bitsPerSample:8 samplesPerPixel:4
					 hasAlpha:YES isPlanar:NO
					 colorSpaceName:NSDeviceRGBColorSpace
					 bytesPerRow:w*4 bitsPerPixel:32];
		
		unsigned char *dstBuf = [rep bitmapData];
		int x, y;
		for (y = 0; y < h; y++) {
			unsigned char *dst = dstBuf + y*w*4;
            
			for (x = 0; x < w; x++) {
				float r, g, b, a;
                
                if (y >= stripeH) {
                    r = r2;
                    g = g2;
                    b = b2;
                    a = a2;
                } else {
                    r = r1;
                    g = g1;
                    b = b1;
                    a = a1;
                }
                
/*                r = r1*p + r2*(1.0f - p);
                g = g1*p + g2*(1.0f - p);
                b = b1*p + b2*(1.0f - p);
                a = a1*p + a2*(1.0f - p);
  */              
				dst[x*4]   = r * mul;
				dst[x*4+1] = g * mul;
				dst[x*4+2] = b * mul;
				dst[x*4+3] = a * mul;
			}
		}
		
		NSImage *im = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
		[im addRepresentation:[rep autorelease]];

	return [im autorelease];
}


+ (NSImage *)verticalRoundGradientImageWithStartRGBA:(LXRGBA)rgba1 endRGBA:(LXRGBA)rgba2
            height:(int)h exponent:(float)exp
{
	float r1, g1, b1, r2, g2, b2, a1, a2;
	float mul = 255.0f;
    a1 = rgba1.a;
	r1 = rgba1.r * a1;
	g1 = rgba1.g * a1;
	b1 = rgba1.b * a1;
    
    a2 = rgba2.a;
	r2 = rgba2.r * a2;
	g2 = rgba2.g * a2;
	b2 = rgba2.b * a2;

		int w = 16;
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
					 pixelsWide:w
					 pixelsHigh:h
					 bitsPerSample:8 samplesPerPixel:4
					 hasAlpha:YES isPlanar:NO
					 colorSpaceName:NSDeviceRGBColorSpace
					 bytesPerRow:w*4 bitsPerPixel:32];
		
		unsigned char *dstBuf = [rep bitmapData];
		int x, y;
		for (y = 0; y < h; y++) {
			unsigned char *dst = dstBuf + y*w*4;
            
            float p = sin(M_PI * 0.5 * ((double)y / (double)h));
            if (exp != 1.0f)
                p = powf(p, exp);
            
			for (x = 0; x < w; x++) {
				float r, g, b, a;
                
                r = r1*p + r2*(1.0f - p);
                g = g1*p + g2*(1.0f - p);
                b = b1*p + b2*(1.0f - p);
                a = a1*p + a2*(1.0f - p);
                
				dst[x*4]   = r * mul;
				dst[x*4+1] = g * mul;
				dst[x*4+2] = b * mul;
				dst[x*4+3] = a * mul;
			}
		}
		
		NSImage *im = [[NSImage alloc] initWithSize:NSMakeSize(w, h)];
		[im addRepresentation:[rep autorelease]];

	return [im autorelease];
}

#endif // !defined(__LAGOON__)


@end
