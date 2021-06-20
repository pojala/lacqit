/*
 *  PixMathFrameworkHeader.h
 *  PixelMath
 *
 *  Created by Pauli Ojala on 30.7.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LQBaseFrameworkHeader.h"

#ifdef __LAGOON__
 #import <Lagoon/Lagoon_All.h>
#else
 #import <Cocoa/Cocoa.h>
#endif


#if defined(__COCOTRON__)
 #import <ApplicationServices/ApplicationServices.h> 
#endif


// platform features:

#if !defined(__LAGOON__)
 #define LQPLATFORM_QUARTZ 1   // CoreGraphics
#else
 #define LQPLATFORM_QUARTZ 0
#endif


