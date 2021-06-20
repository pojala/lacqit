/*
 *  LQBaseFrameworkHeader.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 24.1.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

#if defined(__COCOTRON__) || (defined(__APPLE__) && (__LP64__ || (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5)))
#define LQPLATFORM_IS_LIKE_NS64 1
#endif


#import <Lacefx/LXBasicTypes.h>

#import "LQTimeFunctions.h"


#if !defined(NSINTEGER_DEFINED) && !defined(LQPLATFORM_IS_LIKE_NS64)
 typedef LXInteger NSInteger;
 typedef LXUInteger NSUInteger;
 #define NSINTEGER_DEFINED 1
#endif

#if !defined(CGFLOAT_DEFINED) && !defined(LQPLATFORM_IS_LIKE_NS64)
 typedef LXFloat CGFloat;
 #define CGFLOAT_DEFINED 1
#endif

