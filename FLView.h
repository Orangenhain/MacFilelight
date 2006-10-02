/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"

@interface FLView : NSView <FLHasDataSource> {
    IBOutlet id display;
    IBOutlet id dataSource;
    
    FLRadialPainter *painter;
    NSTrackingRectTag trackingRect;
    BOOL wasAcceptingMouseEvents;
}

@end
