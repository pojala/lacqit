//
//  LQGButtonWithDetailController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGButtonWithDetailController_lagoon : LQGCommonUIController {

    LGNativeWidget *_hboxWidget;
    
    GtkWidget *_buttonWidget;

    NSString *_label;
}

- (NSString *)detailString;
- (void)setDetailString:(NSString *)str;

- (NSString *)buttonLabel;
- (void)setButtonLabel:(NSString *)str;


- (void)_buttonClicked;

@end
