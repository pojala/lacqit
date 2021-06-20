//
//  LQTextField.m
//  Lacqit
//
//  Created by Pauli Ojala on 21.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQTextField.h"


@implementation LQTextField

- (BOOL)becomeFirstResponder
{
    BOOL ok = [super becomeFirstResponder];
    
    if (ok && [[self delegate] respondsToSelector:@selector(textFieldDidBecomeFirstResponder:)]) {
        [(id)[self delegate] textFieldDidBecomeFirstResponder:self];
    }
    return ok;
}

@end
