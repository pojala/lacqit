//
//  LQSimpleImageView.h
//  Lacqit
//
//  Created by Pauli Ojala on 13.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface LQSimpleImageView : NSView {

    NSImage *_image;
    
    CGFloat _opacity;
}

- (void)setImage:(NSImage *)image;
- (NSImage *)image;

- (void)setAlphaValue:(CGFloat)opacity;
- (CGFloat)alphaValue;

@end
