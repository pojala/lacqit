/*
 *  LQModelTypes.h
 *  Lacqit
 *
 *  Created by Pauli Ojala on 22.8.2008.
 *  Copyright 2008 Lacquer oy/ltd. All rights reserved.
 *
 */

#ifndef _LQMODELTYPES_H_
#define _LQMODELTYPES_H_


typedef enum {
    kLQLinearSegment = 0,
    
    kLQInBezierSegment,
    kLQOutBezierSegment,
    kLQInOutBezierSegment,
    
    kLQHermiteSegment,      // requires two tangent control points
    kLQCardinalSegment,     // requires a tightness constant in seg.spec, and previous/next points in cp1/cp2
    kLQCatmullRomSegment,   // same as cardinal segment, but tightness is always 0.5
} LQCurveSegmentType;


typedef struct _LQCurveSegment {
    LQCurveSegmentType type;
	NSPoint startPoint;
	NSPoint controlPoint1;
	NSPoint controlPoint2;
	NSPoint endPoint;
    LXFloat spec;
} LQCurveSegment;


#endif  // _LQMODELTYPES_H_
