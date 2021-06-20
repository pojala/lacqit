//
//  main.m
//  PixelMath
//
//  Created by Pauli Ojala on 23.6.2008.
//  Copyright Lacquer oy/ltd 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXPlatform.h>
#import <Lacqit/LacqitInit.h>
#import <cairo/cairo.h>


int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int initResult = 0;

#ifdef __WIN32__

    LXVersion lxVer = LXLibraryVersion();
    NSLog(@"Cairo version is %s, Lacefx version is %i.%i.%i", cairo_version_string(), lxVer.majorVersion, lxVer.minorVersion, lxVer.milliVersion);

    void *lxMallocedBuf = _lx_malloc(128);
    NSLog(@"... lx malloced buf is: 0x%p (should be 16-byte aligned: %s)", lxMallocedBuf, (((LXUInteger)lxMallocedBuf & 15) == 0) ? "yes" : "FAIL");

    NSLog(@"a constant string from Lacefx DLL: %s", kLXPixelBufferAttachmentKey_ColorSpaceEncoding);
    NSLog(@"a constant string from Lacqit DLL: %s", kLacqitVersionString);
#endif

    if (0 != (initResult = LacqitInitialize(0, NULL))) {
        NSLog(@"*** Lacqit init failed: %i", initResult);
        exit(1);
    }

    [pool drain];

    return NSApplicationMain(argc,  (const char **) argv);
}
