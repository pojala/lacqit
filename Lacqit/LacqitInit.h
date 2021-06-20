//
//  LacqitInit.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#ifndef _LACQIT_INIT_H_
#define _LACQIT_INIT_H_

#include "LacqitExport.h"


#ifdef __cplusplus
extern "C" {
#endif

LACQIT_EXPORT_CONSTVAR char * const kLacqitVersionString;


// calling this in application main ensures that the library is linked
LACQIT_EXPORT int LacqitInitialize(int argc, char *argv[]);

// call this when app finished to prevent stuff like COM components from hanging around
LACQIT_EXPORT void LacqitDeinitialize();


#ifdef __OBJC__
// currently only checks the JavaScriptCore framework version;
// if returns NO, the string arguments are filled with a message to display.
LACQIT_EXPORT BOOL LacqitCheckVersionOfSystemFrameworkDependencies(NSString **alertMsg, NSString **alertInfoMsg);
#endif


#ifdef __cplusplus
}
#endif


#ifdef __OBJC__
#define LQInvalidAbstractInvocation() \
                [NSException raise:NSInvalidArgumentException \
                    format:@"-%s only defined for abstract class (%@)", __func__, self]
#endif


#endif

