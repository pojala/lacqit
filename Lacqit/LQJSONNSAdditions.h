//
//  NSLQJSONAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (LQJSONAdditions)

/**
 @brief Returns a string containing the receiver encoded as a JSON fragment.

 This method is added as a category on NSObject but is only actually
 supported for the following objects:
 @li NSDictionary
 @li NSArray
 @li NSString
 @li NSNumber (also used for booleans)
 @li NSNull 
 */
- (NSString *)lq_JSONFragment;

/**
 @brief Returns a string containing the receiver encoded in JSON.

 This method is added as a category on NSObject but is only actually
 supported for the following objects:
 @li NSDictionary
 @li NSArray
 */
- (NSString *)lq_JSONRepresentation;

- (NSString *)humanReadableJSONRepresentation;

@end

@interface NSString (LQJSONAdditions)

// Returns the object represented in the receiver, or nil on error. 
- (id)parseAsJSONFragment;

// Returns the dictionary or array represented in the receiver, or nil on error.
- (id)parseAsJSON;

@end

@interface NSArray (LQJSONAdditions)

+ (NSArray *)arrayFromJSON:(NSString *)jsonStr;
+ (NSArray *)arrayFromJSON:(NSString *)jsonStr error:(NSError **)error;

@end

@interface NSDictionary (LQJSONAdditions)

+ (NSDictionary *)dictionaryFromJSON:(NSString *)jsonStr;
+ (NSDictionary *)dictionaryFromJSON:(NSString *)jsonStr error:(NSError **)error;

@end
