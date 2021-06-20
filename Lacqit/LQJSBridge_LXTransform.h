//
//  LQJSBridge_LXTransform.h
//  Lacqit
//
//  Created by Pauli Ojala on 10.11.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LXTransform : LQJSBridgeObject  <LQJSCopying> {

    LXTransform3DRef _trs;  // retained
}

- (id)initWithLXTransform3D:(LXTransform3DRef)lxTrs
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (LXTransform3DRef)lxTransform3D;

@end
