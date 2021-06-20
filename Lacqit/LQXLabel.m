//
//  LQXLabel.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.5.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQXLabel.h"
#import "LQUIConstants.h"


@implementation LQXLabel

+ (NSDictionary *)darkTitleTextAttributes
{
    static NSDictionary *s_attrs = nil;

    if ( !s_attrs) {
        NSFont *font = [NSFont systemFontOfSize:11.0];
        NSColor *color = [NSColor colorWithDeviceRed:0.04 green:0.048 blue:0.06 alpha:0.8];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
        [shadow setShadowBlurRadius:0.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:0.2f]];
        
        s_attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            color, NSForegroundColorAttributeName,
                                                            shadow, NSShadowAttributeName,
                                                            nil] retain];
    }
    return s_attrs;
}

+ (NSDictionary *)lightTitleTextAttributes
{
    static NSDictionary *s_attrs = nil;

    if ( !s_attrs) {
        NSFont *font = [NSFont systemFontOfSize:11.0];
        NSColor *color = [NSColor colorWithDeviceRed:0.9 green:0.9 blue:0.9 alpha:0.95];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(1.0f, -1.0f)];
        [shadow setShadowBlurRadius:2.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];            
        
        s_attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            color, NSForegroundColorAttributeName,
                                                            shadow, NSShadowAttributeName,
                                                            nil] retain];
    }
    return s_attrs;
}

+ (NSDictionary *)whiteOverlayTextAttributes
{
    static NSDictionary *s_attrs = nil;

    if ( !s_attrs) {
        NSFont *font = [NSFont systemFontOfSize:11.0];
        NSColor *color = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.95];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(1.0f, -1.0f)];
        [shadow setShadowBlurRadius:2.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:1.0f]];            
        
        s_attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            color, NSForegroundColorAttributeName,
                                                            shadow, NSShadowAttributeName,
                                                            nil] retain];
    }
    return s_attrs;
}


+ (NSDictionary *)browserHeaderTextAttributes
{
    static NSDictionary *s_attrs = nil;

    if ( !s_attrs) {
        NSFont *font = [NSFont systemFontOfSize:14.0];
        //NSColor *color = [NSColor colorWithDeviceRed:0.75 green:0.74 blue:0.71 alpha:0.95];
        NSColor *color = [NSColor colorWithDeviceRed:0.035 green:0.0 blue:0.1 alpha:1.0];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
        //[shadow setShadowBlurRadius:5.0];
        //[shadow setShadowColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.0f alpha:0.9f]];            
        [shadow setShadowBlurRadius:0.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.18]];
        
        s_attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            color, NSForegroundColorAttributeName,
                                                            shadow, NSShadowAttributeName,
                                                            nil] retain];
    }
    return s_attrs;
}

+ (NSDictionary *)browserItemTextAttributes
{
    static NSDictionary *s_attrs = nil;

    if ( !s_attrs) {
        NSFont *font = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];
        NSColor *color = [NSColor colorWithDeviceRed:0.035 green:0.0 blue:0.1 alpha:1.0];

        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowOffset:NSMakeSize(0.0, -0.5)];
        [shadow setShadowBlurRadius:0.0];
        [shadow setShadowColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.1]];
        
        s_attrs = [[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            color, NSForegroundColorAttributeName,
                                                            shadow, NSShadowAttributeName,
                                                            nil] retain];
    }
    return s_attrs;
}


- (id)initWithString:(NSString *)str attributes:(id)attrs
{
    if ([str length] < 1) {
        [self release];
        return nil;
    }
    
    if ( !attrs)
        attrs = [[self class] darkTitleTextAttributes];
    
    NSSize size = [str sizeWithAttributes:attrs];
    
    // add extra room for shadow
    if ([attrs objectForKey:NSShadowAttributeName]) {
        size.width += 6.0;
        size.height += 4.0;
    }
        
    ///NSLog(@"title %@ -- texsize %.2f * %.2f", _title, size.width, size.height);
    
    _attributes = [attrs copy];
        
    self = [super initWithSize:size];
    
    if (self) {
        [self clear];
        [self lockFocus];
        
            NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
            [ctx setCompositingOperation:NSCompositeSourceOver];       
         
            [str drawAtPoint:NSMakePoint(2, 2) withAttributes:attrs];
        
            if ([attrs objectForKey:@"LQCrispFontAttributeName"]) {
                [str drawAtPoint:NSMakePoint(2, 2) withAttributes:attrs];  // "crisp" means just painting twice :)
            }
        
        [self unlockFocus];
    }
    
    return self;
}

- (void)dealloc
{
    [_attributes release];
    [super dealloc];
}


#pragma mark --- drawing ---

- (LXUInteger)storageHintForLXTexture
{
    return (kLXStorageHint_ClientStorage);  //| kLXStorageHint_PreferDMAToCaching);
}

- (void)drawInSurface:(LXSurfaceRef)lxSurface atPoint:(NSPoint)origin
{
    LXVertexXYUV vertices[4];
    
    LXTextureRef titleTex = [self lxTexture];
    if (titleTex) {
        LXSize texSize = LXTextureGetSize(titleTex);

        // offset if we have shadow
        if ([_attributes objectForKey:NSShadowAttributeName]) {
            origin.x += 2.0;
            origin.y += 2.0;
        }
        
        LXSetQuadVerticesXYUV(vertices, LXMakeRect(origin.x, origin.y,  texSize.w, texSize.h), LXUnitRect);


        LXDrawContextRef blendDrawCtx = LXDrawContextWithTexture(NULL, titleTex);
        
        LXDrawContextSetFlags(blendDrawCtx, kLXDrawFlag_UseFixedFunctionBlending_SourceIsPremult);
    
        LXSurfaceDrawPrimitive(lxSurface, kLXQuads, vertices, 4, kLXVertex_XYUV, blendDrawCtx);
    
        //LXSurfaceDrawTexturedQuad(lxSurface, (void *)vertices, kLXVertex_XYUV,
        //                          titleTex, NULL);
    }
}    

- (void)drawInSurface:(LXSurfaceRef)lxSurface atCenterPoint:(NSPoint)center
{
    NSSize size = [self size];
    
    [self drawInSurface:lxSurface atPoint:NSMakePoint(round(center.x - size.width*0.5), round(center.y - size.height*0.5))];
}


@end
