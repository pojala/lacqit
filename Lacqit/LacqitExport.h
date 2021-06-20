/*
 *  LacqitExport.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 8.9.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

#ifndef __LACQIT_EXPORT__
#define __LACQIT_EXPORT__


#include <stdlib.h>

#if defined(__OBJC__)
#include <Foundation/Foundation.h>
#endif

#include <Lacefx/LXBasicTypes.h>


#ifdef __cplusplus
  #define LACQIT_EXTERN_CFUNC extern "C"
#else
  #define LACQIT_EXTERN_CFUNC
#endif



// export declaration for API functions
#if defined(LXPLATFORM_WIN)
  #ifdef LACQIT_INSIDE_BUILD
    #define LACQIT_EXPORT LACQIT_EXTERN_CFUNC __declspec(dllexport)
  #else
    #define LACQIT_EXPORT LACQIT_EXTERN_CFUNC __declspec(dllimport)
  #endif
#elif defined(__APPLE__)
    #define LACQIT_EXPORT LACQIT_EXTERN_CFUNC __attribute__ ((visibility("default")))
#else
  #ifdef HAVE_GCCVISIBILITYPATCH
    #define LACQIT_EXPORT LACQIT_EXTERN_CFUNC __attribute__ ((visibility("default")))
  #else
    #define LACQIT_EXPORT LACQIT_EXTERN_CFUNC
  #endif
#endif


// for variables that are exported from the DLL
#ifdef __cplusplus
#define LACQIT_EXPORT_VAR        LACQIT_EXPORT
#define LACQIT_EXPORT_CONSTVAR   LACQIT_EXPORT const
#else
#define LACQIT_EXPORT_VAR        LACQIT_EXPORT extern
#define LACQIT_EXPORT_CONSTVAR   LACQIT_EXPORT extern const
#endif

#endif // LACQIT_EXPORT
