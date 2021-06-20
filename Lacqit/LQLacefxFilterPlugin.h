//
//  LQLacefxFilterPlugin.h
//  Lacqit
//
//  Created by Pauli Ojala on 15.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LQImageFilterPlugin.h"
#import <Lacefx/Lacefx.h>
#import <Lacefx/LXSuites.h>
@class LQDynModule;


@interface LQLacefxFilterPlugin : LQImageFilterPlugin {

    LQDynModule *_module;

    unsigned int _pluginNumber;
    LXPluginEntryFuncPtr _entryFunc;
    
    // plugin description
    NSString *_className;
    NSString *_plugDescription;
    NSString *_plugCopyright;
    NSString *_plugTypeID;
    NSImage *_plugIcon;
}

- (id)initWithDynModule:(LQDynModule *)module pluginNumber:(int)pluginNumber;

- (LQDynModule *)dynModule;

// entry point to the plugin through Lacefx C API
- (BOOL)performPluginSelector:(const char *)selector
                        inCtx:(void *)inCtx
                        outCtx:(void *)outCtx
                        errorPtr:(LXError *)outError;

@end
