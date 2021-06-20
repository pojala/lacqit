//
//  LQTextField.h
//  Lacqit
//
//  Created by Pauli Ojala on 21.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"

/*
  This subclass adds delegate methods to NSTextField.
*/

@interface LQTextField : NSTextField {

}

@end


@interface NSObject (LQTextFieldDelegate)
- (void)textFieldDidBecomeFirstResponder:(id)field;
@end