//
//  LQGTabbedController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTabbedController.h"


@interface LQGTabbedController_cocoa : LQGTabbedController {

    NSView *_container;

    NSTabView *_tabView;
    
    id _placeholderTabItem;
}

- (void)setControlSize:(LXUInteger)controlSize;

@end
