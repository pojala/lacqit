//
//  LQJSBridge_CurveList.h
//  Lacqit
//
//  Created by Pauli Ojala on 19.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <LacqJS/LacqJS.h>
#import "LQCurveList.h"


@interface LQJSBridge_CurveList : LQJSBridgeObject  <LQJSCopying> {

    LQCurveList *_curveList;
    NSDictionary *_styleAttributes;
}

- (id)initInJSContext:(JSContextRef)context withOwner:(id)owner curveList:(LQCurveList *)cl;

@property (nonatomic, retain) NSDictionary *styleAttributes;

- (LQCurveList *)curveList;

- (id)copyIntoJSContext:(JSContextRef)dstContext;

@end
