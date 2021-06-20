//
//  LQGColorPickerController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 17.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGColorPickerController_cocoa.h"
#import "LQGSliderAndFieldController_cocoa.h"
#import "LQFlippedView.h"
#import "LQNSColorAdditions.h"


@implementation LQGColorPickerController_cocoa

- (void)dealloc
{
    [_controls release];
    _controls = nil;
    
    [_labelStr release];
    [super dealloc];
}

- (void)setRGBAValue:(LXRGBA)rgba
{
    _colorValue = rgba;
    
    [(NSColorWell *)_swatchView setColor:[NSColor colorWithRGBA:_colorValue]];
    
    ///NSLog(@"%s, %@: %@", __func__, self, NSStringFromLXRGBA(rgba));
    
    if ([_controls count] >= 4) {
        int i;
        for (i = 0; i < 4; i++) {
            id sliderAndField = [_controls objectAtIndex:i];
            [sliderAndField setDoubleValue:((LXFloat *)(&rgba))[i]];
        }
    }
}

- (LXRGBA)rgbaValue {
    return _colorValue; }


- (NSString *)label {
    return (_labelField) ? [_labelField stringValue] : _labelStr; }
    
- (void)setLabel:(NSString *)label
{
    [_labelStr release];
    _labelStr = [label copy];
    
    if (_labelField)
        [_labelField setStringValue:(label) ? label : @""];
}


#define SLIDERTAG  4500

- (void)valuesDidChangeInViewController:(id)sliderAndField
{
    int tag = [sliderAndField tag] - SLIDERTAG;
    double v = [sliderAndField doubleValue];
    
    switch (tag) {
        case 0:  _colorValue.r = v;  break;
        case 1:  _colorValue.g = v;  break;
        case 2:  _colorValue.b = v;  break;
        case 3:  _colorValue.a = v;  break;
    }
    
    [(NSColorWell *)_swatchView setColor:[NSColor colorWithRGBA_sRGB:_colorValue]];
    
    if (_delegate)
        [_delegate valuesDidChangeInViewController:self];
}

- (IBAction)swatchAction:(id)sender
{
    LXRGBA rgba = [[sender color] rgba_sRGB];
    
    [[_controls objectAtIndex:0] setDoubleValue:rgba.r];
    [[_controls objectAtIndex:1] setDoubleValue:rgba.g];
    [[_controls objectAtIndex:2] setDoubleValue:rgba.b];
    [[_controls objectAtIndex:3] setDoubleValue:rgba.a];
    
    _colorValue = rgba;
    
    if (_delegate)
        [_delegate valuesDidChangeInViewController:self];    
}


- (void)loadView
{
    if (_view) return;

    NSRect viewRect = NSMakeRect(0, 0, 400, 100);

    [_view release];
    _view = [[LQFlippedView alloc] initWithFrame:viewRect];
    [_view setAutoresizingMask:NSViewWidthSizable];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    NSString *labels[5] = { @"Red", @"Green", @"Blue", @"Alpha", nil };
    
    LXRGBA rgba = _colorValue;
    NSAssert(sizeof(LXRGBA) == (4*sizeof(LXFloat)), @"LXRGBA size is incorrect");
    
    const double x = 72.0;
    const double w = round(viewRect.size.width - x) + 4;
    double y = 0.0;
    const int n = 4;
    int i;
    for (i = 0; i < n; i++) {
        id sliderAndField = [[LQGSliderAndFieldController_cocoa alloc] init];
        [sliderAndField loadView];

        [arr addObject:[sliderAndField autorelease]];
        
        
        [sliderAndField setDoubleValue:((LXFloat *)(&rgba))[i]];
        
        //[sliderAndField setLabel:labels[i]];
        [sliderAndField setLabel:nil];
        [sliderAndField setTag:i + SLIDERTAG];
        
        [sliderAndField setDelegate:(id)self];
        
        
        NSView *cview = [sliderAndField view];
        [cview setAutoresizingMask:NSViewWidthSizable];
        
        NSRect cviewFrame = [cview frame];
        cviewFrame.origin.x = x;
        cviewFrame.origin.y = y - 2;
        cviewFrame.size.width = w;
        cviewFrame.size.height -= 6;
        [cview setFrame:cviewFrame];
        
        [_view addSubview:cview];
        
        y += round(cviewFrame.size.height);
    }
    _controls = [arr retain];
    
    ///NSLog(@"%s: height is %f", __func__, y);
    
    _labelField = [[NSTextField alloc] initWithFrame:NSMakeRect(8, 6, 90, 18)];
    [_labelField setStringValue:(_labelStr) ? _labelStr : @""];
    [_labelField setFont:[NSFont boldSystemFontOfSize:10.0]];
    [_labelField setEditable:NO];
    [_labelField setSelectable:NO];
    [_labelField setBezeled:NO];
    [_labelField setDrawsBackground:NO];
    
    id val;
    if ((val = [_styleDict objectForKey:kLQGStyle_Font])) {
        [_labelField setFont:(NSFont *)val];
    }
    
    [_view addSubview:[_labelField autorelease]];
    
    _swatchView = [[NSColorWell alloc] initWithFrame:NSMakeRect(24, 32, 48, 48)];
    
    [_swatchView setColor:[NSColor colorWithRGBA:_colorValue]];
    [_swatchView setTarget:self];
    [_swatchView setAction:@selector(swatchAction:)];
    
    [_view addSubview:[_swatchView autorelease]];
    
    
    viewRect.size.height = y + 2;
    [_view setFrame:viewRect];

}


@end
