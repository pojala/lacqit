//
//  LQDynModule.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQDynModule.h"


@implementation LQDynModule

- (id)initWithURL:(NSURL *)url
{
#if defined(__APPLE__)
    CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, (CFURLRef)url);
    
    if ( !bundle) {
        NSLog(@"** %s: can't read bundle at given URL (%@)", __func__, url);
        [self release];
        return nil;
    }
    _bundle = bundle;


#elif defined(__WIN32__)
    if ( ![url isFileURL]) {
        NSLog(@"** %s: can't open module from non-file URL (%@)", __func__, url);
        [self release];
        return nil;
    }
    
    NSString *path = [url path];
    NSFileManager *fileMan = [NSFileManager defaultManager];
    
    if ( ![fileMan isReadableFileAtPath:path]) {
        NSLog(@"** %s: file doesn't exist (%@)", __func__, path);
        [self release];
        return nil;
    }
    
    // TODO: should check for bundles (using fileMan's fileExists:isDir: call)
    
    HMODULE hmodule = LoadLibraryA( [path UTF8String] );   // TODO: should use wchar version instead
    
    if ( !hmodule) {
        DWORD err = GetLastError();
        NSLog(@"** %s: Win32 LoadLibrary failed (%i; %@)", __func__, err, path);
        [self release];
        return nil;
    }
    _hmodule = hmodule;
#endif

    _url = [url retain];

    return self;
}


// modules are never unloaded; keep them cached here
static NSMutableDictionary *g_modules = nil;


+ (LQDynModule *)moduleWithURL:(NSURL *)url
{
    if ( !g_modules) {
        g_modules = [[NSMutableDictionary alloc] init];
    }
    
    NSString *key = [url description];
    LQDynModule *module;
    
    if ((module = [g_modules objectForKey:key])) {
        // module was already loaded
    } else {
        module = [[LQDynModule alloc] initWithURL:url];
        
        if (module)
            [g_modules setObject:module forKey:key];
    }
    return module;
}


- (void *)functionPointerForName:(NSString *)name
{
#if defined(__APPLE__)
    return CFBundleGetFunctionPointerForName(_bundle, (CFStringRef)name);

#elif defined(__WIN32__)
    return GetProcAddress(_hmodule, [name UTF8String]);
#endif
}


- (NSURL *)url {
    return _url; }


- (NSString *)_bundleRootPath
{
    NSURL *bundleURL = [self url];
    if ( ![bundleURL isFileURL])
        return nil;
    
    NSString *path = [bundleURL path];
    return [path stringByAppendingPathComponent:@"Contents"];
}

- (NSString *)executablePath
{
    NSString *path = [self _bundleRootPath];
#if defined(__APPLE__)
    return [path stringByAppendingPathComponent:@"MacOS"];
#elif defined(__WIN32__)
    return [path stringByAppendingPathComponent:@"Windows"];
#else
#error "Unimplemented platform"
#endif
}

- (NSString *)resourcePath
{
    NSString *path = [self _bundleRootPath];
    return [path stringByAppendingPathComponent:@"Resources"];
}


@end
