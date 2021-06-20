//
//  LQThemedBox.h
//  Lacqit
//
//  Created by Pauli Ojala on 23.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
@class LQGradient;

/*
  A drawing override for NSBox
*/


@interface LQThemedBox : NSBox {

    LXUInteger _interfaceTint;
    LXUInteger _lq_controlSize;
    
    LQGradient *_boxGradient;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

- (void)setControlSize:(LXUInteger)controlSize;
- (LXUInteger)controlSize;

@end
