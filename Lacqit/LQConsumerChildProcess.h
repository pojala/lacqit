//
//  LQConsumerChildProcess.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.2.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQProducerChildProcess.h"

/*
  This class is a subclass of LQProducerChildProcess just to share code.
  Eventually should make a LQChildProcess that's the abstract superclass for both.
*/

@interface LQConsumerChildProcess : LQProducerChildProcess {

    NSInteger _wantedSharedMemSize;
}

- (void)setRequestedBufferSize:(NSInteger)size;
- (NSInteger)requestedBufferSize;

@end
