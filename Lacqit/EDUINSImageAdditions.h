//
//  EDUINSImageAdditions.h
//  PixelMath
//
//  Created by Pauli Ojala on 27.11.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/LXBasicTypes.h>


@interface NSImage ( EDUINSImageAdditions )

// configurable image search paths.
// this is required for Conduit plugins which need to find images in
// bundles other than the main bundle
+ (NSImage *)imageInBundleWithName:(NSString *)name;
+ (void)addBundleForImageSearch:(NSBundle *)bundle;
+ (void)addPathForImageSearch:(NSString *)path;


#if !defined(__LAGOON__)
+ (NSImage *)verticalRoundGradientImageWithStartRGBA:(LXRGBA)rgba1 endRGBA:(LXRGBA)rgba2
             height:(int)h exponent:(float)exp;
#endif

// -- testing --
+ (NSString *)eduiCategoryTestClassMeth;

@end
