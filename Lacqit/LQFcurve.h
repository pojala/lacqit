//
//  LQFcurve.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQCurveList.h"
#import "LacqitExport.h"

/*
  An fcurve is a curve list that's constrained in the x direction so that segments can't overlap.
  It's fundamentally up to the UI (or other data source) to enforce this.
  
  Fcurves are typically used for parameters varying over time, so they have a "duration" -- i.e. x length.
  This is also up to the UI to enforce.
*/


LACQIT_EXPORT_VAR NSString * const kLQFcurveAttribute_LoopMode;

LACQIT_EXPORT_VAR NSString * const kLQFcurvePlayOnce;
LACQIT_EXPORT_VAR NSString * const kLQFcurvePlayLoop;



@interface LQFcurve : LQCurveList {

    NSString *_name;
    
    id _owner;
    
    double _duration;
    
    NSMutableDictionary *_attrs;
}

- (NSString *)name;
- (void)setName:(NSString *)name;

- (id)owner;
- (void)setOwner:(id)owner;

- (double)duration;
- (void)setDuration:(double)duration;

- (void)getMinValue:(double *)pMin maxValue:(double *)pMax;
- (double)minValue;
- (double)maxValue;

- (void)setAttribute:(id)attr forKey:(NSString *)key;
- (id)attributeForKey:(NSString *)key;

- (LXInteger)indexOfSegmentContainingX:(double)x;

// -- keyframe utilities

// the fps argument determines the allowed interval within which a point is considered a match
- (LXInteger)indexOfPointAtX:(double)x frameRate:(double)fps;  


// -- autosmooth curve utilities from Conduit Live / Radi

+ (LXUInteger)autoSmoothCurveType;

- (void)updateAutoSmoothForPointSelection:(NSIndexSet *)selIndexes;

@end
