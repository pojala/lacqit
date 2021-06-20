//
//  LQLacefxFilterPlugin.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQLacefxFilterPlugin.h"
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXSuites.h>
#import "LQDynModule.h"
#import "EDUINSImageAdditions.h"
#import "LQLXImageAppKitUtils.h"



@implementation LQLacefxFilterPlugin


#pragma mark --- plugin host suite ---

// TODO: host properties should be set by Conduit perhaps using a class method on the plugin class

static const char *hostSuite_getHostName(void *ctx)
{
    return "Conduit";
}

static LXVersion hostSuite_getHostVersion(void *ctx)
{
    LXVersion ver = { 2, 0, 0, 0 };
    return ver;
}

static LXBool hostSuite_canProvideSuiteNamed(void *ctx, const char *suiteName)
{
    return NO;
}

static const char *hostSuite_getPluginExecutablePathUTF8(void *ctx)
{
    LQLacefxFilterPlugin *plugin = (LQLacefxFilterPlugin *)ctx;
    LQDynModule *module = [plugin dynModule];
    NSString *path = [module executablePath];
    if ( !path) {
        NSLog(@"** can't get exec path for LX plugin (%@)", plugin);
        return NULL;
    }
    const char *utf8Path = [path UTF8String];
    
    return utf8Path;
    
    //char *s = _lx_malloc(strlen(utf8Path) + 1);
    //memcpy(s, utf8Path, strlen(utf8Path) + 1);
    //return LXAutoreleaseCPtr(s);
}

static const char *hostSuite_getPluginResourcesPathUTF8(void *ctx)
{
    LQLacefxFilterPlugin *plugin = (LQLacefxFilterPlugin *)ctx;
    LQDynModule *module = [plugin dynModule];
    NSString *path = [module resourcePath];
    if ( !path) {
        NSLog(@"** can't get resource path for LX plugin (%@)", plugin);
        return NULL;
    }
    const char *utf8Path = [path UTF8String];
    
    return utf8Path;
}



#pragma mark --- plugin describe utility ---

- (LXHostSuite_v1)_hostSuite
{
    LXHostSuite_v1 suite;
    suite.ctx = self;
    suite.getHostName = hostSuite_getHostName;
    suite.getHostVersion = hostSuite_getHostVersion;
    suite.canProvideSuiteNamed = hostSuite_canProvideSuiteNamed;
    suite.getPluginExecutablePathUTF8 = hostSuite_getPluginExecutablePathUTF8;
    suite.getPluginResourcesPathUTF8 = hostSuite_getPluginResourcesPathUTF8;
    return suite;
}

// utility for getting NSStrings through the Lacefx API
- (NSString *)_getStringForPluginSelectorWithHostSuite:(const char *)plugSel
{
    LXDECLERROR(error);
    NSString *retStr = nil;
    LXLocString outStr;
    memset(&outStr, 0, sizeof(LXLocString));
    
    LXHostSuite_v1 suite = [self _hostSuite];
    
    [self performPluginSelector:plugSel inCtx:&suite outCtx:&outStr errorPtr:&error];
    
    if (error.errorID == 0 && outStr.idstr != NULL && strlen(outStr.idstr) > 0) {
        retStr = [NSString stringWithUTF8String:outStr.idstr];
    } else {
        NSLog(@"*** failed to get plugin string for selector '%s', error %i", plugSel, error.errorID);
        LXErrorDestroyOnStack(error);
    }
    
    _lx_free(outStr.idstr);        
    return retStr;
}

- (LXPixelBufferRef)_getLXPixelBufferForPluginSelectorWithHostSuite:(const char *)plugSel
{
    LXDECLERROR(error);
    LXPixelBufferRef pixbuf = NULL;
    
    LXHostSuite_v1 suite = [self _hostSuite];
    
    [self performPluginSelector:plugSel inCtx:&suite outCtx:&pixbuf errorPtr:&error];
    
    if (error.errorID != 0) {
        NSLog(@"*** failed to get plugin string for selector '%s', error %i", plugSel, error.errorID);
        LXErrorDestroyOnStack(error);
    }
    return pixbuf;
}


#pragma mark --- init ---

- (id)initWithDynModule:(LQDynModule *)module pluginNumber:(int)pluginNumber
{
    self = [super initWithURL:[module url]];

    if (self) {
        LXPoolRef pool = LXPoolCreateForThread();
        
        _pluginNumber = pluginNumber;
        
        _module = [module retain];

        _entryFunc = [module functionPointerForName:@"LXPluginPerformSelector"]; ///(void *)CFBundleGetFunctionPointerForName(bundle, (CFStringRef)@"LXPluginPerformSelector");

        _plugTypeID = [[self _getStringForPluginSelectorWithHostSuite:kLXSel_getPluginType] retain];
        
        if ( ![_plugTypeID isEqualToString:[NSString stringWithUTF8String:kLXPluginTypeID_render]]) {
            NSLog(@"** expected render plugin, but plugin reports id: '%@' (%@)", _plugTypeID, [module url]);
            [self autorelease];
            return nil;
        }

        _className = [[self _getStringForPluginSelectorWithHostSuite:kLXSel_getName] retain];
        _packageIdentifier = [[self _getStringForPluginSelectorWithHostSuite:kLXSel_getPluginID] retain];
        
        if ([_className length] < 1 || [_packageIdentifier length] < 1) {
            NSLog(@"** unable to read name or ID from plugin (%@; got %@, %@)", [module url], _className, _packageIdentifier);
            [self autorelease];
            return nil;
        }
        
        _plugDescription = [[self _getStringForPluginSelectorWithHostSuite:kLXSel_getDescription] retain];
        _plugCopyright = [[self _getStringForPluginSelectorWithHostSuite:kLXSel_getCopyright] retain];
        
#if !defined(__LAGOON__)
        LXPixelBufferRef iconPixbuf = [self _getLXPixelBufferForPluginSelectorWithHostSuite:kLXSel_getIcon];
        if (iconPixbuf) {
            NSBitmapImageRep *rep = LXPixelBufferCopyAsNSBitmapImageRep(iconPixbuf, NULL);
            if (rep) {
                NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])];
                [image addRepresentation:[rep autorelease]];
                _plugIcon = image;
                
                ///NSLog(@"got plugin icon: %@", _plugIcon);
            }
            LXPixelBufferRelease(iconPixbuf);
        }
#endif
        
        ///NSLog(@"loaded plugin from %@:\nname '%@', desc '%@', copyright '%@'", [module url], _className, _plugDescription, _plugCopyright);
        
        LXPoolRelease(pool);
    }

    return self;
}

- (void)dealloc
{
    _entryFunc = NULL;
    
    [_module release];
        
    [_className release];
        
    [super dealloc];
}


- (id)initWithURL:(NSURL *)url
{
    NSLog(@"** warning: incorrect initializer (%s), should be using -initWithDynModule", __func__);
    return nil;
}


// this code is basically identical to PixMathLXPlugin
+ (BOOL)installPluginsFromURL:(NSURL *)url newPackageIdentifiers:(NSArray **)outIds
{
    if (outIds) *outIds = nil;

    //CFBundleRef bundle = CFBundleCreate(kCFAllocatorDefault, (CFURLRef)url);
    
    LQDynModule *module = [LQDynModule moduleWithURL:url];
    if ( !module) {
        NSLog(@"** %s: can't read module at given URL (%@)", __func__, url);
        return NO;
    }

    // exported functions in plugin
    LXGetPluginCountFuncPtr getCountFunc = [module functionPointerForName:@"LXGetPluginCount"];
    LXGetPluginAPIVersionFuncPtr getAPIVerFunc = [module functionPointerForName:@"LXGetPluginAPIVersion"];
    LXPluginEntryFuncPtr entryFunc = [module functionPointerForName:@"LXPluginPerformSelector"];
    
    if ( !getCountFunc) {
        NSLog(@"** no getPluginCount entry point in plugin loaded from '%@'", url);
        return NO;
    }
    if ( !getAPIVerFunc) {
        NSLog(@"** no getAPIVersion entry point in plugin loaded from '%@'", url);
        return NO;
    }
    if ( !entryFunc) {
        NSLog(@"** no performSelector entry point in plugin loaded from '%@'", url);
        return NO;
    }
    
    // check API version
    const LXVersion minVer = { 0, 2,  0, 0 };
    const LXVersion maxVer = { 1, 99, 0, 0 };
    LXVersion pluginsRequiredVersion = { 0, 0, 0, 0 };
    getAPIVerFunc(&pluginsRequiredVersion);
    
    if (pluginsRequiredVersion.majorVersion < minVer.majorVersion) {
        NSLog(@"** plugin is built for old API version, can't be loaded (%i.%i.%i -- url is '%@')",
            pluginsRequiredVersion.majorVersion, pluginsRequiredVersion.minorVersion, pluginsRequiredVersion.milliVersion, url);
        return NO;
    }
    if (pluginsRequiredVersion.majorVersion > maxVer.majorVersion) {
        NSLog(@"** plugin requires newer API version, can't be loaded (%i.%i.%i -- url is '%@')",
            pluginsRequiredVersion.majorVersion, pluginsRequiredVersion.minorVersion, pluginsRequiredVersion.milliVersion, url);
        return NO;
    }    

    // create the plugins in this bundle and collect the package IDs
    int pluginCount = getCountFunc();
    
    if (pluginCount < 1) {
        NSLog(@"** unable to find any plugins (getPluginCount returns 0) in plugin loaded from '%@'", url);
        return NO;
    }
    
    NSMutableArray *array = [NSMutableArray array];
    int i;
    for (i = 0; i < pluginCount; i++) {
        LQLacefxFilterPlugin *newPlug = [[[self class] alloc] initWithDynModule:module pluginNumber:i];
        NSString *packageID = @"";
        
        if (newPlug) {
            [[self class] installPlugin:newPlug];
            
            packageID = [newPlug packageIdentifier];
        } else {
            NSLog(@"** warning: plugin creation failed for plugin at index %i in '%@'", i, url);
        }
        [array addObject:packageID];
    }

    
    if (outIds) *outIds = array;
    return YES;
}


#pragma mark --- accessors ---

- (LQDynModule *)dynModule {
    return _module; }


#pragma mark --- overrides ---

- (NSImage *)pluginIcon {
    return (_plugIcon) ? _plugIcon : [NSImage imageInBundleWithName:@"nodeicon_plugin"];
}

- (NSString *)pluginName {
    return _className;
}

- (NSString *)infoString {
    return @"An image filter plugin.";
}


// Conduit uses these methods, so implement them
- (NSImage *)nodeClassIcon {
    return [self pluginIcon]; }
    
- (NSString *)nodeClassName {
    return [self pluginName]; }
    
- (NSString *)nodeClassDescription {
    return [self infoString]; }
    


#pragma mark --- access to plugin functions ---

- (BOOL)performPluginSelector:(const char *)selector
                        inCtx:(void *)inCtx outCtx:(void *)outCtx errorPtr:(LXError *)outError
{
    ///NSLog(@"%s: %s;  entry %p", __func__, selector, _entryFunc);

    if (outError) memset(outError, 0, sizeof(LXError));
    
    if ( !selector)
        return NO;
    if ( !_entryFunc)
        return NO;
    
    return _entryFunc(_pluginNumber, selector, strlen(selector),
               inCtx, outCtx, outError);
}


#pragma mark --- overrides ---

- (NSString *)displayName {
    return _className; }

/*
- (id)instantiateFilter
{
    return [[LQLacefxFilter alloc] initWithPlugin:self];
}
*/

@end
