//
//  LQConsumerChildProcess.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.2.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQConsumerChildProcess.h"


@implementation LQConsumerChildProcess

- (void)setRequestedBufferSize:(NSInteger)size {
    _wantedSharedMemSize = size;
}

- (NSInteger)requestedBufferSize {
    return _wantedSharedMemSize;
}



#pragma mark --- overrides ---

- (NSInteger)sharedMemorySizeFromChildProcessHandshakeDict:(NSDictionary *)dict
{
    return _wantedSharedMemSize;
}

@end
