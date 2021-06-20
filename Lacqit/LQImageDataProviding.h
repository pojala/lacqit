/*
 *  LQImageDataProviding.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 24.1.2012.
 *  Copyright 2012 Lacquer oy/ltd. All rights reserved.
 *
 */
 
#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>


@protocol LQImageDataProviding

- (void)addImageDataCallback:(LXGenericImageDataCallbackPtr)callback userData:(void *)userData;

- (void)removeImageDataCallback:(LXGenericImageDataCallbackPtr)callback;

@end
