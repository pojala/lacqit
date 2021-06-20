//
//  LQJSBridge_System.m
//  Lacqit
//
//  Created by Pauli Ojala on 21.4.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_System.h"
#import "LQJSBridge_ByteBuffer.h"
#import "LQJSON.h"
#import "LQTimeFunctions.h"
#import "LQNSDataAdditions.h"
#import <Lacefx/LXPlatform.h>


static NSString *g_hostID = nil;


@implementation LQJSBridge_System

+ (void)setHostID:(NSString *)hostID
{
    [g_hostID release];
    g_hostID = [hostID copy];
}


- (id)initInJSInterpreter:(LQJSInterpreter *)interp withOwner:(id)owner
{
    NSAssert(owner, @"system object needs to have an owner that can act as the delegate for calls");

    self = [self initInJSContext:[interp jsContextRef] withOwner:owner];
    if (self) {
        _interpreter = interp;
        
        uint8_t *guid = NULL;
        size_t guidSize = 0;
        if ( !LXPlatformGetSystemGUID(&guid, &guidSize)) {
            NSLog(@"** JavaScript 'sys.systemUniqueID' -- unable to get system id");
            _systemID = [@"" retain];
        } else {
            NSData *data = [NSData dataWithBytes:guid length:guidSize];
            NSString *b64 = [data encodeAsBase64String];
            _systemID = [b64 retain];
            _lx_free(guid);
        }
    }
    return self;
}

- (void)dealloc
{
    [_systemID release];
    [super dealloc];
}

+ (NSString *)constructorName
{
    return @"<System>"; // can't be constructed
}

+ (NSArray *)objectPropertyNames
{
    return [NSArray arrayWithObjects:@"hostID",
                                     @"systemUniqueID",
                                     nil];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return NO;
}

- (NSString *)hostID
{
    return (g_hostID && [g_hostID length] > 0) ? g_hostID : @"fi.lacquer.Conduit";
}

- (NSString *)systemUniqueID
{
    return _systemID;
}


+ (NSArray *)objectFunctionNames
{
    return [NSArray arrayWithObjects:@"trace",
                                     @"log",
                                     @"alert",

                                     @"readLocalFile",
                                     
                                     @"dateFromRefTime",
                                     @"refTimeFromDate",
                                     nil]; 
}

- (id)lqjsCallDateFromRefTime:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id obj = [args objectAtIndex:0];
    if ( ![obj respondsToSelector:@selector(doubleValue)])
        return nil;
    
    double refTime = [obj doubleValue];
    
    const double refTimeToCFTimeDiff = CFAbsoluteTimeGetCurrent() - LQReferenceTimeGetCurrent();
    
    double cfTime = refTime + refTimeToCFTimeDiff;
    double unixTime = cfTime + NSTimeIntervalSince1970;
    double jsTime = unixTime * 1000.0;  // JavaScript Date constructor expects milliseconds
    
    id interp = _interpreter;
    NSError *error = nil;
    id date = [[interp globalVariableForKey:@"Date"] constructWithParameters:[NSArray arrayWithObject:[NSNumber numberWithDouble:jsTime]] error:&error];
    if (error) {
        NSLog(@"*** JS sys.dateFromRefTime() failed: %@", error);
    }
    return date;
}

- (id)lqjsCallRefTimeFromDate:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id obj = [args objectAtIndex:0];
    double jsTime = 0.0;
    @try {
        jsTime = [[obj callMethod:@"getTime" withParameters:nil error:NULL] doubleValue];
    }
    @catch (id exception) {
        NSLog(@"*** JS sys.refTimeFromDate() failed: %@", exception);
    }
    if (jsTime <= 0.0)
        return nil;
        
    double cfTime = (jsTime / 1000.0) - NSTimeIntervalSince1970;
    
    const double refTimeToCFTimeDiff = CFAbsoluteTimeGetCurrent() - LQReferenceTimeGetCurrent();
    
    double refTime = cfTime - refTimeToCFTimeDiff;
    
    return [NSNumber numberWithDouble:refTime];
}

- (id)lqjsCallAlert:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id obj = [args objectAtIndex:0];
    if ([obj isKindOfClass:[NSString class]]) {
        [[self owner] jsSystemCallForBridge:self showAlertWithString:(NSString *)obj];
    }
    return nil;
}

- (id)lqjsCallTrace:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id obj = [args objectAtIndex:0];
    
    if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
        LQJSON *gen = [[LQJSON alloc] init];
        [gen setAllowsUnknownObjects:YES];  // this will serialize unknown bridge objects in format "<Class: ptr>"
        [gen setHumanReadable:YES];
        obj = [gen stringWithObject:obj error:NULL];
        [gen release];
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        ///NSLog(@"Trace call from JS:  %@", obj);
        [[self owner] jsSystemCallForBridge:self printTraceString:(NSString *)obj];
    }
    return nil;
}

- (id)lqjsCallLog:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id obj = [args objectAtIndex:0];
    if ([obj isKindOfClass:[NSString class]]) {
        NSLog(@"Logged from JS:  %@", obj);
    }
    return nil;
}

- (id)lqjsCallReadLocalFile:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    id retVal = nil;
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    JSContextRef jsCtx = [interp jsContextRef];  ///[self jsContextRefFromJSCallContextObj:contextObj];    
    
    id obj = [args objectAtIndex:0];
    if ([obj isKindOfClass:[NSString class]]) {
        NSError *error = nil;
        
        NSString *path = [obj stringByStandardizingPath];
        
        {
            NSString *lpath = [path lowercaseString];
            
            #ifdef __WIN32__
            lpath = [NSMutableString stringWithString:lpath];
            [(NSMutableString *)lpath replaceOccurrencesOfString:@"\\" withString:@"/" options:0 range:NSMakeRange(0, [lpath length])];
            
            if ([lpath length] > 2 && [lpath characterAtIndex:0] != '/')
                lpath = [path substringFromIndex:2];  // trim off drive letter at start of path, e.g. "C:"
            #endif
            
            // naive safety feature: anything in system paths is off-limits
            if ([lpath hasPrefix:@"/system"] || [lpath hasPrefix:@"/library"] || [lpath hasPrefix:@"/usr"] || [lpath hasPrefix:@"/bin"] || [lpath hasPrefix:@"/etc"]
                #ifdef __WIN32__
                || [lpath hasPrefix:@"/windows"] || [lpath hasPrefix:@"/program"]
                #endif
                ) {
                NSLog(@"** JS call 'readLocalFile': can't allow reading from possible system path: '%@'", path);
                return nil;
            }
        }
    
        NSData *data = [[self owner] jsSystemCallForBridge:self shouldLoadDataFromPath:path error:&error];
        
        if ( !data) {
            NSLog(@"** JS call 'readLocalFile' failed with error: %@", error);
        } else {
            retVal = [[[LQJSBridge_ByteBuffer alloc] initWithData:data inJSContext:jsCtx withOwner:nil] autorelease];
        }
    }
    return retVal;
}

@end
