//
//  LQNSFontAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface NSFont (LQNSFontAdditionsCSSFormatting)

+ (NSFont *)fontWithCSSFormattedString:(NSString *)str;
- (NSString *)cssFormattedString;

@end


#ifdef __APPLE__

@interface NSFont (LQNSFontAdditionsGlyphConversion)

// returns the number of glyphs written in the array
- (size_t)getGlyphs:(NSGlyph *)glyphArray forString:(NSString *)str glyphCount:(size_t)len;

@end

@interface NSFont (LQNSFontAdditionsForCGFont)

- (CGFontRef)lq_createCGFontRef;

@end
#endif
