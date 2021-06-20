//
//  LQSurfacePool.m
//  PixelMath
//
//  Created by Pauli Ojala on 9.8.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQXSurfacePool.h"
#import <Lacefx/LXPlatform.h>
#import "LQTimeFunctions.h"
#import "LQLXBasicFunctions.h"


//#define DEBUGLOG(format, args...)   NSLog(format , ## args);
#define DEBUGLOG(format, args...)


#define ENTER [_lock lock];
#define EXIT  [_lock unlock];


static NSMutableArray *g_pools = nil;
static NSLock *g_poolsLock = nil;


#define REGISTERPOOLS 1



static LXLogFuncPtr g_lqxSurfacePoolLogFuncCb = NULL;
static void *g_lqxSurfacePoolLogFuncCbUserData = NULL;



@implementation LQXSurfacePool

@synthesize name = _name;

+ (void)setLogCallback:(LXLogFuncPtr)cb userData:(void *)data
{
    g_lqxSurfacePoolLogFuncCb = cb;
    g_lqxSurfacePoolLogFuncCbUserData = data;
}

#if REGISTERPOOLS

+ (void)registerSurfacePool:(LQXSurfacePool *)pool
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_pools = [[NSMutableArray alloc] initWithCapacity:10];
        g_poolsLock = [[NSLock alloc] init];
    });
    NSValue *pval = [NSValue valueWithPointer:pool];
    [g_poolsLock lock];
    if (pool && ![g_pools containsObject:pval])
        [g_pools addObject:pval];
    [g_poolsLock unlock];
}

+ (void)unregisterSurfacePool:(LQXSurfacePool *)pool
{
    NSValue *pval = [NSValue valueWithPointer:pool];
    [g_poolsLock lock];
    if (pool && [g_pools containsObject:pval])
        [g_pools removeObject:pval];
    [g_poolsLock unlock];
}

+ (NSArray *)activeSurfacePools
{
    NSMutableArray *arr = [NSMutableArray array];
    [g_poolsLock lock];
    for (NSValue *pval in g_pools) {
        [arr addObject:(id)[pval pointerValue]];
    }
    [g_poolsLock unlock];
    return arr;
}

#endif


- (id)init
{
    self = [super init];
    
    _freeSurfs = [[NSMutableArray arrayWithCapacity:64] retain];
    _usedSurfs = [[NSMutableSet setWithCapacity:64] retain];
    _usedButPurgedSurfs = [[NSMutableSet setWithCapacity:64] retain];
    _usedButPurgedPurgeTimes = [[NSMutableDictionary dictionaryWithCapacity:64] retain];
    _accessTimes = [[NSMutableDictionary dictionaryWithCapacity:64] retain];
    
    _lock = [[NSRecursiveLock alloc] init];
    if ([_lock respondsToSelector:@selector(setName:)]) {
        [_lock setName:[NSString stringWithFormat:@"owned by lqxSurfacePool %p", self]];
    }
    
#if REGISTERPOOLS
    [LQXSurfacePool registerSurfacePool:self];
#endif

    if (g_lqxSurfacePoolLogFuncCb) {
        char text[512];
        snprintf(text, 512, "%s, %p", __func__, self);
        g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
    }
    return self;
}

- (void)dealloc
{
#if REGISTERPOOLS
    [LQXSurfacePool unregisterSurfacePool:self];
#endif
    
    [self purgePool];
    
    [self _releaseAllUsedSurfaces];
    
    [_freeSurfs release];
    [_usedSurfs release];
    [_usedButPurgedSurfs release];
    [_usedButPurgedPurgeTimes release];
    [_accessTimes release];
    [_lock release];
    [_name release];
    
    [super dealloc];
}

- (NSString *)description
{
    double t0 = LQReferenceTimeGetCurrent();
    
    ENTER
    LXInteger free = [_freeSurfs count];
    LXInteger used = [_usedSurfs count];
    LXInteger usedButPurged = [_usedButPurgedSurfs count];
    
    LXSize minSize = LXZeroSize;
    LXSize maxSize = LXZeroSize;
    for (NSValue *pval in _freeSurfs) {
        LXSize size = LXSurfaceGetSize((LXSurfaceRef)[pval pointerValue]);
        if (minSize.w == 0.0) minSize = size;
        else {
            minSize.w = MIN(minSize.w, size.w);
            minSize.h = MIN(minSize.h, size.h);
        }
        if (maxSize.w == 0.0) maxSize = size;
        else {
            maxSize.w = MAX(maxSize.w, size.w);
            maxSize.h = MAX(maxSize.h, size.h);
        }
    }
    for (NSValue *pval in _usedSurfs) {
        LXSize size = LXSurfaceGetSize((LXSurfaceRef)[pval pointerValue]);
        if (minSize.w == 0.0) minSize = size;
        else {
            minSize.w = MIN(minSize.w, size.w);
            minSize.h = MIN(minSize.h, size.h);
        }
        if (maxSize.w == 0.0) maxSize = size;
        else {
            maxSize.w = MAX(maxSize.w, size.w);
            maxSize.h = MAX(maxSize.h, size.h);
        }
    }
    double minPurgeT = t0;
    double maxPurgeT = 0.0;
    void *oldestPurgePtr = NULL;
    for (NSValue *pval in _usedButPurgedSurfs) {
        LXSize size = LXSurfaceGetSize((LXSurfaceRef)[pval pointerValue]);
        if (minSize.w == 0.0) minSize = size;
        else {
            minSize.w = MIN(minSize.w, size.w);
            minSize.h = MIN(minSize.h, size.h);
        }
        if (maxSize.w == 0.0) maxSize = size;
        else {
            maxSize.w = MAX(maxSize.w, size.w);
            maxSize.h = MAX(maxSize.h, size.h);
        }
        double purgeT = [[_usedButPurgedPurgeTimes objectForKey:pval] doubleValue];
        maxPurgeT = MAX(maxPurgeT, purgeT);
        if (purgeT < minPurgeT) {
            minPurgeT = purgeT;
            oldestPurgePtr = pval.pointerValue;
        }
    }
    EXIT
    
    LXInteger total = free + used + usedButPurged;
    
    NSString *info;
    if (total == 0)
        info = @"";
    else if (total == free)
        info = @", all free";
    else if (usedButPurged == 0)
        info = [NSString stringWithFormat:@", %ld free, %ld in use", (long)free, (long)used];
    else
        info = [NSString stringWithFormat:@", %ld free, %ld in use, %ld pending release (i.e. still retained by a user)", (long)free, (long)used, (long)usedButPurged];

    NSString *sizeInfo;
    if (total == 0)
        sizeInfo = @"";
    else if (minSize.w == maxSize.w && minSize.h == maxSize.h)
        sizeInfo = [NSString stringWithFormat:@", all %.0f*%.0f", minSize.w, minSize.h];
    else
        sizeInfo = [NSString stringWithFormat:@", min size %.0f*%.0f, max size %.0f*%.0f", minSize.w, minSize.h, maxSize.w, maxSize.h];

    NSString *purgeTInfo = @"";
    if (usedButPurged > 0) {
        purgeTInfo = [NSString stringWithFormat:@"; pending release oldest %.3fs ago (surf=%p), latest %.3fs ago", t0 - minPurgeT, oldestPurgePtr, t0 - maxPurgeT];
    }
    
    return [NSString stringWithFormat:@"<%@: %p -- %@ -- %ld surfaces%@%@%@>",
            [self class], self,
            (_name) ? _name : @"(no name)",
            (long)total, info, sizeInfo, purgeTInfo];
}


- (void)setLXPixelFormat:(LXUInteger)pxf
{
    BOOL doPurge = NO;
    ENTER
    if (pxf != _pxFormat) {
        _pxFormat = pxf;
        doPurge = YES;
    }
    EXIT
    
    if (doPurge) {    
        [self purgePool];
    }
}

- (LXUInteger)lxPixelFormat {
    ENTER
    LXUInteger pxf = _pxFormat;
    EXIT
    return pxf;
}


/*
#define ENTERSURF   LXSurfaceBeginAccessOnThread(0)
#define EXITSURF    LXSurfaceEndAccessOnThread();

// 2011.02.14 -- surface release does get the lock inside Lacefx, so we don't need to get it here
//#define ENTERSURF     1
//#define EXITSURF      
*/

- (void)_deleteReferencesToSurfacesToBeReleased:(NSSet *)killList
{
    if ([killList count] < 1) return;

    NSEnumerator *surfEnum = nil;
    id pval;
    surfEnum = [killList objectEnumerator];
    while (pval = [surfEnum nextObject]) {
        [_freeSurfs removeObject:pval];
        [_accessTimes removeObjectForKey:pval];
    }
}

- (void)_releaseSurfacesInSet:(NSSet *)killList
{
    if ([killList count] < 1) return;

    //NSLog(@"%s -- releasing %i surfaces -- is main thread %i", __func__, [killList count], LXPlatformCurrentThreadIsMain());
    
    NSEnumerator *surfEnum = nil;
    id pval;
    surfEnum = [killList objectEnumerator];
    while (pval = [surfEnum nextObject]) {
        LXSurfaceRef surf = (LXSurfaceRef)[pval pointerValue];
        LXSurfaceRelease(surf);
    }
}

- (void)_deleteReferencesToSurfaceToBePurged:(LXSurfaceRef)surf
{
    if ( !surf) return;

    id pval = [NSValue valueWithPointer:surf];

    [_usedButPurgedSurfs removeObject:pval];
    [_usedButPurgedPurgeTimes removeObjectForKey:pval];
    [_accessTimes removeObjectForKey:pval];    
}

/*
- (void)_releaseAllFreeSurfaces
{
    NSEnumerator *enumerator = [_freeSurfs objectEnumerator];
    id pval;
    while (pval = [enumerator nextObject]) {
        LXSurfaceRelease([pval pointerValue]);
        
        [_accessTimes removeObjectForKey:pval];
    }
    [_freeSurfs removeAllObjects];
}
*/

- (void)_releaseAllUsedSurfaces
{
    id pval;
    NSEnumerator *enumerator;

    enumerator = [_usedSurfs objectEnumerator];
    while (pval = [enumerator nextObject]) {
        LXSurfaceRelease([pval pointerValue]);        
        [_accessTimes removeObjectForKey:pval];
    }
    [_usedSurfs removeAllObjects];
    
    enumerator = [_usedButPurgedSurfs objectEnumerator];
    while (pval = [enumerator nextObject]) {
        LXSurfaceRelease([pval pointerValue]);
        [_accessTimes removeObjectForKey:pval];
    }
    [_usedButPurgedSurfs removeAllObjects];
    [_usedButPurgedPurgeTimes removeAllObjects];
}




- (LXInteger)surfaceCount
{
    ENTER
    LXInteger n = [_freeSurfs count] + [_usedSurfs count] + [_usedButPurgedSurfs count];
    EXIT
    return n;
}

- (LXInteger)accessCount
{
    ENTER
    LXInteger n = _accessCount;
    EXIT
    return n;
}

- (void)_markSurfaceAsUsed:(LXSurfaceRef)surf
{
    id pval = [NSValue valueWithPointer:surf];
    [_usedSurfs addObject:pval];
    [_freeSurfs removeObject:pval];
}

- (void)_markSurfaceAsFree:(LXSurfaceRef)surf
{
    id pval = [NSValue valueWithPointer:surf];
    
    if ( ![_freeSurfs containsObject:pval]) {
        [_freeSurfs addObject:pval];
    }
    [_usedSurfs removeObject:pval];
    
    double t0 = LQReferenceTimeGetCurrent();
    [_accessTimes setObject:[NSNumber numberWithDouble:t0] forKey:pval];
}


- (LXSurfaceRef)surfaceWithSize:(LXSize)size
{
    double t0 = LQReferenceTimeGetCurrent();

    ENTER
    _accessCount++;

    LXSurfaceRef surf = nil;
    LXSurfaceRef foundSurf = nil;

    ///NSMutableSet *killList = nil;
    ///LQPrintf("..surf count: %ld (used %ld, purged %ld)\n", (long)[_freeSurfs count], (long)[_usedSurfs count], (long)[_usedButPurgedSurfs count]);
    
    NSMutableSet *foundSizes = nil;
    if (g_lqxSurfacePoolLogFuncCb) {
        char text[512];
        snprintf(text, 512, "%s, %s", __func__, self.description.UTF8String);
        g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        
        // track these sizes for logging
        foundSizes = [NSMutableSet setWithCapacity:16];
    }

    NSEnumerator *surfEnum = [_freeSurfs reverseObjectEnumerator];
    id pval;
    while (pval = [surfEnum nextObject]) {
        surf = (LXSurfaceRef) [pval pointerValue];
        
        if ( !foundSurf && LXSurfaceMatchesSize(surf, size)) {
            foundSurf = surf;
        } else {
            if (foundSizes) [foundSizes addObject:[NSValue valueWithSize:NSSizeFromLXSize(LXSurfaceGetSize(surf))]];
            // check last access time for this surface, maybe we can remove it
            
            // 2011.02.15 -- disable this whole check, it's useless here.
            // we don't want to free surfaces while on playback because it can stall rendering.
            // better to do it in a separate call, so  -purgeUnused is added.
            /*
            id tmval;
            if ((tmval = [_accessTimes objectForKey:pval])) {
                double lastAccessTime = [tmval doubleValue];
                double age = (lastAccessTime > 0.0) ?  (t0 - lastAccessTime) : 0.0;
                ///LQPrintf("....surf %p - age %.3f ms\n", surf, 1000*age);
                
                const double ageTreshold = 5.0;  // seconds
                if (age > ageTreshold) {
                    ///LQPrintf("surface %p is old: %.3f ms\n", surf, 1000*age);
                    
                    if ( !killList) killList = [NSMutableSet setWithCapacity:16];
                    
                    [killList addObject:pval];
                }
            }
            */
        }
    }    
    surf = foundSurf;
    if ( !surf) {
        // not found, create new surface
        LXUInteger pxFormat = _pxFormat;

        // must relinquish the lock here to prevent a deadlock
        EXIT
        
        //if ( !LXSurfaceBeginAccessOnThread(kLXDoNotSwitchContextOnLock)) {
        //    NSLog(@"%s: failed to acquire lx lock", __func__);
        //} else {
            
            if (pxFormat == 0) {
                pxFormat = (LXPlatformHWSupportsFloatRenderTargets()) ? kLX_RGBA_FLOAT16 : kLX_RGBA_INT8;
            } else {
                ///NSLog(@"creating pool surface with pxf %lu", pxFormat);
            }
            
            // TODO: should eventually set the pool argument somehow, so that users of the surface can figure out it's from this pool
            LXDECLERROR(err);
            surf = LXSurfaceCreate(NULL, size.w, size.h, pxFormat, 0, &err);

            if ( !surf) {
                NSLog(@"** %s failed (%.0f * %.0f): error %i, '%s'", __func__, size.w, size.h, err.errorID, err.description);
            }
            else { DEBUGLOG(@"%s (%@): created new surface %p (size %.0f * %.0f); no lock", __func__, self, surf, size.w, size.h); }
        
            if (g_lqxSurfacePoolLogFuncCb) {
                char text[512];
                if ( !surf) {
                    snprintf(text, 512, "** %s %p failed (%.0f * %.0f): error %i, '%s'", __func__, self, size.w, size.h, err.errorID, err.description);
                } else {
                    snprintf(text, 512, "%s %p created new %p (%.0f * %.0f), sizes in pool: %s", __func__, self, surf, size.w, size.h, foundSizes.description.UTF8String);
                }
                g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
            }
        
        //    LXSurfaceEndAccessOnThread();
        //}
        ENTER
    }
    /*
    if (killList) {
        // detele buffers that were previously deemed old
        [self _deleteReferencesToSurfacesToBeReleased:killList];
        
        [self performSelectorOnMainThread:@selector(_releaseSurfacesInSet_getsLXLock:) withObject:killList waitUntilDone:NO];        
    }
    */

    if (surf) [self _markSurfaceAsUsed:surf];
    EXIT
    
    ///DEBUGLOG(@"%s (%p): surface %p", __func__, self, surf);
    return surf;
}

- (void)returnSurfaceToPool:(LXSurfaceRef)surf
{
    if ( !surf) return;
    
    id pval = [NSValue valueWithPointer:surf];

    ///DEBUGLOG(@"%s (%p): surface %p", __func__, self, surf);
    
    ENTER
    
    if ([_freeSurfs containsObject:pval]) {
        //NSLog(@"** %s (%p): surface %p was already returned to pool", __func__, self, surf);
        EXIT
        
        if (g_lqxSurfacePoolLogFuncCb) {
            char text[512];
            snprintf(text, 512, "** %s, %p: surface %p was already returned to pool", __func__, self, surf);
            g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        }
        return;
    }
    
    if ([_usedButPurgedSurfs containsObject:pval]) {
        // this surface was purged while still retained by a user of this pool, so free it now
        
        [self _deleteReferencesToSurfaceToBePurged:surf];
        EXIT
        
        if (g_lqxSurfacePoolLogFuncCb) {
            char text[512];
            snprintf(text, 512, "%s, %p: surface %p was previously deferred after purge, will release now", __func__, self, surf);
            g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        }
        
        NSSet *killList = [NSSet setWithObject:[NSValue valueWithPointer:surf]];
        [self performSelectorOnMainThread:@selector(_releaseSurfacesInSet:) withObject:killList waitUntilDone:NO];
    }
    else {
        if ( ![_usedSurfs containsObject:pval]) {
            static NSInteger s_numWarnings = 0;
            if (s_numWarnings < 50) {
                NSLog(@"** %s (%p): surface is not from this pool (%p) -- used surfs: %@", __func__, self, surf, _usedSurfs);
                s_numWarnings++;
            }
            if (g_lqxSurfacePoolLogFuncCb) {
                char text[512];
                snprintf(text, 512, "** %s, %p: surface is not from this pool (%p) -- used surfs: %s", __func__, self, surf, _usedSurfs.description.UTF8String);
                g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
            }

        } else {
            [self _markSurfaceAsFree:surf];
            
            if (g_lqxSurfacePoolLogFuncCb) {
                char text[512];
                LXSize surfSize = LXSurfaceGetSize(surf);
                snprintf(text, 512, "%s, %p: returned surface %p to pool (%.0f * %0.f)", __func__, self, surf, surfSize.w, surfSize.h);
                g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
            }
        }
        EXIT
    }
}




- (LXInteger)purgePool
{
    double t0 = LQReferenceTimeGetCurrent();
    
    ENTER
    
    if ([_usedSurfs count] > 0) {
        ///NSLog(@"** warning: %s called with surfaces still in use (self %p, usedCount %i)", __func__, self, [_usedSurfs count]);
        
        // move any remaining in-use surfaces to a separate set of purged surfaces,
        // so they'll be freed when their retainer returns them to the pool
        [_usedButPurgedSurfs unionSet:_usedSurfs];
        for (NSValue *val in _usedSurfs) {
            [_usedButPurgedPurgeTimes setObject:@(t0) forKey:val];
        }
        [_usedSurfs removeAllObjects];
    }
    
    NSSet *killList = ([_freeSurfs count] > 0) ? [NSSet setWithArray:_freeSurfs] : nil;
    
    //if ([killList count]) NSLog(@"%s: purging %ld free surfs", __func__, (long)[killList count]);

    // this used to call _releaseAllFreeSurfaces; instead, do the two-phase release cycle    
    [self _deleteReferencesToSurfacesToBeReleased:killList];
    
    EXIT
    
    if (killList.count > 0) {
        if (g_lqxSurfacePoolLogFuncCb) {
            char text[512];
            snprintf(text, 512, "%s, %p: releasing %ld surfaces, is main thread %d", __func__, self, [killList count], LXPlatformCurrentThreadIsMain());
            g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        }
        
        [self _releaseSurfacesInSet:killList];
    }
    return killList.count;
}


- (NSSet *)_findSurfacesNotMatchingSize:(LXSize)size inCollection:(id)surfs
{
    NSMutableSet *killList = [NSMutableSet setWithCapacity:16];
    NSEnumerator *surfEnum = [surfs objectEnumerator];
    id pval;
    while (pval = [surfEnum nextObject]) {
        LXSurfaceRef surf = (LXSurfaceRef) [pval pointerValue];
        
        if ( !LXSurfaceMatchesSize(surf, size)) {
            [killList addObject:pval];
        }
    }
    return killList;
}

- (void)purgeAllExceptSize:(LXSize)size
{
    double t0 = LQReferenceTimeGetCurrent();
    
    ENTER
    
    if ([_usedSurfs count] > 0) {
        ///NSLog(@"** warning: %s called with surfaces still in use (self %p, usedCount %i)", __func__, self, [_usedSurfs count]);
        
        // move any remaining in-use surfaces to a separate set of purged surfaces,
        // so they'll be freed when their retainer returns them to the pool
        NSSet *killList = [self _findSurfacesNotMatchingSize:size inCollection:_usedSurfs];
        
        [_usedButPurgedSurfs unionSet:killList];
        for (NSValue *val in killList) {
            [_usedButPurgedPurgeTimes setObject:@(t0) forKey:val];
        }
        [_usedSurfs minusSet:killList];
    }

    // collect the surfaces to be deleted
    NSSet *killList = [self _findSurfacesNotMatchingSize:size inCollection:_freeSurfs];
    
    if ([killList count] > 0) { DEBUGLOG(@"%s: going to release %ld surfaces", __func__, [killList count]); }

    [self _deleteReferencesToSurfacesToBeReleased:killList];
    
    EXIT

    if (killList.count > 0) {
        if (g_lqxSurfacePoolLogFuncCb) {
            char text[512];
            snprintf(text, 512, "%s, %p, (%.0f * %.0f): releasing %ld surfaces, is main thread %d", __func__, self, size.w, size.h, [killList count], LXPlatformCurrentThreadIsMain());
            g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        }
        
        [self _releaseSurfacesInSet:killList];
    }
}

- (void)purgeUnused
{
    [self purgeWithAgeTreshold:5.0];
}

- (void)purgeWithAgeTreshold:(double)ageTreshold
{
    double t0 = LQReferenceTimeGetCurrent();
    NSMutableSet *killList = nil;
    
    ENTER
    
    NSEnumerator *surfEnum = [_freeSurfs objectEnumerator];
    id pval;
    while (pval = [surfEnum nextObject]) {
        LXSurfaceRef surf = (LXSurfaceRef) [pval pointerValue];

        id tmval;
        if ((tmval = [_accessTimes objectForKey:pval])) {
            double lastAccessTime = [tmval doubleValue];
            double age = (lastAccessTime > 0.0) ?  (t0 - lastAccessTime) : 0.0;
            ///LQPrintf("....surf %p - age %.3f ms\n", surf, 1000*age);
            
            if (age > ageTreshold) {
                ///LQPrintf("surface %p is old: %.3f ms\n", surf, 1000*age);
                
                if ( !killList) killList = [NSMutableSet setWithCapacity:16];
                
                [killList addObject:pval];
            }
        }
    }

    [self _deleteReferencesToSurfacesToBeReleased:killList];
    
    EXIT
    
    if ([killList count] > 0) {
        if (g_lqxSurfacePoolLogFuncCb) {
            char text[512];
            snprintf(text, 512, "%s, %p: releasing %ld surfaces, is main thread %d", __func__, self, [killList count], LXPlatformCurrentThreadIsMain());
            g_lqxSurfacePoolLogFuncCb(text, g_lqxSurfacePoolLogFuncCbUserData);
        }
        
        [self _releaseSurfacesInSet:killList];
    }
}


@end
