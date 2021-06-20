//
//  LQCurveFunctions.h
//  Lacqit
//
//  Created by Pauli Ojala on 22.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LacqitExport.h"
#import "LQLXBasicFunctions.h"
#import <Lacefx/LXCurveFunctions.h>


// draws the curve segment in the current NSGraphicsContext using NSBezierPath
LACQIT_EXPORT void LQNSStrokeCurveSegment(LXCurveSegment seg);

LACQIT_EXPORT void LQNSStrokeCurveSegmentWithTransform(LXCurveSegment seg, NSAffineTransform *trs);


// base curve functions have moved to LXCurveFunctions in Lacefx


/*LACQIT_EXPORT void LQCalcCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray);

LACQIT_EXPORT NSPoint LQCalcCurvePointAtU(LQCurveSegment seg, LXFloat u);

LACQIT_EXPORT LXFloat LQEstimateUForCurveAtX(LQCurveSegment seg, LXFloat x);


// called by LQCalcCurve for curves of type kLQInOutBezierSegment
LACQIT_EXPORT void LQCalcBezierCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray);  

// called by LQCalcCurve for curves of type kLQHermiteSegment and kLQCatmullRomSegment
LACQIT_EXPORT void LQCalcHermiteCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray);
*/

