//
//  LQGSliderAndFieldController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>
@class LGWindow;
@class LQNumberScrubField;


@interface LQGSliderAndFieldController_lagoon : LQGCommonUIController {
    
    LGNativeWidget *_hboxWidget;
    
    GtkWidget *_label;
    GtkWidget *_slider;
    
    LGWindow *_lgWindow;
    LQNumberScrubField *_scrubField;
}

- (double)doubleValue;
- (void)setDoubleValue:(double)d;

- (void)setSliderMin:(double)smin max:(double)smax;

- (void)setEnabled:(BOOL)f;


// private
- (void)_newDoubleValueForSlider:(double)v;

@end
