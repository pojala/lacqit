//
//  LQProducerChildProcess.h
//  Lacqit
//
//  Created by Pauli Ojala on 4.2.2011.
//  Copyright 2011 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>


@interface LQProducerChildProcess : NSObject {

    NSString *_name;
    NSString *_path;
    NSString *_hostID;
    NSString *_processAndHostID;
    NSString *_portName;
    NSDictionary *_launchArgsDict;
    NSTask *_task;
    
    id _delegate;
    
    CFMessagePortRef _msgPortLocal;
    CFMessagePortRef _msgPortChild;
    
    // shared memory file for pre-10.6.
    // on 10.6+, the child can send an IOSurface id.
    NSString *_sharedMemPath;
    NSInteger _sharedMemSize;
    int _sharedMemFD;
    uint8_t *_sharedMemBuffer;
    
    NSRecursiveLock *_childInfoLock;
    BOOL _childIsReady;
    BOOL _childIsRunning;
    
    // connection watcher thread
	NSConditionLock *_condLock;
    NSInteger       _threadMsg;
    NSInteger       _threadMsgToRemote;
    NSData          *_threadMsgDataToRemote;
    NSTimer         *_connectionTimer;
    double          _lastStillAliveReplyFromRemote;
}

- (id)initWithChildProcessName:(NSString *)name;
- (id)initWithChildProcessName:(NSString *)name bundle:(NSBundle *)bundle userInfo:(NSDictionary *)userInfo;

- (void)setDelegate:(id)del;
- (id)delegate;

- (BOOL)launchChildProcess;

- (void)sendStartMessageToChild:(id)info;
- (void)sendStopMessageToChild:(id)info;
- (BOOL)sendMessageToChild:(uint32_t)msgId info:(NSDictionary *)info error:(NSError **)outError;

- (BOOL)childProcessIsReady;
- (BOOL)childProcessIsRunning;

- (NSTask *)task;

- (NSString *)uniqueProcessName;


// subclasses should override
- (NSInteger)sharedMemorySizeFromChildProcessHandshakeDict:(NSDictionary *)dict;

- (void)childProcessDidUpdateDataRange:(NSRange)range;

- (void)childProcessHasNewDataID:(uint32_t)dataId otherData:(NSData *)data;


// subclasses can override (default calls -sendStartMessage)
- (void)childProcessDidFinishLaunching;

- (void)signalWorkerThreadToExit;
- (void)waitForWorkerThreadToExit;

// subclasses can override
- (BOOL)handleCustomSendMessageToRemote:(int32_t)msgid data:(NSData *)data;
- (BOOL)handleCustomRemoteMessage:(int32_t)msgid inData:(NSData *)data outData:(NSData **)outData;

// runtime feature checks
+ (BOOL)supportsIOSurface;

@end


@interface NSObject (LQChildProcessDelegate)
- (void)childProcessHasTerminatedUnexpectedly:(LQProducerChildProcess *)process;
@end
