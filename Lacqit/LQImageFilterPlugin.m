//
//  LQImageFilterPlugin.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQImageFilterPlugin.h"
///#import "LQConduitFilterPlugin.h"


@implementation LQImageFilterPlugin

+ (void)installDefaultPlugins
{
    // allows for subclassing
    
        /*
        NSString *bezBlurPath =     [[NSBundle mainBundle] pathForResource:@"bezblur.conduit" ofType:nil];
        NSString *yellowTintPath =  [[NSBundle mainBundle] pathForResource:@"yellow-tint.conduit" ofType:nil];
        
        if (yellowTintPath)
            [LQPlugin installPlugin:[[LQConduitFilterPlugin alloc] initWithURL:[NSURL fileURLWithPath:yellowTintPath]] ];
            
        if (bezBlurPath)
            [LQPlugin installPlugin:[[LQConduitFilterPlugin alloc] initWithURL:[NSURL fileURLWithPath:bezBlurPath]] ];
        */
}

+ (NSArray *)allFilterPlugins
{
    static BOOL s_didInstallDefaults = NO;
    
    if ( !s_didInstallDefaults) {
        [self installDefaultPlugins];
        s_didInstallDefaults = YES;
    }
    
    return [LQPlugin pluginsWithSuperclass:[self class]];
}


- (id)instantiateFilter
{
    NSLog(@"** %s needs to be implemented by subclass (%@)", __func__, self);
    return nil;
}


- (NSImage *)pluginIcon {
    return [NSImage imageNamed:@"nodeicon_plugin"]; }

- (NSString *)pluginName {
    // subclass should provide a more reasonable implementation
    return _packageIdentifier;
}

- (NSString *)pluginCategory {
    return nil;
}

@end
