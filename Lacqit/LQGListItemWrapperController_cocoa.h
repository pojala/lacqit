//
//  LQGListItemWrapperController.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"


@interface LQGListItemWrapperController_cocoa : LQGCommonUIController {

    NSButton *_addButton;
    NSButton *_delButton;
    
    LQGCommonUIController *_containedCtrl;
    
    double _buttonAreaW;
}

- (id)init;

- (void)setContainedViewController:(LQGCommonUIController *)viewCtrl;
- (LQGCommonUIController *)containedViewController;

@end
