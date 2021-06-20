/*
 *  LQTimeFunctions.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 12.1.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#ifndef _LQTIMEFUNCTIONS_H_
#define _LQTIMEFUNCTIONS_H_

#include "LacqitExport.h"
#include <stdint.h>
#include <Lacefx/LXStringUtils.h>


/*
This file defines:
    - a thread-safe reference time which should be monotonically increasing everywhere (uses CACurrentMediaTime on Mac)
    
    - usleep() (which is not available on MinGW;
      the Win32 implementation here uses a cpu timer query for microsecond precision)
        
    - a thread-safe printf (because there's no guarantees about the CRT on MinGW)
      -- note: this was moved into Lacefx/LXStringUtils.h
*/


// this is a convenience that can be used to make it clear that we're using the definition in this file
#define LQUSleep(usecs_)                usleep(usecs_)


#define LQPrintf(format, args...)          LXPrintf(format , ## args);


#ifdef __cplusplus
extern "C" {
#endif
 
LACQIT_EXPORT double LQReferenceTimeGetCurrent();

#if defined(__APPLE__)
 #include <unistd.h>

#elif defined(__WIN32__)

 LACQIT_EXPORT int usleep(uint32_t microseconds);
 
/*
 LACQIT_EXPORT int LQPrintf(const char * __restrict, ...);

 #define LQPrintf_i64(v_)                   LQPrintf("%I64d", v_);
*/  // ^^^these were moved to Lacefx/LXStringUtils.h


// platform-specific implementation:
// for more accurate timing on Win32, a separate timer thread can be run which polls the high-performance CPU timer.
// the downside of this approach is that the thread will peg one CPU at 100%,
// so it's not recommended to keep the thread running all the time.
//
// (when the thread is not running, LQReferenceTimeGetCurrent() will return values using the
// standard Win32 timer which has a 1-2 ms resolution.)
LACQIT_EXPORT void LQWin32ReferenceTime_StartThread();
LACQIT_EXPORT void LQWin32ReferenceTime_StopThread();


#else

  #error "No time function definitions for this platform yet"

#endif


#ifdef __cplusplus
}
#endif

#endif // LQTIMEFUNCTIONS_H