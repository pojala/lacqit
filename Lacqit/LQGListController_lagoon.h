//
//  LQGListController_lagoon.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListController.h"
#import <Lagoon/LGNativeWidget.h>


@interface LQGListController_lagoon : LQGListController {

    LGNativeWidget *_container;

    LGNativeWidget *_listWidget;

    LGNativeWidget *_scrollWidget;
}

@end
