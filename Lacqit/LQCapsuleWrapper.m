//
//  LQCapsuleWrapper.m
//  Lacqit
//
//  Created by Pauli Ojala on 19.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQCapsuleWrapper.h"
#import "LQNSDataAdditions.h"
#import "LQCapsuleDataTypes.h"
#import "LQBitmap.h"  // for LQFourCCToString()




// --- utility macros ---

#define SETOUTERR(code_, descStr_) \
        if (errorPtr) {  \
            *errorPtr = [NSError errorWithDomain:kLQCapsuleErrorDomain code:code_  \
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:  \
                                                        descStr_, NSLocalizedDescriptionKey, nil]];  \
        }

#define BAILFROMINIT(code__, descStr__) \
        SETOUTERR(code__, descStr__) \
        [self release]; \
        return nil;


static NSMutableArray *g_codecs = nil;

@implementation LQCapsuleWrapper

+ (void)addCodecClass:(Class)cls
{
    if ( !cls) return;
    
    if ( !g_codecs) g_codecs = [[NSMutableArray alloc] initWithCapacity:10];
    
    if ([g_codecs containsObject:cls]) return;
    
    [g_codecs addObject:cls];
}


- (id)initWithURL:(NSURL *)url error:(NSError **)errorPtr
{
    self = [super init];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    size_t len = [data length];
    if (len <= kLQCapsuleHeaderSize) {
        BAILFROMINIT(1001, @"Couldn't load data from URL");
    }
    
    uint8_t *buf = (uint8_t *) [data bytes];
    
    LQCapsuleFileHeader header;
    memcpy(&header, buf, kLQCapsuleHeaderSize);
    
    if (LXEndianLittle_u32(header.cookie) != kLQCapsuleCookie) {
        BAILFROMINIT(2001, @"Invalid file header identifier");
    }
    
    // convert endianness of header
    header.formatID = LXEndianLittle_u32(header.formatID);
    header.formatVersion = LXEndianLittle_u32(header.formatVersion);
    header.dataSize = LXEndianLittle_u64(header.dataSize);
    header.uncompDataSize = LXEndianLittle_u64(header.uncompDataSize);
    header.offsetToData = LXEndianLittle_u32(header.offsetToData);
    
    
    id codec = nil;
    if (header.formatID == kLQCapsuleBasicFormat) {
        codec = self;
    } else {
        for (Class codecCls in g_codecs) {
            if ( ![codecCls respondsToSelector:@selector(handledCapsuleFormats)]) {
                continue;
            }
            if ([[codecCls handledCapsuleFormats] containsObject:[NSNumber numberWithInteger:header.formatID]]) {
                codec = [[[codecCls alloc] init] autorelease];
                break;
            }
        }
    }
    if ( !codec) {
        NSString *err = [NSString stringWithFormat:@"Unknown format '%@'", LQFourCCToString(header.formatID)];
        BAILFROMINIT(2005, err);
    }
    
    if (header.dataSize < 1) {
        BAILFROMINIT(2003, @"No data size");
    }
    if (header.dataSize > len - kLQCapsuleHeaderSize) {
        BAILFROMINIT(2004, @"Data has been truncated");
    }
    if (header.dataSize > 1 * 1024*1024*1024) {
        // a capsule size of over 1 gig probably indicates an endianness issue
        BAILFROMINIT(2010, @"Unrealistic data size");
    }
    
    NSData *dataInFile = [NSData dataWithBytesNoCopy:buf + header.offsetToData //kLQCapsuleHeaderSize
                                                  length:header.dataSize
                                                  freeWhenDone:NO];
    
    if ( ![codec decodeCapsule:self fromData:dataInFile header:&header error:errorPtr]) {
        [self release];
        return nil;
    }

    return self;
}


+ (id)decodeCapsuleFromURL:(NSURL *)url error:(NSError **)errorPtr
{
    return [[[[self class] alloc] initWithURL:url error:errorPtr] autorelease];
}

- (void)dealloc
{
    [_capsuleData release];
    
    [_creatorUUID release];
    [_fileUUID release];
    
    [super dealloc];
}


#pragma mark --- encoding ---

- (BOOL)writeToURL:(NSURL *)url format:(uint32_t)format
{
    if ( !url)
        return NO;
    if ( ![url isFileURL]) {
        NSLog(@"** %s: can't write to non-file URL (%@)", __func__, url);
        return NO;
    }
    
    id codec = nil;
    if (format == kLQCapsuleBasicFormat) {
        codec = self;
    } else {
        for (Class codecCls in g_codecs) {
            if ( ![codecCls respondsToSelector:@selector(handledCapsuleFormats)]) {
                continue;
            }
            if ([[codecCls handledCapsuleFormats] containsObject:[NSNumber numberWithInteger:format]]) {
                codec = [[[codecCls alloc] init] autorelease];
                break;
            }
        }
    }
    if ( !codec) {
        NSString *err = [NSString stringWithFormat:@"Unknown format '%@'", LQFourCCToString(format)];
        NSLog(@"** could not write capsule: %@", err);
        return NO;
    }
    
    
    // fill up header
    LQCapsuleFileHeader header;
    memset(&header, 0, sizeof(LQCapsuleFileHeader));
    
    header.cookie =         LXEndianLittle_u32(kLQCapsuleCookie);
    header.formatID =       LXEndianLittle_u32(format);
    header.offsetToData =   LXEndianLittle_u32(kLQCapsuleHeaderSize);
    
    if (_fileUUID) header.capsuleID = [_fileUUID uuidBytes];
    
    NSError *error = nil;
    NSData *dataToWrite = [codec encodeCapsule:self header:&header error:&error];
    if ( !dataToWrite) {
        NSLog(@"** could not encode capsule, codec %@: %@", [codec class], error);
        return NO;
    }

    header.dataSize =       LXEndianLittle_u64([dataToWrite length]);
    header.uncompDataSize = LXEndianLittle_u64([_capsuleData length]);
    
    // write to file
    size_t fileDataLen = sizeof(LQCapsuleFileHeader) + [dataToWrite length];
    
    uint8_t *fileData = NSZoneMalloc(NULL, fileDataLen);
    memcpy(fileData,  &header, kLQCapsuleHeaderSize);
    memcpy(fileData + kLQCapsuleHeaderSize,  [dataToWrite bytes], [dataToWrite length]);
    
    NSData *d = [NSData dataWithBytesNoCopy:fileData length:fileDataLen freeWhenDone:YES];
    
    return [d writeToURL:url atomically:NO];
}



#pragma mark --- accessors ---

- (LQUUID *)creatorUUID {
    return _creatorUUID; }
    
- (LQUUID *)fileUUID {
    return _fileUUID; }

- (void)setCreatorUUID:(LQUUID *)uuid {
    [_creatorUUID release];
    _creatorUUID = [uuid copy];
}

- (void)setFileUUID:(LQUUID *)uuid {
    [_fileUUID release];
    _fileUUID = [uuid copy];
}

- (NSData *)data {
    return _capsuleData; }

- (void)setData:(NSData *)data {
    [_capsuleData autorelease];
    _capsuleData = [data retain];
}



#pragma mark --- codec implementation for default format ---

+ (NSArray *)handledCapsuleFormats
{
    return [NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:kLQCapsuleBasicFormat]];
}

- (NSData *)encodeCapsule:(LQCapsuleWrapper *)capsule header:(LQCapsuleFileHeader *)header error:(NSError **)errorPtr
{
    NSData *zippedData = [[capsule data] zippedData];
    
    if ( !zippedData || [zippedData length] < 1) {
        NSLog(@"** %s: didn't get zippedData", __func__);
        return nil;
    }
    return zippedData;
}

- (BOOL)decodeCapsule:(LQCapsuleWrapper *)capsule
             fromData:(NSData *)data
               header:(LQCapsuleFileHeader *)header error:(NSError **)errorPtr
{
    NSData *unzippedData = [data unzippedDataWithKnownLength:header->uncompDataSize];
    
    if ( !unzippedData || [unzippedData length] < 1) {
        SETOUTERR(2020, @"Decompression failed");
        return NO;
    }
    
    [capsule setData:unzippedData];
    [capsule setFileUUID:[LQUUID uuidFromUUIDBytes:header->capsuleID]];
    
    return YES;
}


@end
