//
//  LQTimeSpan.h
//  Lacqit
//
//  Created by Pauli Ojala on 1.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LacqitExport.h"

/*
  Meant for video in/out times, but can be used for other purposes as well.
*/

// a simple utility for aligning a time value to a frame boundary, given the frame rate and the time value origin (usually 0)
LACQIT_EXPORT double LQAlignTimeToFrameRateWithOrigin(double t, double fps, double origin);


@interface LQTimeSpan : NSObject  <NSCoding, NSCopying> {

    double      _inTime;
    double      _outTime;
    
    double      _fps;
}

- (double)duration;

- (double)inTime;
- (double)outTime;
- (void)setInTime:(double)t;
- (void)setOutTime:(double)t;

- (void)setFramesPerSecond:(double)fps;
- (double)framesPerSecond;

- (LQTimeSpan *)spanByConstrainingWithinSpan:(LQTimeSpan *)otherSpan;

- (void)constrainWithinSpan:(LQTimeSpan *)otherSpan;

// fits the time in range [inTime, outTime[ -- i.e. the max value is (outTime - (duration of one frame)).
// this is the generally used definition of the "out time" in video editing: it's the first frame that is not included in the segment,
// or to put it another way, this segment's out time is the in time for the next segment.
// to get the last valid time within this span, you can thus call:  [span constrainTime:[span outTime]]
- (double)constrainTime:(double)time;

- (void)offsetByTime:(double)time;

@end
