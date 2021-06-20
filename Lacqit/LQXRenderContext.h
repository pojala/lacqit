//
//  PixMathRenderContext.h
//  PixelMath
//
//  Created by Pauli Ojala on 11.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXFPClosureContext.h>
#import "LQLXBasicFunctions.h"


/*
  This is a generic replacement for PixMathRenderContext,
  i.e. a simple collection of render state for conduits and other effects.

  Standard parameter names used by Conduit are provided as a convenience
  through the LQXStandardParamName() function (but they could also be constructed
  manually using the "Slider %i" pattern). They are enumerated starting from zero
  (even though Conduit traditionally counted sliders starting at 1).
*/

enum {
    kLQXStandardParamType_Slider = 0x100,
    kLQXStandardParamType_ColorPicker = 0x200,
};


LACQIT_EXPORT NSString *LQXStandardParamName(LXUInteger type, LXInteger index);


@interface LQXRenderContext : NSObject  <NSCopying> {

    NSMutableArray *_textures;

    NSMutableDictionary *_parameters;
    
    NSMutableDictionary *_vars;
}

// --- input textures (indexed) ---
- (LXInteger)numberOfTextureSlots;

- (LXTextureRef)lxTextureAtIndex:(LXInteger)index;
- (void)setLXTexture:(LXTextureRef)tex forIndex:(LXInteger)index;  // retains the texture

- (void)clearAllTextures;

- (LXTextureArrayRef)createLXTextureArray;
- (LXFPClosureContextPtr)createLXFPClosureContext;

- (void)takeTexturesFromLXTextureArray:(LXTextureArrayRef)texArray;

// --- parameters (named) ---
- (void)setDoubleValue:(double)v forParameterNamed:(NSString *)name;
- (void)setIntegerValue:(long)v forParameterNamed:(NSString *)name;
- (void)setBooleanValue:(BOOL)f forParameterNamed:(NSString *)name;
- (void)setRGBAValue:(LXRGBA)r forParameterNamed:(NSString *)name;

- (double)doubleValueForParameterNamed:(NSString *)name;
- (long)integerValueForParameterNamed:(NSString *)name;
- (BOOL)boolValueForParameterNamed:(NSString *)name;
- (LXRGBA)rgbaValueForParameterNamed:(NSString *)name;

- (BOOL)hasParameterNamed:(NSString *)name;

- (NSArray *)parameterNames;
- (NSDictionary *)parameterDictionary;

- (NSDictionary *)parameterPlistDictionary;
- (void)takeParametersFromPlistDictionary:(NSDictionary *)dict;

// utility for figuring out param base names: e.g. "SomePoint" -> "SomePoint.x" and "SomePoint.y".
// only returns strings that exist in "parameterNames"; yName is not necessarily filled out.
// xName and yName are always set to nil if this call returns NO.
- (BOOL)getParameterNamesForPoint:(NSString *)pointName xNamePtr:(NSString **)outXName yNamePtr:(NSString **)outYName;

// --- other properties (named) ---
- (void)setObject:(id)obj forProperty:(NSString *)property;
- (id)objectForProperty:(NSString *)property;
- (NSArray *)propertyKeys;

- (NSDictionary *)propertyDictionary;
- (void)addPropertiesFromDictionary:(NSDictionary *)dict;

@end
