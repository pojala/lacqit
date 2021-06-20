//
//  LQSimpleBackgroundView.h
//  Lacqit
//
//  Created by Pauli Ojala on 27.12.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQSimpleBackgroundView : NSView {

    NSColor *_c;
    NSUInteger _compOp;
    
    NSColor *_bottomBorderC;
}

- (void)setBackgroundColor:(NSColor *)c;
- (NSColor *)backgroundColor;

- (void)setBottomBorderColor:(NSColor *)c;
- (NSColor *)bottomBorderColor;

@end
