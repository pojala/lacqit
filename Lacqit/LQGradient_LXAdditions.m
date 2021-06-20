//
//  LQGradient_LXAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGradient_LXAdditions.h"

typedef struct LQGradientElement {
	CGFloat red, green, blue, alpha;
	CGFloat position;
	struct LQGradientElement *nextElement;
} LQGradientElement;


@interface LQGradient (Private)
- (LQGradientElement *)elementAtIndex:(unsigned)index;
@end


static NSString *constantStringFromRGBA(float r, float g, float b, float a)
{
    return [NSString stringWithFormat:@"{ %f, %f, %f, %f }", r, g, b, a];
}


@implementation LQGradient (LXAdditions)

- (LXShaderRef)createLXShaderWithAngle:(LXFloat)angle gamma:(LXFloat)gamma
{
    LXDECLERROR(err);
    LQGradientElement *el1 = [self elementAtIndex:0];
    LQGradientElement *el2 = [self elementAtIndex:1];
    
    if ( !el1)
        return NULL;
    
    NSMutableString *str = [NSMutableString stringWithString:@"!!ARBfp1.0\nTEMP t1;"];
                
    if ( !el2) {
        [str appendFormat:@"MOV result.color, %@;", constantStringFromRGBA(el1->red, el1->green, el1->blue, el1->alpha)];
    }
    else {
        NSString *c1 = constantStringFromRGBA(el1->red, el1->green, el1->blue, el1->alpha);
        NSString *c2 = constantStringFromRGBA(el2->red, el2->green, el2->blue, el2->alpha);
        NSString *texCoordVar;
        NSString *s;
        NSString *e;
        
        angle = fmod(angle, 360);
        
        if (angle >= 0.0 && angle < 90.0) {
            texCoordVar = @"fragment.texcoord[0].x";
            s = c1;
            e = c2;
        } else if (angle >= 90.0 && angle < 180.0) {
            texCoordVar = @"fragment.texcoord[0].y";
            s = c1;
            e = c2;
        } else if (angle >= 180.0 && angle < 270.0) {
            texCoordVar = @"fragment.texcoord[0].x";
            s = c2;
            e = c1;
        } else {
            texCoordVar = @"fragment.texcoord[0].y";
            s = c2;
            e = c1;        
        }
    
        [str appendFormat:@"LRP_SAT t1, %@, %@, %@;", texCoordVar, s, e];
    }
    
    if (gamma != 1.0 && gamma > 0.001) {
        [str appendFormat:@"POW_SAT t1.r, t1.r, %f;", gamma];
        [str appendFormat:@"POW_SAT t1.g, t1.g, %f;", gamma];
        [str appendFormat:@"POW_SAT t1.b, t1.b, %f;", gamma];
        [str appendFormat:@"POW_SAT t1.a, t1.a, %f;", gamma];
    }
    
    //[str appendString:@"MUL t1.rgb, t1, t1.a;"];
    [str appendString:@"MOV result.color, t1; "];
    
    [str appendString:@"END"];
    
    const char *cstr = [str UTF8String];
    
    LXShaderRef shader = LXShaderCreateWithString(cstr, strlen(cstr), kLXShaderFormat_OpenGLARBfp,  0, &err);
    if ( !shader) {
        NSLog(@"** %s failed: %i (%s)", __func__, err.errorID, err.description);
    }

    return shader;
}

@end
