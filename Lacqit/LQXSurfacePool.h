//
//  LQXSurfacePool.h
//  Lacqit
//
//  Created by Pauli Ojala on 9.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>


@interface LQXSurfacePool : NSObject {

    NSMutableArray *_freeSurfs;
    NSMutableSet *_usedSurfs;
    
    NSMutableSet *_usedButPurgedSurfs;
    NSMutableDictionary *_usedButPurgedPurgeTimes;
    
    NSMutableDictionary *_accessTimes;
    
    LXInteger _accessCount;
    
    NSRecursiveLock *_lock;
    
    NSString *_name;
    LXUInteger _pxFormat;
}

- (id)init;

@property (atomic, copy) NSString *name;

// the default for pxf is 0, which will use 16-bpc RGBA if available
- (void)setLXPixelFormat:(LXUInteger)pxf;
- (LXUInteger)lxPixelFormat;


- (LXSurfaceRef)surfaceWithSize:(LXSize)size;
- (void)returnSurfaceToPool:(LXSurfaceRef)surf;

- (LXInteger)purgePool;
- (void)purgeAllExceptSize:(LXSize)size;
- (void)purgeUnused;
- (void)purgeWithAgeTreshold:(double)ageTreshold;

- (LXInteger)surfaceCount;
- (LXInteger)accessCount;

@end
