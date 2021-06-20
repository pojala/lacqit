//
//  LQFlatFileArchive.h
//  Lacqit
//
//  Created by Pauli Ojala on 31.7.2012.
//  Copyright (c) 2012 Pauli Ojala. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/LXBasicTypes.h>



/*
 This is a serialization file format intended to be used for format-specific updates.
 By packaging all the assets in a flat file, it can be distributed as blobs over e.g. S3.
 
 Why invent a new file format for this?
 Wwe want to include any JSON metadata with the file, and this format is designed to support exclusively that,
 since there are no other headers aside from the freeform JSON "root dictionary".
 */


extern NSString * const kLQFlatFileKey_Name;
extern NSString * const kLQFlatFileKey_Version;
extern NSString * const kLQFlatFileKey_FileDescriptions;
extern NSString * const kLQFlatFileKey_FileSize;
extern NSString * const kLQFlatFileKey_FileTypeUTI;


#define FILEEXT_LQFLATFILE  @"lark"



@interface LQFlatFileArchive : NSObject {
    
    NSDictionary *_rootDict;
    NSDictionary *_fileDatas;
}

- (id)initWithRoot:(NSDictionary *)dict files:(NSDictionary *)filesDict;  // filesDict should contain NSData objects with name keys

- (NSDictionary *)root;
- (id)objectForRootPath:(NSString *)path;  // uses Cocoa KVC syntax, i.e. "parent.child.property"

- (NSArray *)fileDescriptions;  // an array of dicts containing name/filesize keys
- (NSDictionary *)descriptionForFile:(NSString *)name;

- (NSData *)dataForFile:(NSString *)name;
- (NSString *)stringForFile:(NSString *)name;  // interprets the file as an UTF-8 string

// serialization
- (id)initWithData:(NSData *)data;
- (NSData *)dataRepresentation;

@end
