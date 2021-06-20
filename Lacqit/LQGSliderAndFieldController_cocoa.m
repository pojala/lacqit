//
//  LQGSliderAndFieldController_cocoa.m
//  Lacqit
//
//  Created by Pauli Ojala on 16.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQGSliderAndFieldController_cocoa.h"
#import "LQNumberScrubField.h"
#import "LQAppKitUtils.h"
#import "LQThemedInputField.h"


@implementation LQGSliderAndFieldController_cocoa

- (id)init
{
    self = [super initWithResourceName:@"LQSliderAndField" bundle:[NSBundle bundleForClass:[self class]]];
    
    _prevValue = INFINITY;
    
    return self;
}

- (id)initWithSmallFullWidthSlider
{
    self = [super initWithResourceName:@"LQSliderAndFieldSmall" bundle:[NSBundle bundleForClass:[self class]]];
    
    if (self) {
        _hasSmallFullWidthSlider = YES;
    }
    return self;
}


- (void)dealloc
{
    [_scrubField removeFromSuperview];
    //[_scrubField release];
    _scrubField = nil;
    
    [_slider removeFromSuperview];

    //NSLog(@"%s: scrubfield %@ - retcount %i", __func__, _scrubField, [_scrubField retainCount]);
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
        
    // reposition the slider next to the label
    double w = [_nameLabel frame].size.width;
        
    if ([label length] > 0 && _labelHidden) {
        if ([label length] > 9) {
            w = ([label length] > 15) ? 110 : 80;  // HARDCODED
            NSSize size = [_nameLabel frame].size;
            size.width = w;
            [_nameLabel setFrameSize:size];
        }
        _labelHidden = NO;
        [_nameLabel setHidden:NO];
        [_nameLabel setStringValue:label];
        
        NSRect frame = [_slider frame];
        frame.origin.x += w;
        frame.size.width -= w;
        [_slider setFrame:frame];
        
        ///NSLog(@"...showing label %@ --  slider w now %.0f", label, [_slider frame].size.width);
    }
    else if ( !label && !_labelHidden) {
        _labelHidden = YES;
        [_nameLabel setHidden:YES];
        
        NSRect frame = [_slider frame];
        frame.origin.x -= w;
        frame.size.width += w;
        [_slider setFrame:frame];
    }
    else if (label)
        [_nameLabel setStringValue:label];
}

- (void)setLabelFont:(NSFont *)font
{
    [_nameLabel setFont:font];
}

- (void)setLabelAction:(id)sender
{
    [_label release];
    _label = [[sender stringValue] copy];
    
    if ([_delegate respondsToSelector:@selector(actionInViewController:context:info:)])
        [_delegate actionInViewController:self context:@"SliderAndField::setLabel" info:nil];
}

- (void)setLabelEditable:(BOOL)f
{
    if ( ![_nameLabel isKindOfClass:[LQThemedInputField class]]) {
        _nameLabel = [LQReplaceInputFieldWithThemedField(_nameLabel, NSSmallControlSize) retain];
        [(id)_nameLabel setInterfaceTint:kLQLightTint];
        [_nameLabel setFont:[NSFont boldSystemFontOfSize:10.0]];
        [_nameLabel setTarget:self];
        [_nameLabel setAction:@selector(setLabelAction:)];
        [_nameLabel setStringValue:_label];
        
        NSRect frame = [_nameLabel frame];
        frame.origin.x -= 8.0;
        frame.size.width += 6.0;
        [_nameLabel setFrame:frame];
    }
}
    

- (void)_setValue:(double)v {
    _prevValue = _value;
    _value = v;
}

- (void)setDoubleValue:(double)d
{
    [self _setValue:d];
    [_slider setDoubleValue:_value];
    [_scrubField setDoubleValue:_value];
}
    
- (double)doubleValue {
    return _value; }

- (void)setSliderMin:(double)smin max:(double)smax
{
    [_slider setMinValue:smin];
    [_slider setMaxValue:smax];
}

- (void)setEnabled:(BOOL)f
{
    [_slider setEnabled:f];
    [_scrubField setEnabled:f];
}

- (void)setHasSmallFullWidthSlider:(BOOL)f
{
    _hasSmallFullWidthSlider = f;
}

- (double)increment {
    return [_scrubField increment]; }
    
- (void)setIncrement:(double)f
{
    [_scrubField setIncrement:f];
    
    BOOL useTicks = NO;
    
    if (f > 0.0) {
        double smin = [_slider minValue];
        double smax = [_slider maxValue];
        double slen = smax - smin;
        if (slen >= f && fmod(slen, f) < 0.0001) {
            NSInteger numTicks = 1 + lround(slen / f);
            
            while (numTicks > 50) {
                numTicks /= 2;
            }
            
            [_slider setNumberOfTickMarks:numTicks];
            useTicks = YES;
        }
    }
    [_slider setAllowsTickMarkValuesOnly:useTicks];
}


#pragma mark --- actions ---

- (void)entryFieldAction:(id)sender
{
    ///NSLog(@"%s (%p): %@", __func__, self, sender);
    double v = [sender doubleValue];
    
    if (v != _value) {
        [self _setValue:v];
        [_slider setDoubleValue:_value];
    
        [_delegate valuesDidChangeInViewController:self];
    }
}

- (void)sliderAction:(id)sender
{
    double v = [sender doubleValue];
    ///NSLog(@"%s (%p): %@  / %.4f, old %.4f", __func__, self, sender, v, _prevValue);
    
    if (v != _value) {
        [self _setValue:v];
        [_scrubField setDoubleValue:_value];
    
        [_delegate valuesDidChangeInViewController:self];
    }
}


#pragma mark --- view creation ---

- (void)loadView
{
    if (_scrubField) return;  // already loaded

    id val;
    
    [super loadView];
    
    [self setLabel:[[_label copy] autorelease]];
    
    [_slider setTarget:self];
    [_slider setAction:@selector(sliderAction:)];

    // the scrub field was loaded from NIB; recreate it to get proper size
    NSPoint origin = [_scrubField frame].origin;
    [_scrubField removeFromSuperview];
    _scrubField = nil;
    
    origin.x += 1.0;
    origin.y += 1.0;
    
    LQNumberScrubField *entryField = [[LQNumberScrubField alloc] initWithFrame:NSMakeRect(origin.x, origin.y, 56.0, 16.0)];
    [entryField setEditable:YES];
    [entryField setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
    [entryField setAutoresizingMask:(NSViewMinYMargin | NSViewMinXMargin)];
    [entryField setTarget:self];
    [entryField setAction:@selector(entryFieldAction:)];
    [entryField setDelegate:(id)self];
    _scrubField = entryField;
    
    [_view addSubview:_scrubField];
    
    //NSLog(@"%s: view size is %@ - autoresize mask is %i -- styles: %@", __func__, NSStringFromRect([_view frame]), [_view autoresizingMask], _styleDict);
    
    if ( !_nameLabel)
        return;
        
    BOOL sliderIsFullW = _hasSmallFullWidthSlider;

    ///NSLog(@"...slider width now %.0f -- is full w %i -- label %@", [_slider frame].size.width, sliderIsFullW, _label);
            
    // apply font
    if ((val = [_styleDict objectForKey:kLQGStyle_Font])) {
        [_nameLabel setFont:(NSFont *)val];
    }
    if ((val = [_styleDict objectForKey:kLQGStyle_ForegroundColor])) {
        [_nameLabel setTextColor:(NSColor *)val];
    }
    
    // apply padding
    if ((val = [_styleDict objectForKey:kLQGStyle_PaddingLeft])) {
        double pad = [val doubleValue];
        
        NSRect frame = [_nameLabel frame];
        double offset = pad - frame.origin.x;
        
        frame.origin.x += offset;
        [_nameLabel setFrame:frame];
        
        frame = [_slider frame];
        
        if ( !sliderIsFullW) {
            frame.origin.x += offset;
        } else {
            frame.origin.x += offset;
            frame.size.width += offset;
        }
        [_slider setFrame:frame];
    }
    
    if ((val = [_styleDict objectForKey:kLQGStyle_PaddingRight])) {
        double pad = [val doubleValue];
    
        NSRect frame = [_scrubField frame];
        double offset = ([_view bounds].size.width - (frame.origin.x + frame.size.width)) - pad;
        
        frame.origin.x += offset;
        [_scrubField setFrame:frame];
        
        frame = [_slider frame];
        if (sliderIsFullW) {
            frame.origin.x += offset;
            frame.size.width += offset;        
            
            [_slider setFrame:frame];
        }
    }
    
    if ( !sliderIsFullW) {
        double scrubX = [_scrubField frame].origin.x;
        
        NSRect frame = [_slider frame];
        frame.size.width = scrubX - frame.origin.x - 8;  // HARDCODED interval between slider and field
            //frame.size.width += offset;
        [_slider setFrame:frame];
        
        ///NSLog(@"...slider width after padding and field: %.0f", [_slider frame].size.width);
    }
    
    // check if label fits
    if ( !sliderIsFullW && [self label]) {
        NSDictionary *labelAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [_nameLabel font], NSFontAttributeName,
                                                nil];

        double labelLMargin = [_nameLabel frame].origin.x;
        double labelRMargin = 4;
        NSSize labelSize = [[self label] sizeWithAttributes:labelAttrs];
        labelSize.width += labelRMargin + labelLMargin;
        
        NSRect frame = [_slider frame];
        double labelW = frame.origin.x - labelRMargin - labelLMargin;
        
        if (labelSize.width > labelW) {
            if (labelSize.width < labelW + frame.size.width*0.6) {
                // shrink the slider when it's reasonably possible
                double offset = round(labelSize.width - labelW);
                
                // make offset a multiple of 4 (cleaner alignment)
                offset = ceil(offset / 4.0) * 4.0;
                
                frame.size.width -= offset;
                frame.origin.x += offset;
                [_slider setFrame:frame];
                
                frame = [_nameLabel frame];
                frame.size.width += offset;
                [_nameLabel setFrame:frame];
            } else {
                // TODO: move label onto its own line
            }
        }
        ///NSLog(@"...slider width after label: %.0f", [_slider frame].size.width);
    }
}

@end
