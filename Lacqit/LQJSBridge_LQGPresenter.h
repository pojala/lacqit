//
//  LQJSBridge_LQGPresenter.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/Lacefx.h>
#import <LacqJS/LacqJS.h>


@interface LQJSBridge_LQGPresenter : LQJSBridgeObject {

    id _viewCtrl;  // not retained
}

- (id)initWithViewController:(id)viewCtrl
            inJSContext:(JSContextRef)context withOwner:(id)owner;

- (id)viewController;

@end


@interface NSObject (LQGViewControllerJSBridgeOwner)
- (id)bridgeForViewController:(id)viewCtrl inJSContext:(JSContextRef)context;
@end
