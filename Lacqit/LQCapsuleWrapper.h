//
//  LQCapsuleWrapper.h
//  Lacqit
//
//  Created by Pauli Ojala on 19.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import <Lacefx/LXBasicTypes.h>
#import "LQCapsuleDataTypes.h"

@class LQUUID;

/*
    A class to read and write the capsule format used by Conduit for scripted plugins.
 
    Formats can be added via codec plugins.
*/


@interface LQCapsuleWrapper : NSObject {
    
    LQUUID *_creatorUUID;
    LQUUID *_fileUUID;
    NSData *_capsuleData;
}

+ (void)addCodecClass:(Class)cls;

+ (id)decodeCapsuleFromURL:(NSURL *)url error:(NSError **)outError;

- (BOOL)writeToURL:(NSURL *)url format:(uint32_t)format;

// accessors
- (LQUUID *)creatorUUID;
- (void)setCreatorUUID:(LQUUID *)uuid;

- (LQUUID *)fileUUID;
- (void)setFileUUID:(LQUUID *)uuid;

- (NSData *)data;
- (void)setData:(NSData *)data;

@end


@protocol LQCapsuleCodec <NSObject>

+ (NSArray *)handledCapsuleFormats;

- (BOOL)decodeCapsule:(LQCapsuleWrapper *)capsule
                    fromData:(NSData *)data
                    header:(LQCapsuleFileHeader *)header error:(NSError **)outError;

- (NSData *)encodeCapsule:(LQCapsuleWrapper *)capsule
                    header:(LQCapsuleFileHeader *)header error:(NSError **)errorPtr;

@end
