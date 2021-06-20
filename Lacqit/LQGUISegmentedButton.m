//
//  LQGUISegmentedButton.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUISegmentedButton.h"
#import "LQUIConstants.h"

#if !defined(__LAGOON__)
#import "LQSegmentedCell.h"
#endif


@implementation LQGUISegmentedButton

+ (double)heightForControlSize:(NSControlSize)controlSize
{
#if defined(__LAGOON__)
    switch (controlSize) {
        default:
        case NSMiniControlSize:     return 20;
        case NSSmallControlSize:    return 22;        
        case NSRegularControlSize:  return 24;
    }
#else
    switch (controlSize) {
        default:
        case NSMiniControlSize:     return 17;
        case NSSmallControlSize:    return 19;        
        case NSRegularControlSize:  return 21;
    }
#endif
}


- (void)setTrackingMode:(LQSegmentSwitchTracking)trackingMode
{
    id view = _implView;
    if ([view respondsToSelector:@selector(setTrackingMode:)]) {
        [view setTrackingMode:trackingMode];
    }
#if !defined(__LAGOON__)
    else if ([[view cell] respondsToSelector:@selector(setTrackingMode:)]) {
        [[view cell] setTrackingMode:trackingMode];
    }
#endif
}

- (LQSegmentSwitchTracking)trackingMode
{
    id view = _implView;
    if ([view respondsToSelector:@selector(trackingMode)]) {
        return [view trackingMode];
    }
#if !defined(__LAGOON__)
    else if ([[view cell] respondsToSelector:@selector(trackingMode)]) {
        return [[view cell] trackingMode];
    }
#endif
    else return 0;
}


+ (id)segmentedButtonWithLabels:(NSArray *)labels
                          name:(NSString *)name
                       context:(NSString *)context
                        target:(id)target
                        action:(SEL)action
{
    int i;
    NSRect buttonFrame;
    buttonFrame.origin = NSZeroPoint;
    
#if  !defined(__LAGOON__)
    buttonFrame.size = NSMakeSize(60, [self heightForControlSize:NSSmallControlSize] + 2);

#else
	buttonFrame.size = NSMakeSize(20, 22);
	buttonFrame.origin.y += 6.0;
#endif

    LQGUISegmentedButton *view = [[[self class] alloc] initWithFrame:buttonFrame];
    
    NSFont *labelFont = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];
    NSDictionary *labelAttribs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                labelFont, NSFontAttributeName,
                                                nil];
    
    Class segCls = NSClassFromString(@"LQSegmentedControl");
    if ( !segCls)
        segCls = [NSSegmentedControl class];
    
    NSSegmentedControl *seg = [[segCls alloc] initWithFrame:NSMakeRect(1.0, 1.0, buttonFrame.size.width-2, buttonFrame.size.height-2)];
    
    int count = [labels count];    
    [seg setSegmentCount:count];
    
    double totalW = 0.0;
    
    for (i = 0; i < count; i++) {
        NSString *label = [labels objectAtIndex:i];
        if ( !label) label = @"";
        
        [seg setLabel:label forSegment:i];
        
        double w = ceil([label sizeWithAttributes:labelAttribs].width);
        w += 12.0;

#if !defined(__LAGOON__)
        [[seg cell] setWidth:w forSegment:i];
#endif
        
        totalW += w;
    }
    
    if (count > 0)
        [seg setSelectedSegment:0];
    
    buttonFrame.size.width = totalW + (count-1)*6;
    [seg setFrame:buttonFrame];
    [view setFrame:buttonFrame];
    
	[seg setFont:labelFont];
	[seg setTarget:view];
	[seg setAction:@selector(forwarderAction:)];
    
#if !defined(__LAGOON__)
    [(NSSegmentedCell *)[seg cell] setControlSize:NSSmallControlSize];
    //[(NSSegmentedCell *)[seg cell] setBezelStyle:NSTexturedSquareBezelStyle];
    
    if ([[seg cell] respondsToSelector:@selector(setInterfaceTint:)]) {
        long tint = LQInterfaceTintForUIContext(context);
        ///NSLog(@"%s: setting tint: %i", __func__, tint);
        [[seg cell] setInterfaceTint:tint];
    }
#endif	
    
    [view setImplementationView:[seg autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];


    return [view autorelease];
}

- (void)setControlSize:(LXUInteger)controlSize
{
    id view = _implView;
    NSRect frame = [view frame];
    frame.size.height = [[self class] heightForControlSize:controlSize];
    [view setFrame:frame];
    
    ///NSLog(@".. %s: setting frame h %i for control: %@", __func__, (int)frame.size.height, view);
    
#if !defined(__LAGOON__)
    [(NSSegmentedCell *)[view cell] setControlSize:controlSize];
#endif
    
    if ([self frame].size.height < frame.size.height) {
        frame = [self frame];
        frame.size.height = [[self class] heightForControlSize:controlSize];
        [self setFrame:frame];
    }
}

@end
