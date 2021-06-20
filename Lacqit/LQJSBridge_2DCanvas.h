//
//  LQJSBridge_2DCanvas.h
//  Lacqit
//
//  Created by Pauli Ojala on 14.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQUIFrameworkHeader.h"
#import "LacqitExport.h"
#import <LacqJS/LacqJS.h>
#import "LQCairoBitmap.h"


@interface LQJSBridge_2DCanvas : LQJSBridgeObject  <LQJSCopying> {

    NSString *_name;

    LQCairoBitmap *_bitmap;
    
    id _my2DContext;
    id _myTexBridge;
    
    id _cairoView;
    
    NSMutableDictionary *_colorStyleCache;
    NSMutableDictionary *_fontCache;
}

- (id)initWithCairoBitmap:(LQCairoBitmap *)cairoBitmap  // is retained
            name:(NSString *)name
            inJSContext:(JSContextRef)context
            withOwner:(id)owner;

- (NSString *)name;

- (LQCairoBitmap *)cairoBitmap;
- (void)setCairoBitmap:(LQCairoBitmap *)bitmap;

- (void)finishContext;

// setting the view means that the bridge will call its -setNeedsDisplay: method when necessary
- (void)setCairoView:(id)view;
- (id)cairoView;

// convenience factory method for testing scripts that require a canvas input object
+ (id)nullCanvasBridgeObjectInJSContext:(JSContextRef)context;

- (id)copyIntoJSContext:(JSContextRef)dstContext;


// private
- (void)contextWillPaint;
- (void)contextDidPaint;

- (NSColor *)cachedColorForString:(NSString *)key;
- (NSFont *)cachedFontForString:(NSString *)key;

@end
