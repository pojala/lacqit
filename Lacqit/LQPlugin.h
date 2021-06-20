//
//  LQPlugin.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"

/*
LQPlugin is an abstract superclass, callers should instantiate one of the
concrete subclasses that actually implement an API, e.g. LQLacefxFilterPlugin.

An LQPlugin is _not_ necessarily an executable binary, it can also be a script, etc.
Plugins that are implemented as bundles/DLLs can use LQDynModule to load code.
*/


@interface LQPlugin : NSObject {

    NSURL *_url;
    NSString *_packageIdentifier;   // a reverse DNS identifier
    
    NSMutableDictionary *_attrs;
}

+ (LQPlugin *)pluginWithPackageIdentifier:(NSString *)ident;
+ (NSArray *)pluginsWithSuperclass:(Class)cls;

+ (void)installPlugin:(LQPlugin *)plugin;

+ (BOOL)installPluginsFromURL:(NSURL *)url newPackageIdentifiers:(NSArray **)outIDs;

- (id)initWithURL:(NSURL *)url;

- (NSURL *)url;

- (NSString *)packageIdentifier;

- (NSString *)displayName;
- (NSString *)infoString;

- (void)setAttribute:(id)attr forKey:(NSString *)key;
- (id)attributeForKey:(NSString *)key;

// utility
+ (NSString *)standardizeNameForPackageID:(NSString *)str;
+ (NSString *)standardizeStringForUUIDFragment:(NSString *)str;

@end
