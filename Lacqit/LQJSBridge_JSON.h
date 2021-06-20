//
//  LQJSBridge_JSON.h
//  Lacqit
//
//  Created by Pauli Ojala on 12.5.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/LXBasicTypes.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_JSON : LQJSBridgeObject {

    LQJSInterpreter *_interp;
}

- (id)initInJSInterpreter:(LQJSInterpreter *)interp withOwner:(id)owner;

@end
