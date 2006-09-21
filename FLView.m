/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLView.h"

#import "FLRadialPainter.h"

@implementation FLView

- (void) drawRect: (NSRect)rect
{
    [painter drawInView: self
                   rect: rect
                 center: [self center]
                 radius: [self maxRadius]];
}

- (void) mouseDown: (NSEvent *)event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    id item = [painter itemAt: where
                       center: [self center]
                       radius: [self maxRadius]];
    if (item != nil) {
        [display setStringValue: [item path]];
    }
}

@end
