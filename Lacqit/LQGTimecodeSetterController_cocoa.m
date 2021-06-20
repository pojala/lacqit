//
//  LQGTimecodeSetterController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 20.8.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGTimecodeSetterController_cocoa.h"
#import "LQTimeFormatter.h"


@implementation LQGTimecodeSetterController_cocoa

- (id)init
{
    self = [super initWithResourceName:@"LQTimecodeSetter" bundle:[NSBundle bundleForClass:[self class]]];
    
    _label = [@"Time:" retain];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [super dealloc];
}


#pragma mark --- accessors ---

- (void)setLabel:(NSString *)label
{
    [_label release];
    _label = [label copy];

    if ( !_labelField)
        return;
        
    [_labelField setStringValue:_label];
}

- (void)setLabelFont:(NSFont *)font
{
    [_labelField setFont:font];
}

- (void)setDoubleValue:(double)d
{
    _value = d;
    [_timeField setDoubleValue:_value];
}
    
- (double)doubleValue {
    return _value; }


#pragma mark --- actions ---

- (IBAction)setTimeAction:(id)sender
{
    double t = [sender doubleValue];
    if ([sender isKindOfClass:[NSTextField class]]) {
        [[sender window] makeFirstResponder:[sender superview]]; // end editing for this field
    }
    
    if (t != _value) {
        _value = t;
        [_delegate valuesDidChangeInViewController:self];
    }
}

- (IBAction)setTimeAtCurrentTimeAction:(id)sender
{
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:@"TimecodeSetter::setTimeAtCurrentTime" info:nil];
    else {
        NSLog(@"*** %s: delegate doesn't implement context handler method", __func__);
    }
}

- (IBAction)clearTimeAction:(id)sender
{
    if (_value != DBL_MAX) {
        _value = DBL_MAX;
        [_timeField setDoubleValue:_value];
        
        [_delegate valuesDidChangeInViewController:self];
    }
}



#pragma mark --- view creation ---

- (void)loadView
{
    if (_timeField) return;  // already loaded

    id val;
    
    [super loadView];
    
    [self setLabel:[[_label copy] autorelease]];
    [self setDoubleValue:_value];
    
    
    NSColor *editableFieldColor = [NSColor colorWithDeviceRed:0.7 green:0.7 blue:0.55 alpha:0.98];

#if !defined(__COCOTRON__)
    [_timeField setFormatter:[[[LQTimeFormatter alloc] init] autorelease]];
#endif
    
    [_timeField setBackgroundColor:editableFieldColor];
    [_timeField setDrawsBackground:YES];
    
    // apply font
    if ((val = [_styleDict objectForKey:kLQGStyle_Font])) {
        [_labelField setFont:(NSFont *)val];
    }
    if ((val = [_styleDict objectForKey:kLQGStyle_ForegroundColor])) {
        [_labelField setTextColor:(NSColor *)val];
    }
}

@end
