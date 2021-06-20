//
//  LQGListItemWrapperController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 17.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGListItemWrapperController_lagoon : LQGCommonUIController {

    LGNativeWidget *_hboxWidget;
    
    GtkWidget *_addButton;
    GtkWidget *_delButton;

    LQGCommonUIController *_containedCtrl;
}

- (void)setContainedViewController:(LQGCommonUIController *)viewCtrl;
- (LQGCommonUIController *)containedViewController;

- (void)_buttonClickedWithTag:(NSInteger)tag;

@end
