//
//  LQBaseApplication.h
//  Lacqit
//
//  Created by Pauli Ojala on 24.3.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LQAppHoverList;
@class LQFlatFileArchive;

#ifdef __APPLE__
@class LQGLContext;
#endif


@interface LQBaseApplication : NSApplication {

    NSMutableSet *_moveEventObservers;

    LQAppHoverList *_hoverList;
    
    LQFlatFileArchive *_updateArch;
    
    void *__lqRes2;
    void *__lqRes3;
    void *__lqRes4;
}

#ifdef __APPLE__
// share context for all GL contexts that need to share resources within the app, in different wrappers.
// these methods simply forward to LQLacefxView's equivalent methods.
- (NSOpenGLContext *)sharedNSOpenGLContext;
- (LQGLContext *)sharedLQGLContext;
#endif

- (void)addMouseMovedObserver:(id)ob;
- (void)removeMouseMovedObserver:(id)ob;

- (void)addHoverTracking:(id)obj;
- (void)removeHoverTracking:(id)obj;

- (void)addHoverTrackingObserver:(id)observer forObject:(id)obsObj;
- (void)removeHoverTrackingObserver:(id)observer;

// an online update to the app.
// this is typically loaded from a web server at startup;
// the code to do so depends on the app and is not included in this class.
- (LQFlatFileArchive *)updateArchive;

@end
