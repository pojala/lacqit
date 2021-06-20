//
//  LACDatamethods.h
//  Lacqit
//
//  Created by Pauli Ojala on 3.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LacqitExport.h"
#import "LACPatch.h"


@interface NSObject (LACDataMethods)

// user-visible type name
+ (NSString *)lacTypeID;

// user-visible description (e.g. when printing out a result)
- (NSString *)lacDescription;

@end

