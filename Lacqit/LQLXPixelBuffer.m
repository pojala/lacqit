//
//  LQLXPixelBuffer.m
//  Lacqit
//
//  Created by Pauli Ojala on 8.1.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQLXPixelBuffer.h"
#import "LQModelConstants.h"
#import <Lacefx/LXStringUtils.h>
#import <Lacefx/LXPatternGen.h>
#import <Lacqit/LQLXBasicFunctions.h>



static NSMutableArray *g_fileTypes = nil;


NSArray *LQLXPixelBufferSupportedFileTypes()
{
    if ( !g_fileTypes) {
        g_fileTypes = [[NSMutableArray alloc] init];
        
        [g_fileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"png", @"bmp",
                                                                   @"dpx", @"cin",
                                                                   @"lxp", @"lxpix",
                                                                   @"tif", @"tiff", nil]];

        #if defined(__APPLE__)
        LQLXPixelBufferAddSupportedFileTypes([NSImage imageFileTypes]);
        #endif
    }
    return g_fileTypes;
}

void LQLXPixelBufferAddSupportedFileTypes(NSArray *newTypes)
{
    if ( !g_fileTypes) LQLXPixelBufferSupportedFileTypes();  // creates the array
    
    NSEnumerator *enumerator = [newTypes objectEnumerator];
    NSString *type;
    while (type = [enumerator nextObject]) {
        if ( ![g_fileTypes containsObject:type])
            [g_fileTypes addObject:type];
    }
}



@interface LQLXPixelBuffer (Templating)
- (NSString *)templateName;
- (void)setTemplateName:(NSString *)templateName;
@end


#define TEMPLATENAME_PLACEHOLDER @"placeholder"


@implementation LQLXPixelBuffer

+ (NSString *)lacTypeID {
    return @"PixelBuffer"; }

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (id %ld, refTime %.3f, sourceTime %.3f; %ld * %ld, lxpxf %ld, pixbuf %p, isret %i)>",
                        [self class], self,
                        (long)[self sampleID],
                        [self sampleReferenceTime],
                        [self sampleSourceTime],
                        (long)LXPixelBufferGetWidth(_pixbuf),
                        (long)LXPixelBufferGetHeight(_pixbuf),
                        (long)LXPixelBufferGetPixelFormat(_pixbuf),
                        _pixbuf, _isRetained
                    ];
}


+ (id)placeholderPixelBuffer
{
    static id s_def = nil;
    if ( !s_def) {
        LXPixelBufferRef pattern = LXPatternCreateGradientColorBars(LXMakeSize(256, 256));
        
        s_def = [[LQLXPixelBuffer alloc] initWithLXPixelBuffer:pattern retain:NO];
        [s_def setTemplateName:TEMPLATENAME_PLACEHOLDER];
    }
    return s_def;
}

- (id)initWithLXPixelBuffer:(LXPixelBufferRef)pixbuf retain:(BOOL)doRetain
{
    self = [super init];
    
    _pixbuf = (doRetain) ? LXPixelBufferRetain(pixbuf) : pixbuf;
    _isRetained = doRetain;
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfFile:path properties:nil error:NULL];
}

- (id)initWithContentsOfFile:(NSString *)path properties:(NSDictionary *)props error:(NSError **)outError
{
    self = [super init];
    
    if ([path length] < 1) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Path is empty" forKey:NSLocalizedDescriptionKey];
        if (outError) *outError = [NSError errorWithDomain:kLQErrorDomain code:392000 userInfo:userInfo];
        [self autorelease];
        return nil;
    }

    LXDECLERROR(lxErr);

    LXUnibuffer unipath = LXUnibufferCreateFromNSString(path);
    LXMapPtr lxProps = LXMapCreateFromNSDictionary(props);
    
    LXPixelBufferRef pixbuf = LXPixelBufferCreateFromFileAtPath(unipath, lxProps, &lxErr);
    
    LXStrUnibufferDestroy(&unipath);
    LXMapDestroy(lxProps);
    
    if ( !pixbuf) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:
                                            [NSString stringWithFormat:@"Error while opening image file (%i): %s", lxErr.errorID, lxErr.description]
                                                                forKey:NSLocalizedDescriptionKey];
        if (outError) *outError = [NSError errorWithDomain:kLQErrorDomain code:392002 userInfo:userInfo];
        LXErrorDestroyOnStack(lxErr);
        [self autorelease];
        return nil;
    }
    
    _pixbuf = pixbuf;
    _isRetained = YES;
    return self;
}

- (void)dealloc
{
    ///NSLog(@"%s: %@ (pixbuf %p, ret %i)", __func__, self, _pixbuf, _isRetained);

    if (_isRetained)
        LXPixelBufferRelease(_pixbuf);
    _pixbuf = NULL;
    [super dealloc];
}

- (LXPixelBufferRef)lxPixelBuffer {
    return _pixbuf;
}

- (LXTextureRef)lxTexture {
    LXDECLERROR(err)
    
    LXTextureRef tex = LXPixelBufferGetTexture(_pixbuf, NULL);
    if ( !tex) {
        NSLog(@"** %s (%@): failed to get texture (error %i / %s)", __func__, self, err.errorID, err.description);
        LXErrorDestroyOnStack(err);
    }
    //LXPrintf("%s (%p): texture is %p (size %i * %i)\n", __func__, self, tex, LXTextureGetWidth(tex), LXTextureGetHeight(tex));
    return tex;
}

- (NSString *)templateName {
    return _templateName; }
    
- (void)setTemplateName:(NSString *)templateName {
    [_templateName release];
    _templateName = [templateName copy];
}

- (NSSize)imageDataSize {
    return NSSizeFromLXSize(LXPixelBufferGetSize(_pixbuf)); }


- (LXInteger)width {
    return LXPixelBufferGetWidth(_pixbuf); }
    
- (LXInteger)height {
    return LXPixelBufferGetHeight(_pixbuf); }
    
- (NSSize)size {
    return NSSizeFromLXSize(LXPixelBufferGetSize(_pixbuf)); }
    
    
- (BOOL)matchesSize:(NSSize)size {
    LXSize ps = LXPixelBufferGetSize(_pixbuf);
    
    return (round(size.width) == round(ps.w) && round(size.height) == round(ps.h)) ? YES : NO;
}


#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithLXPixelBuffer:_pixbuf retain:YES];
}


#pragma mark --- NSCoding ---

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        NSString *templateName = [coder decodeObjectForKey:@"templateName"];
        
        if ([templateName isEqualToString:TEMPLATENAME_PLACEHOLDER]) {
            [self release];
            return [[[self class] placeholderPixelBuffer] retain];
        }
        else {
            NSData *serData = [coder decodeObjectForKey:@"serializedLXPixBuf"];
            size_t dataLen = [serData length];
            const uint8_t *buf = (const uint8_t *)[serData bytes];
            LXDECLERROR(err);
            
            _pixbuf = LXPixelBufferCreateFromSerializedData(buf, dataLen, &err);
            
            if ( !_pixbuf) {
                NSLog(@"** failed to decode pixbuf: error %i / %s", err.errorID, err.description);
                LXErrorDestroyOnStack(err);
            }
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ([_templateName length] < 1) {
        uint8_t *deflBuf = NULL;
        size_t deflDataLen = 0;
        LXPixelBufferSerializeDeflated(_pixbuf, &deflBuf, &deflDataLen);

        NSData *serData = [[NSData alloc] initWithBytes:deflBuf length:deflDataLen];
        [coder encodeObject:serData forKey:@"serializedLXPixBuf"];
        [serData release];
    
        _lx_free(deflBuf);
    }
    else {
        // for named template images, encode only the template name
        [coder encodeObject:_templateName forKey:@"templateName"];
    }
}

@end
