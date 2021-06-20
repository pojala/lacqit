//
//  EDUICompConnector.m
//  Edo
//
//  Copyright (c) 2002 Pauli Ojala. All rights reserved.
//

#import "EDUICompConnector.h"
#import "EDUICompInputView.h"
#import "EDUICompNodeView.h"



@implementation EDUICompConnector

- (id)init
{
    self = [super init];
    _connected = NO;
    _drawToFrameOrigin = NO;
	_notePos = 0.5f;
	_note = nil;
	
    return self;
}

- (void)dealloc
{
	[_startColor release];
	[_endColor release];
	[_note release];
	_lx_free(_dropRects);
    [super dealloc];
}


#pragma mark --- accessors ---
//

- (BOOL)isConnected {
    return _connected; }

- (void)setDrawToOrigin:(BOOL)boo {
    _drawToFrameOrigin = boo; }
	
- (void)getStart:(NSPoint *)pStart end:(NSPoint *)pEnd controlPoint1:(NSPoint *)pCp1 controlPoint2:(NSPoint *)pCp2
		inView:(NSView *)view
{
    NSPoint start, end, cp1, cp2;

    BOOL inputIsParameter = [_toInput isParameter];

    start = [_fromOutput bounds].origin;
    end =   [_toInput bounds].origin;
    start.x += 8.0;
    start.y += 4.0;
    
    if (!_drawToFrameOrigin) {
        end.x += 8.0;
        end.y += 12.0;
    }
    else {
        end.y += 16.0;
    }
    
    ///NSLog(@"connector start %f %f,  end %f %f", start.x, start.y,  end.x, end.y);
    start = [view convertPoint:start fromView:_fromOutput];
    end = [view convertPoint:end fromView:_toInput];

    cp1 = NSMakePoint(start.x, start.y - 16.0);
    if (inputIsParameter) {
        end.x += 2.0;
        end.y -= 4.0;
        cp2 = NSMakePoint(end.x + 20.0, end.y - 4.0);
    }
    else
        cp2 = NSMakePoint(end.x, end.y + 16.0);
    if (end.y > start.y) {
        cp1.y -= (end.y - start.y) / 8.0;
        cp2.y += (end.y - start.y) / 8.0;
    }
	
	*pStart = start;
	*pEnd = end;
	*pCp1 = cp1;
	*pCp2 = cp2;
}


static inline void setDropRectInArray(NSRect *pNewRect, NSInteger index, NSRect **pDropRects, NSInteger *pRectArraySize)
{
	// enlargen drop rect array if necessary
	if (index >= *pRectArraySize) {
		*pRectArraySize += 8;
		*pDropRects = _lx_realloc(*pDropRects, (*pRectArraySize) * sizeof(NSRect));
	}
	
	(*pDropRects)[index] = *pNewRect;
}

static inline NSRect ValidateNSRect(NSRect r)
{
	if (r.size.width < 0.0f) {
		r.origin.x += r.size.width;
		r.size.width = -r.size.width;
	}
	if (r.size.height < 0.0f) {
		r.origin.y += r.size.height;
		r.size.height = -r.size.height;
	}
	return r;
}


#define DROPRECTOUTSET_X 2.0f
#define DROPRECTOUTSET_Y 2.0f

- (void)createDropRects
{
	// create drop rects (the compview uses these to determine the active area of this connector)

	NSPoint start, end, cp1, cp2;

	if (_dropRectArraySize == 0) {
		_dropRectArraySize = 8;
		_dropRects = _lx_malloc(_dropRectArraySize * sizeof(NSRect));
	}
	
	_dropRectsAreDirty = NO;
	
	EDUICompositionView *compView = [[_fromOutput nodeView] compView];
	[self getStart:&start end:&end controlPoint1:&cp1 controlPoint2:&cp2 inView:(NSView *)compView];

	// make a flattened path of the curve
	NSBezierPath *gpath = [NSBezierPath bezierPath];
	[gpath moveToPoint:start];
	[gpath curveToPoint:end controlPoint1:cp1 controlPoint2:cp2 ];

	[NSBezierPath setDefaultFlatness:1.0];
	NSBezierPath *flatPath = [gpath bezierPathByFlatteningPath];
	
	// get first point of flattened path
	NSPoint points[3];
	NSPoint firstPoint;
	[flatPath elementAtIndex:0 associatedPoints:&firstPoint];
	NSPoint prevPoint = firstPoint;
	
	// iterate through flattened path line segments
	NSInteger elems = [flatPath elementCount];
	NSInteger i;
	NSRect newRect;
	_dropRectCount = 0;
	
	float xMax = 5.0f;
	float yMax = 5.0f;
	float xOutset = DROPRECTOUTSET_X;
	float yOutset = DROPRECTOUTSET_Y;
	
	for (i = 1; i < elems; i++) {
		[flatPath elementAtIndex:i associatedPoints:points];
		
		NSInteger xc = 1;
		NSInteger yc = 1;
		float x = points[0].x - prevPoint.x;
		float y = points[0].y - prevPoint.y;
		float angle = fabs(y / x);
		#pragma unused (angle)
		
		if (fabs(x) > xMax) {
			xc = ceil(fabs(x) / xMax);
		}
		if (fabs(y) > yMax) {
			yc = ceil(fabs(y) / yMax);
		}
		
		NSInteger c = MIN(xc, yc);

		if (c <= 1) {
			newRect.origin = prevPoint;
			newRect.size = NSMakeSize(x, y);
			
			newRect = NSInsetRect( ValidateNSRect(newRect), -xOutset, -yOutset );

			setDropRectInArray(&newRect, _dropRectCount, &_dropRects, &_dropRectArraySize);
			_dropRectCount++;
		}
		else {
			// break rect into multiple small rects
			NSInteger j;
			
			NSRect bound;
			bound.origin = prevPoint;
			bound.size = NSMakeSize(x, y);
			
			BOOL ydir = (y < 0.0f);
			BOOL xdir = (x < 0.0f);
			bound = ValidateNSRect(bound);

			float sy = ydir ?  (bound.origin.y + bound.size.height) : (bound.origin.y);
			float sx = xdir ?  (bound.origin.x + bound.size.width) :  (bound.origin.x);
			
			x = bound.size.width / (float)c;
			y = bound.size.height / (float)c;
			
			if (ydir) y *= -1.0f;
			if (xdir) x *= -1.0f;
			
			for (j = 0; j < c; j++) {
				newRect.origin.x = sx + x * (float)j;
				newRect.origin.y = sy + y * (float)j;
				newRect.size = NSMakeSize(x, y);
				
				newRect = NSInsetRect( ValidateNSRect(newRect), -xOutset, -yOutset );
				
				setDropRectInArray(&newRect, _dropRectCount, &_dropRects, &_dropRectArraySize);
				_dropRectCount++;
			}
		}

		prevPoint = points[0];
	}
	//NSLog(@"rectcount %i, arraysize %i", _dropRectCount, _dropRectArraySize);
}

- (NSRect *)dropRectsWithCountPtr:(NSInteger *)pRectCount
{
	NSAssert(pRectCount != NULL, @"pRectCount is null");
	
	if (_dropRectsAreDirty)
		[self createDropRects];
	
	*pRectCount = _dropRectCount;
	return _dropRects;
}


- (void)connectFrom:(EDUICompInputView *)fromView to:(EDUICompInputView *)toView
{
    if ([fromView isEqual:toView])
        return;
    
	// check for custom connector colors
	BOOL useCustomStart = NO;
	id fromNode = [[fromView nodeView] node];
	if ([fromNode respondsToSelector:@selector(useCustomConnectorColorsForOutputs)]) {
		useCustomStart = [fromNode useCustomConnectorColorsForOutputs];
		
		if (useCustomStart) {
			NSInteger index = [fromView index];
			[self setStartColor:[fromNode customConnectorColorForOutputAtIndex:index]];
		}
	}
	
	BOOL useCustomEnd = NO;
	id toNode = [[toView nodeView] node];
	BOOL toViewIsParam = [toView isParameter];
	
	if (!toViewIsParam) {
		if ([toNode respondsToSelector:@selector(useCustomConnectorColorsForInputs)]) {
			useCustomEnd = [toNode useCustomConnectorColorsForInputs];
			
			if (useCustomEnd) {
				NSInteger index = [toView index];
				[self setEndColor:[toNode customConnectorColorForInputAtIndex:index]];
			}
		}
	} else {
		// input is a parameter input
		if ([toNode respondsToSelector:@selector(useCustomConnectorColorsForParameters)]) {
			useCustomEnd = [toNode useCustomConnectorColorsForParameters];
			
			if (useCustomEnd) {
				NSInteger index = [toView index];
				[self setEndColor:[toNode customConnectorColorForParameterAtIndex:index]];
			}
		}
	}
	
	_useGradient = (useCustomStart || useCustomEnd);
	
    //[_fromOutput autorelease];
    //[_toInput autorelease];
    _fromOutput = fromView; //[fromView retain];
    _toInput = toView; //[toView retain];
    _connected = YES;
	
	[self createDropRects];
}


- (void)refreshAppearance {
	// refreshes the connector colors
	if (_connected)
		[self connectFrom:_fromOutput to:_toInput];
}

- (void)nodesWereMoved
{
	_dropRectsAreDirty = YES;
}

- (void)setInput:(EDUICompInputView *)toView {
    _toInput = toView; }

- (void)clearConnection
{
    _fromOutput = nil;
    _toInput = nil;
    _connected = NO;
}

- (EDUICompInputView *)fromOutput {
	return _fromOutput; }
	
- (EDUICompInputView *)toInput {
	return _toInput; }

- (void)setUseGradient:(BOOL)grad {
	_useGradient = grad; }
	
- (BOOL)useGradient {
	return _useGradient; }
	
- (void)setStartColor:(NSColor *)color {
	[_startColor release];
	_startColor = [color retain];
}

- (void)setEndColor:(NSColor *)color {
	[_endColor release];
	_endColor = [color retain];
}

- (void)setHighlighted:(BOOL)hilite {
	_hilite = hilite; }
	
- (BOOL)isHighlighted {
	return _hilite; }


#pragma mark --- notes ---

- (void)setNote:(NSString *)note {
	_note = [note retain]; }
	
- (NSString *)note {
	return _note; }
	
- (void)setNotePosition:(float)pos {
	_notePos = pos; }
	
- (float)notePosition {
	return _notePos; }

+ (NSDictionary *)noteTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        attribs = [[NSMutableDictionary alloc] init];
        [attribs setObject:[NSFont boldSystemFontOfSize:9.0] forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.25 green:0.24 blue:0.28 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
					
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(1.5f, -1.5f)];
		[shadow setShadowBlurRadius:3.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.05f green:0.05f blue:0.07f alpha:0.27f]];
		
		[attribs setObject:shadow forKey:NSShadowAttributeName];

    }
    return attribs;
}

+ (NSDictionary *)noteWhiteTextAttributes
{
    static NSMutableDictionary *attribs = nil;
    
    if (!attribs) {
        attribs = [[NSMutableDictionary alloc] init];
        [attribs setObject:[NSFont boldSystemFontOfSize:9.0] forKey:NSFontAttributeName];    
        [attribs setObject:[NSColor colorWithDeviceRed:0.95 green:0.94 blue:0.98 alpha:1.0]
                    forKey:NSForegroundColorAttributeName];
					
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(1.5f, -1.5f)];
		[shadow setShadowBlurRadius:3.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.05f green:0.05f blue:0.07f alpha:0.67f]];
		
		[attribs setObject:shadow forKey:NSShadowAttributeName];

    }
    return attribs;
}


#define NOTEOFFSET_X 15.0f
#define NOTEOFFSET_Y -8.0f

- (NSRect)noteRect
{
	NSRect r;
	r.origin = [self pointAtPosition:fabs(_notePos)];
	r.origin.x += NOTEOFFSET_X;
	r.origin.y += NOTEOFFSET_Y;
	r.size = [_note sizeWithAttributes:[[self class] noteTextAttributes]];
	
    r.size.width = round(r.size.width);
    r.size.height = round(r.size.height);
    
	if (_notePos <= -0.0) {  // note is on left
		r.origin.x -= r.size.width + 2.0*NOTEOFFSET_X;
		r.origin.x -= 2.0f;
	}
	return r;
}


#pragma mark --- drawing ---

- (NSPoint)pointAtPosition:(float)pos
{
	if (_dropRectsAreDirty)
		[self createDropRects];

	if (_dropRectCount < 1)
		return NSZeroPoint;

    NSPoint start, end, cp1, cp2;	
	EDUICompositionView *compView = [[_fromOutput nodeView] compView];
	[self getStart:&start end:&end controlPoint1:&cp1 controlPoint2:&cp2 inView:(NSView *)compView];
	BOOL xIsNeg = (end.x < start.x);
	BOOL yIsNeg = (end.y < start.y);

	pos = MIN(1.0, MAX(0.0, pos));  // clamp to 0-1 range

	NSInteger i;
	float len = 0.0f;
	NSRect r;
	
	// calc total length of the connector
	for (i = 0; i < _dropRectCount; i++) {
		r = NSInsetRect(_dropRects[i], DROPRECTOUTSET_X, DROPRECTOUTSET_Y);
		float w = r.size.width;
		float h = r.size.height;
		len += sqrtf(w*w + h*h);
	}
	float lpos = len * pos;
	
	// find segment that contains the wanted position
	float al = 0.0f;
	
	for (i = 0; i < _dropRectCount; i++) {
		r = NSInsetRect(_dropRects[i], DROPRECTOUTSET_X, DROPRECTOUTSET_Y);
		
		float w = r.size.width;
		float h = r.size.height;
		float l = sqrtf(w*w + h*h);
		
		if ((al + l) >= lpos) {
			// this is the right segment
			float xp = (lpos - al) / l;
			float yp = xp;
			
			if (!xIsNeg)  xp = 1.0f - xp;
			if (!yIsNeg)  yp = 1.0f - yp;
			
			NSPoint segStart = r.origin;
			NSPoint segEnd;
			segEnd.x = segStart.x + w;
			segEnd.y = segStart.y + h;
			
			return NSMakePoint( (1.0f-xp) * segEnd.x + xp * segStart.x,
								(1.0f-yp) * segEnd.y + yp * segStart.y );
		}
		al += l;
	}
	
	return NSMakePoint(0, 0);	
}


#define MAXNOTEPOS 0.99f
#define MINNOTEPOS 0.03f

- (float)positionAtPoint:(NSPoint)wantedPoint
{
	float wantedX = wantedPoint.x;
	float wantedY = wantedPoint.y;
	
	if (_dropRectsAreDirty)
		[self createDropRects];

	if (_dropRectCount < 1)
		return 0.0;

    NSPoint start, end, cp1, cp2;	
	EDUICompositionView *compView = [[_fromOutput nodeView] compView];
	[self getStart:&start end:&end controlPoint1:&cp1 controlPoint2:&cp2 inView:(NSView *)compView];
	BOOL yIsNeg = (end.y < start.y);

	// check if wanted y position is beyond connector's bounds
	if (yIsNeg && wantedY <= end.y) {
		BOOL isOnLeft = wantedX < end.x;
		return (isOnLeft ? -MAXNOTEPOS : MAXNOTEPOS);
	}
	else if (yIsNeg && wantedY >= start.y) {
		BOOL isOnLeft = wantedX < start.x;
		return (isOnLeft ? -MINNOTEPOS : MINNOTEPOS);
	}
	else if (!yIsNeg && wantedY >= end.y) {
		BOOL isOnLeft = wantedX < end.x;
		return (isOnLeft ? -MAXNOTEPOS : MAXNOTEPOS);
	}
	else if (!yIsNeg && wantedY <= start.y) {
		BOOL isOnLeft = wantedX < start.x;
		return (isOnLeft ? -MINNOTEPOS : MINNOTEPOS);
	}

	NSInteger i;
	float len = 0.0f;
	NSRect r;
	
	// calc total length of the connector
	for (i = 0; i < _dropRectCount; i++) {
		r = NSInsetRect(_dropRects[i], DROPRECTOUTSET_X, DROPRECTOUTSET_Y);
		float w = r.size.width;
		float h = r.size.height;
		len += sqrtf(w*w + h*h);
	}

	// find segment that contains the wanted y position
	float al = 0.0f;
	
	for (i = 0; i < _dropRectCount; i++) {
		r = NSInsetRect(_dropRects[i], DROPRECTOUTSET_X, DROPRECTOUTSET_Y);
		float y = r.origin.y;
		float w = r.size.width;
		float h = r.size.height;
		float l = sqrtf(w*w + h*h);
		
		if (wantedY >= y && wantedY < (y+h)) {
			// wanted y position is within this rect
			float yp = (wantedY - y) / h;
			if (yIsNeg)
				yp = 1.0f - yp;
			
			BOOL isOnLeft = (wantedX < r.origin.x);
			float scale = isOnLeft ? -1.0 : 1.0;  // if point is to the left of the connector, return a negative value
			
			return scale * MAX(MINNOTEPOS,  MIN((yp*l + al) / len, MAXNOTEPOS));  // clamp within valid range
		}
		al += l;
	}
	return MAXNOTEPOS;
}

- (void)getShadowBaseColorRed:(float *)r green:(float *)g blue:(float *)b {
    *r = 0.18;
    *g = 0.18;
    *b = 0.18;
}

- (float)_defaultLineWidth {
    return 0.7;
}

- (void)drawInPath:(NSBezierPath *)path inView:(NSView *)view noteVisible:(BOOL)showNote
{
    NSPoint start, end, cp1, cp2;
	[self getStart:&start end:&end controlPoint1:&cp1 controlPoint2:&cp2 inView:view];
	
	NSColor *noteBgColor = nil;

	if (_hilite) {
		// draw highlighted
		NSBezierPath *gpath = [NSBezierPath bezierPath];
		
		[gpath moveToPoint:start];
		[gpath curveToPoint:end controlPoint1:cp1 controlPoint2:cp2 ];
		
		NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
		[shadow setShadowOffset:NSMakeSize(0.0f, 0.0f)];
		[shadow setShadowBlurRadius:8.0];
		[shadow setShadowColor:[NSColor colorWithDeviceRed:0.85f
													   green:0.89f
													   blue:1.0f
													   alpha:1.0f]];
		
		[NSGraphicsContext saveGraphicsState];
		[shadow set];

		noteBgColor = [NSColor colorWithDeviceRed:0.0f green:0.38f blue:0.87f alpha:1.0f];
		[noteBgColor set];
		
		[gpath setLineWidth:1.1];
		[gpath stroke];
		
		[NSGraphicsContext restoreGraphicsState];
	}

	else if (_useGradient && (_startColor || _endColor)) {
		// create a new path that we'll draw using the gradient colors
		NSBezierPath *gpath = [NSBezierPath bezierPath];
		
		[gpath moveToPoint:start];
		[gpath curveToPoint:end controlPoint1:cp1 controlPoint2:cp2 ];
		
		[NSBezierPath setDefaultFlatness:0.6];
		NSBezierPath *flatPath = [gpath bezierPathByFlatteningPath];
		
        ///NSLog(@"flatpath elemcount: %i", [flatPath elementCount]);
        
		CGFloat sr, sg, sb, sa;
		CGFloat er, eg, eb, ea;
		
		if (_startColor)
			[_startColor getRed:&sr green:&sg blue:&sb alpha:&sa];
		else {
			sr = 0; sg = 0; sb = 0; sa = 1; }
		
		if (_endColor)
			[_endColor getRed:&er green:&eg blue:&eb alpha:&ea];
		else {
			er = 0; eg = 0; eb = 0; ea = 1; }
		
		// create a drop shadow if the connector color is too light
		float slum = sr*0.2 + sg*0.7 + sb*0.1;
		float elum = er*0.2 + eg*0.7 + eb*0.1;
		float shadowOpacity = (MAX(slum, elum)) * 1.15 - 0.1;
		BOOL useShadow = NO;
		
        double defaultLineW = [self _defaultLineWidth];
		
		if (shadowOpacity > 0.0f) {
			useShadow = YES;
            
            float shadR, shadG, shadB;
            [self getShadowBaseColorRed:&shadR green:&shadG blue:&shadB];
			
			NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
			[shadow setShadowOffset:NSMakeSize(1.0f, -1.0f)];
			[shadow setShadowBlurRadius:2.0];
			[shadow setShadowColor:[NSColor colorWithDeviceRed:shadR * MAX(sr, er)
														   green:shadG * MAX(sg, eg)
														   blue:shadB * MAX(sb, eb)
														   alpha:shadowOpacity]];
			
			[NSGraphicsContext saveGraphicsState];
			[shadow set];
			
			[gpath setLineWidth:defaultLineW + 0.2*shadowOpacity];
		} else {
			// no shadow, use default line width
			[gpath setLineWidth:defaultLineW];
		}
		
		// get first point of flattened path
		NSPoint points[3];
		NSPoint firstPoint;
		[flatPath elementAtIndex:0 associatedPoints:&firstPoint];
		NSPoint prevPoint = firstPoint;
		
		// iterate through flattened path line segments
		NSInteger elems = [flatPath elementCount];
		NSInteger i;
		float cInc = 1.0 / (double)elems;
		
		NSInteger noteElem = 1 + (fabs(_notePos)*0.99f * (float)(elems - 1));
		
		for (i = 1; i < elems; i++) {
			[flatPath elementAtIndex:i associatedPoints:points];
			
			[gpath removeAllPoints];
			[gpath moveToPoint:prevPoint];
			[gpath lineToPoint:points[0]];
			
			// interpolate color
			float ci = (float)i * cInc;
			float cm = 1.0f - ci;
			NSColor *col =
				[NSColor colorWithDeviceRed:(sr*cm + er*ci) green:(sg*cm + eg*ci) blue:(sb*cm + eb*ci) alpha:(sa*cm + ea*ci)];	
			[col set];
			
			[gpath stroke];
			
			if (i == noteElem) {
				// this segment will set the note's background color
				noteBgColor = col;
			}
			
			prevPoint = points[0];
		}
		
		if (useShadow) {
			// pop previous graphics state
			[NSGraphicsContext restoreGraphicsState];
		}
	}

	else {
		// no gradient, so just draw into given path
		[path moveToPoint:start];
		[path curveToPoint:end controlPoint1:cp1 controlPoint2:cp2 ];
	}
	
	// draw note
	if (_note && showNote) {
		CGFloat noteBgAlpha = 0.75;
		if (!noteBgColor) {
			noteBgColor = [NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:noteBgAlpha];
		}
		else {
			CGFloat r, g, b, a;
			r = g = b = a = 1.0f;
			[noteBgColor getRed:&r green:&g blue:&b alpha:&a];
			noteBgColor = [NSColor colorWithDeviceRed:r green:g blue:b alpha:noteBgAlpha];
		}

		NSRect noteRect = [self noteRect];
		noteRect = NSInsetRect(noteRect, -1.0, -1.0);
		noteRect.origin.x += 2.0f;
		
		// make a path for note bg
		NSBezierPath *noteBgPath = [NSBezierPath bezierPath];
		float lMargin = 2.0f;
		float rMargin = 2.0f;
		float bMargin = 1.0f;
		float rRounding = 1.5f;
		float noteArrowX = NOTEOFFSET_X;
		float noteArrowY = NOTEOFFSET_Y;
		
		// check if note position is negative, which means the note should be displayed on the left side
		BOOL isOnLeft = _notePos <= -0.0;
		if (isOnLeft) {
			/*noteRect = NSMakeRect(noteRect.origin.x - noteArrowX*2.0f, noteRect.origin.y,
									-noteRect.size.width, noteRect.size.height);
			*/
			noteRect = NSMakeRect(noteRect.origin.x + noteRect.size.width, noteRect.origin.y,
									-noteRect.size.width, noteRect.size.height);
			lMargin = -lMargin;
			rMargin = -rMargin;
			rRounding = -rRounding;
			noteArrowX = -noteArrowX;
		}
		
		[noteBgPath moveToPoint:NSMakePoint(noteRect.origin.x - noteArrowX,  noteRect.origin.y - noteArrowY - 2.0f)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x-lMargin, noteRect.origin.y + noteRect.size.height)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x+noteRect.size.width+rMargin, noteRect.origin.y + noteRect.size.height)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x+noteRect.size.width+rMargin+rRounding, noteRect.origin.y + noteRect.size.height-1.5f)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x+noteRect.size.width+rMargin+rRounding, noteRect.origin.y-bMargin+1.5f)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x+noteRect.size.width+rMargin, noteRect.origin.y-bMargin)];
		[noteBgPath lineToPoint:NSMakePoint(noteRect.origin.x-lMargin, noteRect.origin.y-bMargin)];
		
		[noteBgColor set];
		[noteBgPath fill];

		CGFloat r, g, b, a;
		[noteBgColor getRed:&r green:&g blue:&b alpha:&a];
		float bglum = r*0.2 + g*0.7 + b*0.1;
		
		NSDictionary *noteLabelAttribs;
		if (bglum > 0.5)
			noteLabelAttribs = [[self class] noteTextAttributes];
		else
			noteLabelAttribs = [[self class] noteWhiteTextAttributes];

		[_note drawInRect:ValidateNSRect(noteRect) withAttributes:noteLabelAttribs];
	}
}


@end
