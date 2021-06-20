/*
 *  LQTagProviding.h
 *  Inro
 *
 *  Created by Pauli Ojala on 21.12.2011.
 *  Copyright 2011 Lacquer oy/ltd. All rights reserved.
 *
 */


@protocol LQTagProviding <NSObject>

- (LXInteger)retainAvailableTag;
- (void)releaseTag:(LXInteger)tag;

@end
