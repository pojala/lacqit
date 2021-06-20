//
//  LQColoredLabel.h
//  Lacqit
//
//  Created by Pauli Ojala on 7.10.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
@class LQGradient;


@interface LQColoredLabel : NSTextField {

    NSColor *_bgColor;
    
    LQGradient *_bgGrad;
}

- (void)setBaseColor:(NSColor *)color;

@end
