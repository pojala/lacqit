//
//  LQDynModule.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __WIN32__
#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0501  // require WinXP+
#endif
#import <Windows.h>
#endif


@interface LQDynModule : NSObject {

    NSURL *_url;

#if defined(__APPLE__)
    CFBundleRef _bundle;
    
#elif defined(__WIN32__)    
    HMODULE _hmodule;
    
#else
#error "unsupported OS for LQ plugins"

#endif
}


+ (LQDynModule *)moduleWithURL:(NSURL *)url;

- (void *)functionPointerForName:(NSString *)name;

- (NSURL *)url;

// these are only valid for bundle-style modules that are accessed with file URLs
- (NSString *)executablePath;
- (NSString *)resourcePath;

@end
