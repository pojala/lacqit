//
//  LQGTabbedController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTabbedController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGTabbedController_lagoon : LQGTabbedController {

    LGNativeWidget *_container;

    LGNativeWidget *_tabView;
}

@end
