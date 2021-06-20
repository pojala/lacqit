//
//  LQGUISlider.h
//  Lacqit
//
//  Created by Pauli Ojala on 16.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIControl.h"


@interface LQGUISlider : LQGUIControl {

}

+ (id)sliderWithWidth:(double)width
             minValue:(double)minVal maxValue:(double)maxVal numberOfSteps:(int)steps
                        name:(NSString *)name
                     context:(NSString *)context  // this can be used to get special views for different UI contexts (e.g. floater windows)
                      target:(id)target
                      action:(SEL)action;

@end
