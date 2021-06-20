//
//  LQGUISlider.m
//  Lacqit
//
//  Created by Pauli Ojala on 16.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUISlider.h"


@implementation LQGUISlider

+ (id)sliderWithWidth:(double)width
             minValue:(double)minVal maxValue:(double)maxVal numberOfSteps:(int)steps
                        name:(NSString *)name
                     context:(NSString *)context  // this can be used to get special views for different UI contexts (e.g. floater windows)
                      target:(id)target
                      action:(SEL)action
{
    NSRect sliderFrame = NSMakeRect(0, 0, width, 20);
    
    LQGUISlider *view = [[[self class] alloc] initWithFrame:sliderFrame];
    
    NSSlider *slider = [[NSSlider alloc] initWithFrame:sliderFrame];
    [slider setTarget:view];
    [slider setAction:@selector(forwarderAction:)];
    [[slider cell] setControlSize:NSSmallControlSize];
    
    [slider setMinValue:minVal];
    [slider setMaxValue:maxVal];
    [slider setNumberOfTickMarks:steps];
    
    [view setImplementationView:[slider autorelease]];
    [view setName:name];
    [view setContext:context];
    [view setTarget:target];
    [view setAction:action];

    return [view autorelease];
}

@end
