//
//  LQNSValueAdditions.m
//  Lacqit
//
//  Created by Pauli Ojala on 17.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQNSValueAdditions.h"
#import <Lacefx/LXBasicTypeFunctions.h>


@implementation NSValue (LQNSValueAdditions)

+ (NSValue *)valueWithRGBA:(LXRGBA)rgba
{
    return [NSValue value:&rgba withObjCType:@encode(LXRGBA)];
}

- (LXRGBA)rgbaValue
{
    const char *type = [self objCType];
    const char *expType = @encode(LXRGBA);
    if ( !type || !expType || (0 != strcmp(type, expType))) {
        [NSException raise:NSInternalInconsistencyException format:@"invalid value type for -rgbaValue call (%s)", (type) ? type : "(null)"];
        return LXMakeRGBA(0, 0, 0, 0);
    }
    
    LXRGBA rgba;
    [self getValue:&rgba];
    return rgba;
}

@end
