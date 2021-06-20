//
//  LQGUITextField.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGUIControl.h"


@interface LQGUITextField : LQGUIControl {

    LXUInteger _lqFieldType;
}

// charW can be zero for default width

+ (id)textFieldWithWidthInCharacters:(NSInteger)charW
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action;

+ (id)numberScrubFieldWithWidthInCharacters:(NSInteger)charW
                        name:(NSString *)name
                     context:(NSString *)context
                      target:(id)target
                      action:(SEL)action;


// a label resizes automatically to fill its content,
// also when -setStringValue: is called
+ (id)labelWithString:(NSString *)str
                        name:(NSString *)name
                     context:(NSString *)context;

@end
