//
//  LQScroller.h
//  Lacqit
//
//  Created by Pauli Ojala on 25.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"

/*
  A drawing override for NSScroller
*/

@interface LQThemedScroller : NSScroller {

    LXUInteger _interfaceTint;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end
