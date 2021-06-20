//
//  LQCapsuleConstants.h
//  Lacqit
//
//  Created by Pauli Ojala on 26.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#ifndef _LQCAPSULETYPES_H_

#import <Foundation/Foundation.h>
#import <Lacqit/LQUUID.h>
#import <Lacqit/LacqitExport.h>



// --- exported data ---

LACQIT_EXPORT_VAR NSString * const kLQCapsuleErrorDomain;



// --- file format ---

enum {
    kLQCapsuleBasicFormat = 0x44d391,
    kLQCapsuleBinaryFormat = 0x4401d3af
};
typedef uint32_t LQCapsuleFormatID;


// file cookie, i.e. 4-byte start identifier
#define kLQCapsuleCookie 0x5f04a9b8


// all fields are stored to disk as little-endian
#pragma pack(push, 1)
typedef struct _LQCapsuleFileHeader {
    uint32_t cookie;            // file format cookie
    uint32_t formatID;          // an LQCapsuleFormatID value
    uint32_t formatVersion;     // file format version specific to formatID
    uint32_t _res_i1;
    
    CFUUIDBytes capsuleID;      // optional UUID to identify this file
    
    uint64_t dataSize;          // size of data that follows the header
    uint64_t uncompDataSize;    // original data size before zip compression
    
    uint32_t offsetToData;      // size of this header
    
    uint8_t _reserved[32];
} LQCapsuleFileHeader;
#pragma pack(pop)

#define kLQCapsuleHeaderSize   (4*4 + 16 + 2*8 + 4 + 32)  // 84 bytes


#endif
