//
//  LQNSBezierPathAdditions.m
//  Edo
//
//  Created by Pauli Ojala on 12.12.2005.
//  Copyright 2005 Lacquer Oy. All rights reserved.
//

#import "LQNSBezierPathAdditions.h"


@implementation NSBezierPath ( LQNSBezierPathAdditions )


+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect rounding:(double)rounding
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    double rounding2 = rounding * 0.25;
    double width = rect.size.width;
    double height = rect.size.height - rounding;
    double x = rect.origin.x;
    double y = rect.origin.y;
    double yMargin = 0.0;
    double xMargin = 0.0;

    [path moveToPoint:NSMakePoint(x+rounding,   y+yMargin) ];
    [path lineToPoint:NSMakePoint(x+width-rounding,   y+yMargin) ];
    [path curveToPoint:NSMakePoint(x+width,   y+rounding+yMargin)
          controlPoint1:NSMakePoint(x+width-rounding2,   y+yMargin)
          controlPoint2:NSMakePoint(x+width,   y+yMargin+rounding2) ];
    [path lineToPoint:NSMakePoint(x+width,   y+height) ];
    [path curveToPoint:NSMakePoint(x+width-rounding,   y+height+rounding)
          controlPoint1:NSMakePoint(x+width,   y+height+rounding-rounding2)
          controlPoint2:NSMakePoint(x+width-rounding2,   y+height+rounding) ];
    [path lineToPoint:NSMakePoint(x+rounding,   y+height+rounding) ];
    [path curveToPoint:NSMakePoint(x+xMargin,   y+height)
          controlPoint1:NSMakePoint(x+xMargin+rounding2,   y+height+rounding)
          controlPoint2:NSMakePoint(x+xMargin,   y+height+rounding-rounding2) ];
    [path lineToPoint:NSMakePoint(x+xMargin,   y+rounding+yMargin) ];
    [path curveToPoint:NSMakePoint(x+rounding,   y+yMargin)
          controlPoint1:NSMakePoint(x+xMargin,   y+yMargin+rounding2)
          controlPoint2:NSMakePoint(x+xMargin+rounding2,   y+yMargin) ];

    return path;
}

+ (NSBezierPath *)bezierPathWithCutCornersRect:(NSRect)rect cornerSize:(double)rounding
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    double rounding2 = rounding * 0.25;
    double width = rect.size.width;
    double height = rect.size.height - rounding;
    double x = rect.origin.x;
    double y = rect.origin.y;
    double yMargin = 0.0;
    double xMargin = 0.0;

    [path moveToPoint:NSMakePoint(x+rounding,   y+yMargin) ];
    [path lineToPoint:NSMakePoint(x+width-rounding,   y+yMargin) ];
    [path lineToPoint:NSMakePoint(x+width,   y+rounding+yMargin) ];
    [path lineToPoint:NSMakePoint(x+width,   y+height) ];
    [path lineToPoint:NSMakePoint(x+width-rounding,   y+height+rounding)];
    [path lineToPoint:NSMakePoint(x+rounding,   y+height+rounding) ];
    [path lineToPoint:NSMakePoint(x+xMargin,   y+height)];
    [path lineToPoint:NSMakePoint(x+xMargin,   y+rounding+yMargin) ];
    [path lineToPoint:NSMakePoint(x+rounding,   y+yMargin)];

    return path;
}


+ (NSBezierPath *)roundButtonPathWithRect:(NSRect)rect
{
	NSBezierPath *path = [NSBezierPath bezierPath];
	double round = (double)rect.size.height * 0.5;
	double roundCp = round * 0.5;
	
	[path moveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + round)];
	[path curveToPoint:NSMakePoint(rect.origin.x + round, rect.origin.y + rect.size.height)
			controlPoint1:NSMakePoint(rect.origin.x, rect.origin.y + round + roundCp)
			controlPoint2:NSMakePoint(rect.origin.x + round - roundCp, rect.origin.y + rect.size.height) ];
	
	[path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width - round, rect.origin.y + rect.size.height)];
	[path curveToPoint:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + round)
			controlPoint1:NSMakePoint(rect.origin.x + rect.size.width - round + roundCp, rect.origin.y + rect.size.height)
			controlPoint2:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + round + roundCp) ];
	
	[path curveToPoint:NSMakePoint(rect.origin.x + rect.size.width - round, rect.origin.y)
			controlPoint1:NSMakePoint(rect.origin.x + rect.size.width, rect.origin.y + round - roundCp)
			controlPoint2:NSMakePoint(rect.origin.x + rect.size.width - round + roundCp, rect.origin.y)];
			
	[path lineToPoint:NSMakePoint(rect.origin.x + round, rect.origin.y)];
	[path curveToPoint:NSMakePoint(rect.origin.x, rect.origin.y + round)
			controlPoint1:NSMakePoint(rect.origin.x + round - roundCp, rect.origin.y)
			controlPoint2:NSMakePoint(rect.origin.x, rect.origin.y + round - roundCp)];
	
	return path;
}


@end