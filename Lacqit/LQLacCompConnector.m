//
//  LQLacCompConnector.m
//  Lacqit
//
//  Created by Pauli Ojala on 5.9.2008.
//  Copyright 2008 Lacquer oy/ltd. All rights reserved.
//

#import "LQLacCompConnector.h"
#import "LQStreamNode.h"


@implementation LQLacCompConnector


- (void)connectFrom:(EDUICompInputView *)fromView to:(EDUICompInputView *)toView
{
    [super connectFrom:fromView to:toView];
    
    NSUInteger startType = [fromView type];
    NSUInteger endType = [toView type];
    
    BOOL isImageConn = (startType == kLQStreamNodeConnectionType_Image);
    
    NSColor *startC = (isImageConn) ? [NSColor colorWithDeviceRed:0.16 green:0.93 blue:0.42 alpha:0.84]
                                    : //[NSColor colorWithDeviceRed:0.93 green:0.26 blue:0.42 alpha:0.84];
                                        [NSColor colorWithDeviceRed:0.43 green:0.36 blue:0.92 alpha:0.9];
                                      
    NSColor *endC =   (isImageConn) ? [NSColor colorWithDeviceRed:0.3 green:0.95 blue:1.0 alpha:0.97]
                                    : //[NSColor colorWithDeviceRed:0.95 green:0.38 blue:1.0 alpha:1.0];
                                        [NSColor colorWithDeviceRed:0.65 green:0.53 blue:1.0 alpha:1.0];
    
    [self setStartColor:startC];
    [self setEndColor:endC];

    //[self setStartColor:[NSColor colorWithDeviceRed:0.3 green:0.95 blue:1.0 alpha:0.98]];    
    //[self setEndColor:[NSColor colorWithDeviceRed:0.8 green:0.85 blue:1.0 alpha:1.0]];
    
    _useGradient = YES;
}


- (void)getShadowBaseColorRed:(float *)r green:(float *)g blue:(float *)b {
    *r = 0.02;
    *g = 0.08;
    *b = 0.78;
}

- (float)proposedShadowOpacity:(float)op
{
    return op*2;
}

- (float)_defaultLineWidth {
    return 0.77;
}

- (void)getStart:(NSPoint *)pStart end:(NSPoint *)pEnd controlPoint1:(NSPoint *)pCp1 controlPoint2:(NSPoint *)pCp2
		inView:(NSView *)view
{
    NSPoint start, end, cp1, cp2;

    start = [_fromOutput bounds].origin;
    end =   [_toInput bounds].origin;
    start.x += 8.0;
    
    start.y += 8.0;
    
    if ( !_drawToFrameOrigin) {
        end.x += 8.0;
        end.y += 9.0;
    }
    else {
        end.y += 4.0;
    }
    
    ///NSLog(@"connector start %f %f,  end %f %f", start.x, start.y,  end.x, end.y);
    start = [view convertPoint:start fromView:_fromOutput];
    end = [view convertPoint:end fromView:_toInput];

    /*
    cp1 = NSMakePoint(start.x, start.y - 16.0);
    cp2 = NSMakePoint(end.x, end.y + 16.0);

    if (end.y > start.y) {
        cp1.y -= (end.y - start.y) / 8.0;
        cp2.y += (end.y - start.y) / 8.0;
    }
    */
    
    double xDist = fabs(end.x - start.x);
    double yDist = fabs(end.y - start.y);
    
    double xOff_cp1 = 4;
    double xOff_cp2 = 4;
    double xMul_cp1 = 0.31;
    double xMul_cp2 = 0.45;
    if (yDist > xDist) {
        double o = MIN(20, 0.5*(yDist - xDist));
        xOff_cp1 += o;
        xOff_cp2 += o;
    
        double lbase = 28;
        double m = log(lbase + (yDist - xDist)) / log(lbase);
        xMul_cp1 *= m;
        //xMul_cp2 = 1.0 - xMul_cp1;
        xMul_cp2 *= m;
        
        xOff_cp1 *= m;
        xOff_cp2 *= m;
    }
    if (end.x < start.x) xMul_cp2 *= -1.0;
    
    cp1 = NSMakePoint(start.x + xOff_cp1 + fabs(end.x - start.x)*xMul_cp1,  start.y + (end.y - start.y)*0.3);
    //cp2 = NSMakePoint(start.x + (end.x - start.x)*xMul_cp2,  start.y + (end.y - start.y)*0.7);
    cp2 = NSMakePoint(end.x - xOff_cp2 - (end.x - start.x)*xMul_cp2,  start.y + (end.y - start.y)*0.7);
	
	*pStart = start;
	*pEnd = end;
	*pCp1 = cp1;
	*pCp2 = cp2;
}


@end
