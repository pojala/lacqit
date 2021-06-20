//
//  LQGNumberPairFieldController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 11.2.2009.
//  Copyright 2009 Lacquer oy/ltd. All rights reserved.
//

#import "LQGNumberPairFieldController_cocoa.h"
#import "LQNumberScrubField.h"


@implementation LQGNumberPairFieldController_cocoa

- (id)init
{
    self = [super initWithResourceName:@"LQNumberPairField" bundle:[NSBundle bundleForClass:[self class]]];
    
    return self;
}

- (void)dealloc
{
    [_label release];
    [super dealloc];
}


#pragma mark --- accessors ---

- (NSString *)label {
    return (_labelHidden) ? nil : _label; }
    
- (void)setLabel:(NSString *)label
{
    [_label release];
    _label = [label copy];

    if ( !_nameLabel)
        return;
    
    if (label && _labelHidden) {
        _labelHidden = NO;
        [_nameLabel setHidden:NO];
        [_nameLabel setStringValue:label];
    }
    else if ( !label && !_labelHidden) {
        _labelHidden = YES;
        [_nameLabel setHidden:YES];
    }
    else if (label)
        [_nameLabel setStringValue:label];
}

- (void)setLabelFont:(NSFont *)font
{
    [_nameLabel setFont:font];
}


- (double)xValue {
    return _xValue; }
    
- (void)setXValue:(double)d {
    _xValue = d;
    [_scrubField1 setDoubleValue:d];
}

- (double)yValue {
    return _yValue; }
    
- (void)setYValue:(double)d {
    _yValue = d;
    [_scrubField2 setDoubleValue:d];
}

- (void)setEnabled:(BOOL)f {
    [_scrubField1 setEnabled:f];
    [_scrubField2 setEnabled:f];
}

- (double)increment {
    return [_scrubField1 increment]; }
    
- (void)setIncrement:(double)f {
    [_scrubField1 setIncrement:f];
    [_scrubField2 setIncrement:f];
}

- (void)setNumberFormatter:(NSNumberFormatter *)fmt {
    NSString *format = [fmt format];
    NSNumberFormatter *fmt1 = [[[NSNumberFormatter alloc] init] autorelease];
    [fmt1 setFormat:format];
    NSNumberFormatter *fmt2 = [[[NSNumberFormatter alloc] init] autorelease];
    [fmt2 setFormat:format];
    ///NSLog(@"%s: format '%@', fields %@, %@", __func__, format, _scrubField1, _scrubField2);
    [_scrubField1 setNumberFormatter:fmt1];
    [_scrubField2 setNumberFormatter:fmt2];
    [_nformat release];
    _nformat = [format copy];
}

/*
- (void)setMinimumFractionDigits:(NSUInteger)number {
    [_scrubField1 setMinimumFractionDigits:
}

- (void)setMaximumFractionDigits:(NSUInteger)number {

}
*/



#pragma mark --- actions ---

- (void)entryFieldAction:(id)sender
{
    ///NSLog(@"%s (%p): %@", __func__, self, sender);
    LXInteger tag = [sender tag];
    double d = [sender doubleValue];
    
    if (tag == 1) {
        _xValue = d;
    } else {
        _yValue = d;
    }
    
    [_delegate valuesDidChangeInViewController:self];
}


#pragma mark --- view creation ---

- (void)loadView
{
    if (_scrubField1) return; // already loaded

    id val;
    NSPoint origin;
    LQNumberScrubField *entryField;
    
    [super loadView];

    // recreate the scrub field to get proper size
    origin = [_scrubField1 frame].origin;
    [_scrubField1 removeFromSuperview];
    _scrubField1 = nil;
    
    id leftPadVal = [_styleDict objectForKey:kLQGStyle_PaddingLeft];
    
    // apply font
    if ((val = [_styleDict objectForKey:kLQGStyle_Font]) && _label) {
        NSFont *font = (NSFont *)val;
        NSSize labelSize = [_label sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            font, NSFontAttributeName,
                                                            nil]];
        NSRect frame = [_nameLabel frame];
        
        if (leftPadVal)
            frame.origin.x = [leftPadVal doubleValue];
        
        [_nameLabel setFont:font];
        if ([font pointSize] < 10.0) {
            frame.origin.y -= 1.0;
        }
        
        frame.size.width = round(labelSize.width + 4.0);
        
        [_nameLabel setFrame:frame];
        
        ///NSLog(@"namelabel frame: %@ -- scrubfield origin: %@", NSStringFromRect(frame), NSStringFromPoint(origin));
        
        //origin.x = frame.origin.x + frame.size.width + 4;
    }
    if ((val = [_styleDict objectForKey:kLQGStyle_ForegroundColor])) {
        [_nameLabel setTextColor:(NSColor *)val];
    }
    
    [self setLabel:[[_label copy] autorelease]];
    
    origin.x += 1.0;
    origin.y += 1.0;
    
    ///NSLog(@"field origin: %@ ('%@')", NSStringFromPoint(origin), _label);
    
    entryField = [[LQNumberScrubField alloc] initWithFrame:NSMakeRect(origin.x, origin.y, 56.0, 16.0)];
    [entryField setEditable:YES];
    [entryField setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
    [entryField setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
    [entryField setTarget:self];
    [entryField setAction:@selector(entryFieldAction:)];
    [entryField setDelegate:(id)self];
    [entryField setTag:1];
    
    _scrubField1 = entryField;
    [_view addSubview:[_scrubField1 autorelease]];
    
    origin.x += [entryField frame].size.width + 10;

    // second field
    [_scrubField2 removeFromSuperview];
    _scrubField2 = nil;
    
    ///origin.x += 1.0;
    ///origin.y += 1.0;
    
    entryField = [[LQNumberScrubField alloc] initWithFrame:NSMakeRect(origin.x, origin.y, 56.0, 16.0)];
    [entryField setEditable:YES];
    [entryField setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
    [entryField setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
    [entryField setTarget:self];
    [entryField setAction:@selector(entryFieldAction:)];
    [entryField setDelegate:(id)self];
    [entryField setTag:2];
    
    _scrubField2 = entryField;
    [_view addSubview:[_scrubField2 autorelease]];
    
    if (_nformat) {
        NSNumberFormatter *fmt = [[[NSNumberFormatter alloc] init] autorelease];
        [fmt setFormat:_nformat];
        [self setNumberFormatter:fmt];
    }
}

@end
