//
//  LQTimeFormatter.h
//  Lacqit
//
//  Created by Pauli Ojala on 30.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LQTimeFormatter : NSFormatter {

    double _fps;
}

// default system frame rate is 60
+ (double)systemFrameRate;
+ (void)setSystemFrameRate:(double)fps;

// if not set, the formatter will default to +systemFrameRate
- (double)displayFrameRate;
- (void)setDisplayFrameRate:(double)fps;

@end
