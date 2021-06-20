//
//  LQFlatFileArchive.m
//  Lacqit
//
//  Created by Pauli Ojala on 31.7.2012.
//  Copyright (c) 2012 Pauli Ojala. All rights reserved.
//

#import "LQFlatFileArchive.h"
#import "LQJSON.h"


NSString * const kLQFlatFileKey_Name = @"name";
NSString * const kLQFlatFileKey_Version = @"version";
NSString * const kLQFlatFileKey_FileDescriptions = @"fileDescriptions";
NSString * const kLQFlatFileKey_FileSize = @"sizeInBytes";
NSString * const kLQFlatFileKey_FileTypeUTI = @"fileUTI";



@implementation LQFlatFileArchive

- (id)initWithRoot:(NSDictionary *)dict files:(NSDictionary *)filesDict
{
    self = [super init];
    _rootDict = [dict copy];
    _fileDatas = [filesDict copy];
    return self;
}

- (void)dealloc
{
    [_rootDict release];
    [_fileDatas release];
    [super dealloc];
}

- (NSDictionary *)root {
    return _rootDict;
}

- (id)objectForRootPath:(NSString *)path {
    return [_rootDict valueForKeyPath:path];
}

- (NSArray *)fileDescriptions {
    return [_rootDict objectForKey:kLQFlatFileKey_FileDescriptions];
}

- (NSDictionary *)descriptionForFile:(NSString *)name
{
    if ( !name) return nil;
    for (id dict in [self fileDescriptions]) {
        if ([[dict objectForKey:kLQFlatFileKey_Name] isEqualToString:name]) {
            return dict;
        }
    }
    return nil;
}

- (NSData *)dataForFile:(NSString *)name
{
    return [_fileDatas objectForKey:name];
}

- (NSString *)stringForFile:(NSString *)name
{
    NSData *data = [_fileDatas objectForKey:name];
    if ( !data) return nil;
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}



#pragma mark --- serialization ---


#define FILEHEADER_MAGIC_B1  'l'
#define FILEHEADER_MAGIC_B2  'a'
#define FILEHEADER_MAGIC_B3  'r'
#define FILEHEADER_MAGIC_B4  'k'
#define FILEHEADER_MAGIC_B5  0
#define FILEHEADER_MAGIC_B6  0xfa
#define FILEHEADER_MAGIC_B7  0xfc
#define FILEHEADER_MAGIC_B8  0xfb

/*
 This format is the simplest file archive one can imagine.
 There's a tiny 12-byte header followed by a JSON description of the archive. After that, just concatenated file data.
 */
- (NSData *)dataRepresentation
{
    NSError *error = nil;
    LQJSON *gen = [[[LQJSON alloc] init] autorelease];
    [gen setHumanReadable:NO];
    NSString *json = [gen stringWithObject:_rootDict error:&error];
    if ( !json) {
        NSLog(@"*** %s: error %@", __func__, error);
        return nil;
    }
    
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    int32_t jsonLen = (int32_t)[jsonData length];
    
    
    NSMutableData *data = [NSMutableData data];
    
    // the file format identifier (8 bytes)
    uint8_t magic[] = {  FILEHEADER_MAGIC_B1, FILEHEADER_MAGIC_B2, FILEHEADER_MAGIC_B3, FILEHEADER_MAGIC_B4, 
        FILEHEADER_MAGIC_B5, FILEHEADER_MAGIC_B6, FILEHEADER_MAGIC_B7, FILEHEADER_MAGIC_B8  };
    
    [data appendBytes:magic length:8];
    
    // format identifier is followed by an offset to the file data (4 bytes).
    // this value is big-endian
    int32_t offsetToFiles = 8 + 4 + jsonLen;
    offsetToFiles = LXEndianBig_s32(offsetToFiles);
    [data appendBytes:&offsetToFiles length:4];
    
    // write the JSON
    [data appendData:jsonData];
    
    // write files
    NSArray *files = [self fileDescriptions];
    for (id fileDesc in files) {
        NSString *name = [fileDesc objectForKey:kLQFlatFileKey_Name];
        size_t fileSize = [[fileDesc objectForKey:kLQFlatFileKey_FileSize] longValue];
        
        if ([name length] < 1 || fileSize < 1) continue;
        
        NSData *fileData = [self dataForFile:name];
        if ( !fileData) {
            NSLog(@"** %s: can't write file named '%@', no data", __func__, name);
        } else if ([fileData length] != fileSize) {
            NSLog(@"** %s: can't write file named '%@', invalid file size specified (exp %ld, is %ld), can't continue", __func__, name, (long)fileSize, (long)[fileData length]);
            return nil;  // --
        } else {
            [data appendData:fileData];
        }
    }
    
    return data;
}

- (BOOL)_deserializeData:(NSData *)data
{
    if ( !data || [data length] < 12) {
        return NO;
    }
    
    uint8_t magic[] = {  FILEHEADER_MAGIC_B1, FILEHEADER_MAGIC_B2, FILEHEADER_MAGIC_B3, FILEHEADER_MAGIC_B4, 
        FILEHEADER_MAGIC_B5, FILEHEADER_MAGIC_B6, FILEHEADER_MAGIC_B7, FILEHEADER_MAGIC_B8  };
    
    if (0 != memcmp(magic, [data bytes], 8)) {
        uint8_t *b = (uint8_t *)[data bytes];
        NSLog(@"** %s: data header mismatch (%i, %i, %i, %i,  %i, %i, %i, %i)", __func__, b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7]);
        return NO;
    }
    
    int32_t offsetToFiles;
    memcpy(&offsetToFiles, ((uint8_t *)[data bytes]) + 8, 4);
    offsetToFiles = LXEndianBig_s32(offsetToFiles);
    
    if (offsetToFiles < 12) {
        NSLog(@"** %s: invalid offset in file header (%i)", __func__, offsetToFiles);
        return NO;
    }
    
    int32_t jsonLen = offsetToFiles - 12;
    NSData *jsonData = [data subdataWithRange:NSMakeRange(12, jsonLen)];
    NSString *jsonStr = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] autorelease];
    if ( !jsonStr || [jsonStr length] < 1) {
        NSLog(@"** %s: could not decode json in header", __func__);
        return NO;
    }
    
    NSDictionary *rootDict = [jsonStr parseAsJSON];
    if ( !rootDict || ![rootDict isKindOfClass:[NSDictionary class]]) {
        NSLog(@"** %s: could not parse json in header (got %@)", __func__, [rootDict class]);
        return NO;
    }
    
    [_rootDict release];
    _rootDict = [rootDict retain];
    
    NSMutableDictionary *fileDict = [NSMutableDictionary dictionary];
    
    size_t dataConsumed = offsetToFiles;
    
    // read files
    NSArray *files = [self fileDescriptions];
    for (id fileDesc in files) {
        NSString *name = [fileDesc objectForKey:kLQFlatFileKey_Name];
        size_t fileSize = [[fileDesc objectForKey:kLQFlatFileKey_FileSize] longValue];
        
        if ([name length] < 1 || fileSize < 1) continue;
        
        if (dataConsumed + fileSize > [data length]) {
            NSLog(@"** %s: can't read file '%@', insufficient data (should have %ld bytes, only %ld left)", __func__, name, (long)fileSize, (long)[data length]-dataConsumed);
            break;
        } else {
            NSData *fileData = [data subdataWithRange:NSMakeRange(dataConsumed, fileSize)];
            [fileDict setObject:fileData forKey:name];
            //NSLog(@" ... got file '%@', %ld bytes", name, (long)[fileData length]);
            
            dataConsumed += fileSize;
        }
    }
    
    [_fileDatas release];
    _fileDatas = [fileDict retain];
    
    return YES;
}

- (id)initWithData:(NSData *)data
{
    self = [super init];
    
    if ( ![self _deserializeData:data]) {
        [self release];
        return nil;
    }
    
    return self;
}


@end
