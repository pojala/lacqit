//
//  LQGUITextField.m
//  Lacqit
//
//  Created by Pauli Ojala on 24.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUITextField.h"
#import "LQUIConstants.h"
#import "LQNSColorAdditions.h"
#import "LQNumberScrubField.h"


@implementation LQGUITextField

+ (double)emWidthForFont:(NSFont *)font
{
    double em = kLQUIDefaultFontSize;
    
#if !defined(__LAGOON__)
    em = [@"m" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]].width;
    
    if (em < 1.0) {
        NSLog(@"** %s: 'em' calculated by CoreGraphics or CoreText is unexpectedly small: %.4f", __func__, em);
        em = 9.0;
    }
#endif

    return em;
}

- (void)setFrame:(NSRect)frame
{
    [super setFrame:frame];
    /*
    NSRect r = [_implView frame];
    r.size.height = frame.size.height;
    [_implView setFrame:r];*/
}

+ (id)textFieldWithWidthInCharacters:(NSInteger)charW
                        name:(NSString *)name
                     context:(NSString *)context  // this can be used to get special views for different UI contexts (e.g. floater windows)
                      target:(id)target
                      action:(SEL)action
{
    double fieldH = 16;

    NSFont *font = [NSFont systemFontOfSize:kLQUIDefaultFontSize];
    double em = [[self class] emWidthForFont:font];
    NSLog(@"...creating text field, '%@', %.1f", name, font.pointSize);

#ifdef __LAGOON__
    fieldH = 20;
#endif    

    if (charW < 1) charW = 8;

    NSRect fieldFrame = NSMakeRect(0, 0, ceil(charW * em), fieldH);

    LQGUITextField *view = [[[self class] alloc] initWithFrame:fieldFrame];
    
    NSTextField *field = [[NSTextField alloc] initWithFrame:fieldFrame];    
    [field setFont:font];
    [field setBackgroundColor:[NSColor colorWithRGBA:LXMakeRGBA(0.9, 0.9, 0.9, 1.0)]];
    [field setTarget:view];
    [field setAction:@selector(forwarderAction:)];
    [field setAutoresizingMask:NSViewWidthSizable];

    [view setImplementationView:[field autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];

    return [view autorelease];
}


+ (id)numberScrubFieldWithWidthInCharacters:(NSInteger)charW
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action
{
    double fieldH = 16;

    NSFont *font = [NSFont systemFontOfSize:kLQUIDefaultFontSize];
    double em = [[self class] emWidthForFont:font];
    
#ifdef __LAGOON__
    fieldH = 20;
#endif

    if (charW < 1) charW = 7;
    
    NSRect fieldFrame = NSMakeRect(0, 0, ceil(em * charW), fieldH);

    LQGUITextField *view = [[[self class] alloc] initWithFrame:fieldFrame];
        
    NSTextField *field = [[LQNumberScrubField alloc] initWithFrame:fieldFrame];
    [field setTarget:view];
    [field setAction:@selector(forwarderAction:)];

    [view setImplementationView:[field autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];

    return [view autorelease];
}

+ (NSRect)_fieldFrameForString:(NSString *)str
{
    NSFont *font = [NSFont systemFontOfSize:kLQUIDefaultFontSize];
    NSSize size = [str sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil]];
    
    return NSMakeRect(0, 0, ceil(size.width) + 4, ceil(size.height) + 1);
}

- (void)_setLQFieldType:(LXUInteger)type {
    _lqFieldType = type;
}

+ (id)labelWithString:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
{
    if ( !str) return nil;

    NSFont *font = [NSFont systemFontOfSize:kLQUIDefaultFontSize];
    NSRect fieldFrame = [self _fieldFrameForString:str];
    
    LQGUITextField *view = [[[self class] alloc] initWithFrame:fieldFrame];
        
    [view _setLQFieldType:1];

    NSTextField *field = [[NSTextField alloc] initWithFrame:fieldFrame];
    [field setFont:font];
    [field setStringValue:str];
    [field setEditable:NO];
    [field setBezeled:NO];
    [field setDrawsBackground:NO];
    [field setAutoresizingMask:(NSViewMinYMargin | NSViewMaxXMargin)];
    [[field cell] setLineBreakMode:NSLineBreakByWordWrapping];

#if !defined(__LAGOON__)
    [field setSelectable:NO];
    [field setBordered:NO];

    if ([context isEqualToString:kLQUIContext_Floater] && [field respondsToSelector:@selector(setTextColor:)]) {
        [field setTextColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.9]];
        [field setBackgroundColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    }
#endif

    [view setImplementationView:[field autorelease]];
    [view setName:name];
    [view setContext:context];

    return [view autorelease];
}

- (void)setStringValue:(NSString *)str
{
    if (_lqFieldType == 1) {
        NSRect fieldFrame = [[self class] _fieldFrameForString:str];
        [_implView setFrame:fieldFrame];
        
        NSRect frame = [self frame];
        frame.size = fieldFrame.size;
        [self setFrame:frame];
    }
    [(id)_implView setStringValue:str];
}

@end
