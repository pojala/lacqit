//
//  LQCircleButton.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.8.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"


@interface LQCircleButton : NSButton {

    NSImage *_bgImage;
    LQInterfaceTint _tint;
    
    CGImageRef _bgImageMask;
    CGImageRef _buttonImageMask;
}

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end
