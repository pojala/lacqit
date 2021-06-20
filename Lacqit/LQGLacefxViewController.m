//
//  LQGLacefxViewController.m
//  Lacqit
//
//  Created by Pauli Ojala on 13.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGLacefxViewController.h"
#import "LacqitInit.h"

#ifdef __LAGOON__
 #import "LQGLacefxViewController_lagoon_d3d.h"
 #define PLATFORMCLASS LQGLacefxViewController_lagoon_d3d
#else
 #import "LQGLacefxViewController_cocoa.h"
 #define PLATFORMCLASS LQGLacefxViewController_cocoa
#endif


@implementation LQGLacefxViewController


+ (id)lacefxViewController
{
    return [[[PLATFORMCLASS alloc] init] autorelease];
}


- (void)setContentDelegate:(id)del {
    _contentDelegate = del; 
}

- (id)contentDelegate {
    return _contentDelegate;
}


@end
