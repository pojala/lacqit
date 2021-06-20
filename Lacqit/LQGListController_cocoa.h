//
//  LQGListController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGListController.h"
@class LQListView;


@interface LQGListController_cocoa : LQGListController {

    NSView *_container;

    LQListView *_listView;
}

- (NSScrollView *)packIntoScrollView;

@end
