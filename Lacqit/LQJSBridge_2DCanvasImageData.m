//
//  LQJSBridge_2DCanvasImageData.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.9.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_2DCanvasImageData.h"


@implementation LQJSBridge_2DCanvasImageData

- (id)initInJSContext:(JSContextRef)context size:(NSSize)size
{
    if (size.width < 1 || size.height < 1) {
        [self release];
        return nil;
    }

    self = [super initInJSContext:context withOwner:nil];
    if (self) {
        _bitmap = [[LQCairoBitmap alloc] initWithSize:size];
    }
    return self;
}

- (void)dealloc
{
    [_bitmap release];
    [super dealloc];
}

- (LQCairoBitmap *)cairoBitmap {
    return _bitmap; }


+ (NSString *)constructorName
{
    return @"<CanvasImageData>"; // can't be constructed
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects:@"width", @"height", @"data",
                                     nil];
}

- (LXInteger)width {
    return [_bitmap width];
}

- (LXInteger)height {
    return [_bitmap height];
}

- (id)data
{
    if ( !_pixelDataObj) {
    
    }
    return _pixelDataObj;
}

@end
