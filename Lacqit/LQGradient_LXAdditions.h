//
//  LQGradient_LXAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Lacefx/Lacefx.h>
#import "LQGradient.h"


@interface LQGradient (LXAdditions)

- (LXShaderRef)createLXShaderWithAngle:(LXFloat)angle gamma:(LXFloat)gamma;

@end
