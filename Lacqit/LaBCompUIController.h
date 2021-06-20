//
//  LaBCompUIController.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Lacqit/EDUICompViewController.h>
#import <Lacqit/EDUICompositionView.h>


@interface LaBCompUIController : NSObject {

    IBOutlet EDUICompViewController     *_compViewController;
    IBOutlet EDUICompositionView        *_compView;

    IBOutlet NSTableView                *_nodesTableView;
}

@end
