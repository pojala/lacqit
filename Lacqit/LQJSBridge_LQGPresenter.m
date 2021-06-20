//
//  LQJSBridge_LQGPresenter.m
//  Lacqit
//
//  Created by Pauli Ojala on 9.7.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQJSBridge_LQGPresenter.h"
#import "LQJSBridge_2DCanvas.h"
#import "LQCairoBitmap.h"
#import "LQCairoBitmapView.h"
#import "LQGListController.h"
#import "LQGCommonUIControllerSubtypeMethods.h"
#import "LQGCommonUINSViewController.h"
#import "LQNSColorAdditions.h"


@implementation LQJSBridge_LQGPresenter

- (id)initWithViewController:(id)viewCtrl
            inJSContext:(JSContextRef)context withOwner:(id)owner
{
    self = [self initInJSContext:context withOwner:owner];
    if (self) {
        _viewCtrl = viewCtrl;
        
        id forwardCtrl = [_viewCtrl respondsToSelector:@selector(forwardControl)] ? [_viewCtrl forwardControl] : nil;
        ///NSLog(@"%s -- %@ -- ctrl is %@", __func__, viewCtrl, forwardCtrl);
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (id)viewController {
    return _viewCtrl;
}


+ (NSString *)constructorName
{
    return @"<LQGPresenter>"; // can't be constructed
}


#pragma mark --- JS-exported properties ---

+ (NSArray *)_writableProperties
{
    return [NSArray arrayWithObjects:@"text", @"numberValue", @"stringValue",
                                     @"rgbaArrayValue",
                                     @"checked",
                                     @"label",
                                     @"enabled",
                                     @"selectedItem",
                                     @"secure",
                                     nil];
}

+ (NSArray *)objectPropertyNames
{
    NSArray *staticProps = [NSArray arrayWithObjects:
                            @"id", @"title", @"isContainer",
                            nil];
    
    return [staticProps arrayByAddingObjectsFromArray:[self _writableProperties]];
}

+ (BOOL)canWriteProperty:(NSString *)propertyName
{
    return ([[self _writableProperties] containsObject:propertyName]) ? YES : NO;
}

- (NSString *)id {
    NSString *str = [_viewCtrl name];
    return (str) ? str : @"";
}

- (NSString *)title {
    NSString *str = [_viewCtrl title];
    return (str) ? str : @"";
}

- (BOOL)isContainer {
    return ([_viewCtrl respondsToSelector:@selector(viewControllerNamed:)]) ? YES : NO;
}

- (NSString *)label {
    NSString *str = nil;
    if ([_viewCtrl respondsToSelector:@selector(label)]) {
        str = [_viewCtrl label];
    }
    return (str) ? str : @"";
}
    
- (void)setLabel:(NSString *)label
{
    if ( !label)
        return; // --
    
    NSString *str = [NSString stringWithString:label];
    if ([_viewCtrl respondsToSelector:@selector(setLabel:)]) {
        if (LXPlatformCurrentThreadIsMain()) {
            [_viewCtrl setLabel:str];
        } else {
            [_viewCtrl performSelectorOnMainThread:@selector(setLabel:) withObject:str waitUntilDone:NO];
        }
    }
}

- (NSString *)text {
    NSString *str = nil;
    if ([_viewCtrl respondsToSelector:@selector(stringValue)]) 
        str = [_viewCtrl stringValue];
    return (str) ? str : @"";
}
    
- (void)setText:(NSString *)text
{
    if ( !text)
        return; // --
    
    NSString *str = [[[text description] copy] autorelease];
    if ([_viewCtrl respondsToSelector:@selector(setStringValue:)]) {
        if (LXPlatformCurrentThreadIsMain()) {
            [_viewCtrl setStringValue:str];
        } else {
            ///[_viewCtrl performSelectorOnMainThread:@selector(setStringValue:) withObject:[text description] waitUntilDone:NO];
            // performSelectorOnMain.. would work just as well; this invocation is just a mental note of how it needs to be done (retainArguments, etc.)
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_viewCtrl methodSignatureForSelector:@selector(setStringValue:)]];
            [inv setSelector:@selector(setStringValue:)];
            [inv setTarget:_viewCtrl];
            [inv setArgument:&str atIndex:2];
            [inv retainArguments];
            [inv performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
            ///NSLog(@"invoking %@ on main thread", inv);
        }
    }
}

- (NSString *)stringValue {
    if ([_viewCtrl respondsToSelector:@selector(rgbaValue)]) {
        LXRGBA rgba = [_viewCtrl rgbaValue];
        NSColor *c = [NSColor colorWithRGBA_sRGB:rgba];
        return [c htmlFormattedSRGBString];
    }
    return [self text];
}

- (void)setStringValue:(NSString *)str {
    if ([_viewCtrl respondsToSelector:@selector(setRGBAValue:)]) {
        NSColor *c = [NSColor colorWithHTMLFormattedSRGBString:str];
        if (c) {
            [_viewCtrl setRGBAValue:[c rgba_sRGB]];
            return;
        }
    }
    [self setText:str];
}

- (NSArray *)rgbaArrayValue {
    LXRGBA rgba = LXZeroRGBA;
    if ([_viewCtrl respondsToSelector:@selector(rgbaValue)]) {
        rgba = [_viewCtrl rgbaValue];
    }
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:rgba.r],
            [NSNumber numberWithFloat:rgba.g],
            [NSNumber numberWithFloat:rgba.b],
            [NSNumber numberWithFloat:rgba.a],
            nil];
}

- (void)setRgbaArrayValue:(NSArray *)arr {
    LXRGBA rgba = LXBlackOpaqueRGBA;
    @try {
        if (arr.count > 0)
            rgba.r = [[arr objectAtIndex:0] floatValue];
        if (arr.count > 1)
            rgba.g = [[arr objectAtIndex:1] floatValue];
        if (arr.count > 2)
            rgba.b = [[arr objectAtIndex:2] floatValue];
        if (arr.count > 3)
            rgba.a = [[arr objectAtIndex:3] floatValue];
    } @catch (NSException *exc) {
        NSLog(@"** rgbaArrayValue setter: invalid argument %@, exception %@", [arr class], exc);
    }
    if ([_viewCtrl respondsToSelector:@selector(setRGBAValue:)]) {
        [_viewCtrl setRGBAValue:rgba];
    }
}

- (BOOL)isChecked {
    if ([_viewCtrl respondsToSelector:@selector(boolValue)]) {
        return [_viewCtrl boolValue];
    }
    return NO;
}

- (void)setChecked:(BOOL)f {
    if ([_viewCtrl respondsToSelector:@selector(setBoolValue:)]) {
        [_viewCtrl setBoolValue:f];
    }
}

- (NSString *)selectedItem {
    if ([_viewCtrl respondsToSelector:@selector(titleOfSelectedItem)]) {
        return [_viewCtrl titleOfSelectedItem];
    }
    return @"";
}

- (void)setSelectedItem:(NSString *)str {
    if ([_viewCtrl respondsToSelector:@selector(setIndexOfSelectedItem:)]) {
        NSInteger idx = [[_viewCtrl itemTitles] indexOfObject:str];
        [_viewCtrl setIndexOfSelectedItem:idx];
    }
}

- (BOOL)isSecure {
    if ([_viewCtrl respondsToSelector:@selector(isSecure)]) {
        return [_viewCtrl isSecure];
    }
    return NO;
}

- (void)setSecure:(BOOL)f {
    if ([_viewCtrl respondsToSelector:@selector(setSecure:)]) {
        [_viewCtrl setSecure:f];
    }
}

- (BOOL)isEnabled {
    return ([_viewCtrl respondsToSelector:@selector(isEnabled)]) ? [_viewCtrl isEnabled] : NO; }

- (void)setEnabled:(BOOL)f {
    if ([_viewCtrl respondsToSelector:@selector(setEnabled:)]) {
        if (LXPlatformCurrentThreadIsMain()) {
            [_viewCtrl setEnabled:f];
        } else {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_viewCtrl methodSignatureForSelector:@selector(setEnabled:)]];
            [inv setSelector:@selector(setEnabled:)];
            [inv setTarget:_viewCtrl];
            [inv setArgument:&f atIndex:2];
            [inv performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        }
    }
}

- (double)numberValue {
    return ([_viewCtrl respondsToSelector:@selector(doubleValue)]) ? [_viewCtrl doubleValue] : 0.0; }

- (void)setNumberValue:(double)v {
    if ([_viewCtrl respondsToSelector:@selector(setDoubleValue:)]) {
        if (LXPlatformCurrentThreadIsMain()) {
            [_viewCtrl setDoubleValue:v];
        } else {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[_viewCtrl methodSignatureForSelector:@selector(setDoubleValue:)]];
            [inv setSelector:@selector(setDoubleValue:)];
            [inv setTarget:_viewCtrl];
            [inv setArgument:&v atIndex:2];
            [inv performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)setNilValueForKey:(NSString *)theKey
{
    if ([theKey isEqualToString:@"numberValue"]) {
        [self setValue:[NSNumber numberWithDouble:0.0] forKey:theKey];
    } else if ([theKey isEqualToString:@"text"] || [theKey isEqualToString:@"label"] || [theKey isEqualToString:@"stringValue"]) {
        [self setValue:@"(null)" forKey:theKey];
    } else
        [super setNilValueForKey:theKey];
}


#pragma mark --- JS-exported functions ---

+ (NSArray *)objectFunctionNames   // if  the function is named "foo" the selector called is "lqjsCallFoo:"
{
    return [NSArray arrayWithObjects:@"getChildById",
                                     @"getSubviewById",  // don't publish -- old name for getChildById
                                     nil]; 
}

- (id)lqjsCallGetChildById:(NSArray *)args context:(id)contextObj
{
    if ([args count] < 1) return nil;
    
    if ( ![_viewCtrl respondsToSelector:@selector(viewControllerNamed:)]) return nil;
    
    NSString *wantedID = [[args objectAtIndex:0] description];
    id subviewCtrl = [_viewCtrl viewControllerNamed:wantedID];
    
    //NSLog(@"%s, %@, wantedID %@, subview %@", __func__, _viewCtrl, wantedID, subviewCtrl);
    
    if ( !subviewCtrl) return nil;
    
    LQJSInterpreter *interp = LQJSInterpreterFromJSContextRef([self jsContextRef]);
    
    // for canvas view controllers, we'll return a Canvas object
    if ([subviewCtrl respondsToSelector:@selector(cairoBitmap)]) {        
        id canvas = [[LQJSBridge_2DCanvas alloc] initWithCairoBitmap:[subviewCtrl cairoBitmap]
                                                                name:[subviewCtrl name]
                                                                inJSContext:[interp jsContextRef] 
                                                                withOwner:nil];

        [canvas setCairoView:[subviewCtrl nativeView]];
        
        return [canvas autorelease];
    }
    
    // for other types of view controllers, the delegate should decide how to represent them
    if ( ![self owner]) {
        NSLog(@"** JS getSubviewById: unable to return view controller, bridge object has no owner (%@)", self);
        return nil;
    } else {
        return [[self owner] bridgeForViewController:subviewCtrl inJSContext:[interp jsContextRef]];
    }
}

- (id)lqjsCallGetSubviewById:(NSArray *)args context:(id)contextObj
{
    return [self lqjsCallGetChildById:args context:contextObj];
}

@end
