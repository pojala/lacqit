//
//  LGViewController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGViewController.h"


@interface LQGViewController (LQGViewControllerCocoaSpecific)

- (NSView *)view;
- (void)setView:(NSView *)view;

@end


@interface LQGCocoaViewController : LQGViewController {
}

@end


