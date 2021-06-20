//
//  PixMathRenderContext.m
//  PixelMath
//
//  Created by Pauli Ojala on 11.4.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQXRenderContext.h"
#import "LQNSValueAdditions.h"


#define MAXTEXTURES 8


static NSMutableArray *g_sliderNames = nil;
static NSMutableArray *g_pickerNames = nil;

NSString *LQXStandardParamName(LXUInteger type, LXInteger index)
{
    if ( !g_sliderNames) {
        g_sliderNames = [[NSMutableArray alloc] init];
        int i;
        for (i = 0; i < 16; i++) {
            [g_sliderNames addObject:[NSString stringWithFormat:@"Slider %i", i + 1]];
        }
    }
    if ( !g_pickerNames) {
        g_pickerNames = [[NSMutableArray alloc] init];
        int i;
        for (i = 0; i < 16; i++) {
            [g_pickerNames addObject:[NSString stringWithFormat:@"Color Picker %i", i + 1]];
        }
    }
    
    switch (type) {
        case kLQXStandardParamType_Slider:
            if (index >= 0 && index < [g_sliderNames count])
                return [g_sliderNames objectAtIndex:index];
            break;
        case kLQXStandardParamType_ColorPicker:
            if (index >= 0 && index < [g_pickerNames count])
                return [g_pickerNames objectAtIndex:index];
            break;
    }
    return nil;
}


@implementation LQXRenderContext

- (id)init
{
    self = [super init];
    
    _textures = [[NSMutableArray arrayWithCapacity:8] retain];
    // fill with nulls
    int i;
    for (i = 0; i < MAXTEXTURES; i++) {
        [_textures addObject:[NSValue valueWithPointer:NULL]];
    }
    
    _parameters = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc
{
    [_vars release];
    [_parameters release];
    
    int i;
    for (i = 0; i < MAXTEXTURES; i++) {
        LXTextureRef tex = [[_textures objectAtIndex:i] pointerValue];
        LXTextureRelease(tex);
    }

    [_textures release];
    
    [super dealloc];
}


- (LXInteger)numberOfTextureSlots {
    return MAXTEXTURES; }


- (LXTextureRef)lxTextureAtIndex:(LXInteger)index
{
    NSAssert(index >= 0 && index < MAXTEXTURES, @"index out of bounds");
    
    return [[_textures objectAtIndex:index] pointerValue];
}

- (void)setLXTexture:(LXTextureRef)tex forIndex:(LXInteger)index
{
    NSAssert(index >= 0 && index < MAXTEXTURES, @"index out of bounds");
    
    LXTextureRef prevTex = [[_textures objectAtIndex:index] pointerValue];
    
    if (prevTex != tex) {
        LXTextureRelease(prevTex);
    
        LXTextureRetain(tex);
    
        [_textures replaceObjectAtIndex:index withObject:[NSValue valueWithPointer:tex]];
    }
}

- (void)clearAllTextures
{
    LXInteger count = MAXTEXTURES;
    LXInteger i;
    for (i = 0; i < count; i++) {
        [self setLXTexture:NULL forIndex:i];
    }
}

- (void)takeTexturesFromLXTextureArray:(LXTextureArrayRef)texArray
{
    LXInteger count = MIN(MAXTEXTURES, LXTextureArraySlotCount(texArray));
    LXInteger i;
    for (i = 0; i < count; i++) {
        [self setLXTexture:LXTextureArrayAt(texArray, i) forIndex:i];
    }
}

- (LXTextureArrayRef)createLXTextureArray
{
    LXTextureRef textures[MAXTEXTURES];
    LXInteger count = MAXTEXTURES;
    LXInteger i;
    
    LXInteger n = 0;
    for (i = 0; i < count; i++) {
        textures[i] = [[_textures objectAtIndex:i] pointerValue];
        if (textures[i])
            n = i+1;
    }

    LXTextureArrayRef texArr = LXTextureArrayCreateWithTexturesAndCount(textures, n);
    
    return texArr;
}

- (LXFPClosureContextPtr)createLXFPClosureContext
{
    LXFPClosureContextPtr fpctx = LXFPClosureContextCreate();
    
    LXFloat sliderVals[9];
    LXRGBA pickerVals[5];
    int i, n;
    ///[tempCtx getScalarValues:sliderVals arrayFloatCount:9];
    ///[tempCtx getVectorValues:pickerVals arrayVectorCount:4];

    memset(sliderVals, 0, 9*sizeof(LXFloat));
    memset(pickerVals, 0, 5*sizeof(LXRGBA));

    n = 8;
    for (i = 1; i <= n; i++) {
        double sliderVal = [self doubleValueForParameterNamed:[NSString stringWithFormat:@"Slider %i", i]];
        sliderVals[i] = sliderVal;
    }
    
    n = 4;
    for (i = 1; i <= n; i++) {
        LXRGBA pickerVal = [self rgbaValueForParameterNamed:[NSString stringWithFormat:@"Color Picker %i", i]];
        pickerVals[i] = pickerVal;
    }

    LXFPClosureContextSetScalars(fpctx, sliderVals+1, 8);
    LXFPClosureContextSetVectors(fpctx, pickerVals+1, 4);
    
    return fpctx;
}


#pragma mark --- parameters ---

- (void)setDoubleValue:(double)v forParameterNamed:(NSString *)name
{
    [_parameters setObject:[NSNumber numberWithDouble:v] forKey:name];
}

- (void)setIntegerValue:(long)v forParameterNamed:(NSString *)name
{
    [_parameters setObject:[NSNumber numberWithLong:v] forKey:name];
}

- (void)setBooleanValue:(BOOL)f forParameterNamed:(NSString *)name
{
    [_parameters setObject:[NSNumber numberWithBool:f] forKey:name];
}

- (void)setRGBAValue:(LXRGBA)r forParameterNamed:(NSString *)name
{
    [_parameters setObject:[NSValue valueWithRGBA:r] forKey:name];
}

- (double)doubleValueForParameterNamed:(NSString *)name
{
    id val = [_parameters objectForKey:name];
    char s = 0;
    
    if ( !val) {  // try to get double from vector using the point notation (foo.x)
        NSRange range = [name rangeOfString:@"." options:NSBackwardsSearch];
        if (range.location != NSNotFound && range.location < [name length]-1) {
            s = [name characterAtIndex:range.location+1];
            name = [name substringToIndex:range.location];
            
            val = [_parameters objectForKey:name];
        }
    }
    
    if ([val respondsToSelector:@selector(rgbaValue)] && 0 == strcmp([val objCType], @encode(LXRGBA))) {
        LXRGBA rgba = [val rgbaValue];
        if (s == 0) {
            return rgba.r;
        } else {
            switch (s) {
                case 'r':  case 'R':  case 'x':  case 'X':
                    return rgba.r;
                    
                case 'g':  case 'G':  case 'y':  case 'Y':
                    return rgba.g;
                
                case 'b':  case 'B':  case 'z':  case 'Z':
                    return rgba.b;
                
                case 'a':  case 'A':  case 'w':  case 'W':
                    return rgba.a;                
            }
        }
    }
    return (val) ? [val doubleValue] : 0.0;
}

- (long)integerValueForParameterNamed:(NSString *)name
{
    id val = [_parameters objectForKey:name];
    return (val) ? [val longValue] : 0;
}

- (BOOL)boolValueForParameterNamed:(NSString *)name
{
    id val = [_parameters objectForKey:name];
    return (val) ? [val boolValue] : NO;
}

- (LXRGBA)rgbaValueForParameterNamed:(NSString *)name
{
    id val = [_parameters objectForKey:name];
    return (val) ? [val rgbaValue] : LXMakeRGBA(0, 0, 0, 0);
}

- (NSArray *)parameterNames {
    return [_parameters allKeys]; }

- (NSDictionary *)parameterDictionary {
    return _parameters; }


// a dictionary with only plist-valid objects
- (NSDictionary *)parameterPlistDictionary
{
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    NSEnumerator *keyEnum = [_parameters keyEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject]) {
        id val = [_parameters objectForKey:key];
        if ([val respondsToSelector:@selector(rgbaValue)] && 0 == strcmp([val objCType], @encode(LXRGBA))) {
            val = NSStringFromLXRGBA([val rgbaValue]);
        } else if ([val respondsToSelector:@selector(doubleValue)]) {
            val = [NSNumber numberWithDouble:[val doubleValue]];
        } else
            val = nil;
        
        if (val) [plist setObject:val forKey:key];
    }
    return plist;
}
    
- (void)takeParametersFromPlistDictionary:(NSDictionary *)dict
{
    NSEnumerator *keyEnum = [dict keyEnumerator];
    NSString *key;
    while (key = [keyEnum nextObject]) {
        id val = [dict objectForKey:key];
        if ([val isKindOfClass:[NSNumber class]]) {
            // value is ok as-is
        } else if ([val isKindOfClass:[NSString class]]) {
            val = [NSValue valueWithRGBA:LXRGBAFromNSString(val)];
        } else
            val = nil;
        
        if (val) [_parameters setObject:val forKey:[key description]];
    }
}


- (BOOL)hasParameterNamed:(NSString *)name {
    return ([_parameters objectForKey:name]) ? YES : NO; }
    

- (BOOL)getParameterNamesForPoint:(NSString *)pointName xNamePtr:(NSString **)outXName yNamePtr:(NSString **)outYName
{
    if (outXName) *outXName = nil;
    if (outYName) *outYName = nil;

    if ([pointName length] < 1) return NO;

    NSString *xName = nil;
    NSString *yName = nil;
    NSArray *hostValNames = [self parameterNames];
    NSRange range;
    
    if ([hostValNames containsObject:[pointName stringByAppendingString:@".x"]]) {
        xName = [pointName stringByAppendingString:@".x"];
        yName = [pointName stringByAppendingString:@".y"];
    }
    else if ([hostValNames containsObject:[pointName stringByAppendingString:@".r"]]) {
        xName = [pointName stringByAppendingString:@".r"];
        yName = [pointName stringByAppendingString:@".g"];
    }
    else if ((range = [pointName rangeOfString:@"Slider "]).location != NSNotFound) {
        int index = [[pointName substringFromIndex:range.location + range.length] intValue];
        if (index > 0) {
            xName = [NSString stringWithFormat:@"Slider %i", index];
            yName = [NSString stringWithFormat:@"Slider %i", index+1];
        }
    }
    else {
        id val = [_parameters objectForKey:pointName];
        if ([val respondsToSelector:@selector(rgbaValue)] && 0 == strcmp([val objCType], @encode(LXRGBA))) {
            xName = [pointName stringByAppendingString:@".r"];
            yName = [pointName stringByAppendingString:@".g"];
        }
    }
        
    if (xName) {
        if (outXName) *outXName = xName;
        if (outYName) *outYName = yName;
        return YES;
    } else
        return NO;
}

    
    
#pragma mark --- custom properties ---

- (void)_initVars {
    [_vars release];
    _vars = [[NSMutableDictionary alloc] init];
}

- (void)setObject:(id)obj forProperty:(NSString *)property
{
    if ( !property) {
        NSLog(@"** %s: no property", __func__);
        return;
    }        
    if ( !obj) {
        NSLog(@"** %s: no object (%@)", __func__, property);
        return;
    }
    
    if ( !_vars)
        [self _initVars];
    [_vars setObject:obj forKey:property];
}

- (id)objectForProperty:(NSString *)property
{
    if ( !property) {
        NSLog(@"** %s: no property", __func__);
        return nil;
    }        
    
    if ( !_vars) return nil;
    
    return [_vars objectForKey:property];
}

- (NSArray *)propertyKeys {
    return [_vars allKeys]; }

- (NSDictionary *)propertyDictionary {
    return (_vars) ? _vars : [NSDictionary dictionary]; }

- (void)addPropertiesFromDictionary:(NSDictionary *)dict
{
    if ( !_vars)
        [self _initVars];
    [_vars addEntriesFromDictionary:dict];
}


// --- private ---

- (void)_copyParams:(NSDictionary *)aParams {
    [_parameters release];
    _parameters = [[NSMutableDictionary dictionaryWithDictionary:aParams] retain];
}

- (void)_copyVars:(NSDictionary *)aVars {
    [_vars release];
    _vars = [aVars mutableCopy];
}


#pragma mark --- NSCopying ---

- (id)copyWithZone:(NSZone *)zone
{
    LQXRenderContext *newObj = [[[self class] alloc] init];
    [newObj _copyVars:_vars];
    [newObj _copyParams:_parameters];
    
    return newObj;
}

@end
