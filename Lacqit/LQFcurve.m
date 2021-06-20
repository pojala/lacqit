//
//  LQFcurve.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.6.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQFcurve.h"


NSString * const kLQFcurveAttribute_LoopMode = @"loopMode";

NSString * const kLQFcurvePlayOnce = @"once";
NSString * const kLQFcurvePlayLoop = @"loop";



@implementation LQFcurve

+ (NSString *)lacTypeID {
    return @"Fcurve"; }


- (id)init {
    self = [super init];
    if (self) {
        _attrs = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_attrs release];
    [super dealloc];
}


- (NSString *)name {
    return _name; }
    
- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy]; }
    

- (id)owner {
    return _owner; }
    
- (void)setOwner:(id)owner {
    _owner = owner; }
    

- (double)duration {
    return _duration; }
    
- (void)setDuration:(double)duration {
    _duration = duration; }


- (void)getMinValue:(double *)pMin maxValue:(double *)pMax
{
    double minv = DBL_MAX;
    double maxv = DBL_MIN;
    
    LXUInteger n = _segCount;
    LXUInteger i;
    for (i = 0; i < n; i++) {
        LXCurveSegment *seg = _segs + i;
        if (i == 0) {
            minv = maxv = seg->startPoint.y;
        }
        // assumes that curves are continuous -- only checks startpoint for index 0
        if (seg->endPoint.y < minv)
            minv = seg->endPoint.y;
        if (seg->endPoint.y > maxv)
            maxv = seg->endPoint.y;
    }
    
    if (pMin && minv != DBL_MAX) *pMin = minv;
    if (pMax && maxv != DBL_MIN) *pMax = maxv;
}

- (double)minValue
{
    double v;
    [self getMinValue:&v maxValue:NULL];
    return v;
}

- (double)maxValue
{
    double v;
    [self getMinValue:NULL maxValue:&v];
    return v;
}


#pragma mark --- attributes ---

- (void)setAttribute:(id)attr forKey:(NSString *)key
{
    if ( !key || [key length] < 1) {
        NSLog(@"** tried to use null key for stream source attribute");
        return;
    }
    if (attr && attr != [NSNull null])
        [_attrs setObject:attr forKey:key];
    else
        [_attrs removeObjectForKey:key];
}

- (id)attributeForKey:(NSString *)key
{
    id val;
    val = [_attrs objectForKey:key];
    return val;
}

- (NSDictionary *)fcurveAttributes
{
    id val;
    val = [[_attrs copy] autorelease];
    return val;
}

- (void)_setAttributes:(NSDictionary *)attrs
{
    [_attrs release];
    _attrs = [attrs mutableCopy];
}

    
    
#pragma mark --- NSCoding / NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    LQFcurve *newObj = (LQFcurve *)[super copyWithZone:zone];
    [newObj setName:[self name]];
    [newObj setDuration:[self duration]];
    [newObj _setAttributes:_attrs];
    return newObj;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];
    
    [coder encodeDouble:_duration forKey:@"fcurve::duration"];
    if (_name)
        [coder encodeObject:_name forKey:@"fcurve::name"];
    
    [coder encodeObject:_attrs forKey:@"fcurve::attributes"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _duration = [coder decodeDoubleForKey:@"fcurve::duration"];
        
        _name = [[coder decodeObjectForKey:@"fcurve::name"] retain];
        
        _attrs = [[coder decodeObjectForKey:@"fcurve::attributes"] retain];
    }
    return self;
}
    

#pragma mark --- plist ---

- (NSDictionary *)plistRepresentation
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super plistRepresentation]];
    
    [dict setObject:[NSNumber numberWithBool:YES] forKey:@"isFcurve"];
    
    [dict setObject:[NSNumber numberWithDouble:_duration] forKey:@"fcurveDuration"];
    
    if (_name)
        [dict setObject:_name forKey:@"fcurveName"];
        
    if ([_attrs count] > 0)
        [dict setObject:_attrs forKey:@"fcurveAttributes"];
    
    return dict;
}

- (id)initWithPlistDictionary:(NSDictionary *)dict
{
    id val;
    BOOL isFcurve = ((val = [dict objectForKey:@"isFcurve"]) && [val boolValue] == YES);
    if ( !isFcurve) {
        NSLog(@"*** can't init fcurve with plist, does not have key 'isFcurve'");
        [self release];
        return nil;
    }

    self = [super initWithPlistDictionary:dict];
    if (self) {
        _duration = ((val = [dict objectForKey:@"fcurveDuration"])) ? [val doubleValue] : 0.0;
        
        _name = [[[dict objectForKey:@"fcurveName"] description] retain];
        
        _attrs = ((val = [dict objectForKey:@"fcurveAttributes"]) && [val isKindOfClass:[NSDictionary class]]) ?
                        [val mutableCopy] : [[NSMutableDictionary alloc] init];
    }
    return self;
}
    
    
#pragma mark --- autosmooth utils ---

#define AUTOSMOOTHCURVETYPE kLXHermiteSegment

+ (LXUInteger)autoSmoothCurveType {
    return AUTOSMOOTHCURVETYPE;
}

- (void)updateAutoSmoothForPointSelection:(NSIndexSet *)selIndexes
{
    const LXUInteger segCount = [self numberOfSegments];
    LXCurveSegment *segs = [self curveSegmentsArray];
    
    if (segCount < 1) return;
    
    LXUInteger index = [selIndexes firstIndex];
    do {
        LXUInteger segIndex = (index < segCount) ? index : (segCount-1);
        LXCurveSegment *seg = segs + segIndex;
        
        NSRange range;
        range.location = segIndex;
        range.length = 0;
        
        if (seg->type == AUTOSMOOTHCURVETYPE) {  // check if the segment is directly affected
            range.length++;
        }
        // check if previous segment is affected
        if (segIndex > 0) {
            LXCurveSegment *prevSeg = segs + (segIndex-1);
            if (prevSeg->type == AUTOSMOOTHCURVETYPE) {
                range.location--;
                range.length++;
            }
        }
        // check if the next segment is affected
        if (segIndex < segCount-1) {
            LXCurveSegment *nextSeg = segs + (segIndex+1);
            if (nextSeg->type == AUTOSMOOTHCURVETYPE) {
                if (range.length == 0) {
                    range.location++;
                }
                range.length++;
            }
        }
        
        if (range.length > 0) {
            ///NSLog(@"... updating cardinal segments in range %@", NSStringFromRange(range));
            [self convertToFcurveStyleCardinalSegmentsInRange:range];
        }
    }
    while ((index = [selIndexes indexGreaterThanIndex:index]) != NSNotFound);
}



- (LXInteger)indexOfSegmentContainingX:(double)x
{
    LXInteger segIndex = NSNotFound;

    const LXUInteger segCount = [self numberOfSegments];
    LXCurveSegment *segs = [self curveSegmentsArray];
    LXInteger i;
    
    for (i = 0; i < segCount; i++) {
        if (x >= segs[i].startPoint.x && x < segs[i].endPoint.x) {
            segIndex = i;
            break;
        }
    }
    
    return segIndex;
}


- (LXInteger)indexOfPointAtX:(double)t frameRate:(double)fps
{
    const double intv = 0.6 / ((fps > 0.0) ? fps : 24.0);
    LXInteger foundIndex = NSNotFound;
        
    const LXUInteger segCount = [self numberOfSegments];
    LXCurveSegment *segs = [self curveSegmentsArray];
    LXInteger i;
    for (i = 0; i < segCount; i++) {
        LXCurveSegment *seg = segs + i;
        if (fabs(seg->startPoint.x - t) < intv) {
            foundIndex = i;
            break;
        }
        if (i == segCount - 1) {
            // is last segment, so check the end point too
            if (fabs(seg->endPoint.x - t) < intv) {
                foundIndex = i + 1;
                break;
            }
        }
        
        if (seg->endPoint.x >= t+intv)
            break;
    }
    return foundIndex;
}

@end
