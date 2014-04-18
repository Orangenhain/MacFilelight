/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLPolar.h"

@implementation FLPolar

+ (NSPoint) pointWithPolarCenter: (NSPoint)center
                          radius: (CGFloat)r
                           angle: (CGFloat)deg
{
    CGFloat rads = deg * M_PI / 180.0;
    return NSMakePoint(center.x + r * cos(rads), center.y + r * sin(rads));
}

+ (void) coordsForPoint: (NSPoint)point
                 center: (NSPoint)center
             intoRadius: (CGFloat*)r
                  angle: (CGFloat*)deg
{
    CGFloat dy = point.y - center.y;
    CGFloat dx = point.x - center.x;
    
    CGFloat a = atan(dy / dx) + (dx > 0 ? 0 : M_PI);
    if (a < 0) {
        a += 2 * M_PI;
    }
    
    *deg = a * 180.0 / M_PI;
    *r = sqrt(dx*dx + dy*dy);
}


@end
