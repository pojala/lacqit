//
//  LQNSFontAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSFontAdditions.h"


#ifdef __APPLE__
 #define DEFAULTFAMILY_SANS      @"Helvetica"
 #define DEFAULTFAMILY_MONOSPACE @"Monaco"
 #define DEFAULTFAMILY_SERIF     @"Times"
#else
 #define DEFAULTFAMILY_SANS      @"Arial"
 #define DEFAULTFAMILY_MONOSPACE @"Courier"
 #define DEFAULTFAMILY_SERIF     @"TimesNewRoman"
#endif
 
 

@implementation NSFont (LQNSFontAdditionsCSSFormatting)

+ (NSFont *)fontWithCSSFormattedString:(NSString *)str
{
    double pointSize = 10;
    NSString *familyName = @"sans-serif";
    NSString *style = nil;
    NSString *variant = nil;
    NSString *weight = nil;
    
    NSArray *comps = [str componentsSeparatedByString:@" "];
    
    NSString *comp;
    LXInteger i = 0;
    if ([comps count] > 2) {
        NSArray *styles = [NSArray arrayWithObjects:@"italic", @"oblique", nil];
        NSArray *variants = [NSArray arrayWithObjects:@"small-caps", nil];
        NSArray *weights = [NSArray arrayWithObjects:@"bold", @"bolder", @"light", @"lighter", nil];  // values 100-900 not supported currently
    
        for (i = 0; i < [comps count] - 2; i++) {
            comp = [comps objectAtIndex:i];
            if ([styles containsObject:comp]) {
                style = comp;
            } else if ([variants containsObject:comp]) {
                variant = comp;
            }  else if ([weights containsObject:comp]) {
                weight = comp;
            } else if ([comp isEqual:@"normal"]) {
                // do nothing
            } else {
                ///NSLog(@"  .. encountered unknown font spec '%@', breaking", comp);
                break;  // exit loop when something else than one of these keywords is encountered
            }
        }
        
        ///NSLog(@"got font info: style %@ / variant %@ / weight %@", style, variant, weight);
    }
    if (i < [comps count]) {
        comp = [comps objectAtIndex:i];
        i++;
        double parsed = [comp doubleValue];
        if (parsed > 0.001 && parsed < 19999.9) {
            if ([comp rangeOfString:@"em"].location != NSNotFound) {
                pointSize *= parsed;
            } else if ([comp rangeOfString:@"%"].location != NSNotFound) {
                pointSize *= (parsed / 100.0);
            } else {
                pointSize = parsed;  // points == pixels here
            }
        }
        ///NSLog(@"got font size: %.5f, from '%@'", pointSize, comp);
    }
    if (i < [comps count]) {
        comp = [comps objectAtIndex:i];
        i++;
        if ([comp length] > 0) {
            NSRange range;
            unichar c = [comp characterAtIndex:0];

            if (c == '\'' || c == '"') {
                NSMutableString *fullStr = [NSMutableString stringWithString:[comp substringFromIndex:1]];
                NSString *searchStr = [NSString stringWithCharacters:&c length:1];
                
                if ((range = [fullStr rangeOfString:searchStr]).location != NSNotFound) {
                    fullStr = [NSMutableString stringWithString:[fullStr substringToIndex:range.location]];
                } else {
                    LXInteger k = i;
                    while (k < [comps count]) {
                        NSString *nextComp = [comps objectAtIndex:k];
                        k++;
                        range = [nextComp rangeOfString:searchStr];
                        if (range.location == NSNotFound) {
                            [fullStr appendString:nextComp];  // note: we're leaving out the spaces here (i.e. 'Times New Roman' will become TimesNewRoman)
                        } else {
                            [fullStr appendString:[nextComp substringToIndex:range.location]];
                            break;
                        }
                    }
                }
                familyName = fullStr;
            } else {
                if ((range = [comp rangeOfString:@","]).location != NSNotFound) {
                    familyName = [comp substringToIndex:range.location];  // we don't currently process any cascading font definitions (e.g. "Helvetica, Arial, sans")
                } else {
                    familyName = comp;
                }
            }
        }
        ///NSLog(@"got family: %@ (first comp was %@)", familyName, comp);
    }
    
    if ([familyName isEqual:@"serif"]) {
        familyName = DEFAULTFAMILY_SERIF;
    } else if ([familyName isEqual:@"monospace"]) {
        familyName = DEFAULTFAMILY_MONOSPACE;
    } else if ([familyName isEqual:@"sans"] || [familyName isEqual:@"sans-serif"] || [familyName length] < 1) {
        familyName = DEFAULTFAMILY_SANS;
    }
    
    NSFont *theFont = nil;
    LXInteger attempts = 0;
    
    while ( !theFont) {
        NSMutableString *sysName = [NSMutableString stringWithString:familyName];
        BOOL isBold = NO;
        NSString *connector = @"-";
        
        if (weight && ![weight isEqual:@"normal"]) {
            if ([weight isEqual:@"bold"] || [weight isEqual:@"bolder"]) {
                [sysName appendFormat:@"%@Bold", connector];
                connector = @"";
                isBold = YES;
            }
            else if ([weight isEqual:@"light"] || [weight isEqual:@"lighter"]) {
                [sysName appendFormat:@"%@Light", connector];
                connector = @"";
            }
        }
        if (style && ![style isEqual:@"normal"]) {
            BOOL found = NO;
            #ifdef __APPLE__
            if (attempts == 0) {
                // try to find the italic variant through NSFont's mechanism
                NSFontDescriptor *desc = [NSFontDescriptor fontDescriptorWithName:familyName size:pointSize];
                uint32_t traits = NSFontItalicTrait;
                if (isBold)
                    traits |= NSFontBoldTrait;
                desc = [desc fontDescriptorWithSymbolicTraits:traits];
                if (desc && [[desc postscriptName] rangeOfString:familyName].location != NSNotFound) {
                    sysName = [NSMutableString stringWithString:[desc postscriptName]];
                    if ([sysName length] > 0)
                        found = YES;
                }
            }
            #endif
            
            if ( !found) {
                if ([style isEqual:@"italic"]) {
                    [sysName appendFormat:@"%@Italic", connector];
                    connector = @"";
                } else if ([style isEqual:@"oblique"]) {
                    [sysName appendFormat:@"%@Oblique", connector];
                    connector = @"";
                }
            }
        }
        // "variant" (i.e. small-caps) is not currently supported at all
        
        ///NSLog(@"...attempt %i: looking for font with system name '%@'", attempts, sysName);
        
        theFont = [NSFont fontWithName:sysName size:pointSize];
        attempts++;
        
        if ( !theFont) {
            if (attempts == 2) {
                if ([style isEqual:@"italic"]) {
                    style = @"oblique";
                } else if ([style isEqual:@"oblique"]) {
                    style = @"italic";
                }
            } else if (attempts == 3) {
                style = nil;
            } else if (attempts == 4) {
                weight = nil;
            } else if (attempts == 5) {
                familyName = DEFAULTFAMILY_SANS;
            } else if (attempts >= 6) {
                break;
            }
        }
    }

    ///NSLog(@"%s: string '%@' --> font %@ (attempts %i)", __func__, str, theFont, attempts);

    return theFont;
}

// example: "italic small-caps bold 1em/1.5em 'Times New Roman'"
- (NSString *)cssFormattedString
{
#ifdef __APPLE__
    NSFontDescriptor *desc = [self fontDescriptor];
    
    NSString *name = [desc postscriptName];
    double pointSize = [desc pointSize];

#else
    NSString *name = [self fontName];
    double pointSize = [self pointSize];
#endif

    
    NSMutableString *css = [NSMutableString string];
    
    if (fabs(pointSize - round(pointSize)) < 0.0001) {
        [css appendFormat:@"%ipt ", (int)round(pointSize)];
    } else {
        [css appendFormat:@"%.5fpt ", pointSize];
    }
    
    if ([name rangeOfString:@" "].location != NSNotFound) {
        [css appendFormat:@"'%@'", name];
    } else {
        [css appendString:name];
    }

    ///NSLog(@"%s: font attributes: %@\n  --> css formatted string: %@", __func__, [desc fontAttributes], css);
    
    return css;
}

@end



#ifdef __APPLE__

#include <dlfcn.h>

// CreateWithFontName exists in 10.5, but not in 10.4; CreateWithName isn't public in 10.4.
// to maintain 10.4 compatibility, we need to load these dynamically.
static CGFontRef (*CGFontCreateWithFontNamePtr) (CFStringRef) = NULL;
static CGFontRef (*CGFontCreateWithNamePtr) (const char *) = NULL;

// not public
static void (*CGFontGetGlyphsForUnicharsPtr) (CGFontRef, const UniChar[], CGGlyph[], size_t) = NULL;

static BOOL s_cgSymbolLookupDone = NO;

static void doCGSymbolInit()
{
    if (s_cgSymbolLookupDone)
        return;

    CGFontCreateWithFontNamePtr = dlsym(RTLD_DEFAULT, "CGFontCreateWithFontName");
    CGFontCreateWithNamePtr = dlsym(RTLD_DEFAULT, "CGFontCreateWithName");

    // this has a different name on 10.4
    CGFontGetGlyphsForUnicharsPtr = dlsym(RTLD_DEFAULT, "CGFontGetGlyphsForUnichars");
    if (!CGFontGetGlyphsForUnicharsPtr)
        CGFontGetGlyphsForUnicharsPtr = dlsym(RTLD_DEFAULT, "CGFontGetGlyphsForUnicodes");
        
    s_cgSymbolLookupDone = YES;
}


@implementation NSFont (LQNSFontAdditionsForCGFont)

- (CGFontRef)lq_createCGFontRef
{
    doCGSymbolInit();
    
    NSString *psName;
    NSFontDescriptor *desc = [self fontDescriptor];
    if ([desc respondsToSelector:@selector(postscriptName)]) {
        psName = [desc postscriptName];
    } else {
        psName = [self fontName];
    }
    
    CGFontRef cgFont = NULL;
    
    if (CGFontCreateWithFontNamePtr) {
	    cgFont = CGFontCreateWithFontNamePtr((CFStringRef)psName);
	} else if (CGFontCreateWithNamePtr) {
	    cgFont = CGFontCreateWithNamePtr([psName UTF8String]);
	}
    
    if ( !cgFont) {
        NSLog(@"** unable to create CGFontRef for NSFont named '%@'", psName);
    }
    ///else NSLog(@"..created cgfont for psname '%@'", psName);
    
    return cgFont;
}

@end


@implementation NSFont (LQNSFontAdditionsGlyphConversion)

- (size_t)getGlyphs:(NSGlyph *)glyphArray forString:(NSString *)str glyphCount:(size_t)len
{
    doCGSymbolInit();
    
    if ( !CGFontGetGlyphsForUnicharsPtr) {
        NSLog(@"*** %s: can't proceed, no getGlyphs function was found from CoreGraphics", __func__);
        return 0;
    }
    
    len = MIN([str length], len);
    if (len < 1 || !glyphArray) {
        return 0;
    }
    
    CGFontRef cgFont = [self lq_createCGFontRef];
    if ( !cgFont)
        return 0;
    
    unichar *unichars = _lx_malloc(len * sizeof(unichar));
    [str getCharacters:unichars];
    
    CGGlyph *cgGlyphs = _lx_calloc(len, sizeof(CGGlyph));
    
    CGFontGetGlyphsForUnicharsPtr(cgFont, unichars, cgGlyphs, len);
    
    LXInteger i;
    for (i = 0; i < len; i++) {
        glyphArray[i] = cgGlyphs[i];
    }
    
    _lx_free(cgGlyphs);
    _lx_free(unichars);
    
    CGFontRelease(cgFont);
    return len;
}

@end

#endif
