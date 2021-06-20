//
//  LQGUIButton.m
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIButton.h"
#import "LQGUISegmentedButton.h"
#import "LQSegmentedControl.h"
#import "LQAppKitUtils.h"


@implementation LQGUIButton

- (void)_applyAutoresizingBehavior:(LXUInteger)mask
{
    [(NSView *)_implView setAutoresizingMask:mask];
    [self setAutoresizingMask:mask];
}

+ (id)pushButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action                 
{
    NSFont *buttonFont = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];

    NSSize size = (str) ? [str sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            buttonFont, NSFontAttributeName,
                                                            nil]]
                        : NSMakeSize(0, 0);

    NSRect buttonFrame = NSMakeRect(0, 0, ceil(size.width + 30), 20);
    
#if defined(__LAGOON__)
    buttonFrame.size.width += 4;
    buttonFrame.size.height += 4;
#endif    

    NSButton *button = [[NSButton alloc] initWithFrame:buttonFrame];
    LQGUIButton *view = [[[self class] alloc] initWithFrame:buttonFrame];
            
    [button setTitle:([str length] > 0) ? str : @""];
	[button setFont:buttonFont];
	[button setTarget:view];
	[button setAction:@selector(forwarderAction:)];
	[button setTag:1];

#if !defined(__LAGOON__)    
    [button setBezelStyle:NSRoundedBezelStyle];
    //[[button cell] setControlSize:NSMiniControlSize];
    [[button cell] setControlSize:NSSmallControlSize];
#endif
    
	[view setImplementationView:[button autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];
    
    //[view _applyAutoresizingBehavior:NSViewWidthSizable];

    return [view autorelease];
}

+ (id)checkboxWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action                 
{
    NSFont *buttonFont = [NSFont systemFontOfSize:kLQUIDefaultFontSize];

    NSSize size = (str) ? [str sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            buttonFont, NSFontAttributeName,
                                                            nil]]
                        : NSMakeSize(0, 0);

    NSRect buttonFrame = NSMakeRect(0, 0, ceil(size.width + 24), 15);
    
#if defined(__LAGOON__)
    buttonFrame.size.width += 8;
    buttonFrame.size.height += 4;
#endif    

    NSButton *button = [[NSButton alloc] initWithFrame:buttonFrame];
    LQGUIButton *view = [[[self class] alloc] initWithFrame:buttonFrame];
            
    [button setTitle:([str length] > 0) ? str : (id)@""];
	[button setFont:buttonFont];
	[button setTarget:view];
	[button setAction:@selector(forwarderAction:)];
	[button setTag:1];
    

#if !defined(__LAGOON__)    
    [button setButtonType:NSSwitchButton];
    [[button cell] setControlSize:NSMiniControlSize];
#endif

    LQInterfaceTint tint = LQInterfaceTintForUIContext(context);
    switch (tint) {
        case kLQFloaterTint:
            LQSetTextColorForControl([NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.96], button);
            break;
    }
    
	[view setImplementationView:[button autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];
    
    return [view autorelease];
}


+ (id)symbolButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action
{
    if ( !str) return nil;

    NSRect buttonFrame = NSMakeRect(0, 0, 16, 20);

#if defined(__LAGOON__)
	buttonFrame.size = NSMakeSize(20, 24);
	buttonFrame.origin.y += 6.0;
#endif

    NSFont *buttonFont = [NSFont boldSystemFontOfSize:11];

	NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(0, 1, buttonFrame.size.width, buttonFrame.size.height-2)];
    LQGUIButton *view = [[[self class] alloc] initWithFrame:buttonFrame];
    
	[button setTitle:([str length] > 0) ? str : (id)@""];
	[button setFont:buttonFont];
	[button setTarget:view];
	[button setAction:@selector(forwarderAction:)];
	[button setTag:1];
    
#if !defined(__LAGOON__)
	[[button cell] setControlSize:NSSmallControlSize];
	[[button cell] setBezelStyle:NSTexturedSquareBezelStyle];
#endif	

	[view setImplementationView:[button autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];
    
    return [view autorelease];
}

#define SEGTAG 45009

static LQSegmentedControl *createSegControlWithMenuStyleAndLabel(NSString *str)
{
    NSFont *buttonFont = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];
    NSSize size = (str) ? [str sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            buttonFont, NSFontAttributeName,
                                                            nil]]
                        : NSMakeSize(0, 0);
    size.width = ceil(size.width);
    size.height = ceil(size.height);
    double wAdd = 28;
    double segH = [LQGUISegmentedButton heightForControlSize:NSSmallControlSize];

    LQSegmentedControl *seg = [[LQSegmentedControl alloc] initWithFrame:NSMakeRect(1, 1, size.width + wAdd, segH)];
    
    [seg setSegmentCount:1];
    [seg setTag:SEGTAG];
    [seg setLabel:((str) ? str : (NSString *)@"") forSegment:0];
    [seg setFont:buttonFont];
    
    #if !defined(__LAGOON__)    
    [seg setWidth:size.width + wAdd - 2.0 forSegment:0];

    [[seg cell] setControlSize:NSSmallControlSize];
    [[seg cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];
    #endif    
    
    return seg;
}

+ (id)menuButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action
{
    LQSegmentedControl *seg = createSegControlWithMenuStyleAndLabel(str);
    NSSize segSize = [seg frame].size;

    LQGUIButton *view = [[[self class] alloc] initWithFrame:NSMakeRect(0, 0, segSize.width + 2.0, segSize.height + 2.0)];

	[seg setTarget:view];
	[seg setAction:@selector(forwarderAction:)];
	[seg setTag:1];
    
	[view setImplementationView:[seg autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];
    
    [view _applyAutoresizingBehavior:NSViewWidthSizable];

    return [view autorelease];
}

+ (id)menuButtonWithLabel:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context
                        menu:(NSMenu *)menu
{
    LQSegmentedControl *seg = createSegControlWithMenuStyleAndLabel(str);
    NSSize segSize = [seg frame].size;

    LQGUIButton *view = [[[self class] alloc] initWithFrame:NSMakeRect(0, 0, segSize.width + 2.0, segSize.height + 2.0)];
    
    if (menu)
        [seg setMenu:menu forSegment:0];
    
	[view setImplementationView:[seg autorelease]];
    [view setName:name];
    [view setContext:context];
    
    [view _applyAutoresizingBehavior:NSViewWidthSizable];

    return [view autorelease];
}

- (void)setMenu:(NSMenu *)menu
{
    id view = [self viewWithTag:SEGTAG];
    if ([view isKindOfClass:[LQSegmentedControl class]]) {
        [view setMenu:menu forSegment:0];
    }
}

- (NSMenu *)menu
{
    id view = [self viewWithTag:SEGTAG];
    if ([view isKindOfClass:[LQSegmentedControl class]]) {
        return [view menuForSegment:0];
    } else
        return nil;
}

- (void)setLabel:(NSString *)label {
    if ([_implView respondsToSelector:@selector(setTitle:)])
        [_implView setTitle:label];
    else if ([_implView respondsToSelector:@selector(setLabel:forSegment:)])
        [_implView setLabel:label forSegment:0];
}

- (NSString *)label {
    if ([_implView respondsToSelector:@selector(setTitle:)])
        return [_implView title];
    else if ([_implView respondsToSelector:@selector(setLabel:forSegment:)])
        return [_implView labelForSegment:0];
    else
        return nil;
}

@end
