//
//  LQCurveFunctions.m
//  Lacqit
//
//  Created by Pauli Ojala on 22.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQCurveFunctions.h"
#import <Lacefx/LXCurveFunctions.h>


static void drawLinearSegmentNS(LXCurveSegment seg, NSAffineTransform *trs)
{
    NSPoint p0 = NSPointFromLXPoint(seg.startPoint);
    NSPoint p1 = NSPointFromLXPoint(seg.endPoint);
    
    if (trs) {
        p0 = [trs transformPoint:p0];
        p1 = [trs transformPoint:p1];
    }
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:p0];
    [path lineToPoint:p1];
    [path stroke];
}

static void drawBezierSegmentNS(LXCurveSegment seg, NSAffineTransform *trs)
{
    if (seg.type == kLXInBezierSegment) {  // default control point to an interpolated value
        seg.controlPoint2 = LXLinearSegmentPointAtU(seg, 2.0/3.0);
    } else if (seg.type == kLXOutBezierSegment) {
        seg.controlPoint1 = LXLinearSegmentPointAtU(seg, 1.0/3.0);
    }
    
    NSPoint p0 = NSPointFromLXPoint(seg.startPoint);
    NSPoint p1 = NSPointFromLXPoint(seg.endPoint);
    NSPoint cp1 = NSPointFromLXPoint(seg.controlPoint1);
    NSPoint cp2 = NSPointFromLXPoint(seg.controlPoint2);
    
    if (trs) {
        p0 = [trs transformPoint:p0];
        p1 = [trs transformPoint:p1];
        cp1 = [trs transformPoint:cp1];
        cp2 = [trs transformPoint:cp2];
    }

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:p0];
    [path curveToPoint:p1
            controlPoint1:cp1
            controlPoint2:cp2];
    [path stroke];
}

static void drawHermiteSegmentNS(LXCurveSegment seg, const LXInteger steps, NSAffineTransform *trs)
{
    // draw hermite curves as linear segments
    NSBezierPath *path = [NSBezierPath bezierPath];
    LXInteger i;
    
    LXPoint *pointArr = _lx_malloc(steps * sizeof(LXPoint));
    LXCalcHermiteCurve(seg, steps, pointArr);

    NSPoint p0 = NSPointFromLXPoint(seg.startPoint);
    NSPoint p1 = NSPointFromLXPoint(seg.endPoint);

    if (trs) {
        p0 = [trs transformPoint:p0];
        p1 = [trs transformPoint:p1];
    }

    [path moveToPoint:p0];
        
    for (i = 0; i < steps; i++) {
        NSPoint p = NSPointFromLXPoint(pointArr[i]);
        if (trs) {
            p = [trs transformPoint:p];
        }
        [path lineToPoint:p];
    }
        
    [path lineToPoint:p1];
    [path stroke];
    
    _lx_free(pointArr);
}


void LQNSStrokeCurveSegment(LXCurveSegment seg)
{
    LQNSStrokeCurveSegmentWithTransform(seg, nil);
}


void LQNSStrokeCurveSegmentWithTransform(LXCurveSegment seg, NSAffineTransform *trs)
{
    const LXUInteger type = LXCurveSegmentTypeNoFlags(seg.type);
    switch (type) {
        case kLXLinearSegment:
            drawLinearSegmentNS(seg, trs);
            break;
        
        case kLXInBezierSegment:
        case kLXOutBezierSegment:
        case kLXInOutBezierSegment:
            drawBezierSegmentNS(seg, trs);
            break;
                                    
        case kLXHermiteSegment:
        case kLXCardinalSegment:
        case kLXCatmullRomSegment: {
            // TODO: this steps value should be based on the coord scaling actually in use for the graphics context
            LXInteger steps = 32;

            drawHermiteSegmentNS(seg, steps, trs);
            break;
        }
                                    
        default:
            NSLog(@"** %s: unknown curve type (%ld)", __func__, (long)seg.type);
    }
}




// ---- base curve functions have moved to LXCurveFunctions in Lacefx ----

#if (0)


#pragma mark --- beziers ---

// c argument is coefficient array (4 NSPoints)
static inline NSPoint getBezierCurvePoint(const NSPoint *c, const double u)
{
    NSPoint p;
    p.x = c[0].x + u * (c[1].x + u * (c[2].x + u * c[3].x));
    p.y = c[0].y + u * (c[1].y + u * (c[2].y + u * c[3].y));
    return p;
}

// these four coefficients are equivalent to the ABCD parameters in some source material.
// (however the coeffs are in opposite order: coeff[0] is "D", coeff[3] is "A")
static void parametrizeBezierCurve(NSPoint *coefficients,  // array size must be 4
                                   NSPoint startPoint, NSPoint endPoint, NSPoint controlPoint1, NSPoint controlPoint2)
{
    NSPoint tangent2;
    tangent2.x = 3.0 * (endPoint.x - controlPoint2.x);
    tangent2.y = 3.0 * (endPoint.y - controlPoint2.y);

    coefficients[0] = startPoint;
    coefficients[1].x = 3.0 * (controlPoint1.x - startPoint.x);  // 1st tangent
    coefficients[1].y = 3.0 * (controlPoint1.y - startPoint.y);  // 1st tangent
    coefficients[2].x = 3.0 * (endPoint.x - startPoint.x) - 2.0 * coefficients[1].x - tangent2.x;
    coefficients[2].y = 3.0 * (endPoint.y - startPoint.y) - 2.0 * coefficients[1].y - tangent2.y;
    coefficients[3].x = 2.0 * (startPoint.x - endPoint.x) + coefficients[1].x + tangent2.x;
    coefficients[3].y = 2.0 * (startPoint.y - endPoint.y) + coefficients[1].y + tangent2.y;
}

static inline void setControlPointForInOrOutBezSegType(LQCurveSegment *seg)
{
    if ( !seg)
        return;
    else if (seg->type == kLQInBezierSegment) {
        seg->controlPoint1 = LQLinearSegmentPointAtU(*seg, 1.0/3.0);
    }
    else if (seg->type == kLQOutBezierSegment) {
        seg->controlPoint1 = LQLinearSegmentPointAtU(*seg, 2.0/3.0);
    }
}

void LQCalcBezierCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray)
{
    if ( !outArray || steps < 1) return;
    
    setControlPointForInOrOutBezSegType(&seg);

    NSPoint coeffs[4];
    parametrizeBezierCurve(coeffs,  seg.startPoint, seg.endPoint, seg.controlPoint1, seg.controlPoint2);
    
    LXInteger i;
    for (i = 0; i < steps; i++) {
        const double u = (double)i / steps;
        outArray[i] = getBezierCurvePoint((const NSPoint *)coeffs, u);
    }
}


#pragma mark --- hermite/cardinal ---

static inline void setTangentPointsForHermiteOrCardinalSeg(LQCurveSegment *seg)
{
    const BOOL isCatmull = (seg->type == kLQCatmullRomSegment);
    const BOOL isAutoTangents = (isCatmull || seg->type == kLQCardinalSegment);    
    
    if (isAutoTangents) {
        // cardinal spline tangent points are computed from the previous and next points.
        // these need to be passed as cp1/cp2.
        // formula for the tangents is: T[i] = a * ( P[i+1] - P[i-1] )
        NSPoint p0 = seg->controlPoint1;
        NSPoint p1 = seg->startPoint;
        NSPoint p2 = seg->endPoint;
        NSPoint p3 = seg->controlPoint2;

        // "tightness constant" is 0.5 for catmull-rom splines
        const LXFloat cardinalA1 = (isCatmull) ? 0.5 : seg->spec;
        const LXFloat cardinalA2 = (isCatmull) ? 0.5 : seg->spec;
        
        LXFloat t1x = cardinalA1 * (p2.x - p0.x);
        LXFloat t1y = cardinalA1 * (p2.y - p0.y);
        
        LXFloat t2x = cardinalA2 * (p3.x - p1.x);
        LXFloat t2y = cardinalA2 * (p3.y - p1.y);
        
        //NSLog(@"%s: computed cardinal points: (%@) - %@ - %@ - (%@)\n    --> (%.3f, %.3f), (%.3f, %.3f)", __func__, 
        //            NSStringFromPoint(seg->controlPoint1), NSStringFromPoint(seg->startPoint), NSStringFromPoint(seg->endPoint), NSStringFromPoint(seg->controlPoint2),
        //            t1x, t1y,  t2x, t2y);
        
        seg->controlPoint1 = NSMakePoint(t1x, t1y);
        seg->controlPoint2 = NSMakePoint(t2x, t2y);
    }    
}


void LQCalcHermiteCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray)
{
/* pseudocode from http://www.cubic.org/docs/hermite.htm :
 moveto (P1);                            // move pen to startpoint
 for (int t=0; t < steps; t++)
 {
  float s = (float)t / (float)steps;    // scale s to go from 0 to 1
  float h1 =  2s^3 - 3s^2 + 1;          // calculate basis function 1
  float h2 = -2s^3 + 3s^2;              // calculate basis function 2
  float h3 =   s^3 - 2*s^2 + s;         // calculate basis function 3
  float h4 =   s^3 -  s^2;              // calculate basis function 4
  vector p = h1*P1 +                    // multiply and sum all funtions
             h2*P2 +                    // together to build the interpolated
             h3*T1 +                    // point along the curve.
             h4*T2;
  lineto (p)                            // draw to calculated point on the curve
 }
*/
    if ( !outArray || steps < 1) return;
    
    setTangentPointsForHermiteOrCardinalSeg(&seg);

    // hermite curve parameter matrix
    const LXFloat m11 =  2.0,  m12 = -3.0,  m14 =  1.0;
    const LXFloat m21 = -2.0,  m22 =  3.0;
    const LXFloat m31 =  1.0,  m32 = -2.0,  m33 =  1.0;
    const LXFloat m41 =  1.0,  m42 = -1.0;

    LXInteger i;
    for (i = 0; i < steps; i++) {
        const LXFloat u = (LXFloat)i / steps;
        const LXFloat u2 = u * u;
        const LXFloat u3 = u2 * u;
        
        const LXFloat h1 =  m11*u3 + m12*u2         + m14 ;
        const LXFloat h2 =  m21*u3 + m22*u2 ;
        const LXFloat h3 =  m31*u3 + m32*u2 + m33*u ;
        const LXFloat h4 =  m41*u3 + m42*u2 ;
        
        LXFloat x = h1*seg.startPoint.x + h2*seg.endPoint.x + h3*seg.controlPoint1.x + h4*seg.controlPoint2.x;
        LXFloat y = h1*seg.startPoint.y + h2*seg.endPoint.y + h3*seg.controlPoint1.y + h4*seg.controlPoint2.y;
        
        outArray[i] = NSMakePoint(x, y);
    }
}

static inline NSPoint hermiteOrCardinalCurvePointAtU(LQCurveSegment seg, LXFloat u)
{
    setTangentPointsForHermiteOrCardinalSeg(&seg);

    // hermite curve parameter matrix
    const LXFloat m11 =  2.0,  m12 = -3.0,  m14 =  1.0;
    const LXFloat m21 = -2.0,  m22 =  3.0;
    const LXFloat m31 =  1.0,  m32 = -2.0,  m33 =  1.0;
    const LXFloat m41 =  1.0,  m42 = -1.0;

    const LXFloat u2 = u * u;
    const LXFloat u3 = u2 * u;    
    const LXFloat h1 =  m11*u3 + m12*u2         + m14 ;
    const LXFloat h2 =  m21*u3 + m22*u2 ;
    const LXFloat h3 =  m31*u3 + m32*u2 + m33*u ;
    const LXFloat h4 =  m41*u3 + m42*u2 ;
    
    LXFloat x = h1*seg.startPoint.x + h2*seg.endPoint.x + h3*seg.controlPoint1.x + h4*seg.controlPoint2.x;
    LXFloat y = h1*seg.startPoint.y + h2*seg.endPoint.y + h3*seg.controlPoint1.y + h4*seg.controlPoint2.y;
        
    return NSMakePoint(x, y);
}



NSPoint LQCalcCurvePointAtU(LQCurveSegment seg, LXFloat u)
{
    switch (seg.type) {
        case kLQLinearSegment:
            return LQLinearSegmentPointAtU(seg, u);
        
        case kLQInBezierSegment:
        case kLQOutBezierSegment:
        case kLQInOutBezierSegment: {
            NSPoint coeffs[4];
            setControlPointForInOrOutBezSegType(&seg);
            parametrizeBezierCurve(coeffs,  seg.startPoint, seg.endPoint, seg.controlPoint1, seg.controlPoint2);
            return getBezierCurvePoint((const NSPoint *)coeffs, u);
        }
        
        case kLQHermiteSegment:
        case kLQCardinalSegment:
        case kLQCatmullRomSegment:
            return hermiteOrCardinalCurvePointAtU(seg, u);
        
        default:
            NSLog(@"** %s: unknown curve type (%i)", __func__, seg.type);
            return NSZeroPoint;            
    }
}

void LQCalcCurve(LQCurveSegment seg, const LXInteger steps, NSPoint *outArray)
{
    switch (seg.type) {
        case kLQLinearSegment: {
            LXInteger i;
            for (i = 0; i < steps; i++) {
                const LXFloat u = (LXFloat)i / steps;
                outArray[i] = LQLinearSegmentPointAtU(seg, u);
            }
            return;
        }
            
        case kLQInBezierSegment:
        case kLQOutBezierSegment:
        case kLQInOutBezierSegment:
            LQCalcBezierCurve(seg, steps, outArray);
            return;
            
        case kLQHermiteSegment:
        case kLQCardinalSegment:
        case kLQCatmullRomSegment:
            LQCalcHermiteCurve(seg, steps, outArray);
            return;
    }
}


#pragma mark --- estimation of U ---

static inline LXFloat calcUForLinearCurveAtX(LQCurveSegment seg, LXFloat x)
{
    LXFloat lenX = seg.endPoint.x - seg.startPoint.x;
    x -= seg.startPoint.x;

    if (lenX != 0.0) {
        return (x / lenX);
    } else
        return 0.0;
}

static inline LXFloat estimateUForBezierCurveAtX(LQCurveSegment seg, LXFloat x)
{
    setControlPointForInOrOutBezSegType(&seg);

    NSPoint coeffs[4];
    parametrizeBezierCurve(coeffs,  seg.startPoint, seg.endPoint, seg.controlPoint1, seg.controlPoint2);

    // start guessing at u == x
    double u = calcUForLinearCurveAtX(seg, x);
    
    // do N iterations of newton approximation
    LXInteger i;
    for (i = 0; i < 3; i++) {
        double guess = ((coeffs[3].x*u + coeffs[2].x)*u + coeffs[1].x)*u + coeffs[0].x;

        double deriv = (3.0*coeffs[3].x*u + 2.0*coeffs[2].x)*u + coeffs[1].x;
    
        u = u - (guess - x) / deriv;
    }
    
    return u;
}

static inline LXFloat estimateUForHermiteCurveAtX(LQCurveSegment seg, LXFloat x)
{
    setTangentPointsForHermiteOrCardinalSeg(&seg);

    // hermite curve parameter matrix
    const LXFloat m11 =  2.0,  m12 = -3.0,  m14 =  1.0;
    const LXFloat m21 = -2.0,  m22 =  3.0;
    const LXFloat m31 =  1.0,  m32 = -2.0,  m33 =  1.0;
    const LXFloat m41 =  1.0,  m42 = -1.0;

    // start guessing at u == x
    double u = calcUForLinearCurveAtX(seg, x);
    
    LXInteger i;
    for (i = 0; i < 3; i++) {
        const LXFloat u2 = u * u;
        const LXFloat u3 = u2 * u;    
        const LXFloat h1 =  m11*u3 + m12*u2         + m14 ;
        const LXFloat h2 =  m21*u3 + m22*u2 ;
        const LXFloat h3 =  m31*u3 + m32*u2 + m33*u ;
        const LXFloat h4 =  m41*u3 + m42*u2 ;
    
        LXFloat guess = h1*seg.startPoint.x + h2*seg.endPoint.x + h3*seg.controlPoint1.x + h4*seg.controlPoint2.x;
        
        LXFloat d_h1 = (m11*3.0)*u2 + (m12*2.0)*u;
        LXFloat d_h2 = (m21*3.0)*u2 + (m22*2.0)*u;
        LXFloat d_h3 = (m31*3.0)*u2 + (m32*2.0)*u + m33;
        LXFloat d_h4 = (m41*3.0)*u2 + (m42*2.0)*u;
        
        LXFloat deriv = d_h1*seg.startPoint.x + d_h2*seg.endPoint.x + d_h3*seg.controlPoint1.x + d_h4*seg.controlPoint2.x;
        
        u = u - (guess - x) / deriv;
    }
    
    return u;
}

LXFloat LQEstimateUForCurveAtX(LQCurveSegment seg, LXFloat x)
{
    switch (seg.type) {
        case kLQLinearSegment:      return calcUForLinearCurveAtX(seg, x);
        
        case kLQInBezierSegment:
        case kLQOutBezierSegment:
        case kLQInOutBezierSegment:
                                    return estimateUForBezierCurveAtX(seg, x);
        
        case kLQHermiteSegment:
        case kLQCardinalSegment:
        case kLQCatmullRomSegment:
                                    return estimateUForHermiteCurveAtX(seg, x);
        
        default:
            NSLog(@"** %s: unknown curve type (%i)", __func__, seg.type);
            return 0.0;
    }
}

#endif // DISABLED

