//
//  LQPlugin.m
//  Lacqit
//
//  Created by Pauli Ojala on 15.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQPlugin.h"

static NSMutableArray *g_plugins = nil;


@implementation LQPlugin


+ (LQPlugin *)pluginWithPackageIdentifier:(NSString *)ident
{
    NSEnumerator *pluginEnum = [g_plugins objectEnumerator];
    LQPlugin *plug;
    while (plug = [pluginEnum nextObject]) {
        if ([[plug packageIdentifier] isEqual:ident])
            break;
    }
    return plug;
}

+ (NSArray *)pluginsWithSuperclass:(Class)cls
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[g_plugins count]];
    
    NSEnumerator *pluginEnum = [g_plugins objectEnumerator];
    LQPlugin *plug;
    while (plug = [pluginEnum nextObject]) {
        if ([[plug class] isSubclassOfClass:cls])
            [arr addObject:plug];
    }
    return arr;
}


+ (void)installPlugin:(LQPlugin *)newPlug
{
    if ( !g_plugins)
        g_plugins = [[NSMutableArray alloc] initWithCapacity:64];
        
    if ( !newPlug)
        return;
        
    [g_plugins addObject:newPlug];
}

+ (BOOL)installPluginsFromURL:(NSURL *)url newPackageIdentifiers:(NSArray **)outIDs
{
    if (outIDs) *outIDs = nil;
    
    LQPlugin *newPlug = [[[self class] alloc] initWithURL:url];
    if (newPlug) {
        [[self class] installPlugin:newPlug];
        
        if (outIDs) *outIDs = [NSArray arrayWithObject:[newPlug packageIdentifier]]; 
        return YES;
    }
    else return NO;
}


- (id)initWithURL:(NSURL *)url
{
    if ( !url) {
        [self release];
        return nil;
    }

    self = [super init];
    
    _url = [url retain];
    
    _packageIdentifier = [[url path] retain];
    
    return self;
}

- (void)dealloc
{
    [_url release];
    [_packageIdentifier release];
    [super dealloc];
}


- (NSString *)packageIdentifier {
    return _packageIdentifier; }

- (NSURL *)url {
    return _url; }

- (NSString *)displayName {
    return [NSString stringWithFormat:@"<Unknown: %@, %p>", [_packageIdentifier lastPathComponent], self];
}

- (NSString *)infoString {
    return @"";
}

- (void)setAttribute:(id)attr forKey:(NSString *)key {
    if ( !_attrs)
        _attrs = [[NSMutableDictionary alloc] init];
        
    if (attr)
        [_attrs setObject:attr forKey:key];
    else
        [_attrs removeObjectForKey:key];
}

- (id)attributeForKey:(NSString *)key {
    return [_attrs objectForKey:key];
}




#pragma mark --- utilities ---

+ (NSString *)standardizeNameForPackageID:(NSString *)str
{
    if ( !str) return nil;
    
    NSMutableCharacterSet *deletionSet = (NSMutableCharacterSet *)[[[[NSCharacterSet alphanumericCharacterSet] invertedSet] mutableCopy] autorelease];
    [deletionSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableString *mstr = [NSMutableString stringWithString:[str lowercaseString]];

    [mstr replaceOccurrencesOfString:@" " withString:@"_" options:0 range:NSMakeRange(0, [mstr length])];
    
    NSRange range;
    while ((range = [mstr rangeOfCharacterFromSet:deletionSet]).location != NSNotFound) {
        [mstr deleteCharactersInRange:range];
    }
    
    return ([mstr length] > 0) ? mstr : nil;
}

+ (NSString *)standardizeStringForUUIDFragment:(NSString *)str
{
    if ( !str) return nil;
    
    NSMutableCharacterSet *deletionSet = (NSMutableCharacterSet *)[[[[NSCharacterSet alphanumericCharacterSet] invertedSet] mutableCopy] autorelease];
    
    NSMutableString *mstr = [NSMutableString stringWithString:str];
    NSRange range;
    while ((range = [mstr rangeOfCharacterFromSet:deletionSet]).location != NSNotFound) {
        [mstr deleteCharactersInRange:range];
    }
    return ([mstr length] > 0) ? mstr : nil;
}

@end

