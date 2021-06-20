//
//  LQGColorPickerController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 17.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Lacefx/LXBasicTypes.h>
#import "LQGCommonUIController.h"


@interface LQGColorPickerController_cocoa : LQGCommonUIController {

    NSTextField *_labelField;
    NSColorWell *_swatchView;

    NSArray *_controls;
    
    NSString *_labelStr;
    LXRGBA _colorValue;
}

- (NSString *)label;
- (void)setLabel:(NSString *)label;

- (LXRGBA)rgbaValue;
- (void)setRGBAValue:(LXRGBA)rgba;

@end
