//
//  LQFcurveStreamNode.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.11.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Lacefx/Lacefx.h>
#import "LQStreamNode.h"
#import "LQFcurve.h"
@class LQFcurveBunch;


@interface LQFcurveStreamNode : LQStreamNode {

    LQFcurveBunch *_fcurves;
}

// to add/remove curves, the bunch can be manipulated directly
- (LQFcurveBunch *)fcurveBunch;

- (void)didModifyFcurveBunch;

// standard methods used by the curve editor UI in Conduit Live 2
- (LQFcurve *)fcurveForParameterNamed:(NSString *)paramName;
- (void)setFcurve:(LQFcurve *)fcurve forParameterNamed:(NSString *)paramName;

@end
