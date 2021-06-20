//
//  LQJSBridge_System.h
//  Lacqit
//
//  Created by Pauli Ojala on 21.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/LXBasicTypes.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_System : LQJSBridgeObject {
    LQJSInterpreter *_interpreter;
    
    NSString *_systemID;
}

// this is the host ID returned by the system object on JS side
+ (void)setHostID:(NSString *)hostID;

- (id)initInJSInterpreter:(LQJSInterpreter *)interp withOwner:(id)owner;

@end



@interface NSObject (LQJSBridgeSystemForwardedMethods)

- (void)jsSystemCallForBridge:(id)bridgeObj printTraceString:(NSString *)str;

- (void)jsSystemCallForBridge:(id)bridgeObj showAlertWithString:(NSString *)str;

- (NSData *)jsSystemCallForBridge:(id)bridgeObj shouldLoadDataFromPath:(NSString *)path error:(NSError **)error;

@end
