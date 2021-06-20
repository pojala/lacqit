//
//  LQXLabel.h
//  Lacqit
//
//  Created by Pauli Ojala on 5.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LQCGBitmap.h"


// this implementation uses Quartz.
// a Lagoon version would need to be rewritten for Cairo/Pango


@interface LQXLabel : LQCGBitmap {

    NSDictionary *_attributes;
}

+ (NSDictionary *)darkTitleTextAttributes;
+ (NSDictionary *)lightTitleTextAttributes;

+ (NSDictionary *)browserHeaderTextAttributes;
+ (NSDictionary *)browserItemTextAttributes;

+ (NSDictionary *)whiteOverlayTextAttributes;

- (id)initWithString:(NSString *)str attributes:(id)attrs;

- (void)drawInSurface:(LXSurfaceRef)lxSurface atPoint:(NSPoint)origin;
- (void)drawInSurface:(LXSurfaceRef)lxSurface atCenterPoint:(NSPoint)center;

@end
