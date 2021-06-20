//
//  LQActiveTextField.h
//  PixelMath
//
//  Created by Pauli Ojala on 5.1.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LQActiveTextField : NSTextField {
    
    NSDictionary *_hiliteAttrs;

    BOOL        _hilite;
}

- (void)setHighlightAttributes:(NSDictionary *)attrs;
- (NSDictionary *)highlightAttributes;

@end
