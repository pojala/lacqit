//
//  LacqitInit.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LacqitInit.h"
#import "LQCapsuleWrapper.h"
#import "LQLXPixelBuffer.h"
#import "LQLXBasicFunctions.h"

#import <Cairo/cairo.h>

#import <LacqJS/LacqJS.h>
#import <Lacefx/LXPlatform.h>


const char * const kLacqitVersionString = "1.0.0";



#pragma mark --- Win32 init ---

#ifdef __WIN32__

#include <windows.h>

// platform-specific locks
static CRITICAL_SECTION s_lqLock_reftime;
CRITICAL_SECTION *g_lqLock_reftime = NULL;


#ifdef __COCOTRON__
// 2010.09.16 -- this selects the system font for Cocotron's AppKit.
// this patch was implemented by Pauli, it's not in the Cocotron mainline.
// 
static void setupWindowsFontsForCocotronUI()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    ///NSLog(@"---available fonts: %@", [[NSFontManager sharedFontManager] availableFonts]);

    NSArray *fontList = [NSArray arrayWithObjects:@"Segoe UI", @"Tahoma", nil];
    [[NSUserDefaults standardUserDefaults] setObject:fontList forKey:@"org.cocotron.CTFont.preferredSystemFontFamilies"];

    [pool drain];
}
#endif
 

static void initWinAPIs()
{
    NSLog(@"Lacqit: %s", __func__);
    
    // initializes COM
    ///CoInitializeEx(NULL, COINIT_MULTITHREADED);
    OleInitialize(NULL);
    
    // increases resolution of timeGetTime and Sleep calls (requires linking against winmm.lib)
    timeBeginPeriod(1);
    
    // a native lock for the refTime counter thread
    InitializeCriticalSection(&s_lqLock_reftime);
    g_lqLock_reftime = &s_lqLock_reftime;

    #ifdef __COCOTRON__
    setupWindowsFontsForCocotronUI();
    #endif
}

static void deinitWinAPIs()
{
    timeEndPeriod(1);

    OleUninitialize();
}
#endif  // __WIN32__



#pragma mark --- shared init ---

static int g_lacqInited = NO;

int LacqitInitialize(int argc, char *argv[])
{
    if (g_lacqInited) return 0;

    if (sizeof(LQCapsuleFileHeader) != kLQCapsuleHeaderSize) {
        NSLog(@"** invalid capsule header size on this platform (struct alignment differs: %ld, expected %ld)", sizeof(LQCapsuleFileHeader), (long)kLQCapsuleHeaderSize);
        return 501;
    }
    
    if (0 != LacqJSInitialize()) {
        NSLog(@"** failed to initialize LacqJS, can't continue");
        return 502;
    }
    
    // init static data as early as possible
    [LQLXPixelBuffer placeholderPixelBuffer];
    
    
    // ---- Lacefx library version check ----
    LXVersion lxVer = LXLibraryVersion();
    // looking for v86.0; this check last modified 2013.04.07
    if (lxVer.majorVersion < 1 || (lxVer.majorVersion == 1 && lxVer.minorVersion == 0 && lxVer.milliVersion < 86)) {
        NSLog(@"*** Lacefx framework is out of date: %d.%d.%d", lxVer.majorVersion, lxVer.minorVersion, lxVer.milliVersion);
        return 503;
    }
    
    // ---- LacqJS version check ----
    double lqjsVer = LQJSKitVersionNumber;
    if (lqjsVer < 63.0) {
        NSLog(@"*** LacqJS framework is out of date (version is %.1f / '%@')", lqjsVer, LQJSKitVersionString);
        return 504;
    }
    
    // ---- Cairo version check ----
    NSLog(@"LQ framework: Cairo version is %s, Lacefx version is %i.%i.%i", cairo_version_string(),
                                    lxVer.majorVersion, lxVer.minorVersion, lxVer.milliVersion);
    

    
    // ---- basic unit test for Lacefx<->Foundation API compatibility ----
    NSDictionary *origDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"abc öä 123", @"scandic utf8",
                                            [NSNumber numberWithDouble:123.456], @"floatti",
                                            [NSNumber numberWithInt:12345], @"intti",
                                            [NSNumber numberWithBool:YES], @"jees",
                                            nil];
    LXMapPtr map = LXMapCreateFromNSDictionary(origDict);
    LXBool b = 0;
    double d = 0;
    LXMapGetBool(map, "jees", &b);
    LXMapGetDouble(map, "floatti", &d);
    if (b != YES) NSLog(@"*** %s: map test failed, bool", __func__);
    if (d != 123.456) NSLog(@"*** %s: map test failed, double (%f)", __func__, d);
    
    
    // ---- JavaScript interpreter test ----
    LQJSContainer *js = [[LQJSContainer alloc] initWithName:@"__lacqitInitTest"];
    double jt0 = LQReferenceTimeGetCurrent();
    
    if ( ![js setScript:@"return 'twentynine=' + (arg1 + 9);"
                  forKey:@"testFunc"
         parameterNames:[NSArray arrayWithObjects:@"arg1", nil]]) {
        NSLog(@"** %s: could not set script in JS test", __func__);
    } else {
        double jt1 = LQReferenceTimeGetCurrent();
        id jsResult = nil;
        BOOL ok = [js executeScriptForKey:@"testFunc"
                           withParameters:[NSArray arrayWithObjects:[NSNumber numberWithInt:20], nil]
                                 resultPtr:&jsResult];
        if ( !ok) {
            NSLog(@"** %s: could not execute script in JS test", __func__);
        } else {
            if ( ![jsResult isEqualToString:@"twentynine=29"]) {
                NSLog(@"** %s: JS test did not produce expected result: is %@ / '%@'", __func__, [jsResult class], jsResult);
            } else {
                NSLog(@"LQ framework scripting test ok, time %.3f ms", 1000*(LQReferenceTimeGetCurrent() - jt0));
            }
        }
    }
    [js release];
    
    
    // ... could do some check for capsule encryption integrity ....


#ifdef __WIN32__
    initWinAPIs();
#endif

    g_lacqInited = YES;
    return 0;
}


void LacqitDeinitialize()
{
    if (g_lacqInited) {
        #ifdef __WIN32__
        deinitWinAPIs();
        #endif    
        
        g_lacqInited = NO;
    }
}


BOOL LacqitCheckVersionOfSystemFrameworkDependencies(NSString **alertMsg, NSString **alertInfoMsg)
{
    
#ifdef __APPLE__
    NSBundle *jscBundle = [NSBundle bundleWithIdentifier:@"com.apple.JavaScriptCore"];
    NSString *jscPath = [jscBundle bundlePath];
    NSString *versionStr = [jscBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    double versionD = [versionStr doubleValue];
    double expVersion = 5531.21;  // Safari 4.0.4
    
    //NSLog(@"%s: JSC path %@, version %@", __func__, jscPath, versionStr);
    
    if (versionD < expVersion && [jscPath hasPrefix:@"/System"]) {
        NSString *msg = @"System framework 'JavaScriptCore' is out of date. Please install the latest updates for Mac OS X and the Safari web browser.";
        
        NSString *info = [NSString stringWithFormat:@"Conduit uses Apple's JavaScriptCore framework. It appears that the version installed on your system is older "
                                                "than the minimum version required.\n\nBecause JavaScriptCore is included in the Safari web browser, you can fix this problem by "
                                                "installing the latest version of Safari using Software Update (in the Apple menu).\n\n"
                                                "You can still run this application now, but some fuctionality may not work correctly.\n\n"
                                                "(Your JavaScriptCore version is: %.2f)\n", versionD];
                                                
        if (alertMsg) *alertMsg = msg;
        if (alertInfoMsg) *alertInfoMsg = info;
        return NO;
    }
#endif
    
    return YES;
}



