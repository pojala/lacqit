//
//  LACDatamethods.m
//  Lacqit
//
//  Created by Pauli Ojala on 3.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LACDataMethods.h"


NSString *LACTypeIDFromObject(id obj)
{
    if ([obj isKindOfClass:[NSNull class]])
        return @"null";
    else if ([obj isKindOfClass:[NSNumber class]])
        return @"Number";
    else if ([obj isKindOfClass:[NSString class]])
        return @"String";
    else if ([obj isKindOfClass:[NSData class]])
        return @"Data";
    else if ([obj isKindOfClass:[NSDate class]])
        return @"Date";
        
    Class cls = [obj class];
    NSString *lacID = nil;
    
    if ([cls respondsToSelector:@selector(lacTypeID)] && (lacID = [cls lacTypeID]) && ![lacID isEqualToString:@"id"])
        return lacID;
    else
        return NSStringFromClass(cls);
}


@implementation NSObject (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"id"; }

- (NSString *)lacDescription {
    return [NSString stringWithFormat:@"(%@, %p)", [[[self class] lacTypeID] lowercaseString], self]; }
    
@end


@implementation NSString (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"String"; }

- (NSString *)lacDescription {
    return [self description]; }
    
@end


@implementation NSNumber (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"Number"; }

- (NSString *)lacDescription {
    return [self description]; }
    
@end


@implementation NSArray (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"Array"; }

@end


@implementation NSDictionary (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"Dictionary"; }

@end


@implementation NSMutableArray (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"MutableArray"; }

@end


@implementation NSMutableDictionary (LACDataAdditions)

+ (NSString *)lacTypeID {
    return @"MutableDictionary"; }

@end
