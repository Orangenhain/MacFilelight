/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"

@interface NSString (CenteredDrawing)
- (void) drawAtCenter: (NSPoint) center
       withAttributes: (NSDictionary *) attr;
@end

@interface FLView : NSView <FLHasDataSource> {
    IBOutlet id locationDisplay;
    IBOutlet id sizeDisplay;
    IBOutlet id dataSource;
    IBOutlet id controller;
    
    FLRadialPainter *painter;
    NSTrackingRectTag trackingRect;
    BOOL wasAcceptingMouseEvents;
}

@end
