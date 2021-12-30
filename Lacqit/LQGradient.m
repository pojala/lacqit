//
//  LQGradient.m
//
//  "CTGradient" created by Chad Weider on 2/14/07.
//  Written by Chad Weider.
//
//  Released into public domain on 4/10/08.
//  Renamed to LQGradient by Pauli Ojala to avoid name collision
//
//  Version: 1.8

#import "LQGradient.h"


typedef struct LQGradientElement {
	CGFloat red, green, blue, alpha;
	CGFloat position;
	struct LQGradientElement *nextElement;
} LQGradientElement;



@interface LQGradient (Private)
- (void)_commonInit;
- (void)setBlendingMode:(LQGradientBlendingMode)mode;
- (void)addElement:(LQGradientElement*)newElement;

- (LQGradientElement *)elementAtIndex:(LXUInteger)index;

- (LQGradientElement)removeElementAtIndex:(LXUInteger)index;
- (LQGradientElement)removeElementAtPosition:(CGFloat)position;
@end


//C Fuctions for color blending
static void linearEvaluation   (void *info, const CGFloat *in, CGFloat *out);
static void chromaticEvaluation(void *info, const CGFloat *in, CGFloat *out);
static void inverseChromaticEvaluation(void *info, const CGFloat *in, CGFloat *out);
static void transformRGB_HSV(CGFloat *components);
static void transformHSV_RGB(CGFloat *components);
static void resolveHSV(CGFloat *color1, CGFloat *color2);


@implementation LQGradient

- (id)init
{
    self = [super init];
    
    if (self != nil)
	{
        [self _commonInit];
        [self setBlendingMode:kLQLinearBlendingMode];
	}
    return self;
}

- (void)_commonInit
{
    _elementList = NULL;
}

- (void)dealloc
{
#if (LQPLATFORM_QUARTZ)
    CGFunctionRelease(_gradientFunction);
#endif
    
    LQGradientElement *elementToRemove = _elementList;
    while(_elementList)
	{
        elementToRemove = _elementList;
        _elementList = _elementList->nextElement;
        _lx_free(elementToRemove);
	}
    
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    LQGradient *copy = [[[self class] allocWithZone:zone] init];
    
    //now just copy my elementlist
    LQGradientElement *currentElement = _elementList;
    while(currentElement)
	{
        [copy addElement:currentElement];
        currentElement = currentElement->nextElement;
	}
    
    [copy setBlendingMode:_blendingMode];
    [copy setGradientType:_gradientType];
    
    return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    if([coder allowsKeyedCoding])
	{
        LXUInteger count = 0;
        LQGradientElement *currentElement = _elementList;
        while(currentElement)
		{
            [coder encodeValueOfObjCType:@encode(CGFloat) at:&(currentElement->red)];
            [coder encodeValueOfObjCType:@encode(CGFloat) at:&(currentElement->green)];
            [coder encodeValueOfObjCType:@encode(CGFloat) at:&(currentElement->blue)];
            [coder encodeValueOfObjCType:@encode(CGFloat) at:&(currentElement->alpha)];
            [coder encodeValueOfObjCType:@encode(CGFloat) at:&(currentElement->position)];
            
            count++;
            currentElement = currentElement->nextElement;
		}
        [coder encodeInt:count forKey:@"LQ.elementCount"];
        [coder encodeInt:_blendingMode forKey:@"LQ.blendingMode"];
        [coder encodeInt:_gradientType forKey:@"LQ.gradientType"];
	}
}

- (id)initWithCoder:(NSCoder *)coder
{
    [self _commonInit];
    
    [self setGradientType:[coder decodeIntForKey:@"LQ.gradientType"]];
    [self setBlendingMode:[coder decodeIntForKey:@"LQ.blendingMode"]];
    LXUInteger count = [coder decodeIntForKey:@"LQ.elementCount"];
    
    while(count != 0)
	{
        LQGradientElement newElement;
        
        [coder decodeValueOfObjCType:@encode(CGFloat) at:&(newElement.red)];
        [coder decodeValueOfObjCType:@encode(CGFloat) at:&(newElement.green)];
        [coder decodeValueOfObjCType:@encode(CGFloat) at:&(newElement.blue)];
        [coder decodeValueOfObjCType:@encode(CGFloat) at:&(newElement.alpha)];
        [coder decodeValueOfObjCType:@encode(CGFloat) at:&(newElement.position)];
        
        count--;
        [self addElement:&newElement];
	}
    return self;
}


#pragma mark -



#pragma mark Creation
+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  LQGradientElement color2;
  
  [[begin colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&color1.red
															   green:&color1.green
																blue:&color1.blue
															   alpha:&color1.alpha];
  
  [[end   colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&color2.red
															   green:&color2.green
																blue:&color2.blue
															   alpha:&color2.alpha];  
  color1.position = 0;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)aquaSelectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red   = 0.58;
  color1.green = 0.86;
  color1.blue  = 0.98;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red   = 0.42;
  color2.green = 0.68;
  color2.blue  = 0.90;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  LQGradientElement color3;
  color3.red   = 0.64;
  color3.green = 0.80;
  color3.blue  = 0.94;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  LQGradientElement color4;
  color4.red   = 0.56;
  color4.green = 0.70;
  color4.blue  = 0.90;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)aquaNormalGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.95;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.83;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  LQGradientElement color3;
  color3.red = color3.green = color3.blue  = 0.95;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  LQGradientElement color4;
  color4.red = color4.green = color4.blue  = 0.92;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)aquaPressedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.80;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.64;
  color2.alpha = 1.00;
  color2.position = 11.5/23;
  
  LQGradientElement color3;
  color3.red = color3.green = color3.blue  = 0.80;
  color3.alpha = 1.00;
  color3.position = 11.5/23;
  
  LQGradientElement color4;
  color4.red = color4.green = color4.blue  = 0.77;
  color4.alpha = 1.00;
  color4.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  [newInstance addElement:&color3];
  [newInstance addElement:&color4];
  
  return [newInstance autorelease];
  }

+ (id)unifiedSelectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.85;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.95;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedNormalGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.75;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.90;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedPressedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.60;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.75;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)unifiedDarkGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red = color1.green = color1.blue  = 0.68;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red = color2.green = color2.blue  = 0.83;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)sourceListSelectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red   = 0.06;
  color1.green = 0.37;
  color1.blue  = 0.85;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red   = 0.30;
  color2.green = 0.60;
  color2.blue  = 0.92;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)sourceListUnselectedGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red   = 0.43;
  color1.green = 0.43;
  color1.blue  = 0.43;
  color1.alpha = 1.00;
  color1.position = 0;
  
  LQGradientElement color2;
  color2.red   = 0.60;
  color2.green = 0.60;
  color2.blue  = 0.60;
  color2.alpha = 1.00;
  color2.position = 1;
  
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  return [newInstance autorelease];
  }

+ (id)rainbowGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement color1;
  color1.red   = 1.00;
  color1.green = 0.00;
  color1.blue  = 0.00;
  color1.alpha = 1.00;
  color1.position = 0.0;
  
  LQGradientElement color2;
  color2.red   = 0.54;
  color2.green = 0.00;
  color2.blue  = 1.00;
  color2.alpha = 1.00;
  color2.position = 1.0;
    
  [newInstance addElement:&color1];
  [newInstance addElement:&color2];
  
  [newInstance setBlendingMode:kLQChromaticBlendingMode];
  
  return [newInstance autorelease];
  }

+ (id)hydrogenSpectrumGradient
  {
  id newInstance = [[[self class] alloc] init];
  
  struct {CGFloat hue; CGFloat position; CGFloat width;} colorBands[4];
  
  colorBands[0].hue = 22;
  colorBands[0].position = .145;
  colorBands[0].width = .01;
  
  colorBands[1].hue = 200;
  colorBands[1].position = .71;
  colorBands[1].width = .008;
  
  colorBands[2].hue = 253;
  colorBands[2].position = .885;
  colorBands[2].width = .005;
  
  colorBands[3].hue = 275;
  colorBands[3].position = .965;
  colorBands[3].width = .003;
  
  int i;
  /////////////////////////////
  for(i = 0; i < 4; i++)
	{	
	CGFloat color[4];
	color[0] = colorBands[i].hue - 180*colorBands[i].width;
	color[1] = 1;
	color[2] = 0.001;
	color[3] = 1;
	transformHSV_RGB(color);
	LQGradientElement fadeIn;
	fadeIn.red   = color[0];
	fadeIn.green = color[1];
	fadeIn.blue  = color[2];
	fadeIn.alpha = color[3];
	fadeIn.position = colorBands[i].position - colorBands[i].width;
	
	
	color[0] = colorBands[i].hue;
	color[1] = 1;
	color[2] = 1;
	color[3] = 1;
	transformHSV_RGB(color);
	LQGradientElement band;
	band.red   = color[0];
	band.green = color[1];
	band.blue  = color[2];
	band.alpha = color[3];
	band.position = colorBands[i].position;
	
	color[0] = colorBands[i].hue + 180*colorBands[i].width;
	color[1] = 1;
	color[2] = 0.001;
	color[3] = 1;
	transformHSV_RGB(color);
	LQGradientElement fadeOut;
	fadeOut.red   = color[0];
	fadeOut.green = color[1];
	fadeOut.blue  = color[2];
	fadeOut.alpha = color[3];
	fadeOut.position = colorBands[i].position + colorBands[i].width;
	
	
	[newInstance addElement:&fadeIn];
	[newInstance addElement:&band];
	[newInstance addElement:&fadeOut];
	}
  
  [newInstance setBlendingMode:kLQChromaticBlendingMode];
  
  return [newInstance autorelease];
  }

#pragma mark -



#pragma mark Modification
- (LQGradient *)gradientWithAlphaComponent:(CGFloat)alpha
  {
  id newInstance = [[[self class] alloc] init];
  
  LQGradientElement *curElement = _elementList;
  LQGradientElement tempElement;

  while(curElement != nil)
	{
	tempElement = *curElement;
	tempElement.alpha = alpha;
	[newInstance addElement:&tempElement];
	
	curElement = curElement->nextElement;
	}
  
  return [newInstance autorelease];
  }

- (LQGradient *)gradientWithBlendingMode:(LQGradientBlendingMode)mode
  {
  LQGradient *newGradient = [self copy];  
  
  [newGradient setBlendingMode:mode];
  
  return [newGradient autorelease];
  }


//Adds a color stop with <color> at <position> in _elementList
//(if two elements are at the same position then added imediatly after the one that was there already)
- (LQGradient *)gradientByAddingColorStop:(NSColor *)color atPosition:(CGFloat)position
  {
  LQGradient *newGradient = [self copy];
  LQGradientElement newGradientElement;
  
  //put the components of color into the newGradientElement - must make sure it is a RGB color (not Gray or CMYK) 
  [[color colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&newGradientElement.red
															   green:&newGradientElement.green
																blue:&newGradientElement.blue
															   alpha:&newGradientElement.alpha];
  newGradientElement.position = position;
      
  //Pass it off to addElement to take care of adding it to the _elementList
  [newGradient addElement:&newGradientElement];
  
  return [newGradient autorelease];
  }


//Removes the color stop at <position> from _elementList
- (LQGradient *)gradientByRemovingColorStopAtPosition:(CGFloat)position
  {
  LQGradient *newGradient = [self copy];
  LQGradientElement removedElement = [newGradient removeElementAtPosition:position];
  
  if(isnan(removedElement.position))
	[NSException raise:NSRangeException format:@"-[%@ removeColorStopAtPosition:]: no such colorStop at position (%f)", [self class], position];
  
  return [newGradient autorelease];
  }

- (LQGradient *)gradientByRemovingColorStopAtIndex:(LXUInteger)index
  {
  LQGradient *newGradient = [self copy];
  LQGradientElement removedElement = [newGradient removeElementAtIndex:index];
  
  if(isnan(removedElement.position))
	[NSException raise:NSRangeException format:@"-[%@ removeColorStopAtIndex:]: index (%ld) beyond bounds", [self class], (long)index];
  
  return [newGradient autorelease];
  }
#pragma mark -


- (void)setGradientType:(LQGradientType)type {  
    _gradientType = type; }



#pragma mark Information

- (LQGradientType)gradientType {
    return _gradientType; }
    

- (LQGradientBlendingMode)blendingMode
  {
  return _blendingMode;
  }


- (LXUInteger)numberOfColorStops
{
  LXUInteger count = 0;
  LQGradientElement *currentElement = _elementList;
  
  while(currentElement)
	{
	count++;
	currentElement = currentElement->nextElement;
	}
    
  return count;
}


//Returns color at <position> in gradient
- (NSColor *)colorStopAtIndex:(LXUInteger)index
  {
  LQGradientElement *element = [self elementAtIndex:index];
  
  if(element != nil)
	return [NSColor colorWithCalibratedRed:element->red 
									 green:element->green
									  blue:element->blue
									 alpha:element->alpha];
  
  [NSException raise:NSRangeException format:@"-[%@ colorStopAtIndex:]: index (%ld) beyond bounds", [self class], (long)index];
  
  return nil;
  }

- (CGFloat)positionOfColorStopAtIndex:(LXUInteger)index
{
    LQGradientElement *element = [self elementAtIndex:index];
    
    if(element != nil)
        return element->position;
    
    [NSException raise:NSRangeException format:@"-[%@ positionOfColorStopAtIndex:]: index (%ld) beyond bounds", [self class], (long)index];
    
    return 0.0;
}

- (NSColor *)colorAtPosition:(CGFloat)position
  {
  CGFloat components[4];
  
  switch(_blendingMode)
	{
	case kLQLinearBlendingMode:
		 linearEvaluation(&_elementList, &position, components);				break;
	case kLQChromaticBlendingMode:
		 chromaticEvaluation(&_elementList, &position, components);			break;
	case kLQInverseChromaticBlendingMode:
		 inverseChromaticEvaluation(&_elementList, &position, components);	break;
	}
  
      CGFloat a = components[3];
      if (a <= 0.0) {
          return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0];
      } else {
          return [NSColor colorWithCalibratedRed:components[0]/a	//undo premultiplication that CG requires
                                           green:components[1]/a
                                            blue:components[2]/a
                                           alpha:a];
      }
  
  }
#pragma mark -


#pragma mark Cairo support

- (void)_fillCairoPattern:(cairo_pattern_t *)pat
{
    LQGradientElement *el = _elementList;
  
    while (el) {
        ///NSLog(@"%s: adding pos %.3f:  %.3f, %.3f, %.3f, %.3f", __func__, el->position, el->red, el->green, el->blue, el->alpha);
        
        CGFloat a = el->alpha;
        CGFloat r, g, b;
        r = el->red;
        g = el->green;
        b = el->blue;
        
        cairo_pattern_add_color_stop_rgba(pat, el->position,  r, g, b, a);
        
        el = el->nextElement;
	}
}


- (cairo_pattern_t *)createLinearCairoPatternFromPoint:(NSPoint)p1 toPoint:(NSPoint)p2
{
    cairo_pattern_t *pattern = cairo_pattern_create_linear(p1.x, p1.y,  p2.x, p2.y);
    
    [self _fillCairoPattern:pattern];
    
    return pattern;
}

- (cairo_pattern_t *)createRadialCairoPatternFromPoint:(NSPoint)p1 toPoint:(NSPoint)p2 radius1:(double)radi1 radius2:(double)radi2
{
    cairo_pattern_t *pattern = cairo_pattern_create_radial(p1.x, p1.y, radi1,   p2.x, p2.y, radi2);
    
    [self _fillCairoPattern:pattern];
    
    return pattern;
    
}



#pragma mark -

#pragma mark Drawing

#if (LQPLATFORM_QUARTZ)

- (void)drawSwatchInRect:(NSRect)rect
  {
  [self fillRect:rect angle:45];
  }

- (void)fillRect:(NSRect)rect angle:(CGFloat)angle
  {
  //First Calculate where the beginning and ending points should be
  CGPoint startPoint;
  CGPoint endPoint;
  
  if(angle == 0)		//screw the calculations - we know the answer
  	{
  	startPoint = CGPointMake(NSMinX(rect), NSMinY(rect));	//right of rect
  	endPoint   = CGPointMake(NSMaxX(rect), NSMinY(rect));	//left  of rect
  	}
  else if(angle == 90)	//same as above
  	{
  	startPoint = CGPointMake(NSMinX(rect), NSMinY(rect));	//bottom of rect
  	endPoint   = CGPointMake(NSMinX(rect), NSMaxY(rect));	//top    of rect
  	}
  else						//ok, we'll do the calculations now 
  	{
  	CGFloat x,y;
  	CGFloat sina, cosa, tana;
  	
  	CGFloat length;
  	CGFloat deltax,
  		  deltay;
	
  	CGFloat rangle = angle * M_PI/180;	//convert the angle to radians
	
  	if(fabsf(tan(rangle))<=1)	//for range [-45,45], [135,225]
		{
		x = NSWidth(rect);
		y = NSHeight(rect);
		
		sina = sin(rangle);
		cosa = cos(rangle);
		tana = tan(rangle);
		
		length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
		
		deltax = length*cosa/2;
		deltay = length*sina/2;
		}
	else						//for range [45,135], [225,315]
		{
		x = NSHeight(rect);
		y = NSWidth(rect);
		
		sina = sin(rangle - 90*M_PI/180);
		cosa = cos(rangle - 90*M_PI/180);
		tana = tan(rangle - 90*M_PI/180);
		
		length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
		
		deltax =-length*sina/2;
		deltay = length*cosa/2;
		}
  
	startPoint = CGPointMake(NSMidX(rect)-deltax, NSMidY(rect)-deltay);
	endPoint   = CGPointMake(NSMidX(rect)+deltax, NSMidY(rect)+deltay);
	}
  
  //Calls to CoreGraphics
  CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(currentContext);
	  #if defined(__APPLE__) && (MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_4)
		CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	  #else
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	  #endif
	  CGShadingRef myCGShading = CGShadingCreateAxial(colorspace, startPoint, endPoint, _gradientFunction, false, false);
	  
	  CGContextClipToRect (currentContext, *(CGRect *)&rect);	//This is where the action happens
	  CGContextDrawShading(currentContext, myCGShading);
	  
	  CGShadingRelease(myCGShading);
	  CGColorSpaceRelease(colorspace );
  CGContextRestoreGState(currentContext);
  }

- (void)radialFillRect:(NSRect)rect
  {
  CGPoint startPoint, endPoint;
  CGFloat startRadius, endRadius;
  CGFloat scalex, scaley, transx, transy;
  
  startPoint = endPoint = CGPointMake(NSMidX(rect), NSMidY(rect));
  
  startRadius = -1;
  if(NSHeight(rect)>NSWidth(rect))
	{
	scalex = NSWidth(rect)/NSHeight(rect);
	transx = (NSHeight(rect)-NSWidth(rect))/2;
	scaley = 1;
	transy = 1;
	endRadius = NSHeight(rect)/2;
	}
  else
	{
	scalex = 1;
	transx = 1;
	scaley = NSHeight(rect)/NSWidth(rect);
	transy = (NSWidth(rect)-NSHeight(rect))/2;
	endRadius = NSWidth(rect)/2;
	}
  
  //Calls to CoreGraphics
  CGContextRef currentContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
  CGContextSaveGState(currentContext);
	  #if defined(__APPLE__) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_4)
		CGColorSpaceRef colorspace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	  #else
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	  #endif
  	  CGShadingRef myCGShading = CGShadingCreateRadial(colorspace, startPoint, startRadius, endPoint, endRadius, _gradientFunction, true, true);

	  CGContextClipToRect  (currentContext, *(CGRect *)&rect);
	  CGContextScaleCTM    (currentContext, scalex, scaley);
	  CGContextTranslateCTM(currentContext, transx, transy);
	  CGContextDrawShading (currentContext, myCGShading);		//This is where the action happens
	  
	  CGShadingRelease(myCGShading);
	  CGColorSpaceRelease(colorspace);
  CGContextRestoreGState(currentContext);
  }

- (void)fillBezierPath:(NSBezierPath *)path angle:(CGFloat)angle
  {
  NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
  [currentContext saveGraphicsState];
	NSAffineTransform *transform = [[NSAffineTransform alloc] init];
	
	[transform rotateByDegrees:-angle];
	[path transformUsingAffineTransform:transform];
	[transform invert];
	[transform concat];
	
	[path addClip];
	[self fillRect:[path bounds] angle:0];
	[path transformUsingAffineTransform:transform];
	[transform release];
  [currentContext restoreGraphicsState];
  }
- (void)radialFillBezierPath:(NSBezierPath *)path
  {
  NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
  [currentContext saveGraphicsState];
	[path addClip];
	[self radialFillRect:[path bounds]];
  [currentContext restoreGraphicsState];
  }

#endif // LQPLATFORM_QUARTZ  
  
#pragma mark -


static void releaseCallback(void *info) {
    if ( !info) return;

    LQGradient *grad = (LQGradient *)info;
    [grad release];
}


#pragma mark Private Methods

- (LQGradientElementPtr)_elementListFirstItem
{
    return _elementList;
}

- (void)setBlendingMode:(LQGradientBlendingMode)mode;
  {
  _blendingMode = mode;
  
  //Choose what blending function to use
  void *evaluationFunction;
  switch(_blendingMode)
	{
	case kLQLinearBlendingMode:
		 evaluationFunction = &linearEvaluation;			break;
	case kLQChromaticBlendingMode:
		 evaluationFunction = &chromaticEvaluation;			break;
	case kLQInverseChromaticBlendingMode:
		 evaluationFunction = &inverseChromaticEvaluation;	break;
	}

#if (LQPLATFORM_QUARTZ)  
  //replace the current CoreGraphics Function with new one
  if(_gradientFunction != NULL)
	  CGFunctionRelease(_gradientFunction);
    
      CGFunctionCallbacks evaluationCallbackInfo = {0 , evaluationFunction, releaseCallback};	//Version, evaluator function, cleanup function
  
      static const CGFloat input_value_range   [2] = { 0, 1 };						//range  for the evaluator input
      static const CGFloat output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };		//ranges for the evaluator output (4 returned values)
          
      LQGradient *mySelf = [self retain]; // released by releaseCallback
  
      _gradientFunction = CGFunctionCreate(mySelf,					//provides the two transition colors
									  1, input_value_range,		//number of inputs (just fraction of progression)
									  4, output_value_ranges,		//number of outputs (4 - RGBa)
									  &evaluationCallbackInfo);		//info for using the evaluator function
#endif
  }
  

- (void)addElement:(LQGradientElement *)newElement
  {
  if(_elementList == nil || newElement->position < _elementList->position)	//inserting at beginning of list
	{
	LQGradientElement *tmpNext = _elementList;
	_elementList = _lx_malloc(sizeof(LQGradientElement));
	*_elementList = *newElement;
    _elementList->nextElement = tmpNext;
	}
  else																		//inserting somewhere inside list
	{
	LQGradientElement *curElement = _elementList;
	
	while(curElement->nextElement != nil && !((curElement->position <= newElement->position) && (newElement->position < curElement->nextElement->position)))
		{
		curElement = curElement->nextElement;
		}
	
	LQGradientElement *tmpNext = curElement->nextElement;
	curElement->nextElement = _lx_malloc(sizeof(LQGradientElement));
	*(curElement->nextElement) = *newElement;
	curElement->nextElement->nextElement = tmpNext;
	}
  }

- (LQGradientElement)removeElementAtIndex:(LXUInteger)index
  {
  LQGradientElement removedElement;
  
  if(_elementList != nil)
	{
	if(index == 0)
		{
		LQGradientElement *tmpNext = _elementList;
		_elementList = _elementList->nextElement;
		
		removedElement = *tmpNext;
		_lx_free(tmpNext);
		
		return removedElement;
		}
	
	LXUInteger count = 1;		//we want to start one ahead
	LQGradientElement *currentElement = _elementList;
	while(currentElement->nextElement != nil)
		{
		if(count == index)
			{
			LQGradientElement *tmpNext  = currentElement->nextElement;
			currentElement->nextElement = currentElement->nextElement->nextElement;
			
			removedElement = *tmpNext;
			_lx_free(tmpNext);

			return removedElement;
			}

		count++;
		currentElement = currentElement->nextElement;
		}
	}
  
  //element is not found, return empty element
  removedElement.red   = 0.0;
  removedElement.green = 0.0;
  removedElement.blue  = 0.0;
  removedElement.alpha = 0.0;
  removedElement.position = NAN;
  removedElement.nextElement = nil;
  
  return removedElement;
  }

- (LQGradientElement)removeElementAtPosition:(CGFloat)position
  {
  LQGradientElement removedElement;
  
  if(_elementList != nil)
	{
	if(_elementList->position == position)
		{
		LQGradientElement *tmpNext = _elementList;
		_elementList = _elementList->nextElement;
		
		removedElement = *tmpNext;
		_lx_free(tmpNext);
		
		return removedElement;
		}
	else
		{
		LQGradientElement *curElement = _elementList;
		while(curElement->nextElement != nil)
			{
			if(curElement->nextElement->position == position)
				{
				LQGradientElement *tmpNext = curElement->nextElement;
				curElement->nextElement = curElement->nextElement->nextElement;
				
				removedElement = *tmpNext;
				_lx_free(tmpNext);

				return removedElement;
				}
			}
		}
	}
  
  //element is not found, return empty element
  removedElement.red   = 0.0;
  removedElement.green = 0.0;
  removedElement.blue  = 0.0;
  removedElement.alpha = 0.0;
  removedElement.position = NAN;
  removedElement.nextElement = nil;
  
  return removedElement;
  }


- (LQGradientElement *)elementAtIndex:(LXUInteger)index;			
  {
  LXUInteger count = 0;
  LQGradientElement *currentElement = _elementList;
  
  while(currentElement != nil)
	{
	if(count == index)
		return currentElement;
	
	count++;
	currentElement = currentElement->nextElement;
	}
  
  return nil;
  }
#pragma mark -


#pragma mark blending
//////////////////////////////////////Blending Functions/////////////////////////////////////
void linearEvaluation (void *info, const CGFloat *in, CGFloat *out)
  {
  CGFloat position = *in;
    
  LQGradient *grad = (LQGradient *)info;
  LQGradientElementPtr elemList = [grad _elementListFirstItem];
    
  if(elemList == nil)	//if _elementList is empty return clear color
	{
	out[0] = out[1] = out[2] = out[3] = 1;
	return;
	}
  
  //This grabs the first two colors in the sequence
    LQGradientElement *color1 = elemList;
  LQGradientElement *color2 = color1->nextElement;
  
  //make sure first color and second color are on other sides of position
  while(color2 != nil && color2->position < position)
  	{
  	color1 = color2;
  	color2 = color1->nextElement;
  	}
  //if we don't have another color then make next color the same color
  if(color2 == nil)
    {
	color2 = color1;
    }
  
  //----------FailSafe settings----------
  //color1->red   = 1; color2->red   = 0;
  //color1->green = 1; color2->green = 0;
  //color1->blue  = 1; color2->blue  = 0;
  //color1->alpha = 1; color2->alpha = 1;
  //color1->position = .5;
  //color2->position = .5;
  //-------------------------------------
  
  if(position <= color1->position)			//Make all below color color1's position equal to color1
  	{
  	out[0] = color1->red; 
  	out[1] = color1->green;
  	out[2] = color1->blue;
  	out[3] = color1->alpha;
  	}
  else if (position >= color2->position)	//Make all above color color2's position equal to color2
  	{
  	out[0] = color2->red; 
  	out[1] = color2->green;
  	out[2] = color2->blue;
  	out[3] = color2->alpha;
  	}
  else										//Interpolate color at postions between color1 and color1
  	{
  	//adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
	position = (position-color1->position)/(color2->position - color1->position);
	
	out[0] = (color2->red   - color1->red  )*position + color1->red; 
  	out[1] = (color2->green - color1->green)*position + color1->green;
  	out[2] = (color2->blue  - color1->blue )*position + color1->blue;
  	out[3] = (color2->alpha - color1->alpha)*position + color1->alpha;
	}
  
  //Premultiply the color by the alpha.
  out[0] *= out[3];
  out[1] *= out[3];
  out[2] *= out[3];
  }




//Chromatic Evaluation - 
//	This blends colors by their Hue, Saturation, and Value(Brightness) right now I just 
//	transform the RGB values stored in the LQGradientElements to HSB, in the future I may
//	streamline it to avoid transforming in and out of HSB colorspace *for later*
//
//	For the chromatic blend we shift the hue of color1 to meet the hue of color2. To do
//	this we will add to the hue's angle (if we subtract we'll be doing the inverse
//	chromatic...scroll down more for that). All we need to do is keep adding to the hue
//  until we wrap around the colorwheel and get to color2.
void chromaticEvaluation(void *info, const CGFloat *in, CGFloat *out)
  {
  CGFloat position = *in;
  
  LQGradient *grad = (LQGradient *)info;
  LQGradientElement *elemList = [grad _elementListFirstItem];

  if(elemList == nil)	//if _elementList is empty return clear color
	{
	out[0] = out[1] = out[2] = out[3] = 1;
	return;
	}
  
  //This grabs the first two colors in the sequence
  LQGradientElement *color1 = elemList;
  LQGradientElement *color2 = color1->nextElement;
  
  CGFloat c1[4];
  CGFloat c2[4];
    
  //make sure first color and second color are on other sides of position
  while(color2 != nil && color2->position < position)
  	{
  	color1 = color2;
  	color2 = color1->nextElement;
  	}
  //if we don't have another color then make next color the same color
  if(color2 == nil)
    {
	color2 = color1;
    }
  
  
  c1[0] = color1->red; 
  c1[1] = color1->green;
  c1[2] = color1->blue;
  c1[3] = color1->alpha;
  
  c2[0] = color2->red; 
  c2[1] = color2->green;
  c2[2] = color2->blue;
  c2[3] = color2->alpha;
  
  transformRGB_HSV(c1);
  transformRGB_HSV(c2);
  resolveHSV(c1,c2);
  
  if(c1[0] > c2[0]) //if color1's hue is higher than color2's hue then 
	 c2[0] += 360;	//	we need to move c2 one revolution around the wheel
  
  
  if(position <= color1->position)			//Make all below color color1's position equal to color1
  	{
  	out[0] = c1[0]; 
  	out[1] = c1[1];
  	out[2] = c1[2];
  	out[3] = c1[3];
  	}
  else if (position >= color2->position)	//Make all above color color2's position equal to color2
  	{
  	out[0] = c2[0]; 
  	out[1] = c2[1];
  	out[2] = c2[2];
  	out[3] = c2[3];
  	}
  else										//Interpolate color at postions between color1 and color1
  	{
  	//adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
	position = (position-color1->position)/(color2->position - color1->position);
	
	out[0] = (c2[0] - c1[0])*position + c1[0]; 
  	out[1] = (c2[1] - c1[1])*position + c1[1];
  	out[2] = (c2[2] - c1[2])*position + c1[2];
  	out[3] = (c2[3] - c1[3])*position + c1[3];
  	}
    
  transformHSV_RGB(out);
  
  //Premultiply the color by the alpha.
  out[0] *= out[3];
  out[1] *= out[3];
  out[2] *= out[3];
  }



//Inverse Chromatic Evaluation - 
//	Inverse Chromatic is about the same story as Chromatic Blend, but here the Hue
//	is strictly decreasing, that is we need to get from color1 to color2 by decreasing
//	the 'angle' (i.e. 90º -> 180º would be done by subtracting 270º and getting -180º...
//	which is equivalent to 180º mod 360º
void inverseChromaticEvaluation(void *info, const CGFloat *in, CGFloat *out)
  {
    CGFloat position = *in;

  LQGradient *grad = (LQGradient *)info;
  LQGradientElement *elemList = [grad _elementListFirstItem];

  if(elemList == nil)	//if _elementList is empty return clear color
	{
	out[0] = out[1] = out[2] = out[3] = 1;
	return;
	}
  
  //This grabs the first two colors in the sequence
  LQGradientElement *color1 = elemList;
  LQGradientElement *color2 = color1->nextElement;
  
  CGFloat c1[4];
  CGFloat c2[4];
      
  //make sure first color and second color are on other sides of position
  while(color2 != nil && color2->position < position)
  	{
  	color1 = color2;
  	color2 = color1->nextElement;
  	}
  //if we don't have another color then make next color the same color
  if(color2 == nil)
    {
	color2 = color1;
    }

  c1[0] = color1->red; 
  c1[1] = color1->green;
  c1[2] = color1->blue;
  c1[3] = color1->alpha;
  
  c2[0] = color2->red; 
  c2[1] = color2->green;
  c2[2] = color2->blue;
  c2[3] = color2->alpha;

  transformRGB_HSV(c1);
  transformRGB_HSV(c2);
  resolveHSV(c1,c2);

  if(c1[0] < c2[0]) //if color1's hue is higher than color2's hue then 
	 c1[0] += 360;	//	we need to move c2 one revolution back on the wheel

  
  if(position <= color1->position)			//Make all below color color1's position equal to color1
  	{
  	out[0] = c1[0]; 
  	out[1] = c1[1];
  	out[2] = c1[2];
  	out[3] = c1[3];
  	}
  else if (position >= color2->position)	//Make all above color color2's position equal to color2
  	{
  	out[0] = c2[0]; 
  	out[1] = c2[1];
  	out[2] = c2[2];
  	out[3] = c2[3];
  	}
  else										//Interpolate color at postions between color1 and color1
  	{
  	//adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
	position = (position-color1->position)/(color2->position - color1->position);
	
	out[0] = (c2[0] - c1[0])*position + c1[0]; 
  	out[1] = (c2[1] - c1[1])*position + c1[1];
  	out[2] = (c2[2] - c1[2])*position + c1[2];
  	out[3] = (c2[3] - c1[3])*position + c1[3];
  	}
    
  transformHSV_RGB(out);
  
  //Premultiply the color by the alpha.
  out[0] *= out[3];
  out[1] *= out[3];
  out[2] *= out[3];
  }


void transformRGB_HSV(CGFloat *components) //H,S,B -> R,G,B
	{
	CGFloat H, S, V;
	CGFloat R = components[0],
		  G = components[1],
		  B = components[2];
	
	CGFloat MAX = R > G ? (R > B ? R : B) : (G > B ? G : B),
	      MIN = R < G ? (R < B ? R : B) : (G < B ? G : B);
	
	if(MAX == MIN)
		H = NAN;
	else if(MAX == R)
		if(G >= B)
			H = 60*(G-B)/(MAX-MIN)+0;
		else
			H = 60*(G-B)/(MAX-MIN)+360;
	else if(MAX == G)
		H = 60*(B-R)/(MAX-MIN)+120;
	else if(MAX == B)
		H = 60*(R-G)/(MAX-MIN)+240;
	
	S = MAX == 0 ? 0 : 1 - MIN/MAX;
	V = MAX;
	
	components[0] = H;
	components[1] = S;
	components[2] = V;
	}

void transformHSV_RGB(CGFloat *components) //H,S,B -> R,G,B
	{
	CGFloat R, G, B;
	CGFloat H = fmodf(components[0],359),	//map to [0,360)
		  S = components[1],
		  V = components[2];
	
	int   Hi = (int)floorf(H/60.) % 6;
	CGFloat f  = H/60-Hi,
		  p  = V*(1-S),
		  q  = V*(1-f*S),
		  t  = V*(1-(1-f)*S);
	
	switch (Hi)
		{
		case 0:	R=V;G=t;B=p;	break;
		case 1:	R=q;G=V;B=p;	break;
		case 2:	R=p;G=V;B=t;	break;
		case 3:	R=p;G=q;B=V;	break;
		case 4:	R=t;G=p;B=V;	break;
		case 5:	R=V;G=p;B=q;	break;
		}
	
	components[0] = R;
	components[1] = G;
	components[2] = B;
	}

void resolveHSV(CGFloat *color1, CGFloat *color2)	//H value may be undefined (i.e. graycale color)
	{											//	we want to fill it with a sensible value
	if(isnan(color1[0]) && isnan(color2[0]))
		color1[0] = color2[0] = 0;
	else if(isnan(color1[0]))
		color1[0] = color2[0];
	else if(isnan(color2[0]))
		color2[0] = color1[0];
	}

@end
