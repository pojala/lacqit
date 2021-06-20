/*
 *  LQLacefxView_abstract.m
 *  Lacqit
 *
 *  Created by Pauli Ojala on 27.1.2011.
 *  Copyright 2011 Lacquer oy/ltd. All rights reserved.
 *
 */

#import "LQLacefxView.h"


@implementation LQLacefxView

- (id)initWithFrame:(NSRect)frame
{
    NSLog(@"*** %s: subclass should be invoked instead", __func__);
    return self;
}

- (void)setDelegate:(id)del { }
- (id)delegate { return nil; }

- (void)drawNow { }

@end


#if defined(LXPLATFORM_MAC)

#import "LQOpenGLLacefxView.h"
#import <Lacefx/LQGLContext.h>


@implementation LQLacefxView (MacSpecificClassMethods)
 
+ (NSOpenGLContext *)sharedNSOpenGLContext {
    return [LQOpenGLLacefxView sharedNSOpenGLContext];
}

+ (LQGLContext *)sharedLQGLContext {
    return [LQOpenGLLacefxView sharedLQGLContext];
}

@end

#endif

