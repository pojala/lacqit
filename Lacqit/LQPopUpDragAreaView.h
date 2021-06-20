//
//  LQPopUpDragAreaView.h
//  ConduitLive2
//
//  Created by Pauli Ojala on 30.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQPopUpDragAreaView : NSView {

    NSString *_title;
}

- (void)setTitle:(NSString *)title;
- (NSString *)title;

@end
