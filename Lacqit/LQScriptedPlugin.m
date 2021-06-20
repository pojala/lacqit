//
//  LQScriptedPlugin.m
//  Lacqit
//
//  Created by Pauli Ojala on 20.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQScriptedPlugin.h"
#import "LQNSDataAdditions.h"
#import "LQCapsuleWrapper.h"
#import "LQJSMinifier.h"


#define PLISTKEY_SCRIPTS    @"scripts"
#define PLISTKEY_ASSETS     @"assets"
#define PLISTKEY_PACKAGEID  @"packageID"
#define PLISTKEY_PLUGINNAME @"pluginName"
#define PLISTKEY_PLUGINCAT  @"pluginCategory"
#define PLISTKEY_NODECLASS  @"scriptNodeClass"
#define PLISTKEY_NODECLASSPACKAGEID  @"scriptNodeClassPackageID"



@implementation LQScriptedPlugin

+ (NSString *)fileExtensionForFormat:(uint32_t)capsuleFormat
{
    if (capsuleFormat == 0x4401d3af)  // Conduit binary capsule format
        return @"lcb";
    else
        return @"lcs";
}

+ (NSArray *)fileExtensions
{
    return [NSArray arrayWithObjects:@"lcb", @"lcs", nil];
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (%@)>",
                        [self class], self,
                        [self packageIdentifier]
                    ];
}


- (BOOL)_copyContentsFromPlist:(id)plist
{
    if ([plist isKindOfClass:[NSDictionary class]] 
        && [plist objectForKey:PLISTKEY_NODECLASS] && [plist objectForKey:PLISTKEY_SCRIPTS]
        && [plist objectForKey:PLISTKEY_PACKAGEID] && [plist objectForKey:PLISTKEY_PLUGINNAME]
        ) {
        _scriptNodeClassName = [[plist objectForKey:PLISTKEY_NODECLASS] copy];
        _scriptNodeClassPackageID = [[plist objectForKey:PLISTKEY_NODECLASSPACKAGEID] copy];
        _scriptNodeClass = NSClassFromString(_scriptNodeClassName);

        _packageIdentifier = [[plist objectForKey:PLISTKEY_PACKAGEID] copy];
        
        _pluginName = [[plist objectForKey:PLISTKEY_PLUGINNAME] copy];
        
        NSString *cat = [plist objectForKey:PLISTKEY_PLUGINCAT];
        _pluginCategory = ([cat length] > 0) ? [cat copy] : nil;
        
        _scripts = [[plist objectForKey:PLISTKEY_SCRIPTS] retain];

        _assets = [[self readAssetsFromPlistArray:[plist objectForKey:PLISTKEY_ASSETS]] retain];
        
        return YES;
    }
    else
        return NO;
}

- (id)initWithPlistData:(NSData *)plistData forURL:(NSURL *)url
{
    self = [super initWithURL:url];
    
    if (self) {
        NSString *errorStr = nil;
        id plist = nil;
 
        plist = [NSPropertyListSerialization propertyListFromData:plistData
                                mutabilityOption:NSPropertyListImmutable
                                format:nil
                                errorDescription:&errorStr];
        
        [self _copyContentsFromPlist:plist];
        
        if ( !_scripts || !_scriptNodeClass) {
            NSLog(@"** %s: failed to load scripts from URL '%@'\n  %@ class is %@", __func__, _url,
                                                (errorStr) ? [NSString stringWithFormat:@"(plist error: %@) -", errorStr] : @"",
                                                _scriptNodeClass);
            [self autorelease];
            return nil;
        }
    }
    return self;
}

- (id)initWithURL:(NSURL *)url
{
    NSData *plistData = [NSData dataWithContentsOfURL:url];
    if ( !plistData) {
        [self release];
        return nil;
    } else {
        return [self initWithPlistData:plistData forURL:url];
    }
}

- (void)dealloc
{
    [_scriptNodeClassName release];
    [_scriptNodeClassPackageID release];    
    [_scripts release];
    [_assets release];
    [_assetNames release];

    [_pluginName release];
    [_pluginCategory release];

    [super dealloc];
}


// declaration here just to eliminate compiler warning
+ (NSString *)nodeClassPackageID {
    return @""; }
    

- (id)initWithPackageIdentifier:(NSString *)packageID
            name:(NSString *)pluginName
            category:(NSString *)category
            nodeClass:(Class)cls
            scripts:(NSDictionary *)scripts
            assets:(NSArray *)assets
            assetNames:(NSDictionary *)assetNames
{
    if ( !scripts || !cls || !packageID || !pluginName) {
        [self autorelease];
        return nil;
    }
    
    self = [super init];
    
    _scriptNodeClass = cls;
    _scriptNodeClassName = [NSStringFromClass(_scriptNodeClass) copy];
    
    _scriptNodeClassPackageID = ([cls respondsToSelector:@selector(nodeClassPackageID)]) ? [[cls nodeClassPackageID] copy]
                                        : [@"" retain];

    _packageIdentifier = [packageID copy];
    _pluginName = [pluginName copy];
    _pluginCategory = ([category length] > 0) ? [category copy] : nil;
        
    _scripts = [scripts copy];
    _assetNames = [assetNames copy];    
    _assets = [[NSMutableArray alloc] init];
    
    NSEnumerator *assetEnum = [assets objectEnumerator];
    id asset;
    while (asset = [assetEnum nextObject]) {
        if ( ![asset conformsToProtocol:@protocol(NSCoding)]) {
            NSLog(@"** %s: asset doesn't conform to NSCoding, will replace with empty default (%@ / objcls %@)", __func__, packageID, [asset class]);
            asset = @"";
        }
        id newAsset = nil;
        if ([asset conformsToProtocol:@protocol(NSCopying)]) {
            newAsset = [[asset copy] autorelease];
        } else {
            newAsset = asset;  // just retain (this is appropriate for e.g. LQLXPixelBuffers used as image assets - they are immutable in practice)
        }
        [(NSMutableArray *)_assets addObject:(newAsset) ? newAsset : @""];
    }
    
    return self;
}


- (NSString *)pluginName {
    return _pluginName; }

- (NSString *)pluginCategory {
    return _pluginCategory; }
    
- (Class)nodeClass {
    return _scriptNodeClass; }

- (NSDictionary *)scripts {
    return _scripts; }

- (NSArray *)assets {
    return _assets; }

- (NSDictionary *)assetNames {
    return _assetNames; }

    
- (NSString *)displayName {
    return _pluginName; }
    
    
- (void)minifyScripts
{
    LQJSMinifier *jsmin = [[LQJSMinifier alloc] init];

    NSMutableDictionary *newScripts = [NSMutableDictionary dictionary];

    NSEnumerator *keyEnum = [_scripts keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        NSString *scr = [_scripts objectForKey:key];
        NSString *err = nil;
        NSString *minified = [jsmin minifyJavaScript:scr withErrorDescription:&err];
        
        if ( !minified && [scr length] > 0) {
            NSLog(@"** plugin %@:  failed to minify script %@: error '%@'", self, key, err);
        } else {
            ///NSLog(@"... minified script %@ -- orig len %i -> %i", key, [scr length], [minified length]);
        }
        [newScripts setObject:(minified) ? [NSString stringWithString:minified] : scr forKey:key];
    }
    
    [jsmin release];
    
    [_scripts release];
    _scripts = [newScripts retain];
}
    

#pragma mark --- writing to plist / URL ---

- (NSArray *)readAssetsFromPlistArray:(NSArray *)plists
{
    if ( !plists) return [NSArray array];

    NSMutableArray *assets = [NSMutableArray array];

    if ( ![plists respondsToSelector:@selector(objectEnumerator)]) {
        NSLog(@"** %s: invalid assets plist object (%@)", __func__, [plists class]);
        return assets;
    }

    NSEnumerator *plistEnum = [plists objectEnumerator];
    id plist;
    while (plist = [plistEnum nextObject]) {
        id newAsset = nil;
        
        // strings are handles as-is, anything else is an NSData zipped blob of keyarch XML
        if ([plist isKindOfClass:[NSString class]]) {
            newAsset = plist;
        }
        else if ([plist isKindOfClass:[NSData class]]) {
            NSData *archData = [(NSData *)plist unzippedDataWithKnownLength:0];
            if ( !archData) {
                NSLog(@"** %s: unable to unzip data from plist (orig data size %ld)", __func__, (long)[plist length]);
            } else {
                ///NSLog(@"successfully unzipped scripted plugin's plist data: %ld -> %ld", [plist length], [archData length]);
/*        } else if ([plist isKindOfClass:[NSString class]]) {
            const char *utf8 = [plist UTF8String];
            size_t utf8Size = strlen(utf8) + 1;
            archData = [NSData dataWithBytes:utf8 length:utf8Size];
        }
        
        if (archData) {
*/
                NSKeyedUnarchiver *unarch = [[NSKeyedUnarchiver alloc] initForReadingWithData:archData];
                
                newAsset = [unarch decodeObjectForKey:@"asset"];
                [unarch finishDecoding];
                [unarch release];
            }
        }
        
        [assets addObject:(newAsset) ? newAsset : @""];
    }
    return assets;
}

- (NSArray *)writePlistArrayForAssets:(NSArray *)assets
{
    NSMutableArray *plists = [NSMutableArray array];

    NSEnumerator *assetEnum = [assets objectEnumerator];
    id asset;
    while (asset = [assetEnum nextObject]) {
        // strings are handles as-is, anything else is written as a keyedarch blob
        if ([asset isKindOfClass:[NSString class]]) {
            [plists addObject:asset];
        } else {
            NSMutableData *data = [NSMutableData data];
            if ( ![asset conformsToProtocol:@protocol(NSCoding)]) {
                NSLog(@"** %s: asset doesn't conform to NSCoding, will replace with empty default (%@ / objcls %@)", __func__, [self packageIdentifier], [asset class]);
                asset = @"";
            }
            NSKeyedArchiver *arch = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
            [arch setOutputFormat:NSPropertyListXMLFormat_v1_0];
                
            [arch encodeObject:asset forKey:@"asset"];
            [arch finishEncoding];
            [arch release];
            
            NSData *zippedData = [data zippedData];
            
            ///NSLog(@"%s: writing zipped data: orig size %ld -> %ld", __func__, [data length], [zippedData length]);
            
            [plists addObject:zippedData];
            //NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            //[plists addObject:str];
        }
    }
    return plists;
}

- (NSDictionary *)plistDictionary
{
    NSArray *assetPlists = [self writePlistArrayForAssets:_assets];

    return [NSDictionary dictionaryWithObjectsAndKeys:
                             _scriptNodeClassName,      PLISTKEY_NODECLASS,
                             _scriptNodeClassPackageID, PLISTKEY_NODECLASSPACKAGEID,
                             _scripts,                  PLISTKEY_SCRIPTS,
                             assetPlists,               PLISTKEY_ASSETS,
                             _packageIdentifier,        PLISTKEY_PACKAGEID,
                             _pluginName,               PLISTKEY_PLUGINNAME,
                             (_pluginCategory) ? _pluginCategory : @"", PLISTKEY_PLUGINCAT,
                             nil];
}

- (NSData *)plistData
{
    id plist = [self plistDictionary];
    if ( !plist) return nil;

    NSString *errorStr = nil;
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListXMLFormat_v1_0 errorDescription:&errorStr];
    
    if ( !plistData) {
        NSLog(@"** %s failed; error: %@", __func__, errorStr);
    }
    return plistData;
}

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)errorPtr
{
    NSData *plistData = [self plistData];
    if ( !plistData) // TODO: should write an error here
        return NO;
    else
        return [plistData writeToURL:url options:0 error:errorPtr];
}


@end
