//
//  LQNSDataAdditions.h
//  Lacqit
//
//  Created by Pauli Ojala on 26.6.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"


@interface NSData (LQNSDataAdditions)

- (NSData *)zippedData;
- (NSData *)unzippedDataWithKnownLength:(size_t)knownLength;

+ (NSData *)dataFromBase64String:(NSString *)string;
- (NSString *)encodeAsBase64String;

@end
