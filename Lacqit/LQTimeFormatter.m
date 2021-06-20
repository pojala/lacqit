//
//  LQTimeFormatter.m
//  Lacqit
//
//  Created by Pauli Ojala on 30.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQTimeFormatter.h"


static double g_timeFormatterSystemFrameRate = 60.0;


@implementation LQTimeFormatter

+ (void)setSystemFrameRate:(double)fps {
    g_timeFormatterSystemFrameRate = fps; 
}

+ (double)systemFrameRate {
    return g_timeFormatterSystemFrameRate;
}

- (double)displayFrameRate {
    return _fps; }
    
- (void)setDisplayFrameRate:(double)fps {
    _fps = MAX(fps, 0.0); }


- (NSString *)stringForObjectValue:(id)anObject
{
    double v, fract;
    long h = 0;
    long m = 0;
    long s = 0;
    long f = 0;
    BOOL negative = NO;

    if ( ![anObject respondsToSelector:@selector(doubleValue)]) {
        NSLog(@"** %s: unknown object class (%@)", __func__, NSStringFromClass([anObject class]));
        return nil;
    }

    v = [anObject doubleValue];
    
    if (v == DBL_MAX) {
        return @"not set";
    }
    if ( !isfinite(v)) {
        return @"(invalid)";
    }
    
    if (v < 0) {
        negative = YES;
        v = fabs(v);
    }
    
    s = floor(v);
    fract = v - s;
    
    const double fps = (isfinite(_fps) && _fps > 0.0) ? _fps : [[self class] systemFrameRate];
    
    f = floor(fract * fps * 1.000001);
    
    m = s / 60;
    s = s % 60;
    
    h = m / 60;
    m = m % 60;
    
    return [NSString stringWithFormat:@"%02i:%02i:%02i.%02i", (int)h, (int)m, (int)s, (int)f];
}


- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    if ([[string lowercaseString] isEqualToString:@"not set"]) {
        *obj = [NSNumber numberWithDouble:DBL_MAX];
        return YES;
    }
    if ([[string lowercaseString] rangeOfString:@"invalid"].location != NSNotFound) {
        *obj = [NSNumber numberWithDouble:0.0];
        return YES;
    }

    double doubleResult = 0.0;
    long h = 0;
    long m = 0;
    long s = 0;
    long f = 0;
    NSMutableArray *comp = [NSMutableArray arrayWithCapacity:5];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSString *tempString;
    long count = 0;
    const double fps = (isfinite(_fps) && _fps > 0.0) ? _fps : [[self class] systemFrameRate];
    
    
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    while (![scanner isAtEnd]) {
        if ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&tempString])
            [comp addObject:tempString];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    }

    count = [comp count];
    if (count < 1) {
        *obj = [NSNumber numberWithDouble:0.0];
        return YES;
    }
    
    // scan frames
    count--;
    f = [(NSString *)[comp objectAtIndex:count] intValue];
    
    // scan seconds, if array has more than 1 member
    count--;
    if (count >= 0)
        s = [(NSString *)[comp objectAtIndex:count] intValue];
        
    // scan minutes
    count--;
    if (count >= 0)
        m = [(NSString *)[comp objectAtIndex:count] intValue];

    // scan hours
    count--;
    if (count >= 0)
        h = [(NSString *)[comp objectAtIndex:count] intValue];
    
    // calculate overflow
    s += f / (int)fps;
    f = f % (int)fps;
    
    m += s / 60;
    s = s % 60;
    
    h += m / 60;
    s = s % 60;
    
    // final result
    doubleResult = (double)h * 3600.0 + (double)m * 60.0 + (double)s + (double)f / fps;

    // return value into provided object
    if (obj) *obj = [NSNumber numberWithDouble:doubleResult];
        
    return YES;
}


- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
    return nil;
}

/*
- (BOOL)isPartialStringValid:(NSString *)partialString
        newEditingString:(NSString **)newString
        errorDescription:(NSString **)error
{
    NSString *resultString;
    NSScanner *scanner = [NSScanner scannerWithString:partialString];
    NSRange range;
    NSString *tempString;
    NSString *string2 = @"";
    NSString *sepChar = @":";
    long i, len;
    
    [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    while (![scanner isAtEnd]) {
        if ([scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&tempString])
            string2 = [string2 stringByAppendingString:tempString];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:nil];
    }
    
    len = [string2 length];
    
    if (len == 0) {
        *newString = string2;
        return NO;
    }
    
    if (len % 2) {
        range = NSMakeRange(0, 1);
        i = 1;
    }
    else {
        range = NSMakeRange(0, 2);
        i = 2;
    }

    resultString = [string2 substringWithRange:range];
    
    while (i < len) { 
        range = NSMakeRange(i, 2);
        resultString =
            [NSString stringWithFormat:@"%@%@%@", resultString, sepChar, [string2 substringWithRange:range]];
        i += 2;
    }
    
    *newString = resultString;
    return NO;
}
*/

- (BOOL)isPartialStringValid:(NSString **)partialStringPtr
        proposedSelectedRange:(NSRangePointer)proposedSelRangePtr
        originalString:(NSString *)origString
        originalSelectedRange:(NSRange)origSelRange
        errorDescription:(NSString **)error
{
    NSString *partialString = (partialStringPtr) ? *partialStringPtr : nil;
    ///NSLog(@"partial string: '%@' -- original: '%@' -- range: %@", partialString, origString, NSStringFromRange(origSelRange));
    
    if (error) *error = nil;
    
    // if the new string is shorter, the user deleted something; just accept that
    if ([partialString length] < [origString length])
        return YES;
        
    NSCharacterSet *acceptedChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789:.,"];
        
    BOOL accept = YES;
        
    // if there wasn't a deletion, the user typed something, so check if it's a number
    if (origSelRange.location != NSNotFound) {
        unichar newChar = [partialString characterAtIndex:origSelRange.location];
        if ( ![acceptedChars characterIsMember:newChar])
            accept = NO;
    }

    if ( !accept) {
        *partialStringPtr = [[origString copy] autorelease];
        *proposedSelRangePtr = NSMakeRange(origSelRange.location, 0);
        return NO;
    }

    return YES;
}

@end
