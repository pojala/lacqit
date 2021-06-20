//
//  LQJSMinifier.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LQJSMinifier : NSObject {

    void *_state;
}

- (NSString *)minifyJavaScript:(NSString *)inStr withErrorDescription:(NSString **)outError;

@end
