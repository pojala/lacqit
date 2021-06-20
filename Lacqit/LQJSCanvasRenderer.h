//
//  LQJSCanvasRenderer.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LacqitExport.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"


@interface LQJSCanvasRenderer : NSObject {

    LQJSContainer *_js;
    
    NSError *_lastError;
}

- (BOOL)compileScript:(NSString *)script;
- (NSString *)script;

- (NSError *)lastError;

- (LQBitmap *)renderBitmapWithSize:(NSSize)size;


#if !defined(__LAGOON__)
- (NSImage *)renderNSImageWithSize:(NSSize)size;
#endif

@end
