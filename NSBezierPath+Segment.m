/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "NSBezierPath+Segment.h"

#import "FLPolar.h"

@implementation NSBezierPath (Segment)

+ (NSBezierPath*) circleSegmentWithCenter: (NSPoint)center
                               startAngle: (CGFloat)a1
                                 endAngle: (CGFloat)a2
                              smallRadius: (CGFloat)r1
                                bigRadius: (CGFloat)r2
{
    NSBezierPath *bp = [NSBezierPath bezierPath];
    [bp moveToPoint: [FLPolar pointWithPolarCenter: center
                                                 radius: r1
                                                  angle: a1]];
    [bp appendBezierPathWithArcWithCenter: center
                                   radius: r1
                               startAngle: a1
                                 endAngle: a2
                                clockwise: NO];
    [bp lineToPoint: [FLPolar pointWithPolarCenter: center
                                            radius: r2
                                             angle: a2]];
    [bp appendBezierPathWithArcWithCenter: center
                                   radius: r2 
                               startAngle: a2
                                 endAngle: a1
                                clockwise: YES];
    [bp closePath];
    return bp;
}

@end
