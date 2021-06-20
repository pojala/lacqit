//
//  LQPopUpCloseButtonView.h
//  Lacqit
//
//  Created by Pauli Ojala on 19.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQPopUpCloseButtonView : NSView {

    BOOL _hilite;
    
    id _target;
    SEL _action;
}

- (void)setTarget:(id)target;
- (void)setAction:(SEL)action;

- (id)target;
- (SEL)action;

@end
