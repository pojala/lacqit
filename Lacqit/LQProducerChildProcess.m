//
//  LQProducerChildProcess.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.2.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import "LQProducerChildProcess.h"
#import "LQProducerChildProcess_priv.h"
#import <AppKit/AppKit.h>


#define LACQIT_HAS_IOSURFACE 1


enum {
    kThreadCond_NoRequest = 0,
    kThreadCond_HasRequest = 1,
    kThreadCond_ThreadHasStarted = 2,
    kThreadCond_ThreadHasFinished = 0x10,
};
enum {
    kThreadMsg_Proceed = 0,
    kThreadMsg_ExitNow = 0x100,
    kThreadMsg_SendMessageToRemote = 0x200
};



@interface LQProducerChildProcess (PrivateConnectionHandling)

- (NSData *)receivedData:(NSData *)data fromRemoteMessagePortWithID:(int32_t)msgid;

- (void)connectionThreadMainLoop:(id)unused;

@end



static CFDataRef msgPortReceivedDataCb(CFMessagePortRef msgPort, SInt32 msgid, CFDataRef cfData, void *info)
{
    NSData *data = (NSData *)cfData;
    ///NSLog(@"%s, msgid %i, data length %i", __func__, msgid, [data length]);
    
    NSData *retData = [(id)info receivedData:data fromRemoteMessagePortWithID:msgid];    
    return (CFDataRef)[retData retain];
}



@implementation LQProducerChildProcess

+ (BOOL)supportsIOSurface
{
#if (LACQIT_HAS_IOSURFACE)
    return YES;
#else
    return NO;
#endif
}

- (id)initWithChildProcessName:(NSString *)name
{
    return [self initWithChildProcessName:name bundle:nil userInfo:nil];
}

- (id)initWithChildProcessName:(NSString *)name bundle:(NSBundle *)bundle userInfo:(NSDictionary *)argsDict
{
    if ( !bundle) bundle = [NSBundle mainBundle];
    NSString *exePath = [[[bundle executablePath] stringByResolvingSymlinksInPath] stringByDeletingLastPathComponent];
    
    ///NSLog(@"looking for child app '%@' in bundle: %@", name, bundle);

    NSString *pathToChildApp = [bundle pathForAuxiliaryExecutable:name];
    if ( !pathToChildApp) {
        pathToChildApp = [exePath stringByAppendingPathComponent:name];
        if ( ![[NSFileManager defaultManager] fileExistsAtPath:pathToChildApp]) {
            NSLog(@".. tried unsuccesfully to look for executable '%@' at: %@", name, pathToChildApp);
            pathToChildApp = nil;
        }
    }
    if ( !pathToChildApp) {
        NSLog(@"** could not get path for child app '%@', can't continue (bundle: %@)", name, bundle);
        [self release];
        return nil;
    }
    
    // check if the caller provided an ID that we should use to identify this child relation;
    // if not, just use the current process ID.
    id myUniqueID = [argsDict objectForKey:@"hostID"];
    if ([myUniqueID length] < 1)
        myUniqueID = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationProcessIdentifier"];


    NSLog(@"will launch child task '%@', exec path: %@", myUniqueID, pathToChildApp);
    
    
    // create message port    
    NSString *portName = [NSString stringWithFormat:@"%@-Port-%@", name, myUniqueID];
    CFMessagePortContext msgPortCtx;
    memset(&msgPortCtx, 0, sizeof(msgPortCtx));
    msgPortCtx.info = self;    
    CFMessagePortRef local = CFMessagePortCreateLocal(NULL, (CFStringRef)portName, msgPortReceivedDataCb, &msgPortCtx, NULL);
    if ( !local) {
        NSLog(@"** could not create local port by name '%@'", portName);
        [self release];
        return nil;
    }
    
    _msgPortLocal = local;
    _name = [name copy];
    _portName = [portName retain];
    _hostID = [myUniqueID copy];
    _processAndHostID = [[NSString stringWithFormat:@"%@-%@", _name, _hostID] retain];
    _path = [pathToChildApp copy];
    _launchArgsDict = [argsDict copy];
    _childInfoLock = [[NSRecursiveLock alloc] init];
    
    ///NSLog(@"created msgport '%@'", portName);
    
    return self;
}

- (BOOL)launchChildProcess
{
    if (_task) {
        NSLog(@"%@ (%@): already launched", self, _processAndHostID);
        return YES;
    }

    // launch process
    NSMutableArray *launchArgs = [NSMutableArray arrayWithObjects:_portName, nil];
    
    if (_launchArgsDict) {
        NSString *json = [_launchArgsDict lq_JSONRepresentation];
        [launchArgs addObject:[NSString stringWithFormat:@"--userInfo '%@'", json]];
    }
    
    NSMutableDictionary *env = nil;
    /*
    NSMutableArray *fwkPaths = [NSMutableArray array];
    NSString *mainExePath = [[[[NSBundle mainBundle] executablePath] stringByResolvingSymlinksInPath] stringByDeletingLastPathComponent];

    if ( ![mainExePath isEqual:exePath]) {
        NSRange range = [exePath rangeOfString:@".framework"];
        if (range.location != NSNotFound) {
            exePath = [exePath substringToIndex:range.location+range.length];
        } else {
            [fwkPaths addObject:[exePath stringByAppendingPathComponent:@"Frameworks"]];
            [fwkPaths addObject:[exePath stringByAppendingPathComponent:@"Libraries"]];
            [fwkPaths addObject:exePath];
        }
        NSString *basePath = [exePath stringByDeletingLastPathComponent];
        [fwkPaths addObject:basePath];
        [fwkPaths addObject:[basePath stringByAppendingPathComponent:@"Lacqit.framework"]];
        [fwkPaths addObject:[basePath stringByAppendingPathComponent:@"Lacqit.framework/Versions/A"]];
    }
    
    NSString *mainBundlePath = [mainExePath stringByDeletingLastPathComponent];
    [fwkPaths addObject:[mainBundlePath stringByAppendingPathComponent:@"Frameworks"]];
    [fwkPaths addObject:[mainBundlePath stringByAppendingPathComponent:@"Libraries"]];
    [fwkPaths addObject:mainBundlePath];
    
    NSLog(@"framework paths: %@", [fwkPaths componentsJoinedByString:@";"]);

    env = [NSMutableDictionary dictionary];
    [env setObject:[fwkPaths componentsJoinedByString:@";"] forKey:@"DYLD_FRAMEWORK_PATH"];
    [env setObject:[fwkPaths componentsJoinedByString:@";"] forKey:@"DYLD_LIBRARY_PATH"];
    */
    
    
    NSTask *task = [[NSTask alloc] init];
    [task setArguments:launchArgs];
    [task setLaunchPath:_path];
    
    if (env) [task setEnvironment:env];

    @try {
        [task launch];
    } @catch (id exc) {
        NSLog(@"** could not launch child app '%@'", _name);
        [task release];
        task = nil;
    }
    
    if ( !task) {
        return NO;
    }

    _task = task;

    // start thread for handling messaging with the child process
    _condLock = [[NSConditionLock alloc] initWithCondition:kThreadCond_NoRequest];
    _threadMsg = kThreadMsg_Proceed;
    
    double t0 = LQReferenceTimeGetCurrent();
    [NSThread detachNewThreadSelector:@selector(connectionThreadMainLoop:) toTarget:self withObject:nil];
    
    [_condLock lockWhenCondition:kThreadCond_ThreadHasStarted];
    ///NSLog(@"%s -- thread has started (%.3f ms)", __func__, 1000*(LQReferenceTimeGetCurrent() - t0));
    [_condLock unlockWithCondition:kThreadCond_NoRequest];
    
    return YES;
}


- (void)signalWorkerThreadToExit
{
    [_condLock lock];
    NSUInteger cond = [_condLock condition];
    if (cond == kThreadCond_ThreadHasFinished) {
        [_condLock unlockWithCondition:kThreadCond_ThreadHasFinished];
    } else {
        _threadMsg = kThreadMsg_ExitNow;
        [_condLock unlockWithCondition:kThreadCond_HasRequest];
    }
}

- (void)waitForWorkerThreadToExit
{
	if ( !_condLock) return;

    if ([_condLock lockWhenCondition:kThreadCond_ThreadHasFinished beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
        [_condLock unlock];
    }
    
	[_condLock release];
	_condLock = nil;
}

- (void)dealloc
{
    //NSLog(@"%s, %p: '%@'", __func__, self, [self uniqueProcessName]);

    if (_condLock) {
        [self sendStopMessageToChild:nil];
        [self signalWorkerThreadToExit];
        [self waitForWorkerThreadToExit];
    }

    if (_msgPortLocal) {
        CFMessagePortInvalidate(_msgPortLocal);
        CFRelease(_msgPortLocal);
        _msgPortLocal = NULL;
    }
    if (_msgPortChild) {
        CFRelease(_msgPortChild);
        _msgPortChild = NULL;
    }
        
    if (_sharedMemPath) {
        ///NSLog(@"%s (%@): closing path: %@, buffer %p", __func__, _processAndHostID, _sharedMemPath, _sharedMemBuffer);
    
        close(_sharedMemFD);
        _sharedMemFD = 0;
        
        unmapSharedMemoryFile(_sharedMemBuffer, _sharedMemSize);
        _sharedMemBuffer = NULL;
        
        NSError *delError = nil;
        [[NSFileManager defaultManager] removeItemAtPath:_sharedMemPath error:&delError];
        if (delError) {
            NSLog(@"process host '%@': could not delete shared file (path: '%@', error: %@)", _name, _sharedMemPath, delError);
        } else {
            //NSLog(@"process host '%@': deleted path: %@", _name, _sharedMemPath);
        }
        
        [_sharedMemPath release];
        _sharedMemPath = nil;
    }
    
    [_task release];
    [_name release];
    [_hostID release];
    [_processAndHostID release];
    [_path release];
    
    [super dealloc];
}

- (void)setDelegate:(id)del {
    _delegate = del; }
    
- (id)delegate {
    return _delegate; }


#define ENTERCHILDLOCK [_childInfoLock lock];
#define EXITCHILDLOCK  [_childInfoLock unlock];


- (BOOL)childProcessIsReady
{
    ENTERCHILDLOCK
    BOOL f = _childIsReady;
    EXITCHILDLOCK
    return f;
}

- (BOOL)childProcessIsRunning
{
    ENTERCHILDLOCK
    BOOL f = _childIsRunning;
    EXITCHILDLOCK
    return f;
}


- (void)connectionTimer:(NSTimer *)timer
{
    if (_msgPortChild) {
        NSData *returnData = NULL;
        CFMessagePortSendRequest(_msgPortChild, kLQProcessHostMsg_StillAlive, NULL,
                                 0.02, 0.02,
                                 kCFRunLoopCommonModes, (CFDataRef *)&returnData);
        [returnData autorelease];
        
        if ([returnData length] > 0) {
            _lastStillAliveReplyFromRemote = LQReferenceTimeGetCurrent();
        } else {
            ///NSLog(@"no return data from child connection (%@)", [self uniqueProcessName]);
        }
    }
}

- (NSString *)uniqueProcessName {
    return _processAndHostID;
}

- (NSTask *)task {
    return _task;
}

- (BOOL)handleCustomSendMessageToRemote:(int32_t)msgid data:(NSData *)data
{
    return NO;
}


- (void)connectionThreadMainLoop:(id)unused
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    CFRunLoopRef cfRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    
    CFRunLoopSourceRef msgPortSrc = CFMessagePortCreateRunLoopSource(NULL, _msgPortLocal, 0);
    CFRunLoopAddSource(cfRunLoop, msgPortSrc, kCFRunLoopCommonModes);
    CFRelease(msgPortSrc);
    
    NSString *threadName = [NSString stringWithFormat:@"fi.lacquer.%@: '%@'", [self class], [self uniqueProcessName]];
    
    [[NSThread currentThread] setName:threadName];
#if (LACQIT_HAS_IOSURFACE)
    pthread_setname_np([threadName UTF8String]);
#endif
    
    ///NSLog(@"'%@' connection thread started, runloop %@, cfmessageport src %p", _name, runLoop, msgPortSrc);
    
    [_condLock lock];
    [_condLock unlockWithCondition:kThreadCond_ThreadHasStarted];

    BOOL doExit = NO;
    BOOL isUnexpectedTermination = NO;
    
    while ( !doExit) {
        if ([_condLock tryLockWhenCondition:kThreadCond_HasRequest]) {
            NSInteger unlockCondition = kThreadCond_NoRequest;
            
            ///NSLog(@"... child process thread msg %i", _threadMsg);
            
            switch (_threadMsg) {
                case kThreadMsg_ExitNow:
                    doExit = YES;
                    unlockCondition = kThreadCond_ThreadHasFinished;
                    break;
                
                case kThreadMsg_SendMessageToRemote:
                    if ( !_msgPortChild) {
                        doExit = YES;
                        break;
                    }
                
                    if ( ![self handleCustomSendMessageToRemote:_threadMsgToRemote data:_threadMsgDataToRemote]) {
                        switch (_threadMsgToRemote) {
                            default:
                                CFMessagePortSendRequest(_msgPortChild, _threadMsgToRemote, (CFDataRef)_threadMsgDataToRemote, 0.5, 0.01, NULL, NULL);
                                break;
                                
                            case kLQProcessHostMsg_Start: {
                                //NSLog(@"'%@': sending start...", [self uniqueProcessName]);
                                
                                NSMutableDictionary *info = [NSMutableDictionary dictionary];
                                #if (LACQIT_HAS_IOSURFACE)
                                [info setObject:[NSNumber numberWithBool:YES] forKey:@"hostSupportsIOSurface"];
                                #endif
                                
                                NSData *data = [[info lq_JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
                            
                                CFMessagePortSendRequest(_msgPortChild, kLQProcessHostMsg_Start, (CFDataRef)data, 5.0, 5.0, kCFRunLoopDefaultMode, NULL);
                                
                                //NSLog(@"'%@': start finished", [self uniqueProcessName]);
                            
                                // start a timer that will send a "keep alive" message to the child process
                                // (this allows the child to tell if our process has crashed without closing the connection, and vice versa)
                                _connectionTimer = [NSTimer timerWithTimeInterval:2.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:YES];
                                [runLoop addTimer:_connectionTimer forMode:NSRunLoopCommonModes];
                                
                                ENTERCHILDLOCK
                                _childIsRunning = YES;
                                EXITCHILDLOCK
                                break;
                            }
                                
                            case kLQProcessHostMsg_Stop: {
                                CFMessagePortSendRequest(_msgPortChild, kLQProcessHostMsg_Stop, NULL, 5.0, 5.0, kCFRunLoopDefaultMode, NULL);
                                
                                [_connectionTimer invalidate];
                                _connectionTimer = nil;
                                
                                ENTERCHILDLOCK
                                _childIsRunning = NO;
                                EXITCHILDLOCK
                                break;
                            }
                        }
                    }
                    break;
            }
            
            [_condLock unlockWithCondition:unlockCondition];
        }
        
        if ( !doExit) {
            [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0/1000.0]];
            
            BOOL isHung = _task && _lastStillAliveReplyFromRemote > 0.0 && (LQReferenceTimeGetCurrent() - _lastStillAliveReplyFromRemote) > 12.0;
            
            if (isHung) {
                NSLog(@"** child process seems to have hung, will try to terminate (%p '%@', %@)", self, [self uniqueProcessName], _task);
                usleep(5*1000);
                [_task terminate];
            }
            
            ///if ( !isHung) printf("task %p, running: %i\n", _task, [_task isRunning]);
            
            if (_task && ![_task isRunning]) {
                doExit = YES;
                isUnexpectedTermination = YES;
                
                int termStatus = [_task terminationStatus];
                
                NSLog(@"** child process has terminated unexpectedly%@ (%p '%@', %@, terminationstatus %i)", (isHung) ? @", seems to have hung" : @"",
                            self, [self uniqueProcessName], _task, termStatus);
                
                [_condLock lock];
                [_condLock unlockWithCondition:kThreadCond_ThreadHasFinished];
                // for thread safety, ensure that the main thread is the one in charge of releasing the condlock
                [self performSelectorOnMainThread:@selector(waitForWorkerThreadToExit) withObject:nil waitUntilDone:NO];
            }
        }
        
        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];
    }
    
    [_connectionTimer invalidate];
    _connectionTimer = nil;
    
    ENTERCHILDLOCK
    _childIsReady = NO;
    _childIsRunning = NO;
    EXITCHILDLOCK
    
    if (isUnexpectedTermination) {
        [[self delegate] performSelectorOnMainThread:@selector(childProcessHasTerminatedUnexpectedly:) withObject:self waitUntilDone:NO];
    }
    
    [pool drain];
}

- (BOOL)sendMessageToChild:(uint32_t)msgId info:(NSDictionary *)info error:(NSError **)outError
{
    if ( !_condLock) {
        NSLog(@"** %@, msg %i: can't send, thread not running", [self uniqueProcessName], msgId);
        return NO;
    }
    
    if (msgId == 0) {
        NSLog(@"** %@, msg %i: can't send, null message", [self uniqueProcessName], msgId);
        return NO;
    }
    
    NSData *data = nil;
    if (info) {
        data = [[info lq_JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if ( ![_condLock lockWhenCondition:kThreadCond_NoRequest beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
        NSLog(@"** %@, msg %i: can't send, thread is busy", [self uniqueProcessName], msgId);
        return NO;
    }
        
    ENTERCHILDLOCK
        
    NSInteger unlockCondition = kThreadCond_NoRequest;
    BOOL ok;
    if ( !_childIsRunning) {
        NSLog(@"** %@, msg %i: can't send, thread is not running", [self uniqueProcessName], msgId);
        ok = NO;
    } else {
        unlockCondition = kThreadCond_HasRequest;
        ok = YES;

        _threadMsg = kThreadMsg_SendMessageToRemote;
        _threadMsgToRemote = msgId;
        
        [_threadMsgDataToRemote release];
        _threadMsgDataToRemote = [data retain];        
    }
    
    EXITCHILDLOCK
    
    [_condLock unlockWithCondition:unlockCondition];
    return ok;
}


- (void)sendStartMessageToChild:(id)info
{
    if ( !_condLock) return;
        
    if ( ![_condLock lockWhenCondition:kThreadCond_NoRequest beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.0]])
        return;
        
    ENTERCHILDLOCK
        
    NSInteger unlockCondition = kThreadCond_NoRequest;
    if ( !_childIsRunning) {
        _threadMsg = kThreadMsg_SendMessageToRemote;
        _threadMsgToRemote = kLQProcessHostMsg_Start;
        unlockCondition = kThreadCond_HasRequest;
    }    
    
    EXITCHILDLOCK
    
    [_condLock unlockWithCondition:unlockCondition];    
}

- (void)sendStopMessageToChild:(id)unused
{
    if ( !_condLock) return;
   
    if ( ![_condLock lockWhenCondition:kThreadCond_NoRequest beforeDate:[NSDate dateWithTimeIntervalSinceNow:2.0]])
        return;
        
    ENTERCHILDLOCK
        
    NSInteger unlockCondition = kThreadCond_NoRequest;
    if (_childIsRunning) {
        _threadMsg = kThreadMsg_SendMessageToRemote;
        _threadMsgToRemote = kLQProcessHostMsg_Stop;
        unlockCondition = kThreadCond_HasRequest;
    }
    
    EXITCHILDLOCK
    
    [_condLock unlockWithCondition:unlockCondition];
}


#pragma mark --- responding to child process messages ---

- (NSInteger)sharedMemorySizeFromChildProcessHandshakeDict:(NSDictionary *)dict
{
    return 0;
}

- (NSDictionary *)childProcessWillFinishLaunching:(NSDictionary *)dict
{
    if ( !dict || ![dict isKindOfClass:[NSDictionary class]]) {
        NSLog(@"*** %s: invalid response from child process, will terminate child", __func__);
        [_task terminate];
        return nil;
    }
    
    NSString *portName = [dict objectForKey:kLQProcessChildKey_childPortName];

    // get the remote port
    _msgPortChild = CFMessagePortCreateRemote(NULL, (CFStringRef)portName);
    if ( !_msgPortChild) {
        NSLog(@"*** %s: failed to create remote port named '%@', will terminate child", __func__, portName);
        [_task terminate];
        return nil;
    }
    
    ///NSLog(@"... got child process port '%@'", portName);
    
    if ([[dict objectForKey:kLQProcessChildKey_childPassesDataIDs] boolValue]) {
        // this indicates that the child will pass IOSurfaces using the dataId calls,
        // so it doesn't need a shared memory buffer
        NSLog(@"Child at port '%@' will use dataId passing", portName);
        
        return [NSDictionary dictionary];
    }
    else {
        NSInteger dataSize = [self sharedMemorySizeFromChildProcessHandshakeDict:dict];

        if (dataSize <= 0) {
            dataSize = 1024*1024 * 10;  // some kind of default that's hopefully big enough :/
        } else {
            dataSize += 1024;  // add some padding
        }
            
        NSString *sharedMemPath = nil;
        void *sharedMemBuf = NULL;
        int sharedMemFD = createSharedMemoryFile([self uniqueProcessName], dataSize, &sharedMemPath, &sharedMemBuf);
        if (sharedMemFD == -1) {
            NSLog(@"*** %s: failed to create shared memory file ('%@', size %ld), will terminate child", __func__, [self uniqueProcessName], (long)dataSize);
            [_task terminate];
            return nil;
        }
        NSAssert(sharedMemPath, @"no shared mem path");
        
        _sharedMemFD = sharedMemFD;
        _sharedMemPath = [sharedMemPath retain];
        _sharedMemSize = dataSize;
        _sharedMemBuffer = (uint8_t *)sharedMemBuf;
            
        ///NSLog(@"created shared mem file of size %ld, ptr %p, path:  %@", dataSize, sharedMemBuf, sharedMemPath);
        
        return [NSDictionary dictionaryWithObjectsAndKeys:_sharedMemPath, kLQProcessChildKey_sharedMemPath,
                                                             [NSNumber numberWithLong:_sharedMemSize], kLQProcessChildKey_sharedMemFileSize,
                                                             nil];

    }
}

- (void)childProcessDidFinishLaunching
{
    [self performSelectorOnMainThread:@selector(sendStartMessageToChild:) withObject:nil waitUntilDone:NO];
}

- (void)childProcessDidUpdateDataRange:(NSRange)range
{
}

- (void)childProcessHasNewDataID:(uint32_t)dataId otherData:(NSData *)data
{
}

- (BOOL)handleCustomRemoteMessage:(int32_t)msgid inData:(NSData *)data outData:(NSData **)outData
{
    return NO;
}

- (NSData *)receivedData:(NSData *)data fromRemoteMessagePortWithID:(int32_t)msgid
{
    NSData *retData = nil;
    NSDictionary *retDict = nil;
    
    //NSLog(@"%s -- msgid %i", __func__, msgid);
    
    //_lastStillAliveReplyFromRemote = LQReferenceTimeGetCurrent();
    
    switch (msgid) {
        case kLQProcessChildMsg_WillFinishLaunching: {
            NSString *json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

            retDict = [self childProcessWillFinishLaunching:[json parseAsJSON]];
            break;
        }
        
        case kLQProcessChildMsg_DidFinishLaunching:
            ENTERCHILDLOCK
            _childIsReady = YES;
            EXITCHILDLOCK
            [self childProcessDidFinishLaunching];
            break;
        
        case kLQProcessChildMsg_HasUpdatedBufferRange: {
            uint32_t rangeU[2] = { 0, 0 };
            if ([data length] >= 2*sizeof(uint32_t)) {
                memcpy(rangeU, [data bytes], 2*sizeof(uint32_t));
            }
            NSRange range = NSMakeRange(rangeU[0], rangeU[1]);
            
            ///NSLog(@"%s -- updated range %@", __func__, NSStringFromRange(range));
            
            if (range.length > 0) {
                [self childProcessDidUpdateDataRange:range];
            }
        
            ///int32_t v = *((int32_t *)_sharedMemBuffer);
            ///NSLog(@"%s -- value is %i", __func__, v);
            break;
        }
            
        case kLQProcessChildMsg_HasNewDataID: {
#if ( !LACQIT_HAS_IOSURFACE)
            // this shouldn't happen because the child processes should check the dict passed
            // with the 'start' message to ensure that the host supports IOSurfaces
            NSLog(@"** Received 'newDataID' from child process; can't handle without IOSurface support");
#else
            uint32_t dataId = 0;
            if ([data length] >= sizeof(uint32_t)) {
                memcpy(&dataId, [data bytes], sizeof(uint32_t));
            }
            //NSLog(@"%@ - data ID from child process: %i (len %i)\n", self, dataId, (int)[data length]);
            
            [self childProcessHasNewDataID:dataId otherData:([data length] > 4) ? [data subdataWithRange:NSMakeRange(4, [data length]-4)] : nil];
#endif
            break;
        }
        
        default:
            [self handleCustomRemoteMessage:msgid inData:data outData:&retData];
            break;
    }
    
    if ( !retData && retDict) {
        retData = [[retDict lq_JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
    }

    return retData;
}

@end
