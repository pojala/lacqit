//
//  LQTimeSpan.m
//  Lacqit
//
//  Created by Pauli Ojala on 1.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQTimeSpan.h"


double LQAlignTimeToFrameRateWithOrigin(double t, double fps, double origin)
{
    if (fps <= 0.0) return t;
    if (t == -DBL_MAX || t == DBL_MAX) return t;
    if ( !isfinite(t)) return 0.0;
    
    t -= origin;
    return origin + round(t * fps) / fps;
}


@implementation LQTimeSpan

- (NSString *)description
{
    NSString *outStr = (_outTime == DBL_MAX) ? @"[not set]" : [NSString stringWithFormat:@"%.3f", _outTime];
    NSString *inStr = (_inTime == -DBL_MAX)  ? @"[not set]" : [NSString stringWithFormat:@"%.3f", _inTime];
    return [NSString stringWithFormat:@"<%@: %p -- in %@, out %@, fps %.2f>",
                        [self class], self, inStr, outStr, _fps];
}

- (id)init
{
    self = [super init];
    _fps = 60.0;
    _inTime = 0.0;
    _outTime = DBL_MAX;
    return self;
}

- (double)duration
{
    return _outTime - _inTime;
}

- (double)inTime {
    return _inTime; }

- (double)outTime {
    return _outTime; }
    
    
- (void)setInTime:(double)t {
    _inTime = MIN(t, _outTime);
}

- (void)setOutTime:(double)t {
    _outTime = MAX(t, _inTime);
}
    

- (void)setFramesPerSecond:(double)fps {
    _fps = MAX(fps, 0.00001); }
    
- (double)framesPerSecond {
    return _fps; }


- (id)copyWithZone:(NSZone *)zone
{
    id newObj = [[[self class] alloc] init];
    [newObj setInTime:_inTime];
    [newObj setOutTime:_outTime];
    [newObj setFramesPerSecond:_fps];
    return newObj;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeDouble:_inTime forKey:@"inTime"];
    [coder encodeDouble:_outTime forKey:@"outTime"];
    [coder encodeDouble:_fps forKey:@"fps"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    _inTime = [coder decodeDoubleForKey:@"inTime"];
    _outTime = [coder decodeDoubleForKey:@"outTime"];
    _fps = [coder decodeDoubleForKey:@"fps"];
    return self;
}


- (LQTimeSpan *)spanByConstrainingWithinSpan:(LQTimeSpan *)otherSpan {
    LQTimeSpan *newSpan = [[self copy] autorelease];
    [newSpan constrainWithinSpan:otherSpan];
    return newSpan;
}

- (void)constrainWithinSpan:(LQTimeSpan *)otherSpan
{
    if ( !otherSpan) return;
    double oin = [otherSpan inTime];
    double oout = [otherSpan outTime];
    
    _inTime = MAX(_inTime, oin);
    _outTime = MIN(_outTime, oout);
}

- (double)constrainTime:(double)time
{
    time = MAX(_inTime, time);
    
    double maxTime = _outTime - (1.0 / _fps);
    time = MIN(maxTime, time);
    
    return time;
}

- (void)offsetByTime:(double)offtime
{
    if (_inTime != DBL_MAX)
        _inTime += offtime;
        
    if (_outTime != DBL_MAX)
        _outTime += offtime;
}

@end
