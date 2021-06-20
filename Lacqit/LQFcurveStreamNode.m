//
//  LQFcurveStreamNode.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQFcurveStreamNode.h"
#import "LQStreamNode_priv.h"
#import "LQNSValueAdditions.h"
#import "LQFcurve.h"
#import "LQFcurveBunch.h"


@implementation LQFcurveStreamNode

- (void)_recreateInputsAndOutputs
{
    LXInteger n = [_fcurves count];
    LXInteger i;
    
    LXInteger inputCount = [_inputs count];
    id newInputs = nil;
    if (inputCount >= n) {
        newInputs = [_inputs subarrayWithRange:NSMakeRange(0, n)];
        for (i = n; i < inputCount; i++) {
            [[_inputs objectAtIndex:i] disconnect];
        }
    } else {
        newInputs = (_inputs) ? [NSMutableArray arrayWithArray:_inputs] : [NSMutableArray array];
        for (i = inputCount; i < n; i++) {
            id fcurve = [_fcurves fcurveAtIndex:i];
            NSString *name = [NSString stringWithFormat:@"position for %@", [fcurve name]];
            id inp = [[LACInput alloc] initWithName:name typeKey:nil];
            [newInputs addObject:[inp autorelease]];
        }
    }
    [self _setInputs:newInputs];

    /*LXInteger outputCount = [_outputs count];
    id newOutputs = nil;
    if (outputCount >= n) {
        newOutputs = [_outputs subarrayWithRange:NSMakeRange(0, n)];
        for (i = n; i < outputCount; i++) {
            id outp = [_outputs objectAtIndex:i];
            [[outp connectedInputs] makeObjectsPerformSelector:@selector(disconnect)];
        }
    } else {
        newOutputs = (_outputs) ? [NSMutableArray arrayWithArray:_outputs] : [NSMutableArray array];
        for (i = outputCount; i < n; i++) {
            id fcurve = [_fcurves fcurveAtIndex:i];
            NSString *name = [NSString stringWithFormat:@"Value from %@", [fcurve name]];
            id outp = [[LACOutput alloc] initWithName:name typeKey:nil];
            [newOutputs addObject:[outp autorelease]];
        }
    }
    [self _setOutputs:newOutputs];
    */
    
}

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    
    _fcurves = [[LQFcurveBunch alloc] init];

    LXInteger i;
    for (i = 0; i < 1; i++) {
        LQFcurve *curve = [[[LQFcurve alloc] init] autorelease];
        [curve setName:[NSString stringWithFormat:@"Curve %ld", (long)i+1]];
        [_fcurves addFcurve:curve];
    }
    

    id outp = [[LACOutput alloc] initWithName:@"curve values" typeKey:nil];

    [self _setOutputs:[NSArray arrayWithObject:outp]];
    
    [self _recreateInputsAndOutputs];
        
    return self;
}

- (void)dealloc
{
    [_fcurves release];

    [super dealloc];
}

+ (NSString *)proposedDefaultName {
    return @"a-curve"; }


- (LXUInteger)typeOfOutputAtIndex:(LXInteger)index {
    return kLACNodeDefaultConnectionType;
}


- (LQFcurveBunch *)fcurveBunch {
    return _fcurves; }
    
- (void)didModifyFcurveBunch {
}


- (LQFcurve *)fcurveForParameterNamed:(NSString *)paramName {
    return [_fcurves fcurveForKey:paramName];
}

- (void)setFcurve:(LQFcurve *)fcurve forParameterNamed:(NSString *)paramName {
    [_fcurves replaceFcurveForKey:paramName withFcurve:(fcurve) ? fcurve : [[[LQFcurve alloc] init] autorelease]];
    
    [self didModifyFcurveBunch];
}


#pragma mark --- eval ---

- (double)getValueForFcurveAtIndex:(LXInteger)index atTime:(double)t
{
    LQFcurve *fcurve = [_fcurves fcurveAtIndex:index];
    
    if ([fcurve numberOfSegments] < 1) return 0.0;
    
    // check if we're looping
    id loopMode = [fcurve attributeForKey:kLQFcurveAttribute_LoopMode];
    BOOL doLoop = ([loopMode isEqualToString:kLQFcurvePlayLoop]);
    if (doLoop) {
        double maxX = [fcurve lastSegment].endPoint.x;
        if (t > maxX) {
            t = fmod(t, maxX);        
        }
    }
    
    double y = 0.0;
    [fcurve getYValue:&y atX:t];
    
    return y;
}

- (LACArrayListPtr)evaluateOutputAtIndex:(LXInteger)index
                            inputLists:(LACArrayListPtr *)inputLists
                            context:(NSDictionary *)context
{
    if ( ![self canEvalWithContext:context])
        return LACEmptyArrayList;

    double timeInStream = [self currentTimeInStreamFromEvalContext:context];

    [self runOnRenderScriptForOutputAtIndex:index inputLists:inputLists context:context];

    LXInteger n = [_fcurves count];


    /*
    // version for multiple outputs (one for each curve):
    if (index >= n) {
        NSLog(@"*** '%@' eval: output index out of bounds (%i, %i)", [self name], index, n);
        return LACEmptyArrayList;
    }
    
    double y = [self getValueForFcurveAtIndex:i atTime:timeInStream];
    
    ///NSLog(@"... %.3f -> y %.3f", timeInStream, y);    
    return LACArrayListCreateWithObject([NSNumber numberWithDouble:y]);
    */
                
                
    // version that outputs a list of all the values:    
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:n];
    LXInteger i;
    for (i = 0; i < n; i++) {
        double y = [self getValueForFcurveAtIndex:i atTime:timeInStream];
        
        [values addObject:[NSNumber numberWithDouble:y]];
    }
    
    LACArrayListPtr list = LACArrayListCreateWithArray(values);
    LACArrayListSetIndexNamesFromArray(list, [_fcurves orderedKeys]);
    return list;
}


@end
