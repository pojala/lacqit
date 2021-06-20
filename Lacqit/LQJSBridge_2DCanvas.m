//
//  LQJSBridge_2DCanvas.m
//  Lacqit
//
//  Created by Pauli Ojala on 14.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_2DCanvas.h"
#import "LQJSBridge_2DContext.h"
#import "LQCairoBitmap.h"
#import "LQNSColorAdditions.h"
#import "LQNSFontAdditions.h"

#import "LQJSBridge_LXSurface.h"
#import "LQJSBridge_LXTexture.h"


@implementation LQJSBridge_2DCanvas

+ (id)nullCanvasBridgeObjectInJSContext:(JSContextRef)context
{
    LQCairoBitmap *bmp = [[LQCairoBitmap alloc] initWithSize:NSMakeSize(8, 8)];
        
    id obj = [[[self class] alloc] initWithCairoBitmap:[bmp autorelease]
                                        name:[NSString stringWithFormat:@"%@_nullObj", [self class]]
                                        inJSContext:context
                                        withOwner:nil];
    return [obj autorelease];
}

- (id)initWithCairoBitmap:(LQCairoBitmap *)cairoBitmap name:(NSString *)name
            inJSContext:(JSContextRef)context
            withOwner:(id)owner
{
    self = [super initInJSContext:context withOwner:owner];
    if (self) {
        _name = [name copy];
        _bitmap = [cairoBitmap retain];
    }
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@", __func__, self);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [_myTexBridge setOwner:nil];
    [_myTexBridge release];
    _myTexBridge = nil;

    [_my2DContext finishContext];
    [_my2DContext release];
    _my2DContext = nil;
    
    ///NSLog(@"canvas dealloc: cached colors: %i, fonts: %i", [_colorStyleCache count], [_fontCache count]);
    [_colorStyleCache release];
    [_fontCache release];
    
    [_bitmap release];
    _bitmap = nil;
    
    [_name release];
    _name = nil;
    
    [pool drain];

    [super dealloc];
}

- (id)copyIntoJSContext:(JSContextRef)dstContext
{
    LQCairoBitmap *newBmp = [[LQCairoBitmap alloc] initWithContentsOfLQBitmap:[self cairoBitmap]];
    id newObj = nil;
            
    if (newBmp) {
        newObj = [[[self class] alloc] initWithCairoBitmap:[newBmp autorelease]
                                                name:[self name]
                                                inJSContext:dstContext
                                                withOwner:nil];
    }
    return [newObj autorelease];
}


- (LQCairoBitmap *)cairoBitmap {
    return _bitmap;
}

- (void)setCairoBitmap:(LQCairoBitmap *)bitmap
{
    [_my2DContext finishContext];  // this ensures that a reference to the previous bitmap doesn't linger in the 2D context

    if (bitmap != _bitmap) {
        [_bitmap release];
        _bitmap = [bitmap retain];
    }
}


+ (NSString *)constructorName
{
    return @"Canvas";
}

- (void)_releaseAfterJSConstructor:(id)unused
{
    [self release];
}

- (void)awakeFromConstructor:(NSArray *)arguments
{
    long w = 256, h = 256;  // defaults
    
    if ([arguments count] >= 2) {
        id firstArg = [arguments objectAtIndex:0];
        id secondArg = [arguments objectAtIndex:1];
        
        //NSLog(@"%s (%p): args %@, %@", __func__, self, [firstArg class], [secondArg class]);
        
        [self parseLongFromArg:firstArg outValue:&w];
        [self parseLongFromArg:secondArg outValue:&h];
        
        w = MAX(w, 1);
        h = MAX(h, 1);
        
        ///NSLog(@"   creating canvas with size %i * %i", w, h);
            
        if (w > 60000 || h > 60000) {  // sanity check
            NSLog(@"** JS 2DCanvas constructor - warning: ridiculous image size given as argument: %ld * %ld", w, h);
            w = MIN(w, 1024);
            h = MIN(h, 1024);
        }
    }
    
    [_name release];
    _name = [[NSString stringWithFormat:@"(constructed:<%ld*%ld>)", w, h] retain];
    
    [_bitmap release];
    _bitmap = [[LQCairoBitmap alloc] initWithSize:NSMakeSize(w, h)];
    [_bitmap clear];
    
    // hack to ensure that this object is not released prematurely
    [self retain];
    [self performSelectorOnMainThread:@selector(_releaseAfterJSConstructor:) withObject:nil waitUntilDone:NO];
    
    ///NSLog(@"%s: %@", __func__, self);
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects: @"name", @"width", @"height", nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return [propertyName isEqualToString:@"name"];
}

- (LXInteger)width {
    return [_bitmap width]; }
    
- (LXInteger)height {
    return [_bitmap height]; }
    
    
- (NSString *)name {
    return _name; }
    
- (void)setName:(NSString *)name {
    [_name release];
    _name = [name copy];
}

- (void)finishContext {
    [_my2DContext finishContext];
    [_my2DContext release];
    _my2DContext = nil;
}

- (void)setCairoView:(id)view {
    _cairoView = view; }
    
- (id)cairoView {
    return _cairoView; }


// called by the context when drawing is performed
- (void)contextWillPaint
{
    [_bitmap willModifyFrameBuffer];
}

- (void)contextDidPaint
{
    [_bitmap didModifyFrameBuffer];
    
    if (_cairoView)
        [_cairoView setNeedsDisplay:YES];
}
    

+ (NSArray *)objectFunctionNames // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"getContext", @"getTextureForSurface",
                nil]; 
}

- (id)lqjsCallGetContext:(NSArray *)args context:(id)contextObj
{
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);

    ///JSContextRef jsCtx = [self jsContextRefFromJSCallContextObj:contextObj];
    ///NSLog(@"%s: args %@ -- this JS context %p (creation context was %p) -- interpreter %@; its context %p", __func__, args, jsCtx, [self jsContextRef],
    ///                        interp, [interp jsContextRef]);
                            
    
    if ([args count] > 0 && [[[args objectAtIndex:0] description] isEqualToString:@"2d"]) {
        if ( !_my2DContext) {
            _my2DContext = [[LQJSBridge_2DContext alloc] initInJSContext:[interp jsContextRef] withOwnerCanvas:self];
        }
            
        return _my2DContext;
    }
    
    return nil;
}

- (id)lqjsCallGetTextureForSurface:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1)
        return nil;

    [self finishContext];
                
    ///JSContextRef jsCtx = [self jsContextRefFromJSCallContextObj:contextObj];

    // the surface argument is not really used right now, but it's required in case we need to get different texture objs
    // for different rendering devices later on

    id surf = [args objectAtIndex:0];
    if ([surf isKindOfClass:[LQJSBridge_LXSurface class]]) {
        if ( !_myTexBridge) {
            LXTextureRef myTex = [_bitmap lxTexture];
            if (myTex) {
                _myTexBridge = [[LQJSBridge_LXTexture alloc] initWithLXTexture:myTex
                                                    inJSContext:[self jsContextRef]
                                                    withOwner:self];
            }
        }
        return _myTexBridge;
    }
    else {
        [NSException raise:@"LQJSBridgeException" format:@"Can't acquire canvas texture for object of class '%@'", [surf class]];
    }
    
    return nil;
}



#pragma mark --- caching ---

- (NSColor *)cachedColorForString:(NSString *)key
{
    if ([key length] < 1) return nil;
    
    key = [key lowercaseString];

    if ( !_colorStyleCache)
        _colorStyleCache = [[NSMutableDictionary alloc] init];
        
    NSColor *obj;
    if ((obj = [_colorStyleCache objectForKey:key]))
        return obj;
        
    obj = [NSColor colorWithHTMLFormattedSRGBString:key];
        //[[LQJSBridge_Color alloc] initWithHTMLFormattedString:key inJSContext:[self jsContextRef] withOwner:self];
    
    if (obj) [_colorStyleCache setObject:obj forKey:key];
    
    return obj;
}

- (NSFont *)cachedFontForString:(NSString *)key
{
    if ([key length] < 1) return nil;
    
    if ( !_fontCache)
        _fontCache = [[NSMutableDictionary alloc] init];
        
    NSFont *obj;
    if ((obj = [_fontCache objectForKey:key]))
        return obj;
        
    obj = [NSFont fontWithCSSFormattedString:key];
    
    if (obj) [_fontCache setObject:obj forKey:key];
    
    return obj;
}

@end
