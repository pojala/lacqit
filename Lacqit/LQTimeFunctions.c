/*
 *  LQTimeFunctions.c
 *  Lacqit
 *
 *  Created by Pauli Ojala on 12.1.2009.
 *  Copyright 2009 Lacquer oy/ltd. All rights reserved.
 *
 */

#include "LQTimeFunctions.h"
#include <Lacefx/LXBasicTypes.h>
#include <Lacefx/LXStringUtils.h>



#pragma mark --- OS spinlock ---

#ifdef __WIN32__

#include <windows.h>
#include <process.h>

// this is a basic spinlock implemented with the CPU compare and swap primitive
// (directly based on Cocotron's NSZone.m)

typedef unsigned int OSSpinLock;


// __sync_bool_compare_and_swap requires 486+ CPU,
// so this project must include e.g.  -march=i686 in its C compilation flags

char OSSpinLockTry( volatile OSSpinLock *__lock )
{
   return __sync_bool_compare_and_swap(__lock, 0, 1);
}

void OSSpinLockLock( volatile OSSpinLock *__lock )
{
   while( !__sync_bool_compare_and_swap(__lock, 0, 1))
   {
#ifdef __WIN32__
      Sleep(0);
#else
      usleep(1);
#endif
   }
}

void OSSpinLockUnlock( volatile OSSpinLock *__lock )
{
   __sync_bool_compare_and_swap(__lock, 1, 0);
}

#endif


#pragma mark --- Apple implementation ---

#ifdef __APPLE__

#import <QuartzCore/QuartzCore.h>

double LQReferenceTimeGetCurrent()
{
    return CACurrentMediaTime();
}

#endif


#pragma mark --- Win32 implementation ---

#ifdef __WIN32__

#include <windows.h>


// platform lock defined and initialized in LacqitInit.m
extern CRITICAL_SECTION *g_lqLock_reftime;
#define REFTIME_LOCK      EnterCriticalSection(g_lqLock_reftime);
#define REFTIME_UNLOCK    LeaveCriticalSection(g_lqLock_reftime);

//OSSpinLock g_winRefTimeLock = 0;
//#define REFTIME_LOCK    OSSpinLockLock(&g_winRefTimeLock);
//#define REFTIME_UNLOCK  OSSpinLockUnlock(&g_winRefTimeLock);




double g_winRefTime = -1.0;
DWORD g_winPrevW32Time = 0;

HANDLE g_winRefTimeThreadH = NULL;
double g_winRefTimeFromThread = -1.0;
LXInteger g_winRefTimeThreadMsg = 0;


double LQReferenceTimeGetCurrent()
{
    double retVal = -1.0;

    REFTIME_LOCK
    
    if (g_winRefTimeThreadH != NULL) {
        // the timer thread is active, so we can get the reference time from it
        retVal = g_winRefTimeFromThread;
    }
    REFTIME_UNLOCK
        
    if (retVal != -1.0)
        return retVal;
    

    REFTIME_LOCK
    
    DWORD w32time_ms = timeGetTime();   // Win32 "multimedia" timer API; value is in milliseconds

    // the time value returned by timeGetTime is a DWORD and so it can wrap around;
    // MSDN says we must always use the difference between two values.
    
    if (g_winRefTime == -1.0) {
        // this is the first call to this function
        g_winRefTime = (double)w32time_ms / 1000.0;        
    }
    else {
        DWORD diff = w32time_ms - g_winPrevW32Time;
        
        if (diff != 0)
            g_winRefTime += (double)diff / 1000.0;
    }
    g_winPrevW32Time = w32time_ms;
    
    retVal = g_winRefTime;
    
    REFTIME_UNLOCK
    return retVal;
}


// ---- thread that updates the reference time ---


unsigned __stdcall timerThreadMainLoop(void *args) 
{
    LXPrintf("entered timer thread\n");
    //
    //LXInteger i;
    //for (i = 0; i < 50; i++)
    //    LXPrintf("hello from Win32 thread! (%i)\n", (int)GetCurrentThreadId());

    // restrict the thread to the primary CPU on a multi-proc system
    DWORD_PTR affRes = 0;
    if (0 == (affRes = SetThreadAffinityMask(GetCurrentThread(), (DWORD_PTR)0x01))) {
        LXPrintf("** unable to set thread affinity mask for timer (win32 error is %i)\n", (int)GetLastError());
    }
    
    // lower its priority to prevent CPU burn
    if (0 == SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_IDLE)) {
        LXPrintf("*** unable to set thread priority for timer (win32 error is %i)\n", (int)GetLastError());
    }

    LARGE_INTEGER freqLI;
    freqLI.QuadPart = 0;   // "QuadPart" is an int64
    QueryPerformanceFrequency(&freqLI);

    LARGE_INTEGER tLI;
    tLI.QuadPart = 0;
    QueryPerformanceCounter(&tLI);
    
    if (freqLI.QuadPart == 0 || tLI.QuadPart == 0) {
        LXPrintf("*** performance counter doesn't work, can't run timer thread\n");
        return 0;
    }
    
    
    const DWORD startW32Time_ms = timeGetTime();   // Win32 "multimedia" timer API; value is in milliseconds
    const double startRefTime = (double)startW32Time_ms / 1000.0;

    const double ticksPerSec = (double)freqLI.QuadPart;
    
    const int64_t ticksAtStart = tLI.QuadPart;
    
    LXInteger n = 0;
    while (1) {
        // this will keep one CPU core running at 100% in Windows's perf monitor -- laptop users will hate it
        Sleep(0);
        n++;
        
        QueryPerformanceCounter(&tLI);
        
        int64_t countNow = tLI.QuadPart;
        int64_t tickDiff = countNow - ticksAtStart;
        
        double newRefTime = startRefTime + ((double)tickDiff / ticksPerSec);
        
        /*if (n % 200 == 199) {
            LXPrintf("refTime now: %f\n", newRefTime);
        }*/
        
        LXInteger threadMsg = 0;
        
        REFTIME_LOCK
        {
            g_winRefTimeFromThread = newRefTime;
    
            threadMsg = g_winRefTimeThreadMsg;
            if (threadMsg != 0) {
                g_winRefTimeThreadMsg = 0;
            }
        }
        REFTIME_UNLOCK
        
        if (threadMsg != 0)  break;
    }

// --- exit thread
    g_winRefTimeFromThread = -1.0;
    
    _endthreadex(0);
    return 0;
}

void LQWin32ReferenceTime_StartThread()
{
    if (g_winRefTimeThreadH) {
        return;
    }
    
    if (g_lqLock_reftime == NULL) {
        LXPrintf("*** %s: framework has not been initialized yet\n", __func__);
        return;
    }

    unsigned int threadID = 0;

/*
    HANDLE hStdout;
    hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

    char testStr[] = "jotain jotain\n";
    DWORD nWritten = 0;
    if (0 == WriteConsoleA(hStdout, testStr, strlen(testStr), &nWritten, NULL))
        LXPrintf("** write console failed (win32 err: %i)\n", (int)GetLastError());
*/
    LXPrintf("...creating timer thread...\n");

    HANDLE hth = ///CreateThread(NULL, 0, timerThreadMainLoop, NULL, 0, &threadID);
                 (HANDLE)_beginthreadex(NULL, 0, timerThreadMainLoop, NULL, 0, &threadID);

    if ( !hth) {
        LXPrintf(".... oh no! failed to create timer thread\n");
        exit(1);
    }

    g_winRefTimeThreadH = hth;
    Sleep(10);

    //LXInteger i;
    //for (i = 0; i < 50; i++)
    //    LXPrintf("... created win32 thread with id %i (this thread is %i)\n", threadID, (int)GetCurrentThreadId());
}

void LQWin32ReferenceTime_StopThread()
{
    if (g_winRefTimeThreadH) {
        HANDLE hth = g_winRefTimeThreadH;

        REFTIME_LOCK
        
        g_winRefTimeThreadMsg = 1;  // this will cause the thread to exit
        g_winRefTimeThreadH = NULL;
        
        REFTIME_UNLOCK
        
        WaitForSingleObject(hth, INFINITE);        
        CloseHandle(hth);
    }
}


// --- usleep ---

static int sleepUsingThread(uint32_t microseconds)
{
    // check if the timer thread is running
    BOOL didSleepUsingThreadTime = NO;
    
    REFTIME_LOCK
    
    if (g_winRefTimeThreadH != NULL) {
        // the timer thread is active, so we can get the reference time from it
        double timeNow = g_winRefTimeFromThread;
        double startTime = timeNow;
        
        REFTIME_UNLOCK
        
        double endTime = startTime + ((double)microseconds / 1000000.0);
        
        if (microseconds >= 2000) {
            uint32_t millisecs = (microseconds / 1000) - 1;  // subtract one because sleeping in Win32 is so unreliable

            if (millisecs >= 20)
                millisecs--;

            Sleep(millisecs);
        }
        
        REFTIME_LOCK
        timeNow = g_winRefTimeFromThread;
        REFTIME_UNLOCK
        
        if (timeNow > endTime) {
            LXPrintf("*** usleep using thread overshoot its target (sleeptime %i; overshot by %.3f ms)\n", microseconds,
                            (timeNow-endTime)*1000);
        }
        
        while (timeNow < endTime) {
            Sleep(0);
            REFTIME_LOCK
            timeNow = g_winRefTimeFromThread;
            REFTIME_UNLOCK
        }
        
        didSleepUsingThreadTime = YES;
        
        ///LXPrintf("slept using thread; time is now %f (sleep usecs %i)\n", timeNow, microseconds);
    } else {
        REFTIME_UNLOCK
    }

    return (didSleepUsingThreadTime) ? 0 : 1;
}



#define USE_PLAIN_WIN32SLEEP 0

int usleep(uint32_t microseconds)
{
    if (microseconds < 2) {
        Sleep(0);
        return 0;  // early exit
    }

#if (USE_PLAIN_WIN32SLEEP)
    Sleep((200+microseconds)/1000);
    return 0;
#endif

    if (sleepUsingThread(microseconds) == 0) {
        return 0;
    }


    // useful Win32 timing info: http://www.geisswerks.com/ryan/FAQS/timing.html
    BOOL okToMicroSleep = YES;

    LARGE_INTEGER freqLI;
    freqLI.QuadPart = 0;   // "QuadPart" is an int64
    QueryPerformanceFrequency(&freqLI);
        
    LARGE_INTEGER tLI;
    tLI.QuadPart = 0;
    int qpRet = 0;
    
    if (0 == (qpRet = QueryPerformanceCounter(&tLI)) || tLI.QuadPart == 0) {
        LXPrintf("*** can't query performance counter (returned %i; win32 error is %i)\n", qpRet, (int)GetLastError());
        okToMicroSleep = NO;
    }
    if (freqLI.QuadPart == 0) {
        LXPrintf("*** system frequency is 0\n");
        okToMicroSleep = NO;
    }

    // Windows sleep has 1-2 millisec resolution and is rather imprecise
    if (microseconds >= 2000) {
        uint32_t millisecs = (microseconds / 1000);  // could perhaps subtract one because sleeping in Win32 is so unreliable

        ///LXPrintf("%s: going to full sleep for %u millisecs, %u us left, time now: %f\n", __func__, millisecs, microseconds, LQReferenceTimeGetCurrent());
        
        Sleep(millisecs);
    }
    
    if ( !okToMicroSleep) {
        Sleep(0);
        return 0;
    }

/*
    // check if the timer thread is running
    BOOL didSleepUsingThreadTime = NO;
    REFTIME_LOCK
    
    if (g_winRefTimeThreadH != NULL) {
        // the timer thread is active, so we can get the reference time from it
        double timeNow = g_winRefTimeFromThread;
    }
    REFTIME_UNLOCK

    if (didSleepUsingThreadTime)
        return 0;
*/

    // for precision sleep, spin and periodically check perf counter
    const int64_t ticksAtStart = tLI.QuadPart;
    const int64_t ticksPerSec = freqLI.QuadPart;
    const int64_t expectedTicks = ticksAtStart + ((double)ticksPerSec * ((double)microseconds / 1000000.0));

    QueryPerformanceCounter(&tLI);
    int64_t countNow = tLI.QuadPart;
    const int64_t countAfterBigSleep = countNow;
    
    LXInteger n = 0;
    while (countNow < expectedTicks && n < 5000) {
        Sleep(0);
        n++;
        
        QueryPerformanceCounter(&tLI);
        countNow = tLI.QuadPart;
    }
/*    
    LXPrintf("%s .. freq count is %.0f, starting ticks is %.0f; after big sleep is %.0f; waiting total of %.0f ticks (now left %.0f)\n", __func__,
                (double)ticksPerSec, (double)ticksAtStart, (double)countAfterBigSleep, (double)(expectedTicks-ticksAtStart),
                (double)(expectedTicks-countAfterBigSleep)
                );
                    
    LXPrintf(" ... done, slept %i times\n", n);
*/
    ///LXPrintf("qp: %u / %u --> %.1f (%I64d)\n", tLI.u.LowPart, tLI.u.HighPart, (double)tLI.QuadPart, (int64_t)tLI.QuadPart);
    
/*
    if (microseconds > 0) {
        else if (freqLI.QuadPart > 0) {
        
            QueryPerformanceCounter(&tLI);
            
            int64_t countNow = tLI.QuadPart;
            const int64_t freq = freqLI.QuadPart;
            const int64_t origCount = countNow;
            const int64_t expectedCount = countNow + ((double)freq * ((double)microseconds / 1000000.0));
            
            LXInteger n = 0;
            while (countNow < expectedCount && n < 2000) {
                Sleep(0);
                n++;
                
                QueryPerformanceCounter(&tLI);
                countNow = tLI.QuadPart;
            }

            LXPrintf("%s .. freq count is %.0f, count now is %.0f; waiting for %.0f cycles\n", __func__, (double)freq, (double)origCount, (double)(expectedCount-origCount));
                    
            LXPrintf(" ... done, slept %i times; time now: %f\n", n, LQReferenceTimeGetCurrent());
        }
        else {
            Sleep(0);
        }
    }
*/
    return 0;
}

#endif
 
 
 