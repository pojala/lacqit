//
//  LQGCheckboxController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 11.10.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGCheckboxController_cocoa.h"


@implementation LQGCheckboxController_cocoa

- (id)init
{
    self = [super initWithResourceName:nil bundle:[NSBundle bundleForClass:[self class]]];
    //self = [super initWithResourceName:@"LQCheckbox" bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [super dealloc];
}

- (NSString *)label {
    if (_label)
        return _label;
    else
        return [_button title];
}

- (void)setLabel:(NSString *)label {
    [_label release];
    _label = [label copy];
    
    [_button setTitle:(_label) ? _label : @""];
}

- (LXInteger)tag {
    return _tag; }
    
- (void)setTag:(LXInteger)tag {
    _tag = tag;
    [_button setTag:tag]; }


- (BOOL)boolValue {
    return _boolValue; }
//    return ([_button state] == NSOnState) ? YES : NO; }
    
- (void)setBoolValue:(BOOL)f {
    _boolValue = f;
    [_button setState:(f) ? NSOnState : NSOffState]; }

- (double)doubleValue {
    return (_boolValue) ? 1.0 : 0.0; }


- (void)checkboxAction:(id)sender
{
    ///NSLog(@"%s (%p): %@", __func__, self, sender);

    _boolValue = ([sender state] == NSOnState) ? YES : NO;
    
    [_delegate valuesDidChangeInViewController:self];
}


- (void)loadView
{
    if (_view) return;

    NSRect viewRect = NSMakeRect(0, 0, 300, 24);

    [_view autorelease];
    _view = [[NSView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];

    NSRect buttonRect = viewRect;
    buttonRect.origin.x += 4;
    buttonRect.origin.y += 6;
    buttonRect.size.width -= 8;
    buttonRect.size.height = 12;
    
    NSFont *font = [NSFont boldSystemFontOfSize:kLQUIDefaultFontSize];
    NSString *label = [self label];
    if ( !label)  label = @"";

			NSButton *button = [[NSButton alloc] initWithFrame:buttonRect];

            [button setButtonType:NSSwitchButton];
            [button setTitle:label];
			[button setFont:font];

            [[button cell] setControlSize:NSMiniControlSize];
			[button setAutoresizingMask:(NSViewMinYMargin | NSViewMaxXMargin)];
            [button setTarget:self];
            [button setAction:@selector(checkboxAction:)];

    _button = button;
    
    [_view addSubview:[button autorelease]];
}

@end
