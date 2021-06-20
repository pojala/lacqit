//
//  LQImageFilterPlugin.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQPlugin.h"


@interface LQImageFilterPlugin : LQPlugin {

}

+ (NSArray *)allFilterPlugins;

- (id)instantiateFilter;

- (NSImage *)pluginIcon;
- (NSString *)pluginName;
- (NSString *)pluginCategory;

@end
