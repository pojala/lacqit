//
//  LQScriptedPlugin.h
//  Lacqit
//
//  Created by Pauli Ojala on 20.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQPlugin.h"

/*
  a scripted plugin is a package of scripts and assets.
  
  scripts are strings identified by keys (e.g. "onMouseClick").
  assets are an array of objects whose only requirement is that they implement NSCoding.
  
  script plugins used in Conduit to implement node presets.
*/


@interface LQScriptedPlugin : LQPlugin {

    NSString *_pluginName;
    NSString *_pluginCategory;

    Class _scriptNodeClass;
    NSString *_scriptNodeClassName;
    NSString *_scriptNodeClassPackageID;

    NSDictionary *_scripts;
    NSArray *_assets;
    NSDictionary *_assetNames;
}

+ (NSString *)fileExtensionForFormat:(uint32_t)capsuleFormat;
+ (NSArray *)fileExtensions;

// -initWithURL: is the inherited initializer for loading; it takes an URL to a script plist as argument
- (id)initWithURL:(NSURL *)url;
- (id)initWithPlistData:(NSData *)plistData forURL:(NSURL *)url;

// this is the initializer for creating a plugin from a node's data within the application.
// objects in 'assets' must implement keyed archiving by conforming to NSCoding.
// category can be nil.
- (id)initWithPackageIdentifier:(NSString *)packageID
            name:(NSString *)pluginName
            category:(NSString *)catName
            nodeClass:(Class)cls
            scripts:(NSDictionary *)scripts
            assets:(NSArray *)assets
            assetNames:(NSDictionary *)assetNames;

- (NSString *)pluginName;
- (NSString *)pluginCategory;
- (Class)nodeClass;

- (NSDictionary *)scripts;
- (NSArray *)assets;
- (NSDictionary *)assetNames;

- (void)minifyScripts;

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)errorPtr;
- (NSData *)plistData;

// private implementation
- (NSArray *)readAssetsFromPlistArray:(NSArray *)plists;
- (NSArray *)writePlistArrayForAssets:(NSArray *)assets;

@end
