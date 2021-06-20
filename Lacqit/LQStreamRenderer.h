//
//  LQStreamRenderer.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBufferingStreamNode.h"


@interface LQStreamRenderer : LQBufferingStreamNode {

    BOOL    _shouldRenewRenderSchedule;  // a hint that the render schedule should be renegotiated eventually
}

- (void)decideRenderingSchedule;

- (BOOL)usePrivateWorkThread;

// utils
- (LQStreamNode *)findNonRendererNodeUpstream;

@end
