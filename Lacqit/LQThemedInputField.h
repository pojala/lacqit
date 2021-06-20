//
//  LQThemedInputField.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQUIConstants.h"
#import "LQTextField.h"


@interface LQThemedInputField : LQTextField {

    LXUInteger _interfaceTint;
}

+ (CGFloat)fieldHeightForControlSize:(LXUInteger)controlSize;

- (void)setInterfaceTint:(LQInterfaceTint)tint;
- (LQInterfaceTint)interfaceTint;

@end
