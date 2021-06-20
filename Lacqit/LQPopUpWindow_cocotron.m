//
//  LQPopUpWindow_cocotron.m
//  Lacqit
//
//  Created by Pauli Ojala on 25.4.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//


#import "LQPopUpWindow.h"
#import "LQNSBezierPathAdditions.h"



@implementation LQPopUpWindow

- (id)initWithFrame:(NSRect)frame
{
    return [self initWithContentRect:frame
                            styleMask:NSBorderlessWindowMask
                            backing:NSBackingStoreBuffered
                            defer:NO];
}

@end
