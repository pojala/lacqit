//
//  LQPerformer.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
  This is a helper object that contains a list of timed tasks with associated context strings.
  Tasks are always performed as method calls on the 'owner' object.
  
  This can be useful for e.g. hiding one or more context-specific windows after a certain delay.
*/

@interface LQPerformer : NSObject {

    id _owner;

    NSTimer *_timer;
    double _startTime;
    
    NSMutableArray *_tasks;
}

- (id)initWithOwner:(id)owner;

- (id)owner;

- (void)performSelector:(SEL)action withObject:(id)arg
        inContext:(NSString *)ctx
        afterDelay:(NSTimeInterval)time;

- (void)cancelTasksForContext:(NSString *)ctx;

- (void)abort;

@end
