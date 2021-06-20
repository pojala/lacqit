//
//  LQFullscreenCoverView.m
//  Lacqit
//
//  Created by Pauli Ojala on 29.7.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQFullscreenCoverView.h"


@implementation LQFullscreenCoverView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (BOOL)canBecomeKeyView {
    return NO; }

- (BOOL)acceptsFirstResponder {
    return NO; }

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
    return NO; }
    

- (void)drawRect:(NSRect)rect {
    
    [[NSColor colorWithDeviceRed:0.015 green:0.0 blue:0.03 alpha:1.0] set];
    
    [[NSBezierPath bezierPathWithRect:rect] fill];
}

@end
