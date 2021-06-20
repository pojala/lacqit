//
//  LQNumberScrubField.m
//  PixelMath
//
//  Created by Pauli Ojala on 10.9.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQNumberScrubField.h"
#import "LQUIFrameworkHeader.h"
#import "LQNSBezierPathAdditions.h"
#import "EDUINSImageAdditions.h"
#import "LQGradient.h"
///#import "LQPopUpWindow.h"


#if defined(__LAGOON__) || defined(__COCOTRON__)
 #define USEPLAINLOOK 1
#endif


#ifdef USEPLAINLOOK
 #define LAGOON_BGCOLOR_R 0.926
 #define LAGOON_BGCOLOR_G 0.924
 #define LAGOON_BGCOLOR_B 0.942
 #define MAXCOLOR 65535.0
#endif


static BOOL isYosemite()
{
    static int s_f = -1;
    if (s_f == -1) {
        s_f = (NSClassFromString(@"NSVisualEffectView") != Nil);
    }
    return s_f ? YES : NO;
}



@implementation LQNumberScrubField

static LQGradient *g_bgGradient = nil;
static LXInteger g_defaultInterfaceTint = kLQSystemTint;
static BOOL g_scrubEnabled = YES;

+ (void)setDefaultBackgroundGradient:(LQGradient *)grad
{
    [g_bgGradient autorelease];
    g_bgGradient = [grad retain];
}

+ (void)setDefaultInterfaceTint:(LQInterfaceTint)tint {
    g_defaultInterfaceTint = tint; }

+ (LQInterfaceTint)defaultInterfaceTint {
    return g_defaultInterfaceTint; }

+ (void)setScrubEnabled:(BOOL)flag {
    g_scrubEnabled = flag; }

+ (Class)cellClass {
	return nil; }


#define SPINNERWIDTH 12.0


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _scrubRatio = 500.0;
		_value = 0.0;
        _increment = 0.1;
        _enabled = YES;
        
        _interfaceTint = g_defaultInterfaceTint;
		
		NSRect rect = [self bounds];
		rect.origin.x += SPINNERWIDTH;
		rect.origin.y += 2.0;
		rect.size.height -= 4.0;
		rect.size.width -= 2.0*SPINNERWIDTH;
/*#ifndef __APPLE__
		rect.size.height -= 2.0;
		rect.origin.y += 1.0;
#endif
*/

		_editor = [[NSTextField alloc] initWithFrame:rect];
		
		[_editor setEditable:NO];
		[_editor setBezeled:NO];
#if !defined(__LAGOON__) && !defined(__COCOTRON__)
		[_editor setBordered:NO];
		[_editor setDrawsBackground:NO];
		[_editor setFocusRingType:NSFocusRingTypeNone];
        //[_editor setFont:[NSFont boldSystemFontOfSize:kLQUIDefaultFontSize]];
        //[_editor setTextColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.87]];
        [_editor setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
#else
		[_editor setFont:[NSFont systemFontOfSize:kLQUIDefaultFontSize]];
#endif		
		[_editor setDelegate:(id)self];
		[_editor setDoubleValue:_value];

#if !defined(__LAGOON__) && !defined(__COCOTRON__)
		NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		//[numberFormatter setFormat:@"###0.000;0;-###0.000"];
        [numberFormatter setMinimumIntegerDigits:1];
        [numberFormatter setMinimumFractionDigits:1];
        [numberFormatter setMaximumFractionDigits:3];
        [self setNumberFormatter:numberFormatter];
        
#elif defined(__LAGOON__)
		GdkColor bgColor = { 0, MAXCOLOR*LAGOON_BGCOLOR_R, MAXCOLOR*LAGOON_BGCOLOR_G, MAXCOLOR*LAGOON_BGCOLOR_B };
		gtk_widget_modify_base( [_editor nativeWidget], GTK_STATE_NORMAL, &bgColor);
#endif

		
		[self addSubview:_editor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _interfaceTint = g_defaultInterfaceTint;
    }
    return self;
}

- (void)dealloc {
	[_editor release];
    [_baseC release];
    [_baseCImage release];
	[super dealloc];
}

- (void)setTarget:(id)anObject {
	_target = anObject; }

- (id)target {
	return _target; }
	
- (void)setAction:(SEL)aSelector {
	_action = aSelector; }
	
- (SEL)action {
	return _action; }
    
- (id)delegate {
    //return _delegate;
    return nil; }
    
- (void)setDelegate:(id)del {
    /*_delegate = del;*/ }
	
- (float)floatValue {
	return _value; }
	
- (double)doubleValue {
	return _value; }
	
- (void)setFloatValue:(float)v {
	[_editor setDoubleValue:v];
	_value = v; }
	
- (void)setDoubleValue:(double)v {
	[_editor setDoubleValue:v];
	_value = v; }
	
- (NSString *)stringValue {
	return [NSString stringWithFormat:@"%f", _value]; }
    
- (void)setEnabled:(BOOL)flag 
{
    if (flag != _enabled) {
        _enabled = flag;
        [self setNeedsDisplay:YES];
        [_editor setHidden: !flag];
    }
}
    
- (BOOL)isEnabled {
    return _enabled; }
	
- (double)increment {
    return _increment; }
    
- (void)setIncrement:(double)f {
    if (f <= 0.0) f = 0.01;
    _increment = f; }
    
- (void)setNumberFormatter:(NSNumberFormatter *)numberFormatter
{
    [[_editor cell] setFormatter:numberFormatter];
}

- (void)setInterfaceTint:(LQInterfaceTint)tint {
    if (tint != _interfaceTint) {
        _interfaceTint = tint;
        [self setNeedsDisplay:YES];
    }
}

- (LQInterfaceTint)interfaceTint {
    return _interfaceTint; }


// returns yes if user did scrub
- (BOOL)trackMouseForScrubWithEvent:(NSEvent *)event
{
    if (!g_scrubEnabled)
        return NO;
    
	BOOL shiftDown = (([event modifierFlags] & NSShiftKeyMask) ? YES : NO);
	BOOL altDown =   (([event modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    BOOL cmdDown =   (([event modifierFlags] & NSCommandKeyMask) ? YES : NO);
    double scale = altDown ? 100.0 : (shiftDown ? 10.0 : (cmdDown ? 0.1 : 1.0));

	NSPoint startPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	NSPoint curPoint = startPoint;
	double startValue = _value;

    if ([[self target] respondsToSelector:@selector(fieldStartsScrub:)])
        [[self target] fieldStartsScrub:self];

    ///NSLog(@"%s -- starting", __func__);

    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        ///NSLog(@"%s -- event is: %@ (window %p)", __func__, event, [self window]);
        if ( !event || [event type] == NSLeftMouseUp) {
            break;
        }
        curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
		double xdiff = (curPoint.x - startPoint.x) * scale;
		_value = startValue + xdiff / _scrubRatio;
		[_editor setDoubleValue:_value];
		[[self target] performSelector:[self action] withObject:self];
		[self setNeedsDisplay:YES];
	}
	
	if (startPoint.x == curPoint.x && startPoint.y == curPoint.y)
		return NO;
	else
		return YES;
}

- (void)trackMouseForSpinner:(LXInteger)spinnerID withEvent:(NSEvent *)event
{
	BOOL shiftDown = (([event modifierFlags] & NSShiftKeyMask) ? YES : NO);
	BOOL altDown =   (([event modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    BOOL cmdDown =   (([event modifierFlags] & NSCommandKeyMask) ? YES : NO);
	double incMult = altDown ? 100.0 : (shiftDown ? 10.0 : (cmdDown ? 0.1 : 1.0));
    double inc = _increment * incMult;
	if (spinnerID == 0)
		inc = -inc;
	
	///NSLog(@"tracking for spinner: %i", spinnerID);
		
	// let's do a first click right now (on mouseDown)
	_value += inc;
    if (fabs(_value) < 0.0001)
        _value = 0.0;  // prevent negative zero
    
	[_editor setDoubleValue:_value];
	[[self target] performSelector:[self action] withObject:self];
	[self setNeedsDisplay:YES];
	
	// then wait for the mouseUp event
	float waitTime = 0.3;
	
    while (1) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask)
#if !defined(__LAGOON__)
							   untilDate:[NSDate dateWithTimeIntervalSinceNow:waitTime]
							   inMode:NSEventTrackingRunLoopMode
							   dequeue:YES
#endif
							];
        if ( !event || [event type] == NSLeftMouseUp) {
            break;
        }				   
		waitTime = 0.06;

		_value += inc;
        if (fabs(_value) < 0.0001)
            _value = 0.0;  // prevent negative zero
		
        [_editor setDoubleValue:_value];
		[[self target] performSelector:[self action] withObject:self];
		[self setNeedsDisplay:YES];
	}
}


- (void)mouseDown:(NSEvent *)event
{
    if (![self isEnabled])
        return;
    
#ifdef USEPLAINLOOK
    if ([event clickCount] > 1)  // ignore doubleclicks... hackety hack
    	return;
#endif
        
	NSRect bounds = [self bounds];
	NSRect leftSpinnerRect =  NSMakeRect(0, 0, SPINNERWIDTH, bounds.size.height);
	NSRect rightSpinnerRect = NSMakeRect(bounds.origin.x + bounds.size.width - SPINNERWIDTH, 0, SPINNERWIDTH, bounds.size.height);
	NSPoint curPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	
	if (NSMouseInRect(curPoint, leftSpinnerRect, YES)) {
		[self trackMouseForSpinner:0 withEvent:event];
		return;
	}
	if (NSMouseInRect(curPoint, rightSpinnerRect, YES)) {
		[self trackMouseForSpinner:1 withEvent:event];
		return;
	}

	BOOL didScrub = [self trackMouseForScrubWithEvent:event];
	
    #if !defined(__LAGOON__)
	// on Lagoon, this same functionality is implemented in the -handleTextFieldGdkEvent: delegate method
	
	if ( !didScrub) {
		[_editor setEditable:YES];
        [_editor setDelegate:(id)self];
        
        if ([[self delegate] respondsToSelector:@selector(startTabbingBetweenScrubFields)])
            [(id)[self delegate] startTabbingBetweenScrubFields];
        
        if (_nextKeyView) {
            //NSLog(@"...setting nextkeyview for %p", self);
            [self setNextKeyView:_nextKeyView];
        }
        
		if ( ![[self window] makeFirstResponder:[self window]]) {
            // a field editor may be attached if first responder assignment didn't succeed
            NSLog(@"(Conduit number scrub field: did terminate window field editor before editing)");
            [[self window] endEditingFor:nil];
        }

        ///NSLog(@"%s: first responder is now %@", __func__, [[self window] firstResponder]);
        
        [[self window] makeFirstResponder:_editor];
        
        ///NSLog(@"   ... first resp is: %@", [[self window] firstResponder]);
	}
	#endif
}

/*
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)field
{
    ///NSLog(@"** %s, value '%@'", __func__, [field string]);
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)field
{
    ///NSLog(@"** %s, value '%@'", __func__, [field string]);
    return YES;
}
*/

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
	NSTextField *field = [notif object];
	double v = [field doubleValue];

    //NSLog(@"%s (%p), value %f", __func__, self, v);

#if defined(__LAGOON__)
    [field setEditable:NO];
    [field setDoubleValue:[field doubleValue]];
#else
    
    NSEvent *event = [NSApp currentEvent];
    NSEventType evType = [event type];
    BOOL shouldFinish = YES;
    if (evType == NSKeyDown || evType == NSKeyUp) {
        int keyCode = [event keyCode];
        if (keyCode == 48) {  // this is a tab event
            shouldFinish = NO;
            //NSLog(@"... is tab: next view %@ (in editor: %@, editor %p)", _nextKeyView, field.nextKeyView, field);
        }
    }
    if (shouldFinish) {
        // finish editing - notify delegate that we should end the tabbing sequence
        [field setEditable:NO];
        if ([[self delegate] respondsToSelector:@selector(endTabbingBetweenScrubFields)])
            [(id)[self delegate] endTabbingBetweenScrubFields];
    }
#endif
	    
	_value = v;
	[[self target] performSelector:[self action] withObject:self];
	[self setNeedsDisplay:YES];
}



- (void)startTabbing {
    [_editor setEditable:YES]; }

- (void)endTabbing {
    [_editor setEditable:NO]; }

- (NSTextField *)valueEditor {
    return _editor; }    


#ifdef __LAGOON__

- (BOOL)handleTextFieldGdkEvent:(GdkEvent *)ev
{
	if (ev->type != GDK_BUTTON_PRESS)
		return NO;
	
	BOOL didScrub = [self trackMouseForScrubWithEvent:[[self window] currentEvent]];

	///NSLog(@"mouse click, ev %p, did scrub %i", ev, didScrub);
	
	if ( !didScrub) {
		[_editor setEditable:YES];		

		// scrubbing used a gtk event 3, so the entry field widget hasn't received the mouseUp event.
		// we should synthesize one and send it to the widget immediately after it has finished with this event...		
		return NO;
	} else
		return YES;  // means we handled this event, and it won't be propagated further
}

#endif
    
    
#if !defined(__LAGOON__)

- (void)setNextKeyView:(NSView *)view {
    _nextKeyView = view;
    NSTextField *nextEditor = ([_nextKeyView respondsToSelector:@selector(valueEditor)]) ? [(id)_nextKeyView valueEditor] : nil;
    [_editor setNextKeyView:nextEditor];
    if (_nextKeyView) {
        //NSLog(@"%s (%p), setting nexteditor %@ (from %@, %i) in field %p", __func__, self, nextEditor, _nextKeyView, [_nextKeyView respondsToSelector:@selector(valueEditor)], _editor);
    }
}

- (NSView *)nextKeyView {
///	NSLog(@"scrubfield -nextkey (%p, next %p)", self, [super nextKeyView]);
    return _nextKeyView; }

#endif

/*	
- (BOOL)acceptsFirstResponder {
	NSLog(@"scrubfield -accepts1st (%p, %i)", self, [super acceptsFirstResponder]);
	return YES; }

- (BOOL)becomeFirstResponder {
	NSLog(@"scrubfield -become1st (%p, %i)", self, [super becomeFirstResponder]);
	return YES; }
*/


#ifndef USEPLAINLOOK
- (void)_createButtonBaseColor
{
    [_baseCImage release], _baseCImage = nil;
    [_baseC release], _baseC = nil;
    
    if (isYosemite() && (_interfaceTint == kLQLightTint || _interfaceTint == kLQSystemTint)) {
        LXRGBA c1, c2;
        c1 = LXMakeRGBA(0.98, 0.98, 0.98, 1.0);
        c2 = LXMakeRGBA(0.8, 0.8, 0.8, 0.95);

        _baseCImage = [[NSImage verticalRoundGradientImageWithStartRGBA:c1 endRGBA:c2 height:26 exponent:1.5] retain];
        _baseC = [[NSColor colorWithPatternImage:_baseCImage] retain];

        return; // --
    }
    
/*
    LXRGBA c1;
    LXRGBA c2;
    LXInteger tint = kLQSemiDarkTint;
    switch (tint) {
        default:
        case kLQLightTint:
        case kLQSemiLightTint:
            c1 = LXMakeRGBA(0.73, 0.73, 0.75, 0.8);
            c2 = LXMakeRGBA(0.951, 0.95, 0.977, 0.99);
            break;
                
        case kLQSemiDarkTint:
        case kLQDarkTint:
            c1 = LXMakeRGBA(0.63, 0.63, 0.63, 1.0);
            c2 = //LXMakeRGBA(0.82, 0.82, 0.83, 1.0);
                LXMakeRGBA(0.922, 0.92, 0.932, 1.0);
            break;
        
        case kLQFloaterTint:
            c1 = LXMakeRGBA(0.0, 0.0, 0.0, 1.0);
            c2 = LXMakeRGBA(0.02, 0.02, 0.021, 1.0);
            break;
    }

    NSImage *im = [NSImage verticalRoundGradientImageWithStartRGBA:c1 endRGBA:c2 height:30 exponent:3.0];
*/
    NSImage *im;
    im = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"ui_scrubbutton_pattern_2" ofType:@"png"]] autorelease];
    if ( !im) {
        im = [NSImage imageInBundleWithName:@"ui_scrubbutton_pattern"];
    }
    if ( !im) {
        static BOOL s_didWarn = NO;
        if ( !s_didWarn) {
            NSLog(@"** %s: pattern image is missing", __func__);
            s_didWarn = YES;
        }
    }

    _baseCImage = [im retain];
    _baseC = [[NSColor colorWithPatternImage:_baseCImage] retain];
}
#endif



- (void)drawRect:(NSRect)rect
{
	NSRect bounds = [self bounds];
	bounds = NSInsetRect(bounds, 1.0, 0.5);
    NSBezierPath *path = [NSBezierPath roundButtonPathWithRect:bounds];
    
    const BOOL isYos = isYosemite();
 
    //NSLog(@"scrubfield drawrect, %p, %@, tint %i, grad %p", self, NSStringFromRect(rect), (int)_interfaceTint, g_bgGradient);

#ifndef USEPLAINLOOK

    if (g_bgGradient) {
        [g_bgGradient fillBezierPath:path angle:90.0];
    } else {
        if ( !_baseC)
            [self _createButtonBaseColor];

        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        if ( !isYos) {
            NSPoint phasePoint = [self convertPoint:[self bounds].origin toView:nil];
            [[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0.0, phasePoint.y-1.0)];
        }
	
        if (_baseCImage) {
            [path addClip];
        
            NSSize size = _baseCImage.size;
            [_baseCImage drawInRect:self.bounds fromRect:NSMakeRect(0, 0, size.width, self.bounds.size.height) operation:NSCompositeSourceOver fraction:1.0];
        } else {
            [_baseC set];
            [path fill];
        }
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }

    if (_interfaceTint == kLQLightTint && 0) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositePlusLighter];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.05] set];
        [path fill];
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
	
    
#else
    // Lagoon implementation
	[[NSColor colorWithDeviceRed:LAGOON_BGCOLOR_R green:LAGOON_BGCOLOR_G blue:LAGOON_BGCOLOR_B alpha:1.0] set];
	[path fill];

	// in the Gtk+ version, we don't have a pattern image, so draw a bit of 3d highlight/shadow
	{
		NSBezierPath *linePath;
		double xoff = 6;
		double yoff = 1;
		double lineH = 1.0;
		[[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.98] set];
		linePath = [NSBezierPath bezierPathWithRect:NSMakeRect(xoff, bounds.size.height-yoff,  bounds.size.width-xoff*2, lineH) ];
		[linePath fill];
	
		[[NSColor colorWithDeviceRed:0.2 green:0.25 blue:0.35 alpha:0.2] set];
		linePath = [NSBezierPath bezierPathWithRect:NSMakeRect(xoff, yoff,  bounds.size.width-xoff*2, lineH) ];
		[linePath fill];
	}
#endif
	

    if ([self isEnabled])
#ifndef USEPLAINLOOK
        ///[[NSColor colorWithDeviceRed:0.16 green:0.24 blue:0.35 alpha:1.0] set];
        [[NSColor colorWithDeviceRed:0.0 green:0.04 blue:0.08 alpha:0.94] set];
#else
        [[NSColor colorWithDeviceRed:0.1 green:0.05 blue:0.4 alpha:1.0] set];  // use a darker outline color to match Win/Gtk+ look
#endif

    else {
        if (isYos) {
            [[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
        } else {
            [[NSColor colorWithDeviceRed:0.45 green:0.45 blue:0.46 alpha:0.9] set];
        }
    }
    
    [path setLineWidth:(isYos) ? 0.3 : 0.6];
	[path stroke];
	
	// draw spinners
	float spinnerY = 5.0;
	float spinnerH = 6.0;
	
#if defined(__LAGOON__)
	spinnerY += 2.0;
#endif
	
	[path removeAllPoints];
	[path moveToPoint:NSMakePoint(5.5, spinnerY + spinnerH*0.5)];
	[path lineToPoint:NSMakePoint(9.0, spinnerY + spinnerH)];
	[path lineToPoint:NSMakePoint(9.0, spinnerY)];
	[path fill];

	[path removeAllPoints];
	[path moveToPoint:NSMakePoint(bounds.origin.x + bounds.size.width - 4.5,
								  spinnerY + spinnerH*0.5)];
	[path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width - 4.5 - 3.5,
								  spinnerY + spinnerH)];
	[path lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width - 4.5 - 3.5,
								  spinnerY)];
	[path fill];	
}

@end
