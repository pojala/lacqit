//
//  LacqitTestView.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LQCairoBitmap, LQCGBitmap;
@class LQLXPixelBuffer;


@interface LacqitTestView : NSView {

    LQCairoBitmap *_cairoBitmap;
    
    LQCGBitmap *_cgBitmap;
    
    LQLXPixelBuffer *_pixbuf;
}

@end
