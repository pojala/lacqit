//
//  LQLXPixelBuffer.h
//  Lacqit
//
//  Created by Pauli Ojala on 8.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Lacefx/Lacefx.h>
#import "LQStreamBuffer.h"


LACQIT_EXPORT NSArray *LQLXPixelBufferSupportedFileTypes();

LACQIT_EXPORT void LQLXPixelBufferAddSupportedFileTypes(NSArray *newTypes);


/*
  This class is used for buffers in LQStreamPatch.
  The idea is that these objects are thin wrappers that all return -lxTexture.

  This class also adds NSCoding support for pixel buffers by wrapping LXPixelBufferSerialize().
  
  NOTE: NSCopying retains the pixel buffer rather than copying the data.
*/

@interface LQLXPixelBuffer : LQStreamBuffer  <NSCoding, NSCopying> {

    LXPixelBufferRef _pixbuf;
    BOOL _isRetained;
    
    NSString *_templateName;
}

+ (id)placeholderPixelBuffer;  // default image where one is needed (e.g. Conduit embedded assets where no image has been loaded yet)

- (id)initWithLXPixelBuffer:(LXPixelBufferRef)pixbuf retain:(BOOL)doRetain;

- (id)initWithContentsOfFile:(NSString *)path
                  properties:(NSDictionary *)properties 
                       error:(NSError **)outError;  // wrapper for LXPixelBufferCreateFromFileAtPath() function

- (id)initWithContentsOfFile:(NSString *)path;

- (LXPixelBufferRef)lxPixelBuffer;
- (LXTextureRef)lxTexture;

- (LXInteger)width;
- (LXInteger)height;
- (NSSize)size;
- (BOOL)matchesSize:(NSSize)size;

- (NSSize)imageDataSize;

@end
