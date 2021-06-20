//
//  LQGColorPickerController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>
#import <Lacefx/LXBasicTypes.h>


@interface LQGColorPickerController_lagoon : LQGCommonUIController {

    LGNativeWidget *_hboxWidget;
    
    GtkWidget *_label;
    GtkWidget *_colorButton;
    
    LXRGBA _rgba;
}

- (NSString *)label;
- (void)setLabel:(NSString *)label;

- (LXRGBA)rgbaValue;
- (void)setRGBAValue:(LXRGBA)rgba;


- (void)_newRGBAValueForColorButton:(LXRGBA)c;

@end
