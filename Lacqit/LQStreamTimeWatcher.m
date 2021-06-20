//
//  LQStreamTimeWatcher.m
//  Lacqit
//
//  Created by Pauli Ojala on 6.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQStreamTimeWatcher.h"
#import "LQTimeFunctions.h"



@implementation LQStreamTimeWatcher

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p -- %@>",
                        [self class], self,
                        (_name) ? _name : @"(untitled)"];
}


- (id)initWithCapacity:(LXInteger)capacity
{
    if (capacity < 4) capacity = 4;

    self = [super init];
    _recSampleArraySize = capacity;
    _recordedSampleTimes = _lx_malloc(capacity * sizeof(double));
    _recordedSampleIDs = _lx_malloc(capacity * sizeof(int64_t));
    _recSampleTimesCursor = 0;
    
    LXMutexInit(&_mutex);
    
    return self;
}

- (id)init
{
    return [self initWithCapacity:16];
}

- (void)dealloc
{
    LXMutexLock(&_mutex);
    LXMutexUnlock(&_mutex);
    LXMutexDestroy(&_mutex);
    
    _lx_free(_recordedSampleTimes);
    _lx_free(_recordedSampleIDs);
    
    [super dealloc];
}


- (void)addSampleRefTime:(double)t
{
    [self addSampleRefTime:t withID:0];
}

- (void)_reallyAddTime:(double)time withID:(int64_t)sampleID
{
    // reset cached values to zero so that they are recomputed when next needed
    _avgIntv = _minIntv = _maxIntv = _intvVariance = 0.0;

    if ( !_isFIFO) {
        if (_recSampleTimesCursor < _recSampleArraySize) {
            _recordedSampleTimes[_recSampleTimesCursor] = time;
            _recordedSampleIDs[_recSampleTimesCursor] = sampleID;
            _recSampleTimesCursor++;
        }
    } else {
        if (_recSampleTimesCursor == _recSampleArraySize) {
            memmove(_recordedSampleTimes, _recordedSampleTimes+1, (_recSampleTimesCursor-1)*sizeof(double));
            memmove(_recordedSampleIDs,   _recordedSampleIDs+1,   (_recSampleTimesCursor-1)*sizeof(int64_t));
            _recSampleTimesCursor--;
        }
        _recordedSampleTimes[_recSampleTimesCursor] = time;
        _recordedSampleIDs[_recSampleTimesCursor] = sampleID;
        _recSampleTimesCursor++;
    }
}

- (void)addSampleRefTime:(double)time withID:(int64_t)sampleID
{
    LXMutexLock(&_mutex);
    
    if (_recSampleArraySize < 1)  goto bail;

    if (_recordsIntervals) {
        LXPrintf("** stream time watcher (%p) can't record refTimes\n", self);
        goto bail;
    }
    
    [self _reallyAddTime:time withID:sampleID];
    
bail:
    LXMutexUnlock(&_mutex);
}

- (void)addInterval:(double)time withID:(int64_t)sampleID
{
    LXMutexLock(&_mutex);

    if (_recSampleArraySize < 1)  goto bail;
        
    if ( !_recordsIntervals) {
        LXPrintf("** stream time watcher (%p) can't record refTimes\n", self);
        goto bail;
    }
    
    [self _reallyAddTime:time withID:sampleID];
    
bail:
    LXMutexUnlock(&_mutex);
}


- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy]; }
    
- (NSString *)name {
    return _name; }
    

- (void)setIsFIFO:(BOOL)f {
    _isFIFO = f; }
    
- (BOOL)isFIFO {
    return _isFIFO; }

- (void)setRecordsIntervals:(BOOL)f {
    if (f != _recordsIntervals) {
        _recordsIntervals = f;
        _recSampleTimesCursor = 0;
    }
}

- (BOOL)recordsIntervals {
    return _recordsIntervals; }

    

- (BOOL)isAtEnd
{
    BOOL r;
    LXMutexLock(&_mutex);
    r = (_recSampleTimesCursor >= _recSampleArraySize) ? YES : NO;
    LXMutexUnlock(&_mutex);
    return r;
}

- (LXInteger)sampleCount
{
    LXInteger r;
    LXMutexLock(&_mutex);
    r = _recSampleTimesCursor;
    LXMutexUnlock(&_mutex);
    return r;
}

- (double)latestSampleRefTime
{
    double r;
    LXMutexLock(&_mutex);
    if (_recSampleTimesCursor < 1)
        r = 0.0;
    else
        r = _recordedSampleTimes[_recSampleTimesCursor-1];
    LXMutexUnlock(&_mutex);
    return r;
}

- (void)_computeStats
{
    if (_recordsIntervals) {
        if (_recSampleTimesCursor < 1) {
            _avgIntv = _minIntv = _maxIntv = 0.0;
        } else {
            LXInteger n = _recSampleTimesCursor;
            double *times = _recordedSampleTimes;
            LXInteger i;
            double minIntv = times[0];
            double maxIntv = minIntv;
            double sum = minIntv;
            for (i = 1; i < n; i++) {
                double t = times[i];
                sum += t;
                minIntv = MIN(minIntv, t);
                maxIntv = MAX(maxIntv, t);
            }
            
            // compute variance
            double devSqSum = 0.0;
            for (i = 0; i < n; i++) {
                double t = times[i];
                double dev = t - (sum/n);
                devSqSum += dev*dev;
            }
            _intvVariance = devSqSum / n;
            
            // 2011.01.22 -- to make the result more useful, eliminate the min/max outliers
            if (n > 6) {
                double oldAvg = sum / n;
                sum -= maxIntv;
                sum -= minIntv;
                n -= 2;
                ///printf("eliminating timewatch outliers (records intv): was %.3f --> now %.3f (%i samples, '%@')\n", oldAvg*1000, (sum/n)*1000, (int)n, [_name UTF8String]);
            }
            
            _avgIntv = sum / n;
            _minIntv = minIntv;
            _maxIntv = maxIntv;
        }
    }
    else {
        if (_recSampleTimesCursor < 4) {
            _avgIntv = _minIntv = _maxIntv = 0.0;
        } else {
            LXInteger n = _recSampleTimesCursor - 0;
            double *times = _recordedSampleTimes + 0;  // set this offset to 1 to disregard the first sample
            LXInteger i;
            double minSampleLen = times[1] - times[0];
            double maxSampleLen = minSampleLen;
            for (i = 2; i < n; i++) {
                double l = times[i] - times[i-1];
                if (l < minSampleLen) minSampleLen = l;
                if (l > maxSampleLen) maxSampleLen = l;
            }
            
            double sampleLenSum = 0.0;
            for (i = 1; i < n; i++) {
                sampleLenSum += (times[i] - times[i-1]);
            }
            double avgSampleTime = sampleLenSum / (n-1);
            
            // compute variance
            double devSqSum = 0.0;
            for (i = 1; i < n; i++) {
                double t = times[i] - times[i-1];
                double dev = t - avgSampleTime;
                ///NSLog(@"   .... %i -- %.3f, dev is %.3f", i, t, dev);
                devSqSum += dev*dev;
            }
            _intvVariance = devSqSum / (n-1);
            
            ///NSLog(@"'%@': variance %.6f, samples %i, sum %.5f", [self name], _intvVariance, n-1, devSqSum);
            
            // 2011.01.22 -- to make the result more useful, eliminate the min/max outliers
            if (n > 6) {
                double oldAvg = avgSampleTime;
                sampleLenSum -= minSampleLen;
                sampleLenSum -= maxSampleLen;
                n -= 2;
                avgSampleTime = sampleLenSum / (n-1);
                ///printf("eliminating timewatch outliers (records reftime): was %.3f --> now %.3f (%i samples, '%s')\n", oldAvg*1000, avgSampleTime*1000, (int)n, [_name UTF8String]);
            }
            
            ///NSLog(@"got sample times (%i):\n  min %f, max %f -- avg %f --> %f", n, minSampleLen, maxSampleLen, avgSampleTime, 1.0 / avgSampleTime);
            
            _avgIntv = avgSampleTime;
            _minIntv = minSampleLen;
            _maxIntv = maxSampleLen;
        }
    }
}

- (double)averageInterval
{
    double r;
    LXMutexLock(&_mutex);

    if (_avgIntv <= 0.0) [self _computeStats];
    r = _avgIntv;
    
    LXMutexUnlock(&_mutex);
    return r;
}

- (double)maxInterval
{
    double r;
    LXMutexLock(&_mutex);

    if (_maxIntv <= 0.0) [self _computeStats];
    r = _maxIntv;
    
    LXMutexUnlock(&_mutex);
    return r;
}

- (double)minInterval
{
    double r;
    LXMutexLock(&_mutex);

    if (_minIntv <= 0.0) [self _computeStats];
    r = _minIntv;
    
    LXMutexUnlock(&_mutex);
    return r;
}

- (double)latestInterval
{
    double r;
    LXMutexLock(&_mutex);

    double *times = _recordedSampleTimes;

    if (_recordsIntervals) {
        r = (_recSampleTimesCursor < 1) ? 0.0 : times[_recSampleTimesCursor-1];
    }
    else {
        if (_recSampleTimesCursor < 2) {
            r = 0.0;
        } else {
            r = (times[_recSampleTimesCursor-1] - times[_recSampleTimesCursor-2]);
        }
    }
    
    LXMutexUnlock(&_mutex);
    return r;
}

- (double)intervalVariance
{
    double r;
    LXMutexLock(&_mutex);

    if (_intvVariance <= 0.0) [self _computeStats];
    r = _intvVariance;
    
    LXMutexUnlock(&_mutex);
    return r;
}

- (NSDictionary *)timingInfoDict
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    LXMutexLock(&_mutex);
    
    [self _computeStats];
    
    [dict setObject:[NSNumber numberWithDouble:_avgIntv] forKey:@"averageInterval"];
    [dict setObject:[NSNumber numberWithDouble:_minIntv] forKey:@"minInterval"];
    [dict setObject:[NSNumber numberWithDouble:_maxIntv] forKey:@"maxInterval"];
    
    if (_recSampleTimesCursor > 0) {
        double *times = _recordedSampleTimes;
        int64_t *ids = _recordedSampleIDs;
        
        [dict setObject:[NSNumber numberWithDouble:times[0]] forKey:@"firstRecordedSampleTime"];
        [dict setObject:[NSNumber numberWithDouble:times[_recSampleTimesCursor - 1]] forKey:@"lastRecordedSampleTime"];
        
        [dict setObject:[NSNumber numberWithLongLong:ids[0]] forKey:@"firstRecordedSampleID"];
        [dict setObject:[NSNumber numberWithLongLong:ids[_recSampleTimesCursor - 1]] forKey:@"lastRecordedSampleID"];
    }
    
    LXMutexUnlock(&_mutex);
    return dict;
}


- (NSString *)debugContentsString
{
    NSMutableString *str;
    if (_name) {
        str = [NSMutableString stringWithFormat:@"Contents of time watcher %p ('%@'):\n", self, _name];
    } else {
        str = [NSMutableString stringWithFormat:@"Contents of time watcher %p:\n", self];    
    }
    
    LXMutexLock(&_mutex);
    
    char idStr[64];
    LXInteger i;
    for (i = 0; i < _recSampleTimesCursor; i++) {
        // printing 64-bit ints in a MinGW-compatible way looks like this...
        sprintf(idStr, "" LXPRINTF_SPEC_PREFIX_INT64 "d", _recordedSampleIDs[i]);
        
        if (_recordsIntervals) {
            [str appendFormat:@"    Sample %i:   interval %.3f ms -- id %s",  (int)i, 1000.0*_recordedSampleTimes[i], idStr];
        }
        else {
            [str appendFormat:@"    Sample %i:   time %f -- id %s",  (int)i, _recordedSampleTimes[i], idStr];
            if (i > 0) {
                [str appendFormat:@" -- interval was %.3f ms",  1000.0*(_recordedSampleTimes[i] - _recordedSampleTimes[i-1])];
            }
        }
        [str appendString:@" "];
    }
    
    LXMutexUnlock(&_mutex);
    return str;
}

- (void)debugPrintContents
{
    NSString *str = [self debugContentsString];
    LXPrintf("%s", [str UTF8String]);
}

@end
