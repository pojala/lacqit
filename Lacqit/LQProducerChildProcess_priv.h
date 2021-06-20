/*
 *  LQProducerChildProcess_priv.h
 *  ConduitFreenect
 *
 *  Created by Pauli Ojala on 12/1/10.
 *  Copyright 2010 Lacquer oy/ltd. All rights reserved.
 *
 */

#import <Lacqit/LQJSON.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/dirent.h>
#include <fcntl.h>
#include <stdlib.h>


enum {
    kLQProcessChildMsg_WillFinishLaunching = 1001,
    kLQProcessChildMsg_DidFinishLaunching = 1002,
    
    // applies to producer child process (sent by child)
    kLQProcessChildMsg_HasUpdatedBufferRange = 2001,
    kLQProcessChildMsg_HasNewDataID = 2002,
    
    
    kLQProcessHostMsg_Start = 30001,
    kLQProcessHostMsg_Stop = 30002,
    kLQProcessHostMsg_StillAlive = 30100,
    
    // applies to consumer child process (sent by host)
    kLQProcessHostMsg_HasUpdatedBufferRange = 32001,
    kLQProcessHostMsg_HasNewDataID = 32002,
};


#define kLQProcessChildKey_childPortName        @"childPortName"
#define kLQProcessChildKey_childPassesDataIDs   @"childPassesDataIDs"

#define kLQProcessChildKey_sharedMemPath        @"sharedMemFilePath"
#define kLQProcessChildKey_sharedMemFileSize    @"sharedMemFileSize"



#pragma mark --- shared mem utils ---

// create the map file and fill it with bytes
static int createSharedMemoryFile(NSString *progName, NSInteger length, NSString **outPath, void **outBuffer)
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.scratch", progName]];
    int fd;
 
    fd = open([path UTF8String], O_RDWR | O_CREAT, 0600);
    
    if (fd == -1) return -1;
    
    length += 1024;
    
    size_t bufSize = 512;
    char buf[bufSize];
    memset(buf, 0, bufSize);
    
    NSInteger i;
    NSInteger n = length / bufSize;
    for (i = 0; i < n; i++) {
        write(fd, buf, bufSize);
    }    
    n = length - n*bufSize;
    for (i = 0; i < n; i++) {
        write(fd, buf, 1);
    }
    
    void *map = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, fd, 0);
    if ( !map) {
        NSLog(@"** could not get mmap() for path '%@'", path);
    }
    
    if (outPath) *outPath = path;
    if (outBuffer) *outBuffer = map;
    return fd;
}
 
// map the file into memory in a read-write fashion
static void *mapSharedMemoryFile(NSString *path, NSInteger length)
{
    int fd = open([path UTF8String], O_RDWR, 0);
    if (fd == -1) return NULL;
    
    void *map = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_FILE|MAP_SHARED, fd, 0);
    
    close(fd);
    
    return map;
}

static void unmapSharedMemoryFile(void *buffer, NSInteger length)
{
    int ret = munmap(buffer, length);
    if (ret != 0) {
        NSLog(@"** %s: unmap failed (%p)", __func__, buffer);
    }
}


