//
//  LQJSBridge_StreamNodeBase.h
//  LacqMediaCore
//
//  Created by Pauli Ojala on 9.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_StreamNodeBase : LQJSBridgeObject {

    id _node;   // not retained
}

// the new bridge object is created in the JSContext of the node's owner (i.e. the containing streamPatch)
- (id)initWithNode:(id)node;

// subclasses can use to post a notif when object properties change
- (void)postNodeWasModifiedNotificationWithInfo:(NSDictionary *)info;

@end
