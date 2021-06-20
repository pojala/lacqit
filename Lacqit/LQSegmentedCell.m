//
//  LQSegmentedCell.m
//  Edo
//
//  Created by Pauli Ojala on 17.5.2006.
//  Copyright 2006 Lacquer Oy. All rights reserved.
//

#import "LQSegmentedCell.h"
#import <Lacefx/LXBasicTypeFunctions.h>
#import "LQNSBezierPathAdditions.h"
#import "LQNSColorAdditions.h"
#import "EDUINSImageAdditions.h"
#import "LQAppKitUtils.h"

#if !defined(__COCOTRON__)
#import "LQPopUpWindow.h"
#endif


#if defined(__COCOTRON__)
#define DEBUGLOG(format, args...)   //NSLog(format , ## args);
#else
//#define DEBUGLOG(format, args...)   NSLog(format , ## args);
#define DEBUGLOG(format, args...)
#endif


@implementation LQSegmentedCell

- (void)copySettingsFromCell:(NSSegmentedCell *)cell
{
    [self setControlSize:[cell controlSize]];
    [self setFont:[cell font]];
    
    [self setTarget:[cell target]];
    [self setAction:[cell action]];
    
    if ( ![cell isKindOfClass:[NSSegmentedCell class]])
        return;

    [self setTrackingMode:[cell trackingMode]];

    LXInteger count = [cell segmentCount];
    [self setSegmentCount:count];
    
    ///[self setSelectedSegment:[cell selectedSegment]];
    
    LXInteger i;
    for (i = 0; i < count; i++) {
        [self setWidth:[cell widthForSegment:i] forSegment:i];
        [self setLabel:[cell labelForSegment:i] forSegment:i];
        [self setImage:[cell imageForSegment:i] forSegment:i];
        [self setSelected:[cell isSelectedForSegment:i] forSegment:i];
        [self setEnabled:[cell isEnabledForSegment:i] forSegment:i];
        [self setTag:[cell tagForSegment:i] forSegment:i];
        [self setMenu:[cell menuForSegment:i] forSegment:i];
    }
}

- (void)dealloc
{
    [_baseC release];
    [_baseCImage release];
    [_selC release];
    [_selCImage release];
    [_selShad release];
    [_hiliteShad release];

    [super dealloc];
}

- (void)_privateCellInit
{
    _opacity = 1.0;
    _useFixedImageSize = NO;
    _imageSize = NSMakeSize(16, 16);
    self.bordered = YES;
}

- (id)initTextCell:(NSString *)str
{
    self = [super initTextCell:str];
    if (self) {
        [self _privateCellInit];
    }
    return self;
}

- (id)initImageCell:(NSImage *)image
{
    self = [super initImageCell:image];
    if (self) {
        [self _privateCellInit];
    }
    return self;
}

/*
-(BOOL)selectSegmentWithTag:(LXInteger)tag {
    NSLog(@"%s (%p): %i", __func__, self, tag);
    return [super selectSegmentWithTag:tag];
}

-(void)setSelected:(BOOL)flag forSegment:(LXInteger)segment {
    NSLog(@"%s (%p): %i for %i", __func__, self, flag, segment);
    [super setSelected:flag forSegment:segment];
}

-(void)setSelectedSegment:(LXInteger)segment {
    NSLog(@"%s (%p): %i", __func__, self, segment);
    [super setSelectedSegment:segment];
}
*/

- (void)_invalidateColors
{

}

- (void)setImageOpacity:(CGFloat)op {
    _opacity = op;
    [self _invalidateColors];
}

- (void)setFixedImageSize:(NSSize)size {
    _imageSize = size; }
    
- (void)setFixedImageSizeEnabled:(BOOL)flag {
    _useFixedImageSize = flag; }

- (void)setDrawsMenuIndicator:(BOOL)f {
    _drawsMenuIndicator = f; }


- (void)setInterfaceTint:(LQInterfaceTint)tint
{
    [self _invalidateColors];
    [_selShad release];
    [_hiliteShad release];
    _selShad = nil;
    _hiliteShad = nil;
    
    _lqTint = tint;
}
    
- (LQInterfaceTint)interfaceTint {
    return _lqTint; }


- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    return;
    
    //[super drawInteriorWithFrame:cellFrame inView:controlView];
	
/*
    int segCount = [self segmentCount];
    float xMargin = 1.0f;
    float segH = cellFrame.size.height - 4.0f;
    
    int i;
    float x = cellFrame.origin.x + 3.0f;
    float y = cellFrame.origin.y + 2.0f;
    
    for (i = 0; i < segCount; i++) {
        float segW = [self widthForSegment:i];
        NSRect segFrame = NSMakeRect(x, y,  segW, segH);
        
        [self drawSegment:i inFrame:segFrame withView:controlView];
        x += segW + xMargin;
    }
*/
}

static BOOL isYosemite()
{
    static int s_f = -1;
    if (s_f == -1) {
        s_f = (NSClassFromString(@"NSVisualEffectView") != Nil);
    }
    return s_f ? YES : NO;
}

- (void)_createButtonSelectionColor
{
    LXRGBA c1;
    LXRGBA c2;
    switch (_lqTint) {
        default:
        case kLQLightTint:
            if (isYosemite()) {
                if ([NSColor currentControlTint] == NSBlueControlTint) {
                    c1 = LXMakeRGBA(98/255.0, 172/255.0, 251/255.0, 1.0);
                    c2 = LXMakeRGBA(15/255.0, 0.5, 1.0, 1.0);
                } else {
                    c1 = LXMakeRGBA(0.68, 0.68, 0.68, 1.0);
                    c2 = LXMakeRGBA(0.51, 0.51, 0.515, 1.0);
                }
            } else {
                c1 = LXMakeRGBA(0.66, 0.66, 0.66, 1.0);
                c2 = LXMakeRGBA(0.53, 0.53, 0.53, 1.0);
            }
            break;
        
        case kLQSemiLightTint:
            c1 = LXMakeRGBA(0.63, 0.63, 0.63, 1.0);
            c2 = LXMakeRGBA(0.40, 0.40, 0.41, 1.0);
            break;
                
        case kLQSemiDarkTint:
        case kLQDarkTint:
            c1 = LXMakeRGBA(0.60, 0.60, 0.60, 1.0);
            c2 = LXMakeRGBA(0.38, 0.38, 0.391, 1.0);
            break;
        
        case kLQDarkDashboardTint:
            if (isYosemite()) {
                if ([NSColor currentControlTint] == NSBlueControlTint) {
                    c1 = LXMakeRGBA(98/255.0, 172/255.0, 251/255.0, 0.9);
                    c2 = LXMakeRGBA(15/255.0, 0.5, 1.0, 0.99);
                } else {
                    c1 = LXMakeRGBA(0.68, 0.68, 0.68, 0.9);
                    c2 = LXMakeRGBA(0.51, 0.51, 0.515, 0.9);
                }
            } else {
                c1 = LXMakeRGBA(0.12, 0.12, 0.12, _opacity);
                c2 = LXMakeRGBA(0.21, 0.21, 0.21, _opacity);
            }
            break;
        
        case kLQFloaterTint:
            c2 = LXMakeRGBA(0.20, 0.20, 0.20, 1.0);
            c1 = LXMakeRGBA(0.08, 0.08, 0.091, 1.0);
            break;
    }

    [_selC release];
    [_selCImage release], _selCImage = nil;

#if defined(__COCOTRON__)
    c1.r = 0.5*c1.r + 0.5*c2.r;
    c1.g = 0.5*c1.g + 0.5*c2.g;
    c1.b = 0.5*c1.b + 0.5*c2.b;
    _selC = [[NSColor colorWithRGBA:c1] retain];
#else
    if (isYosemite()) {
        _selCImage = [[NSImage verticalRoundGradientImageWithStartRGBA:c2 endRGBA:c1 height:25 exponent:1.0] retain];
    } else {
        _selCImage = [[NSImage verticalRoundGradientImageWithStartRGBA:c1 endRGBA:c2 height:25 exponent:1.0] retain];
    }
    _selC = [[NSColor colorWithPatternImage:_selCImage] retain];
#endif
}


- (void)_createButtonBaseColor
{
    LXRGBA c1;
    LXRGBA c2;
    switch (_lqTint) {
        default:
        case kLQLightTint:
            if (isYosemite()) {
                c1 = LXMakeRGBA(0.9, 0.9, 0.905, 0.95);
                c2 = LXMakeRGBA(1.0, 1.0, 1.0, 1.0);
            } else {
                c1 = LXMakeRGBA(0.77, 0.77, 0.779, 0.95);
                c2 = LXMakeRGBA(1.0, 1.0, 1.0, 1.0);
            }
            break;
        
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
            
        case kLQDarkDashboardTint:
            c1 = LXMakeRGBA(0.2*_opacity, 0.2*_opacity, 0.2*_opacity, _opacity);
            c2 = LXMakeRGBA(0.31*_opacity, 0.31*_opacity, 0.31*_opacity, _opacity);
            break;
        
        case kLQFloaterTint:
            c1 = LXMakeRGBA(0.0, 0.0, 0.0, 1.0);
            c2 = LXMakeRGBA(0.02, 0.02, 0.021, 1.0);
            break;
    }
    
    [_baseC release];
    [_baseCImage release], _baseCImage = nil;

#if defined(__COCOTRON__)
    c1.r = 0.3*c1.r + 0.7*c2.r;
    c1.g = 0.3*c1.g + 0.7*c2.g;
    c1.b = 0.3*c1.b + 0.7*c2.b;
    _baseC = [[NSColor colorWithRGBA:c1] retain];
#else
    if (isYosemite()) {
        _baseCImage = [[NSImage verticalRoundGradientImageWithStartRGBA:c2 endRGBA:c1 height:40 exponent:3.0] retain];
    } else {
        _baseCImage = [[NSImage verticalRoundGradientImageWithStartRGBA:c1 endRGBA:c2 height:40 exponent:3.0] retain];
    }
    
    _baseC = [[NSColor colorWithPatternImage:_baseCImage] retain];
#endif
}


- (void)_createSelectedContentsShadow
{
    [_selShad release];
    NSColor *c = (_lqTint == kLQFloaterTint) ? [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.95]
                                             : [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5];

        NSShadow *s = [[NSShadow alloc] init];
        [s setShadowBlurRadius:0.0];
        [s setShadowOffset:NSMakeSize(0.0, -1.0)];
        [s setShadowColor:c];
    
    _selShad = s;
}

- (void)_createOutlineShadow
{
    [_outlineShad release];
    NSColor *c = (_lqTint == kLQFloaterTint) ? [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.95]
    : [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    
    NSShadow *s = [[NSShadow alloc] init];
    [s setShadowBlurRadius:0.0];
    [s setShadowOffset:NSMakeSize(0.0, -1.0)];
    [s setShadowColor:c];
    
    _outlineShad = s;
}

- (void)_createHighlightedContentsShadow
{
    [_hiliteShad release];
    
    double alpha = 0.35;
    if (isYosemite()) {
        alpha = 0.1;
    }

        NSShadow *s = [[NSShadow alloc] init];
        [s setShadowBlurRadius:5.0];
        [s setShadowOffset:NSMakeSize(0.0, 0.0)];
        [s setShadowColor:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.08 alpha:alpha]];
    
    _hiliteShad = s;
}


- (void)setHighlightedSegment:(LXInteger)index {
    _highlightSeg = index;
}

/*
- (NSSize)displaySize
{
    int segCount = [self segmentCount];
    int segW = [self widthForSegment:0];
    float xMargin = 1.0f;

    NSView *controlView = [self controlView];
    float h = (controlView) ? [controlView frame].size.height : 24.0; 
    
    return NSMakeSize(segCount*segW + (segCount - 1)*xMargin,
                      h);
}
*/

- (LXInteger)_findSegmentAtPoint:(NSPoint)p controlView:(NSView *)controlView
{
    LXInteger i;
    LXInteger segCount = [self segmentCount];
    CGFloat x = 3.0;  // TODO: this is hardcoded also in LQSegmentedCell.m, should be in a single place
    CGFloat y = 1.0;
    CGFloat xMargin = 1.0f;
    CGFloat segH = [controlView bounds].size.height;
    
    for (i = 0; i < segCount; i++) {
        CGFloat segW = [self widthForSegment:i] + xMargin;
        NSRect segFrame = NSMakeRect(x, y,  segW, segH);
        
        if (NSMouseInRect(p, segFrame, NO)) {
            //NSLog(@"%s, seg %i, width %.1f", __func__, i, segW);
            return i;
        }
        
        x += segW;
    }
    
    // do second pass with expanded rects
    for (i = 0; i < segCount; i++) {
        CGFloat segW = [self widthForSegment:i] + xMargin;
        NSRect segFrame = NSMakeRect(x, y,  segW, segH);
        
        if (NSMouseInRect(p, NSInsetRect(segFrame, -2, -2), NO))
            return i;
        
        x += segW;
    }
    
    return NSNotFound;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)stopPoint
              inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    [super stopTracking:lastPoint at:stopPoint inView:controlView mouseIsUp:flag];

    if (flag == YES) {
        LXInteger seg = [self _findSegmentAtPoint:stopPoint controlView:controlView];
        if (seg != NSNotFound) [self setSelected:YES forSegment:seg];
    }
}

- (NSDictionary *)textAttributesForSegment:(LXInteger)i
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        [self font], NSFontAttributeName,
                                        nil];

    NSColor *c = nil;
    switch (_lqTint) {
        default:
        case kLQLightTint:
            c = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.9];
            break;        
        
        case kLQSemiLightTint:
            c = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.85];
            break;

        case kLQSemiDarkTint:
        case kLQDarkTint:
            c = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:1.0];
            break;
            
        case kLQDarkDashboardTint:
            c = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:(_opacity > 0.85) ? 0.91 : ((_opacity > 0.5) ? _opacity*1.3 : 0.7)];
            break;
        
        case kLQFloaterTint:
            c = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
            break;
    }
    
    if ([self isSelectedForSegment:i] && [self isEnabled]) {
        c = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.66]];
        [shadow setShadowBlurRadius:3.0];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [dict setObject:shadow forKey:NSShadowAttributeName];
    }
    
    [dict setObject:c forKey:NSForegroundColorAttributeName];
    
    return dict;
}


- (CGFloat)widthForSegment:(LXInteger)index
{
    CGFloat w = [super widthForSegment:index];
    if (w <= 0.0) {
        NSString *label = [self labelForSegment:index];
        NSSize textSize = [label sizeWithAttributes:[self textAttributesForSegment:index]];
        
        NSImage *image = [self imageForSegment:index];
        NSSize imageSize = NSZeroSize;
        if (image) {
            imageSize = [image size];
            if (_useFixedImageSize)
                imageSize = _imageSize;
        }
        
        w = ceil(textSize.width + 12 + (imageSize.width > 0 ? imageSize.width+4 : 0));
    }
    return w;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    ///NSLog(@"lqsegcell draw: %@, viewframe %@ (%p)", NSStringFromRect(cellFrame), NSStringFromRect([controlView frame]), controlView);
    ///[super drawWithFrame:cellFrame inView:controlView];
    
    if ([self respondsToSelector:@selector(setControlView:)])
        [self setControlView:controlView];

    LXUInteger lqTint = _lqTint;
    
    if (isYosemite() && lqTint == kLQSystemTint) {
        lqTint = kLQLightTint;
    }

    NSWindow *window = [controlView window];
    const BOOL windowIsActive = ([window isKeyWindow] || [window isKindOfClass:[NSPanel class]]
#ifdef __APPLE__
                                 || [window isKindOfClass:[LQPopUpWindow class]]);
#else
    );
#endif
    
    const BOOL controlIsEnabled = [(NSControl *)controlView isEnabled];
    BOOL isHighlighted = [self isHighlighted]; 
    LXUInteger trackingMode = [self trackingMode];   
    LXInteger segCount = [self segmentCount];
    LXInteger i;
    double x = cellFrame.origin.x + 3.0;
    double y = cellFrame.origin.y + 1.0;
    double xMargin = 1.0;
    double totalH = round(cellFrame.size.height) - 4.0;
    double totalW;
    
    if (segCount < 2) {
        totalW = round(cellFrame.size.width) - 6.0;
    } else {
        totalW = -1.0;
        for (i = 0; i < segCount; i++) {
            double segW = [self widthForSegment:i];
            totalW += segW + xMargin;
        }
    }
    
    //NSLog(@"lq segmentcell draw: first '%@', count %i; %i, %i, %i, tint %i, op %.3f",
    //            [self labelForSegment:0], segCount, [self isEnabled], [self state], [self isHighlighted], lqTint, _opacity);

    const double borderXOff = (lqTint == kLQFloaterTint) ? 0.5 : -0.5;
    const double borderYOff = (lqTint == kLQFloaterTint) ? 0.5 : -0.5;
    const double borderHOff = (lqTint == kLQFloaterTint) ? 1.0 : 1.0;
    double borderRounding = (lqTint == kLQFloaterTint) ? (totalH > 18.0) ? 8.0 : 6.0
                                                       : 5.0;
    
    NSRect borderRect = NSMakeRect(x+borderXOff, y+borderYOff,  1.0 + totalW, totalH+borderHOff);
    
    if (segCount == 1)
        borderRect.size.width -= 4.0;    
    
    NSBezierPath *path = (self.bordered) ? [NSBezierPath bezierPathWithRoundedRect:borderRect rounding:borderRounding] : nil;

    ///NSLog(@"base rect: %@", NSStringFromRect(borderRect));

    NSPoint phase = NSZeroPoint;
    
    //[[NSColor colorWithDeviceRed:0.8 green:0.8 blue:0.8 alpha:0.7] set];
    
    if (controlIsEnabled && path) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        NSColor *c = nil;
        BOOL useImage = NO;
        if (isYosemite() && lqTint == kLQLightTint) {
            c = [NSColor whiteColor];
        } else {
            if ( !_baseC) [self _createButtonBaseColor];
            c = _baseC;
            useImage = _baseCImage != nil;
        }

        if (useImage && _baseCImage && isYosemite()) {
            [path addClip];
            
            NSRect r = path.bounds;
            NSSize size = _baseCImage.size;
            [_baseCImage drawInRect:r fromRect:NSMakeRect(0, round(0.5*(size.height-r.size.height)), size.width, r.size.height) operation:NSCompositeSourceOver fraction:1.0];
        } else {
            if ( !isYosemite()) {
                phase = [controlView convertPoint:[controlView bounds].origin toView:nil];
                phase.y -= 20.0;
                [[NSGraphicsContext currentContext] setPatternPhase:phase];
            }
            [c set];
            [path fill];
        }
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
    
    LXInteger selectedSeg = [self selectedSegment];
    
    for (i = 0; i < segCount; i++) {
        double segW = (segCount > 1) ? [self widthForSegment:i] : totalW;
        NSRect segFrame = NSMakeRect(x, y,  segW, totalH);
        NSShadow *shad = nil;

        [[NSGraphicsContext currentContext] saveGraphicsState];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        
        ///NSLog(@" (%p) ... %i / '%@': is sel %i, track %i, selseg %i", self, i, [self labelForSegment:i], [self isSelectedForSegment:i], trackingMode, selectedSeg);

        if (selectedSeg != -1 && [self isSelectedForSegment:i] && (trackingMode != NSSegmentSwitchTrackingMomentary || 
                                              [self menuForSegment:i] == nil)
            ) {
            NSColor *selBorderC = (controlIsEnabled) ? [NSColor blackColor] : [NSColor darkGrayColor];
            
            double lineW = 0.55;
            NSRect borderRect = NSInsetRect(segFrame, -0.5, -0.75);
            borderRect.size.height -= 0.5;
            borderRect.origin.y += 0.5;
            
            if (segCount == 1)
                borderRect.size.width -= 4.0;
            
            if (lqTint == kLQFloaterTint) {
                borderRect.origin.x = 0.5 + round(borderRect.origin.x);
                borderRect.origin.y = segFrame.origin.y + 0.75;
                borderRect.size.height -= 0.25;
                borderRect.size.width = round(borderRect.size.width);
                lineW = 0.63;
                
                selBorderC = (controlIsEnabled) ? [NSColor whiteColor] : [NSColor lightGrayColor];
            }
            else if (lqTint == kLQLightTint && isYosemite()) {
                selBorderC = [NSColor colorWithCalibratedWhite:0.0 alpha:0.5];
                lineW = 0.3;
            }
            
            ///NSLog(@"selected rect: %@", NSStringFromRect(borderRect));
            
            NSBezierPath *path = (self.bordered) ? [NSBezierPath bezierPathWithRoundedRect:borderRect rounding:borderRounding] : nil;

            if (controlIsEnabled && path) {
                if ( !_selC) [self _createButtonSelectionColor];
                
                [[NSGraphicsContext currentContext] saveGraphicsState];
                if (_selCImage && isYosemite()) {
                    [path addClip];
                    
                    NSSize size = _selCImage.size;
                    [_selCImage drawInRect:segFrame fromRect:NSMakeRect(0, size.height-segFrame.size.height, size.width, segFrame.size.height) operation:NSCompositeSourceOver fraction:1.0];
                } else {
                    phase.y += 20.0;
                    [[NSGraphicsContext currentContext] setPatternPhase:phase];
                    [_selC set];
                    [path fill];
                }
                [[NSGraphicsContext currentContext] restoreGraphicsState];

            } else {
                [[NSColor colorWithCalibratedWhite:0.1 alpha:0.1] set];
                [path fill];
            }
            
            [selBorderC set];
            
            [path setLineWidth:lineW];
            [path stroke];
        } else {
        }

        if ( !_hiliteShad) [self _createHighlightedContentsShadow];
        
        shad = (isHighlighted && _highlightSeg == i) ? _hiliteShad : _selShad;        
        [shad set];
        
        [self drawSegment:i inFrame:segFrame withView:controlView];        

        [[NSGraphicsContext currentContext] restoreGraphicsState];

        x += segW + xMargin;
    }
    
    // draw outline
    if (windowIsActive) {
        switch (lqTint) {
            case kLQLightTint:
                if (isYosemite()) {
                    [[NSColor colorWithDeviceRed:0.12 green:0.126 blue:0.16 alpha:0.6] set];
                    break;
                }
                
            case kLQSemiLightTint:
                //[[NSColor colorWithDeviceRed:0.1 green:0.015 blue:0.05 alpha:0.85] set];
                [[NSColor colorWithDeviceRed:0.12 green:0.126 blue:0.16 alpha:0.82] set];
                break;
                
            case kLQFloaterTint:
                [[NSColor colorWithDeviceRed:0.5 green:0.5 blue:0.5 alpha:0.92] set];
                break;
                
            default:
                [[NSColor colorWithDeviceRed:0.08 green:0.15 blue:0.2 alpha:0.87] set];
                break;
        }
    } else {
        [[NSColor colorWithDeviceRed:0.1 green:0.1 blue:0.1 alpha:0.6] set];
    }
    
    if ( !_outlineShad) [self _createOutlineShadow];
    [_outlineShad set];
    
    [path setLineWidth:(controlIsEnabled) ? 0.6 : 0.3];
    [path stroke];
}


- (void)_drawSegmentMenuIndicatorInFrame:(NSRect)frame
{
    frame = NSInsetRect(frame, 4, 4);
    frame.origin.x = 1.0 + round(frame.origin.x);
    
    NSBezierPath *path = [NSBezierPath bezierPath];
/*    
    NSPoint corner = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);
    double triSize = 4.0;
    [path moveToPoint:corner];
    [path lineToPoint:NSMakePoint(corner.x, corner.y - triSize)];
    [path lineToPoint:NSMakePoint(corner.x - triSize, corner.y)];
  */
    double triW = 5.0;
    double triH = 3.0;
    NSPoint corner = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height - triH);
    [path moveToPoint:corner];
    [path lineToPoint:NSMakePoint(corner.x - triW*0.5, corner.y + triH)];
    [path lineToPoint:NSMakePoint(corner.x - triW, corner.y)];
    
    NSColor *c;
    if (_lqTint == kLQDarkDashboardTint) {
        c = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.86];
    } else {
        c = [NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.11 alpha:0.86];
    }
          
    [c set];
    [path fill];
}


- (void)drawSegment:(LXInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView
{
    DEBUGLOG(@"..lqsegment draw: seg %i, %@, %p", segment, NSStringFromRect(frame), controlView);

    NSString *label = [self labelForSegment:segment];
    NSImage *image = [self imageForSegment:segment];
    BOOL hasMenu = (_drawsMenuIndicator && [self menuForSegment:segment] != nil);
    const BOOL controlIsEnabled = [(NSControl *)controlView isEnabled];
    
    const BOOL isSelected = [self selectedSegment] != -1 && [self isSelectedForSegment:segment] && self.trackingMode != NSSegmentSwitchTrackingMomentary;
    
    const BOOL isHighlighted = _highlightSeg == segment && self.isHighlighted;
    
    if (frame.size.width < 51)
        hasMenu = NO;
	
    DEBUGLOG(@"%p / %i: label %@ / tracking %i / target %p, action %p / menu: %@", self, segment, label, [self trackingMode],
                                                                  [self target], [self action], [self menuForSegment:segment]);
	//if ([label isEqual:@"kam"])
	//	NSLog(@"     drawing camera seg (%@); image %p, menu %i", [self description], image, hasMenu);

    const double xOffset = (hasMenu || [self segmentCount] == 1) ? ((hasMenu && [self segmentCount] == 1) ? -4.0 : -2.0)
                                                                 : 0.0;
    BOOL drawTitle = YES;
    CGFloat imageW = 0;
    if (image) {
        NSSize imageSize = [image size];
        if (_useFixedImageSize)
            imageSize = _imageSize;
        
        drawTitle = ([label length] > 0);
        
        BOOL centerImage = (drawTitle) ? NO : YES;
        
        double imageX = (centerImage) ? frame.origin.x + (frame.size.width - imageSize.width) * 0.5 + xOffset
        : frame.origin.x + xOffset + 5;
        
        NSRect imageFrame = NSMakeRect(imageX,
                                       frame.origin.y + (frame.size.height - imageSize.height) * 0.5,
                                       imageSize.width,
                                       imageSize.height);

        imageFrame.origin.x = round(imageFrame.origin.x);
        
        imageW = round(imageFrame.size.width * 0.6);

        if ( !self.bordered && (isSelected || isHighlighted)) {
            CGRect targetRect = NSRectToCGRect(imageFrame);
            CGContextRef ctx = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            
            CGImageRef alphaImage = LQCreateGrayscaleImageFromCGImageAlpha([image CGImageForProposedRect:NULL context:NULL hints:nil]);
            
            LXRGBA hiliteRGBA = (isHighlighted)
                                ? LXMakeRGBA(0.5, 0.66, 1.0, 1.0)
                                : LXMakeRGBA(0.2, 0.25, 1.0, 0.99);
            
            CGContextSaveGState(ctx);
            CGContextTranslateCTM(ctx, 0, targetRect.origin.y + targetRect.size.height);
            CGContextScaleCTM(ctx, 1, -1);
            targetRect.origin.y = 0;
            
            CGContextClipToMask(ctx, targetRect, alphaImage);
            CGContextSetRGBFillColor(ctx, hiliteRGBA.r, hiliteRGBA.g, hiliteRGBA.b, hiliteRGBA.a);
            CGContextFillRect(ctx, targetRect);
            CGContextRestoreGState(ctx);
            
            CGImageRelease(alphaImage);
        }
        else {
            BOOL f = [image isFlipped];
            if (!f) [image setFlipped:YES];
            
            [image drawInRect:imageFrame
                     fromRect:NSMakeRect(0, 0, [image size].width, [image size].height)
                    operation:NSCompositeSourceOver
                     fraction:([self isSelectedForSegment:segment] && [self selectedSegment] != -1) ? 1.0f : _opacity];
            
            if (!f) [image setFlipped:f];
        }
    }
    
    if (drawTitle) {
        BOOL isAttributed = [label isKindOfClass:[NSAttributedString class]];
        
        NSDictionary *textAttribs = isAttributed ? [(NSAttributedString *)label attributesAtIndex:0 effectiveRange:nil]
                                                 : [self textAttributesForSegment:segment]; 
        
        NSSize labelSize = [label sizeWithAttributes:textAttribs];
        NSRect newFrame = frame;
        newFrame.size.height = round(labelSize.height + 1.0);
        newFrame.size.width = ceil(labelSize.width);
        
        newFrame.origin.y += (frame.size.height - newFrame.size.height) * 0.5 + 0.5;
        
        if (labelSize.height <= 13.0 || (LXInteger)(frame.size.height - labelSize.height) % 2 == 0) newFrame.origin.y -= 1.0;
        
        newFrame.origin.x += (frame.size.width - newFrame.size.width) * 0.5 + xOffset;
        newFrame.origin.x += imageW;
        
        newFrame.origin.x = round(newFrame.origin.x);
        newFrame.origin.y = round(newFrame.origin.y);
        
        newFrame.origin.y += 1.0; // 2014.01.30
        
        // if there's a menu, add space for an indicator
        if (hasMenu)
            newFrame.origin.x -= 2.0;
        
        if (isAttributed) {
            [(NSAttributedString *)label drawInRect:newFrame];
        } else {
            if ( !controlIsEnabled) {
                textAttribs = [NSMutableDictionary dictionaryWithDictionary:textAttribs];
                [(NSMutableDictionary *)textAttribs setObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] forKey:NSForegroundColorAttributeName];
            }
        
            DEBUGLOG(@"drawing label '%@' in frame %@ (full size %@, had attribs: %i)", label, NSStringFromRect(newFrame), NSStringFromRect(frame), isAttributed);
            [label drawInRect:newFrame withAttributes:textAttribs];
        }
    }

    if (hasMenu) {
        frame.size.width -= 4.0;
        [self _drawSegmentMenuIndicatorInFrame:frame];
    }

    //[super drawSegment:segment inFrame:frame withView:controlView];
    return;
    
}


@end
