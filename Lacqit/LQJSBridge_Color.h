//
//  LQJSBridge_Color.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/LXBasicTypes.h>
#import <LacqJS/LacqJS.h>
#import "LQJSPatchMarshalling.h"


@interface LQJSBridge_Color : LQJSBridgeObject  <LQJSCopying, LQJSPatchMarshalling> {

    double _red, _green, _blue, _alpha;
}

/* values are internally stored as sRGB always.
   the methods without sRGB in their name are a remnant from before this change.
*/

- (id)initWithHTMLFormattedString:(NSString *)str
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (NSString *)htmlFormattedString;
- (NSString *)htmlFormattedSRGBString;

- (LXRGBA)rgba;
- (void)setRGBA:(LXRGBA)rgba;

- (LXRGBA)rgba_sRGB;
- (void)setRGBA_sRGB:(LXRGBA)rgba;

- (void)getRed:(double *)pR green:(double *)pG blue:(double *)pB alpha:(double *)pA;


- (id)copyIntoJSContext:(JSContextRef)dstContext;

@end
