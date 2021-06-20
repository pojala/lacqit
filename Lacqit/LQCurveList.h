//
//  LQCurveList.h
//  Lacqit
//
//  Created by Pauli Ojala on 23.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import "LQLXBasicFunctions.h"
#import "LQCurveFunctions.h"


@interface LQCurveList : NSObject  <NSCopying, NSCoding> {
    LXUInteger _segCount;
    LXCurveSegment *_segs;
    
    BOOL _isClosed;
    LXCurveSegment _closingSeg;
    
    LXRGBA _rgba;
    
    void *__clRes1;
    void *__clRes2;
}

- (LXUInteger)numberOfSegments;
- (void)setNumberOfSegments:(LXUInteger)segCount;

- (LQCurveList *)curveListWithSubRange:(NSRange)range;

- (LXCurveSegment)segmentAtIndex:(LXInteger)index;
- (LXCurveSegmentType)segmentTypeAtIndex:(LXInteger)index;
- (LXCurveSegment)lastSegment;

- (void)setSegment:(LXCurveSegment)segment forIndex:(LXInteger)index;
- (void)setSegmentType:(LXCurveSegmentType)type forIndex:(LXInteger)index;

// inserts raw segments without modifying the existing segments for continuity
- (void)insertSegments:(LXCurveSegment *)addSegs count:(size_t)addCount atIndex:(LXInteger)index;

// inserts a segment connecting the surrounding segments' start/end points to maintain continuity
- (void)insertContinuousSegment:(LXCurveSegment)segment atIndex:(LXInteger)index;

- (void)deleteSegmentAtIndex:(LXInteger)index;
- (void)deletePointAtIndex:(LXInteger)index;

- (void)subdivideSegmentAtIndex:(LXInteger)index splitPosition:(LXFloat)splitPos;  // to split the segment into two at the middle, pass 0.5 for splitPos

- (BOOL)appendLinearSegmentToPoint:(NSPoint)p;  // returns NO if curve is empty (can't append a point without a start point)

- (BOOL)appendCurveSegmentToPoint:(NSPoint)p type:(LXCurveSegmentType)curveSegType
                    controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2;

- (LXCurveSegment *)curveSegmentsArray;

- (BOOL)isClosed;
- (void)close;
- (void)open;
- (LXCurveSegment *)closingSegment;  // if the curve is closed, this segment contains the last segment's properties (start/end points are ignored, they depend on the "real" segments)

- (void)setRGBA:(LXRGBA)c;
- (LXRGBA)rgba;

- (NSString *)stringRepresentation;

- (NSArray *)curveListsForContinuityBreaks;

// Lacefx drawing utility
- (BOOL)getXYZWVertices:(LXVertexXYZW *)vertices arraySize:(const LXInteger)bufferSize
        maxSamplesPerSegment:(LXInteger)maxSamples
        outVertexCount:(LXInteger *)pVertexCount;

// ... following two methods (and -convertToFcurveStyleCardinal..) should be moved into LQFcurve  ---
- (BOOL)getYValue:(double *)outY atX:(double)x;

- (BOOL)plotCurveIntoArray:(LXFloat *)array
            arraySize:(const LXInteger)arraySize
            minX:(LXFloat)minX maxX:(LXFloat)maxX;

// convenience function that sets the required prev/next control points for all catmull-rom curve segments
// (if you call this when the curve is complete, you can just pass NSZeroPoint as cp1/cp2 for any catmull-rom segments).
// the returned value is the number of segments that were modified by this call.
- (LXInteger)setAutomaticControlPointsForCardinalSegments;

// this implements something fairly similar to Photoshop's Curves tools:
// hermite (catmull-rom) segments with a tweak to make the curve behave nicer with tight point intervals; x overlap not permitted.
- (void)convertToFcurveStyleCardinalSegmentsInRange:(NSRange)range;


// plist serialization
- (NSDictionary *)plistRepresentation;
- (id)initWithPlistDictionary:(NSDictionary *)dict;

@end
