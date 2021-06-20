//
//  LQJSBridge_LXShader.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LXShader.h"
#import <Lacefx/LXShaderUtils.h>


@implementation LQJSBridge_LXShader



- (id)initWithLXShader:(LXShaderRef)shader
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _shader = LXShaderRetain(shader);
    }
    return self;
}

- (void)dealloc
{
    LXShaderRelease(_shader);
    [super dealloc];
}

- (LXShaderRef)lxShader {
    return _shader; }
    
    
- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj = [[[self class] alloc] initWithLXShader:[self lxShader]
                                            inJSContext:dstContext
                                            withOwner:nil];
    return [newObj autorelease];
}


+ (NSString *)constructorName {
    return @"Shader";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] == 1) {
        id arg = [arguments objectAtIndex:0];

        LXShaderRelease(_shader);
        _shader = NULL;
        
        if ([arg respondsToSelector:@selector(lxShader)]) {
            _shader = LXShaderCopy([arg lxShader]);
        }
        else {
            NSString *str = [arg description];
            
            // preset template shaders
            if ([str isEqualToString:@"solid-color"] || [str isEqualToString:@"color"]) {
                _shader = LXCreateShader_SolidColor();
            }
            else if ([str isEqualToString:@"mask-with-red-channel"]) {
                _shader = LXCreateMaskShader_MaskWithRed();
            }
            else if ([str isEqualToString:@"mask-with-alpha-channel"]) {
                _shader = LXCreateMaskShader_MaskWithAlpha();
            }
            else if ([str isEqualToString:@"composite-over"]) {
                _shader = LXCreateCompositeShader_OverOp_Premult();
            }
            else if ([str isEqualToString:@"composite-over-with-opacity-param"]) {
                _shader = LXCreateCompositeShader_OverOp_Premult_Param();
            }
            else if ([str isEqualToString:@"composite-over-with-mask-texture"]) {
                _shader = LXCreateCompositeShader_OverOp_Premult_MaskWithRed();
            }
            else {
                const char *ss = [str UTF8String];
                LXDECLERROR(err);
                LXShaderRef newShader = LXShaderCreateWithString(ss, (ss) ? strlen(ss) : 0, kLXShaderFormat_OpenGLARBfp, 0, &err);
        
                if ( !newShader) {
                    NSLog(@"** failed to set shader program from JS call: error %i (%s)", err.errorID, err.description);
                    LXErrorDestroyOnStack(err);
                } else {
                    _shader = newShader;
                }
            }
        }
    }
    
    if ( !_shader) {
        // default to solid color shader if argument count is invalid
        _shader = LXCreateShader_SolidColor();
    }
}


+ (NSArray *)objectPropertyNames {
    return [NSArray array];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName {
    return NO;
}

+ (NSArray *)objectFunctionNames {
    return [NSArray array];
}

@end
