//
//  LQCurveList.m
//  Lacqit
//
//  Created by Pauli Ojala on 23.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQCurveList.h"


@implementation LQCurveList

+ (NSString *)lacTypeID {
    return @"CurveList"; }


- (NSString *)description
{
    long segCount = [self numberOfSegments];
    return [NSString stringWithFormat:@"<%@: %p -- %ld segments>",
                                    [self class], self, segCount];
}


- (id)init {
    self = [super init];
    
    _rgba = LXBlackOpaqueRGBA;
    return self;
}

- (id)initWithSegmentCount:(LXInteger)segCount segments:(LXCurveSegment *)segs
{
    self = [self init];
    [self setNumberOfSegments:segCount];
    memcpy(_segs, segs, segCount * sizeof(LXCurveSegment));
    
    return self;
}

- (void)dealloc
{
    _lx_free(_segs);
    _segCount = 0;
    
    ///[_color release];
    
    [super dealloc];
}

- (LXUInteger)numberOfSegments {
    return _segCount; }
    
- (void)setNumberOfSegments:(LXUInteger)segCount
{
    if (_segCount != segCount) {
        _segCount = segCount;
    
        if ( !_segs) {
            _segs = _lx_calloc(_segCount, sizeof(LXCurveSegment));
        } else {
            _segs = _lx_realloc(_segs, _segCount * sizeof(LXCurveSegment));
        }
    }
}

- (void)setSegmentType:(LXCurveSegmentType)type forIndex:(LXInteger)index
{
    if (index >= _segCount) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    _segs[index].type = type;
}

- (void)setSegment:(LXCurveSegment)segment forIndex:(LXInteger)index
{
    if (index >= _segCount) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    _segs[index] = segment;
}

- (void)insertSegments:(LXCurveSegment *)addSegs count:(size_t)addCount atIndex:(LXInteger)index
{
    if (index > _segCount || index < 0) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    
    _segs = (_segs) ? _lx_realloc(_segs, (_segCount+addCount) * sizeof(LXCurveSegment))
                    :         _lx_malloc((_segCount+addCount) * sizeof(LXCurveSegment));
    
    if (_segCount > 0 && (_segCount-index) > 0) {
        memmove(_segs + index + addCount,  _segs + index,  (_segCount-index) * sizeof(LXCurveSegment));
    }
    _segCount += addCount;
    
    memcpy(_segs + index,  addSegs,  addCount * sizeof(LXCurveSegment));
}

- (void)insertContinuousSegment:(LXCurveSegment)segment atIndex:(LXInteger)index
{
    [self insertSegments:&segment count:1 atIndex:index];
    
    if (index > 0)
        _segs[index-1].endPoint = _segs[index].startPoint;
        
    if (index < _segCount-1)
        _segs[index+1].startPoint = _segs[index].endPoint;
}

- (BOOL)appendLinearSegmentToPoint:(NSPoint)p
{
    if (_segCount < 1) return NO;
    
    LXCurveSegment seg;
    seg.startPoint = _segs[_segCount-1].endPoint;
    seg.endPoint = LXPointFromNSPoint(p);
    seg.controlPoint1 = LXPointFromNSPoint(p);
    seg.controlPoint2 = LXPointFromNSPoint(p);
    seg.type = kLXLinearSegment;
    
    [self insertContinuousSegment:seg atIndex:_segCount];
    return YES;
}

- (BOOL)appendCurveSegmentToPoint:(NSPoint)p type:(LXCurveSegmentType)curveSegType
                    controlPoint1:(NSPoint)cp1 controlPoint2:(NSPoint)cp2
{
    if (_segCount < 1) return NO;
    
    LXCurveSegment seg;
    seg.startPoint = _segs[_segCount-1].endPoint;
    seg.endPoint = LXPointFromNSPoint(p);
    seg.controlPoint1 = LXPointFromNSPoint(cp1);
    seg.controlPoint2 = LXPointFromNSPoint(cp2);
    seg.type = curveSegType;
    
    [self insertContinuousSegment:seg atIndex:_segCount];
    return YES;

}


- (void)deleteSegmentAtIndex:(LXInteger)index
{
    if (index >= _segCount || index < 0) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    
    if (index < _segCount-1) {
        memmove(_segs + index, _segs + index+1, (_segCount-index-1) * sizeof(LXCurveSegment));
    }
    _segCount--;
    
    if (index > 0)
        _segs[index-1].endPoint = _segs[index].startPoint;
        
    if (index < _segCount-1)
        _segs[index+1].startPoint = _segs[index].endPoint;
}

- (void)deletePointAtIndex:(LXInteger)index
{
    if (index > _segCount) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    if (_segCount < 1) return;
    
    if (index == _segCount) {
        if (_segCount > 1) {
            [self deleteSegmentAtIndex:index-1];
        } else {
            // keep the sole point in a zero-length segment
            _segs[0].endPoint = _segs[0].startPoint;
            _segs[0].type = kLXLinearSegment;        
        }
    }
    else if (index == _segCount-1) {
        if (_segCount > 1) {
            LXPoint lastPoint = _segs[index].endPoint;
            [self deleteSegmentAtIndex:index];
            _segs[_segCount-1].endPoint = lastPoint;
        } else {
            // zero-length segment
            ///NSLog(@"deleting first point, end: %@", NSStringFromLXPoint(_segs[0].endPoint));
            _segs[0].startPoint = _segs[0].endPoint;
            _segs[0].type = kLXLinearSegment;
        }
    }
    else {
        [self deleteSegmentAtIndex:index];
    }
}


- (void)subdivideSegmentAtIndex:(LXInteger)index splitPosition:(LXFloat)splitPos
{
    if (index >= _segCount || index < 0) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return;
    }
    splitPos = MIN(1.0f, MAX(0.0f, splitPos));
    
    LXCurveSegment origSeg = _segs[index];

    [self insertSegments:&origSeg count:1 atIndex:index];
    
    LXCurveSegment *seg1 = _segs + index;
    LXCurveSegment *seg2 = _segs + index + 1;
    
    //LXPoint midPoint = LXMakePoint((origSeg.startPoint.x + origSeg.endPoint.x) * 0.5,
    //                               (origSeg.startPoint.y + origSeg.endPoint.y) * 0.5);
    
    LXPoint midPoint = LXCalcCurvePointAtU(origSeg, splitPos);

    seg1->endPoint = midPoint;
    seg2->startPoint = midPoint;
}


- (LXCurveSegmentType)segmentTypeAtIndex:(LXInteger)index
{
    if (index >= _segCount) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        return 0;
    }

    return _segs[index].type;
}


#define LXNULLCURVESEGMENT  { 0, LXZeroPoint, LXZeroPoint, LXZeroPoint, LXZeroPoint }


- (LXCurveSegment)segmentAtIndex:(LXInteger)index
{
    if (index >= _segCount) {
        NSLog(@"** %s: index out of bounds (%ld, %ld)", __func__, (long)index, (long)_segCount);
        LXCurveSegment nullSeg = LXNULLCURVESEGMENT;
        return nullSeg;
    }
    
    return _segs[index];
}

- (LXCurveSegment)lastSegment
{
    if (_segCount == 0) {
        LXCurveSegment nullSeg = LXNULLCURVESEGMENT;
        return nullSeg;
    } else {
        return _segs[_segCount-1];
    }
}

- (LXCurveSegment *)curveSegmentsArray {
    return _segs; }

/*
- (void)setClosed:(BOOL)f
{
    if (_isClosed != f) {
        _isClosed = f;
        
        if (_isClosed && _segCount >= 2) {  // check if we need to add the closing segment
            LXPoint firstPoint = _segs[0].startPoint;
            LXPoint lastPoint = _segs[_segCount-1].endPoint;
            
            if (firstPoint.x != lastPoint.x || firstPoint.y != lastPoint.y) {
                [self appendLinearSegmentToPoint:NSPointFromLXPoint(firstPoint)];
            }
        }
    }
}
*/
- (void)close {
    if ( !_isClosed) {
        _isClosed = YES;
        
         /*if (_segCount >= 2) {  // add a closing segment if necessary
            LXPoint firstPoint = _segs[0].startPoint;
            LXPoint lastPoint = _segs[_segCount-1].endPoint;
            
            if (firstPoint.x != lastPoint.x || firstPoint.y != lastPoint.y) {
                [self appendLinearSegmentToPoint:NSPointFromLXPoint(firstPoint)];
            }
        }*/
    }
}

- (void)open {
    if (_isClosed) {
        _isClosed = NO;
        
         /*if (_segCount >= 3) {  // delete the last segment if it's a closing segment
            LXPoint firstPoint = _segs[0].startPoint;
            LXPoint lastPoint = _segs[_segCount-1].endPoint;
            
            if (firstPoint.x == lastPoint.x || firstPoint.y == lastPoint.y) {
                [self deleteSegmentAtIndex:_segCount-1];
            }
        }*/
    }
}

- (void)_setClosed:(BOOL)f {
    _isClosed = f; }

- (void)setClosed:(BOOL)f {
    if (f) [self close];
    else [self open];
}

- (BOOL)isClosed {
    return _isClosed; }
    
- (LXCurveSegment *)closingSegment {
    return &_closingSeg; }

/*
- (void)setColor:(NSColor *)c {
    [_color autorelease];
    _color = [c copy];
}

- (NSColor *)color {
    return _color; }
*/

- (void)setRGBA:(LXRGBA)c {
    _rgba = c; }
    
- (LXRGBA)rgba {
    return _rgba; }

- (void)setRGBA_sRGB:(LXRGBA)c {
    _rgba = c; }

- (LXRGBA)rgba_sRGB {
    return _rgba; }


static NSString *stringFromCurveType(LXUInteger type)
{
    switch (type) {
        case kLXLinearSegment:      return @"linear";
        case kLXInOutBezierSegment: return @"bezier";
        case kLXHermiteSegment:     return @"hermite";
        case kLXCardinalSegment:     return @"cardinal";
        case kLXCatmullRomSegment:     return @"catmullrom";
        default:    return [NSString stringWithFormat:@"segmenttype_%i", (int)type];
    }
}

static LXUInteger curveTypeFromString(NSString *str)
{
    if ([str isEqualToString:@"linear"])            return kLXLinearSegment;
    else if ([str isEqualToString:@"bezier"])       return kLXInOutBezierSegment;
    else if ([str isEqualToString:@"hermite"])      return kLXHermiteSegment;
    else if ([str isEqualToString:@"cardinal"])     return kLXCardinalSegment;
    else if ([str isEqualToString:@"catmullrom"])   return kLXCatmullRomSegment;
    else return kLXLinearSegment;
}

static NSArray *arrayFromLXPoint(LXPoint p)
{
    return [NSArray arrayWithObjects:[NSNumber numberWithDouble:p.x], [NSNumber numberWithDouble:p.y], nil];
}

static LXPoint lxPointFromArray(NSArray *arr)
{
    if ([arr count] < 2) return LXZeroPoint;
    return LXMakePoint([[arr objectAtIndex:0] doubleValue], [[arr objectAtIndex:1] doubleValue]);
}

static NSDictionary *dictFromCurveSegment(LXCurveSegment *seg)
{
    if ( !seg) return nil;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            stringFromCurveType(seg->type), @"type",
                                            arrayFromLXPoint(seg->startPoint), @"start",
                                            arrayFromLXPoint(seg->endPoint), @"end",
                                            nil];
                                            
    if (seg->type != kLXLinearSegment && seg->type != kLXCardinalSegment && seg->type != kLXCatmullRomSegment) {
        [dict setObject:arrayFromLXPoint(seg->controlPoint1) forKey:@"cp1"];
        [dict setObject:arrayFromLXPoint(seg->controlPoint2) forKey:@"cp2"];
    }
    if (seg->type == kLXCardinalSegment) {
        [dict setObject:arrayFromLXPoint(seg->tangentInfo) forKey:@"tightness"];
    }
    
    return dict;
}

static void setCurveSegmentFromDict(LXCurveSegment *seg, NSDictionary *dict)
{
    if ( !seg || !dict) return;
    
    seg->type = curveTypeFromString([dict objectForKey:@"type"]);
    seg->startPoint = lxPointFromArray([dict objectForKey:@"start"]);
    seg->endPoint = lxPointFromArray([dict objectForKey:@"end"]);
    
    if (seg->type != kLXLinearSegment && seg->type != kLXCardinalSegment && seg->type != kLXCatmullRomSegment) {
        seg->controlPoint1 = lxPointFromArray([dict objectForKey:@"cp1"]);
        seg->controlPoint2 = lxPointFromArray([dict objectForKey:@"cp2"]);
    }
    if (seg->type == kLXCardinalSegment) {
        seg->tangentInfo = lxPointFromArray([dict objectForKey:@"tightness"]);
    }
}


- (NSDictionary *)plistRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    const LXUInteger segCount = _segCount;
    if (segCount < 1) return dict;

    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:segCount];
    LXUInteger i;
    for (i = 0; i < segCount; i++) {
        LXCurveSegment *seg = _segs + i;
        
        [arr addObject:dictFromCurveSegment(seg)];
    }
    [dict setObject:arr forKey:@"segments"];
    
    if ([self isClosed]) {
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"isClosed"];
        
        NSMutableDictionary *closingSeg = [NSMutableDictionary dictionaryWithDictionary:dictFromCurveSegment(&_closingSeg)];
        [closingSeg removeObjectForKey:@"start"];
        [closingSeg removeObjectForKey:@"end"];
        [dict setObject:closingSeg forKey:@"closingSegmentInfo"];
    }
    
    return dict;  // needs to be a mutable dict for subclasses
}

- (id)initWithPlistDictionary:(NSDictionary *)dict
{
    self = [self init];

    BOOL needsCatmullUpdate = NO;
    
    id segsArr = [dict objectForKey:@"segments"];
    if ([segsArr isKindOfClass:[NSArray class]] && [segsArr count] > 0) {
        LXUInteger count = [segsArr count];
        [self setNumberOfSegments:count];
        
        NSAssert1(_segCount == count, @"invalid segcount (%i)", (int)_segCount);
        
        LXUInteger i;
        for (i = 0; i < count; i++) {
            setCurveSegmentFromDict(_segs + i, (NSDictionary *)[segsArr objectAtIndex:i]);
            
            if ( !needsCatmullUpdate && (_segs[i].type == kLXCatmullRomSegment || _segs[i].type == kLXCardinalSegment))
                needsCatmullUpdate = YES;
        }        
    }
    
    if ([[dict objectForKey:@"isClosed"] boolValue]) {
        _isClosed = YES;
        
        setCurveSegmentFromDict(&_closingSeg, [dict objectForKey:@"closingSegmentInfo"]);
        if (_closingSeg.type == kLXCatmullRomSegment || _closingSeg.type == kLXCardinalSegment)
            needsCatmullUpdate = YES;
    }
    
    if (needsCatmullUpdate) [self setAutomaticControlPointsForCardinalSegments];
    
    return self;
}

- (NSString *)_additionalJSONPropertiesForSegmentAtIndex:(LXInteger)index
{
    return nil;    // subclasses can override
}

- (NSString *)stringRepresentation
{
    NSMutableString *str = [NSMutableString string];
    
    const LXUInteger segCount = _segCount;
    if (segCount < 1) return str;
    
    [str appendString:@"[ "];
    
    LXUInteger i;
    for (i = 0; i < segCount; i++) {
        LXCurveSegment *seg = _segs + i;
        
        [str appendFormat:@" { 'type': %@, 'start': %@, 'end': %@", stringFromCurveType(seg->type),
                    NSStringFromPoint(NSPointFromLXPoint(seg->startPoint)),
                    NSStringFromPoint(NSPointFromLXPoint(seg->endPoint))
            ];
        
        if (seg->type != kLXLinearSegment) {
        [str appendFormat:@", 'cp1': %@, 'cp2': %@",
                    NSStringFromPoint(NSPointFromLXPoint(seg->controlPoint1)),
                    NSStringFromPoint(NSPointFromLXPoint(seg->controlPoint2))
            ];            
        }
        
        NSString *add = [self _additionalJSONPropertiesForSegmentAtIndex:i];
        if ([add length] > 0) {
            [str appendFormat:@", %@", add];
        }
        
        [str appendString:@" }\n"];
    }
    
    [str appendString:@"] "];
        
    return str;
}


#pragma mark --- curve utils ---

- (LXInteger)setAutomaticControlPointsForCardinalSegments
{
    const LXUInteger segCount = _segCount;
    if (segCount < 1)
        return 0;
        
    ///LXCurveSegment *prevSeg = (_isClosed) ? (_segs + (segCount-1)) : NULL;
    LXPoint *prevPoint = (_isClosed) ? &(_segs[_segCount-1].endPoint) : NULL;
    
    ///NSLog(@"%s: %i points...", __func__, segCount);
    
    LXInteger n = 0;
    LXUInteger i;
    for (i = 0; i < segCount; i++) {
        LXCurveSegment *seg = _segs + i;
        
        if (seg->type == kLXCatmullRomSegment || seg->type == kLXCardinalSegment) {
            n++;
            ///LXCurveSegment *nextSeg = (i < segCount-1) ? (_segs + (i+1))
            ///                                           : ((_isClosed) ? _segs : NULL);
            LXPoint *nextPoint = (i < segCount-1) ? &(_segs[i+1].endPoint)
                                                  : ((_isClosed) ? &(_segs[0].startPoint) : &(_segs[i].endPoint));
                                                       
            if (prevPoint)
                seg->controlPoint1 = *prevPoint; ///prevSeg->startPoint;
            if (nextPoint)
                seg->controlPoint2 = *nextPoint; ///nextSeg->endPoint;
                
            /*NSLog(@"... %i: segment is %@ -> %@, cp1 is %@ (%i), cp2 is %@ (%i), ", i,
                    NSStringFromLXPoint(seg->startPoint), NSStringFromLXPoint(seg->endPoint),
                    NSStringFromLXPoint(seg->controlPoint1), (prevPoint != NULL),
                    NSStringFromLXPoint(seg->controlPoint2), (nextPoint != NULL));
                    */
        }
        prevPoint = &(seg->startPoint);
    }
    
    // do the closing segment too
    if (_isClosed) {
        LXCurveSegment *seg = &_closingSeg;
        
        if (seg->type == kLXCatmullRomSegment || seg->type == kLXCardinalSegment) {
            n++;
            
            LXPoint *nextPoint = &(_segs[0].endPoint);
            if (prevPoint)
                seg->controlPoint1 = *prevPoint;
            if (nextPoint)
                seg->controlPoint2 = *nextPoint;
        }
    }
    
    return n;
}

// this implements something fairly similar to Photoshop's curves by converting the curve list to hermite curves
// and calculating catmull-rom tangents with a tweak to keep them from bending the curve in the x direction
- (void)convertToFcurveStyleCardinalSegmentsInRange:(NSRange)range
{
    LXUInteger count = [self numberOfSegments];
    LXUInteger i;
    //for (i = 0; i < count; i++) {
    
    for (i = range.location; i < range.location + range.length; i++) {
        LXCurveSegment seg = [self segmentAtIndex:i];

        seg.type = kLXHermiteSegment;
        
        LXPoint prevPoint = (i == 0) ? LXMakePoint(seg.startPoint.x - (seg.endPoint.x - seg.startPoint.x) * 0.1,
                                                   seg.startPoint.y - (seg.endPoint.y - seg.startPoint.y) * 0.1)
                                     : [self segmentAtIndex:i-1].startPoint;
                            
        LXPoint nextPoint = (i == count-1) ? LXMakePoint(seg.endPoint.x + (seg.endPoint.x - seg.startPoint.x) * 0.1,
                                                         seg.endPoint.y + (seg.endPoint.y - seg.startPoint.y) * 0.1)
                                     : [self segmentAtIndex:i+1].endPoint;

        LXFloat lenX = fmax(0.0, seg.endPoint.x - seg.startPoint.x - 0.0001);
        //LXFloat lenXHalf = 0.5 * lenX;

        seg.controlPoint1 = LXMakePoint(0.5*(seg.endPoint.x - prevPoint.x),  // catmull-rom method for computing hermite tangents
                                        0.5*(seg.endPoint.y - prevPoint.y)
                                        );
                                        
        if ((lenX) < (seg.controlPoint1.x)) {
            //NSLog(@".. seg %i: x len half %.3f; cp1 x %.3f", i, lenXHalf, seg.controlPoint1.x);
            LXFloat mul = pow((lenX / seg.controlPoint1.x), 0.8);  // a weird hack to make the curve behave nicer in x
            seg.controlPoint1.x *= mul;
            seg.controlPoint1.y *= mul;
        }

        seg.controlPoint2 = LXMakePoint(0.5*(nextPoint.x - seg.startPoint.x),
                                        0.5*(nextPoint.y - seg.startPoint.y)
                                        );
        
        if ((lenX) < (seg.controlPoint2.x)) {
            LXFloat mul = pow((lenX / seg.controlPoint2.x), 0.8);
            seg.controlPoint2.x *= mul;
            seg.controlPoint2.y *= mul;
        }
        
        /*if (seg.controlPoint1.x + seg.controlPoint2.x > lenX * 2.0) {
            NSLog(@" -- constraining x points (%.3f / %3f - %3f)", seg.controlPoint1.x, seg.controlPoint2.x, lenX);
            LXFloat m = lenX / (seg.controlPoint1.x + seg.controlPoint2.x);
            seg.controlPoint1.x *= m;
            seg.controlPoint2.x *= m;
        }*/

        //NSLog(@"tangents for seg %i:\n   %.3f, %.3f  --  %.3f, %.3f  --  %.3f, %.3f  --  %.3f, %.3f", i,  seg.startPoint.x, seg.startPoint.y,
        //                seg.controlPoint1.x, seg.controlPoint1.y,  seg.controlPoint2.x, seg.controlPoint2.y,  seg.endPoint.x, seg.endPoint.y);
        
        [self setSegment:seg forIndex:i];
    }
}

- (LQCurveList *)curveListWithSubRange:(NSRange)range
{
    if (range.length < 1)
        return nil;
    
    if (range.location >= _segCount || range.location+range.length > _segCount) {
        NSLog(@"** %s: invalid range: %@, segcount is %ld", __func__, NSStringFromRange(range), (long)_segCount);
        return nil;
    }
    
    LQCurveList *newList = [[[self class] alloc] initWithSegmentCount:range.length segments:_segs + range.location];
    
    return [newList autorelease];
}

- (NSArray *)curveListsForContinuityBreaks
{
    NSMutableArray *subpathRanges = nil; //[NSMutableArray array];
    NSInteger segCount = _segCount;
    LXCurveSegment *segs = _segs;
    LXPoint prevEnd = segs[0].endPoint;
    NSInteger start = 0;
    NSInteger end;
    for (end = 1; end < segCount; end++) {
        LXCurveSegment *seg = segs + end;
        
        if (prevEnd.x != seg->startPoint.x || prevEnd.y != seg->startPoint.y) {
            if ( !subpathRanges)
                subpathRanges = [NSMutableArray array];
            
            [subpathRanges addObject:[NSValue valueWithRange:NSMakeRange(start, end-start)]];
            //NSLog(@"new subpath starts at %ld, prev is: %ld -> %ld", (long)end, (long)start, (long)end-1);
            start = end;
        }
        
        prevEnd = seg->endPoint;
    }
    
    if ( !subpathRanges || [subpathRanges count] < 1) {
        return [NSArray arrayWithObject:self]; // --
    }
    
    if (end-1 > start) {
        [subpathRanges addObject:[NSValue valueWithRange:NSMakeRange(start, end-start)]];
    }
    
    NSInteger n = [subpathRanges count];
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:n];
    for (NSInteger i = 0; i < n; i++) {
        NSRange r = [[subpathRanges objectAtIndex:i] rangeValue];
        LQCurveList *sublist = [self curveListWithSubRange:r];
        
        [sublist setClosed:YES];
        
        [arr addObject:sublist];
    }
    return arr;
}


#pragma mark --- NSCopying & NSCoding ---

- (id)copyWithZone:(NSZone *)zone
{
    LQCurveList *newList = [[[self class] alloc] initWithSegmentCount:_segCount segments:_segs];
    
    [newList _setClosed:_isClosed];
    
    [newList setRGBA:_rgba];
    
    *([newList closingSegment]) = _closingSeg;

    return newList;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    /*LXUInteger _segCount;
    LXCurveSegment *_segs;
    
    BOOL _isClosed;
    
    LXRGBA _rgba;
*/
    if (_segCount > 0) {
        size_t curveSerSize = LXCurveArrayGetSerializedDataSize(_segs, _segCount);
        if (curveSerSize > 0) {
            NSMutableData *serData = [NSMutableData dataWithLength:curveSerSize];
        
            BOOL success = LXCurveArraySerialize(_segs, _segCount, [serData mutableBytes], curveSerSize);
            if ( !success) {
                NSLog(@"** %s (%@): unable to serialize curve data", __func__, self);
            } else {
                [coder encodeObject:serData forKey:@"curveList::lxSerCurveArray"];
            }
        }
    }
    [coder encodeObject:NSStringFromLXRGBA(_rgba) forKey:@"curveList::rgba"];
    
    [coder encodeBool:_isClosed forKey:@"curveList::isClosed"];
    
    [coder encodeInt:_closingSeg.type forKey:@"curveList::closingSeg.type"];
    [coder encodePoint:NSPointFromLXPoint(_closingSeg.controlPoint1) forKey:@"curveList::closingSeg.cp1"];
    [coder encodePoint:NSPointFromLXPoint(_closingSeg.controlPoint2) forKey:@"curveList::closingSeg.cp2"];
    [coder encodePoint:NSPointFromLXPoint(_closingSeg.tangentInfo) forKey:@"curveList::closingSeg.tangentInfo"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    
    _isClosed = [coder decodeBoolForKey:@"curveList::isClosed"];
    
    if ([coder containsValueForKey:@"curveList::closingSeg.type"]) {
        _closingSeg.type = [coder decodeIntForKey:@"curveList::closingSeg.type"];
        _closingSeg.controlPoint1 = LXPointFromNSPoint([coder decodePointForKey:@"curveList::closingSeg.cp1"]);
        _closingSeg.controlPoint2 = LXPointFromNSPoint([coder decodePointForKey:@"curveList::closingSeg.cp2"]);
        _closingSeg.tangentInfo =   LXPointFromNSPoint([coder decodePointForKey:@"curveList::closingSeg.tangentInfo"]);
    }
    
    NSString *rgbaStr = [coder decodeObjectForKey:@"curveList::rgba"];
    _rgba = (rgbaStr) ? LXRGBAFromNSString(rgbaStr) : LXBlackOpaqueRGBA;

    NSData *serData = [coder decodeObjectForKey:@"curveList::lxSerCurveArray"];
    if (serData) {
        LXDECLERROR(err);
    
        BOOL ok = LXCurveArrayCreateFromSerializedData([serData bytes], [serData length],
                                                       &_segs, &_segCount,
                                                       &err);
        if ( !ok) {
            NSLog(@"** %s (%@): curvearray deserialize failed: %i / %s", __func__, self, err.errorID, err.description);
        } else {
        }
    }
    return self;
}


#pragma mark --- fcurve eval / plotting ---

- (BOOL)getYValue:(double *)outY atX:(double)x
{
    if ( !outY) return NO;
    if ( !isfinite(x)) return NO;
    if (_segCount < 1) return NO;
    
    if (x < _segs[0].startPoint.x) {  // wanted x is before the segments
        *outY = _segs[0].startPoint.y;
        return (isfinite(*outY)) ? YES : NO;
    }
    
    const LXUInteger n = _segCount;
    LXUInteger i;
    for (i = 0; i < n; i++) {
        LXCurveSegment *seg = _segs + i;
        if (x >= seg->startPoint.x && x < seg->endPoint.x) {
            break;
        }
    }
    
    double y = NAN;
    
    if (i == n) {  // wanted x is after the segments, so just return the last y value
        y = _segs[n-1].endPoint.y;
    } else {
        LXCurveSegment *seg = _segs + i;
        
        LXFloat u = LXEstimateUForCurveAtX(*seg, x);
        LXPoint p = LXCalcCurvePointAtU(*seg, u);
        y = p.y;
    }
    
    *outY = y;
    return (isfinite(y)) ? YES : NO;
}

- (BOOL)plotCurveIntoArray:(LXFloat *)array
            arraySize:(const LXInteger)arraySize
            minX:(LXFloat)minX maxX:(LXFloat)maxX
{
    if ( !array || arraySize < 2) return NO;
    
    const LXInteger numSamples = arraySize;
    double xInc = ((double)maxX - minX) / (double)(numSamples - 1);
    
    LXCurveSegment *segs = _segs;
    const LXInteger segCount = _segCount;
    LXInteger segn = 0;
    LXInteger arrn = 0;
    
    double x;
    for (x = minX; x < maxX; x += xInc) {
        while (segs[segn].startPoint.x > x || segs[segn].endPoint.x < x) {
            segn++;
            if (segn == segCount) {
                LXInteger j;
                for (j = arrn; j < arraySize; j++)
                    array[j] = 0.0;
                return NO;
            }
        }
        LXCurveSegment *seg = _segs + segn;
        double xInSeg = fmin(seg->endPoint.x, x);
        
        LXFloat u = LXEstimateUForCurveAtX(*seg, xInSeg);
        LXPoint p = LXCalcCurvePointAtU(*seg, u);
        
        if ( !isfinite(p.x))
            p.x = 0.0;
        
        array[arrn++] = p.y;
    }
    return YES;
}            



#pragma mark --- Lacefx format conversion ---


- (BOOL)getXYZWVertices:(LXVertexXYZW *)vertices arraySize:(const LXInteger)bufferSize
        maxSamplesPerSegment:(LXInteger)maxSamples
        outVertexCount:(LXInteger *)pVertexCount
{
    if ( !vertices || bufferSize < 1 || !pVertexCount) return NO;
    
    const BOOL isClosed = _isClosed;
    const LXUInteger segCount = (isClosed && _segCount >= 2) ? _segCount+1 : _segCount;
    BOOL complete = NO;
    LXInteger n = 0;
    LXInteger segN = 0;
    LXCurveSegment *prevSeg = NULL;
    
    maxSamples = MAX(2, maxSamples);
    
    LXPoint segPointsArr[maxSamples];
    memset(segPointsArr, 0, maxSamples*sizeof(LXPoint));
    
    while (segN < segCount) {
        LXCurveSegment *seg;
        const BOOL isClosingSeg = (isClosed && segN == segCount-1);
        if ( !isClosingSeg) {
            seg = _segs + segN;
        } else {
            seg = &_closingSeg;
            seg->startPoint = _segs[_segCount-1].endPoint;
            seg->endPoint = _segs[0].startPoint;
        }
        segN++;
                
        // vertex count for this segment
        BOOL isContinued = (prevSeg && NSEqualPoints(NSPointFromLXPoint(seg->startPoint), NSPointFromLXPoint(prevSeg->endPoint)));
        LXInteger vcount;
        switch (seg->type) {
            case kLXLinearSegment:   vcount = 2;  break;
            default:                 vcount = maxSamples;  break;
        }
        if (isContinued)
            vcount--;
        
        if (n + vcount > bufferSize) {
            complete = NO;
            break;
        } else {
            if ( !isContinued) {
                LXSetVertex2(vertices+(n++),  seg->startPoint.x, seg->startPoint.y);
                
                ///NSLog(@"vertex %i: %.3f, %.3f", n-1, seg->startPoint.x, seg->startPoint.y);
            }
            
            if (seg->type != kLXLinearSegment) {
                switch (seg->type) {
                    default:
                    case kLXInOutBezierSegment:
                        LXCalcBezierCurve(*seg, maxSamples, segPointsArr);
                        break;
                    
                    case kLXHermiteSegment:
                    case kLXCatmullRomSegment:
                        LXCalcHermiteCurve(*seg, maxSamples, segPointsArr);
                        break;
                }
                
                int si;
                for (si = 1; si < maxSamples-1; si++) {
                    LXSetVertex2(vertices+(n++),  segPointsArr[si].x,  segPointsArr[si].y);
                }
            }
            LXSetVertex2(vertices+(n++),  seg->endPoint.x, seg->endPoint.y);
            
            
            ///NSLog(@"vertex %i: %.3f, %.3f", n-1, seg->endPoint.x, seg->endPoint.y);
            
            if (segN == segCount)
                complete = YES;
        }
        prevSeg = seg;
    }
    
    *pVertexCount = n;
    return complete;
}

@end
