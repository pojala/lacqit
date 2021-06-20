//
//  LQOverflowBox.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQThemedBox.h"


@interface LQOverflowBox : LQThemedBox {

    double _contentMinW;
    
    NSString *_overflowLabel;
    
    NSMenu *_overflowMenu;
}

- (double)contentOverflowMinWidth;
- (void)setContentOverflowMinWidth:(double)w;

- (NSString *)overflowLabel;
- (void)setOverflowLabel:(NSString *)str;

- (NSMenu *)overflowMenu;
- (void)setOverflowMenu:(NSMenu *)menu;

@end
