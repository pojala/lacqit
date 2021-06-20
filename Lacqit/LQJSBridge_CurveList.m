//
//  LQJSBridge_CurveList.m
//  Lacqit
//
//  Created by Pauli Ojala on 19.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_CurveList.h"
#import "LQCurveList.h"
#import <Lacefx/LXCurveFunctions.h>
#import <Lacqit/LQJSUtils.h>



@implementation LQJSBridge_CurveList

@synthesize styleAttributes = _styleAttributes;

+ (Class)curveClass {
    return [LQCurveList class]; }
    

- (void)_setCurve:(id)clist
{
    [_curveList autorelease];
    _curveList = [clist copy];
}


- (id)initInJSContext:(JSContextRef)context withOwner:(id)owner curveList:(LQCurveList *)cl
{
    self = [super initInJSContext:context withOwner:owner];
    if (self) {
        if (cl)
            [self _setCurve:cl];
        else
            _curveList = [[[[self class] curveClass] alloc] init];
    }
    return self;
}

- (id)initInJSContext:(JSContextRef)context withOwner:(id)owner
{
    return [self initInJSContext:context withOwner:owner curveList:nil];
}


- (void)dealloc
{
    [_curveList release];
    [_styleAttributes release];
    [super dealloc];
}

- (LQCurveList *)curveList {
    return _curveList; }


- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    id newObj = [[[self class] alloc] initInJSContext:dstContext
                                                withOwner:nil
                                                curveList:[self curveList]];  // is copied when set
    return [newObj autorelease];
}

+ (NSString *)constructorName
{
    return @"CurveList";
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    if ([arguments count] >= 1) {
        id arg = [arguments objectAtIndex:0];
        
        if ([arg respondsToSelector:@selector(curveList)]) {
            [self _setCurve:[arg curveList]];
        }
    }
    
    if ( !_curveList)
        _curveList = [[[[self class] curveClass] alloc] init];
}



#pragma mark --- JS-exported properties ---

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"length", @"closed", @"style", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return NO; //return [propertyName isEqual:@"closed"] ? YES : NO;
}

- (NSInteger)length
{
    const BOOL closed = _curveList.isClosed;
    NSInteger numSegs = [_curveList numberOfSegments];
    if (closed)
        numSegs++;
    return numSegs;
}
    
- (BOOL)isClosed {
    return [_curveList isClosed]; }

- (NSDictionary *)style {
    return (_styleAttributes) ? _styleAttributes : [NSDictionary dictionary];
}

- (void)setStyle:(id)obj
{
    self.styleAttributes = LQJSConvertKeyedItemsRecursively(obj);
}


#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames  // if the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"appendCurveToPoint",
                                     @"insertCurve",
                                     @"addArc",
                                     @"close",
                                     @"open",
                                                                          
                                     @"curveAt",
                                     @"tessellateCurveAt",
                                     
                                     @"copy",
                                     nil];
}

- (id)lqjsCallClose:(NSArray *)args context:(id)contextObj {
    [_curveList close];
    return nil;
}

- (id)lqjsCallOpen:(NSArray *)args context:(id)contextObj {
    [_curveList open];
    return nil;
}


- (id)lqjsCallCopy:(NSArray *)args context:(id)contextObj
{
    ///JSContextRef jsCtx = [self jsContextRefFromJSCallContextObj:contextObj];
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    
    // the init method will copy the curvelist object
    id newObj = [[[self class] alloc] initInJSContext:[interp jsContextRef] withOwner:nil curveList:_curveList];
    return [newObj autorelease];
}

- (NSString *)_curveStringIDFromSegmentType:(LXInteger)type
{
    switch (type) {
        default:
        case kLXLinearSegment:          return @"linear";
        case kLXInOutBezierSegment:     return @"bezier";
        case kLXCatmullRomSegment:      return @"autosmooth";
    }
}

- (id)_jsObjectFromLXPoint:(LXPoint)p
{
    id newObj = [self emptyProtectedJSObject];
    [newObj setProtected:NO];
    [newObj setValue:[NSNumber numberWithDouble:p.x] forKey:@"x"];
    [newObj setValue:[NSNumber numberWithDouble:p.y] forKey:@"y"];
    return newObj;
}

// returns a plain JS object with the following properties: startPoint, endPoint, curveType, [controlPoint1, controlPoint2]
// ... sure seems expensive to marshal a struct like this, but oh well, that's JavaScript...
- (id)lqjsCallCurveAt:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index]) return nil;
    
    if (index < 0) {
        return nil;
    }
    const BOOL closed = _curveList.isClosed;
    NSInteger numSegs = [_curveList numberOfSegments];
    if (( !closed && index >= numSegs) || (closed && index > numSegs)) {
        return nil;
    }
    LXCurveSegment seg = (index == numSegs) ? *[_curveList closingSegment] : [_curveList segmentAtIndex:index];
    
    id newObj = [self emptyProtectedJSObject];
    [newObj setProtected:NO];
    [newObj setValue:[self _curveStringIDFromSegmentType:seg.type] forKey:@"curveType"];
    [newObj setValue:[self _jsObjectFromLXPoint:seg.startPoint] forKey:@"startPoint"];
    [newObj setValue:[self _jsObjectFromLXPoint:seg.endPoint] forKey:@"endPoint"];
    
    if (seg.type == kLXInOutBezierSegment) {
        [newObj setValue:[self _jsObjectFromLXPoint:seg.controlPoint1] forKey:@"controlPoint1"];
        [newObj setValue:[self _jsObjectFromLXPoint:seg.controlPoint2] forKey:@"controlPoint2"];
    }
    return newObj;
}

- (id)lqjsCallTessellateCurveAt:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    long index = -1;
    if ( ![self parseLongFromArg:[args objectAtIndex:0] outValue:&index]) return nil;
    
    if (index < 0) {
        return nil;
    }
    const BOOL closed = _curveList.isClosed;
    NSInteger numSegs = [_curveList numberOfSegments];
    if (( !closed && index >= numSegs) || (closed && index > numSegs)) {
        return nil;
    }
    
    LXCurveSegment seg = (index == numSegs) ? *[_curveList closingSegment] : [_curveList segmentAtIndex:index];
    
    if (seg.type == kLXLinearSegment) {
        return [NSArray arrayWithObjects:
                [NSNumber numberWithDouble:seg.startPoint.x],
                [NSNumber numberWithDouble:seg.startPoint.y],
                [NSNumber numberWithDouble:seg.endPoint.x],
                [NSNumber numberWithDouble:seg.endPoint.y],
                nil];
    }
    
    long steps = 16;
    [self parseLongFromArg:[args objectAtIndex:1] outValue:&steps];
    if (steps <= 0)
        return [NSArray array];
    if (steps > 1024)
        steps = 1024;
    
    LXPoint points[steps];
    LXCalcCurve(seg, steps, points);
    
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:steps];
    for (NSInteger i = 0; i < steps; i++) {
        [arr addObject:[NSNumber numberWithDouble:points[i].x]];
        [arr addObject:[NSNumber numberWithDouble:points[i].y]];
    }
    
    return arr;
}

- (int)_curveSegmentTypeFromStringID:(NSString *)typeStr
{
    if ([typeStr isEqualToString:@"linear"]) {
        return kLXLinearSegment;
    } 
    else if ([typeStr isEqualToString:@"bezier"]) {
        return kLXInOutBezierSegment;
    } 
    else if ([typeStr isEqualToString:@"autosmooth"] || 
             [typeStr isEqualToString:@"cardinal"] || [typeStr isEqualToString:@"catmull-rom"] || [typeStr isEqualToString:@"catmullrom"]) {
        return kLXCatmullRomSegment;
    }
    else return -1;
}

// curveList.addArc(xc, yc, radius, angle1, angle2, [anticlockwise]);
- (id)lqjsCallAddArc:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 5) return nil;
    
    double xc = [[args objectAtIndex:0] doubleValue];
    double yc = [[args objectAtIndex:1] doubleValue];
    double radius = [[args objectAtIndex:2] doubleValue];
    double angle1 = [[args objectAtIndex:3] doubleValue];
    double angle2 = [[args objectAtIndex:4] doubleValue];

    if ( !isfinite(xc) || !isfinite(yc) ||
         !isfinite(radius) || !isfinite(angle1) || !isfinite(angle2)) {
        return nil;
    }

    BOOL isForward = YES;
    if ([args count] >= 6) {
        isForward = ([[args objectAtIndex:5] doubleValue] == 0.0);  // for last arg, true means anti-clockwise
    }
    
    LXCurveSegment *segs = NULL;
    size_t segCount = 0;
    LXCreateBezierCurvesForArc(xc, yc, radius,  angle1, angle2, isForward,  &segs, &segCount);

    [_curveList insertSegments:segs count:segCount atIndex:[_curveList numberOfSegments]];
    return self;
}

// curveList.insertCurve("linear", x1, y1, x2, y2, [index]);
- (id)lqjsCallInsertCurve:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 5) return nil;
    
    NSString *typeStr = [[args objectAtIndex:0] description];
    int segType = [self _curveSegmentTypeFromStringID:typeStr];
    
    if (segType == -1) {
        NSLog(@"** invalid curve type given in JS call: '%@'", typeStr);
        return nil;
    }
    
    double x1 = [[args objectAtIndex:1] doubleValue];
    double y1 = [[args objectAtIndex:2] doubleValue];
    double x2 = [[args objectAtIndex:3] doubleValue];
    double y2 = [[args objectAtIndex:4] doubleValue];
    int argsConsumed = 5;
    if ( !isfinite(x1) || !isfinite(y1) ||
         !isfinite(x2) || !isfinite(y2))
        return nil;

    NSPoint startP = NSMakePoint(x1, y1);
    NSPoint endP = NSMakePoint(x2, y2);
    NSPoint cp1 = startP;
    NSPoint cp2 = endP;

    if (segType == kLXInOutBezierSegment && [args count] >= 9) {
        double cp1x = [[args objectAtIndex:5] doubleValue];
        double cp1y = [[args objectAtIndex:6] doubleValue];
        double cp2x = [[args objectAtIndex:7] doubleValue];
        double cp2y = [[args objectAtIndex:8] doubleValue];
        argsConsumed = 9;
        
        if ( !isfinite(cp1x) || !isfinite(cp1y) ||
             !isfinite(cp2x) || !isfinite(cp2y)) return nil;

        cp1 = NSMakePoint(cp1x, cp1y);
        cp2 = NSMakePoint(cp2x, cp2y);
    }
    
    LXInteger segIndex = [_curveList numberOfSegments];
    
    // the insertion index can be given as the last argument
    if ([args count] > argsConsumed) {
        segIndex = [[args objectAtIndex:argsConsumed] intValue];

        if (segIndex > [_curveList numberOfSegments] || segIndex < 0)
            return nil;
    }

    LXCurveSegment seg;
    seg.startPoint = LXPointFromNSPoint(startP);
    seg.endPoint = LXPointFromNSPoint(endP);
    seg.controlPoint1 = LXPointFromNSPoint(cp1);
    seg.controlPoint2 = LXPointFromNSPoint(cp2);
    seg.type = segType;
    
    [_curveList insertContinuousSegment:seg atIndex:segIndex];
    return self;
}


// JS call argument examples:
//  curveList.appendCurveToPoint("linear", x, y);
//  curveList.appendCurveToPoint("bezier", x, y, cp1x, cp1y, cp2x, cp2y);
//  curveList.appendCurveToPoint("cardinal", x, y);

- (id)lqjsCallAppendCurveToPoint:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 3) return nil;
    
    if ([_curveList numberOfSegments] < 1)
        return nil;
    
    NSString *typeStr = [[args objectAtIndex:0] description];
    int segType = [self _curveSegmentTypeFromStringID:typeStr];
    
    if (segType == -1) {
        NSLog(@"** invalid curve type given in JS call: '%@'", typeStr);
        return nil;
    }
    
    double x = [[args objectAtIndex:1] doubleValue];
    double y = [[args objectAtIndex:2] doubleValue];
    if ( !isfinite(x) || !isfinite(y)) return nil;

    NSPoint endP = NSMakePoint(x, y);
    NSPoint cp1 = NSZeroPoint;
    NSPoint cp2 = NSZeroPoint;
    
    if (segType == kLXInOutBezierSegment && [args count] >= 7) {
        double cp1x = [[args objectAtIndex:3] doubleValue];
        double cp1y = [[args objectAtIndex:4] doubleValue];
        double cp2x = [[args objectAtIndex:5] doubleValue];
        double cp2y = [[args objectAtIndex:6] doubleValue];
        
        if ( !isfinite(cp1x) || !isfinite(cp1y) ||
             !isfinite(cp2x) || !isfinite(cp2y)) return nil;

        cp1 = NSMakePoint(cp1x, cp1y);
        cp2 = NSMakePoint(cp2x, cp2y);
    }
    
    [_curveList appendCurveSegmentToPoint:endP type:segType controlPoint1:cp1 controlPoint2:cp2];
    return self;
}


@end
