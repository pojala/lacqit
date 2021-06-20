//
//  LQGCanvasController_cocoa.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.1.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCommonUIController.h"
@class LQCairoBitmap;


@interface LQGCanvasController_cocoa : LQGCommonUIController {

    NSSize _size;
}

- (void)setCanvasSize:(NSSize)size;
- (NSSize)canvasSize;

- (LQCairoBitmap *)cairoBitmap;

@end
