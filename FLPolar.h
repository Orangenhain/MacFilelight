/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Utilities for polar points
// NB: Angles are all in degrees
@interface FLPolar : NSObject

// Create a point with polar coordinates
+ (NSPoint) pointWithPolarCenter: (NSPoint)center
                          radius: (CGFloat)r
                           angle: (CGFloat)deg;

// Extract the coordinates for a point. Always gives 0 <= deg < 360
+ (void) coordsForPoint: (NSPoint)point
                 center: (NSPoint)center
             intoRadius: (CGFloat*)r
                  angle: (CGFloat*)deg;

@end
