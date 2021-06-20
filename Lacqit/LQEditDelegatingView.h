//
//  LQEditDelegatingView.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.2.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQEditDelegatingView : NSView {

    id _delegate;
}

- (void)setDelegate:(id)del;
- (id)delegate;

@end
