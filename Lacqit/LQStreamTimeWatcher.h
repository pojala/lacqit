//
//  LQStreamTimeWatcher.h
//  Lacqit
//
//  Created by Pauli Ojala on 6.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQBaseFrameworkHeader.h"
#import <Lacefx/LXMutex.h>


@interface LQStreamTimeWatcher : NSObject {

    NSString                *_name;

    double                  *_recordedSampleTimes;
    int64_t                 *_recordedSampleIDs;
    size_t                  _recSampleArraySize;
    LXInteger               _recSampleTimesCursor;
    
    BOOL                    _isFIFO;
    BOOL                    _recordsIntervals;
    
    double                  _avgIntv;
    double                  _minIntv;
    double                  _maxIntv;
    double                  _intvVariance;
    
    LXMutex                 _mutex;
}

- (id)initWithCapacity:(LXInteger)capacity;

- (void)addSampleRefTime:(double)time;
- (void)addSampleRefTime:(double)time withID:(int64_t)sampleID;

- (void)addInterval:(double)time withID:(int64_t)sampleID;  // only applicable if -setRecordsIntervals:YES is called

///- (void)removeSamplesInRange:(NSRange)range;

- (void)setName:(NSString *)name;
- (NSString *)name;

// when in FIFO mode, old samples will be discarded when the watcher reaches its capacity
- (void)setIsFIFO:(BOOL)f;
- (BOOL)isFIFO;

- (void)setRecordsIntervals:(BOOL)f;
- (BOOL)recordsIntervals;

- (BOOL)isAtEnd;

- (LXInteger)sampleCount;

- (double)latestSampleRefTime;

- (double)averageInterval;
- (double)minInterval;
- (double)maxInterval;
- (double)latestInterval;
- (double)intervalVariance;

- (NSDictionary *)timingInfoDict;

- (NSString *)debugContentsString;
- (void)debugPrintContents;

@end
