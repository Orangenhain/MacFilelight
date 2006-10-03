/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLView.h"

#import "FLRadialPainter.h"
#import "FLFile.h"
#import "FLController.h"
#import "FLDirectoryDataSource.h"

@implementation NSString (CenteredDrawing)

- (void) drawAtCenter: (NSPoint) center
       withAttributes: (NSDictionary *) attr
{
    NSSize size = [self sizeWithAttributes: attr];
    NSPoint p = NSMakePoint(center.x - size.width / 2,
                            center.y - size.height / 2);
    [self drawAtPoint: p withAttributes: attr];
}

@end


@implementation FLView

#pragma mark Tracking

- (void) setTrackingRect
{    
    NSPoint mouse = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint where = [self convertPoint: mouse fromView: nil];
    BOOL inside = ([self hitTest: where] == self);
    
    trackingRect = [self addTrackingRect: [self visibleRect]
                                   owner: self
                                userData: NULL
                            assumeInside: inside];
    if (inside) {
        [self mouseEntered: nil];
    }
}

- (void) clearTrackingRect
{
	[self removeTrackingRect: trackingRect];
}

- (BOOL) acceptsFirstResponder
{    
    return YES;
}

- (BOOL) becomeFirstResponder
{
    return YES;
}

- (void) resetCursorRects
{
	[super resetCursorRects];
	[self clearTrackingRect];
	[self setTrackingRect];
}

-(void) viewWillMoveToWindow: (NSWindow *) win
{
	if (!win && [self window]) {
        [self clearTrackingRect];
    }
}

-(void) viewDidMoveToWindow
{
	if ([self window]) {
        [self setTrackingRect];
    }
}

- (void) mouseEntered: (NSEvent *) event
{
    wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [[self window] makeFirstResponder: self];
}

- (void) mouseExited: (NSEvent *) event
{
    [[self window] setAcceptsMouseMovedEvents: wasAcceptingMouseEvents];
    [locationDisplay setStringValue: @""];
    [sizeDisplay setStringValue: @""];
}

- (void) mouseMoved: (NSEvent *) event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    id item = [painter itemAt: where];
    if (item) {
        [locationDisplay setStringValue: [item path]];
        [sizeDisplay setStringValue: [item displaySize]];
    } else {
        [locationDisplay setStringValue: @""];
        [sizeDisplay setStringValue: @""];
    }
}

- (void) mouseUp: (NSEvent *) event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    id item = [painter itemAt: where];
    if (item && [item isKindOfClass: [FLDirectory class]]) {
        [controller setRootDir: item];
    }
}


#pragma mark Drawing

- (void) drawRect: (NSRect)rect
{
    NSString *size;
    [painter drawRect: rect];
    
    size = [[[self dataSource] rootDir] displaySize];
    [size drawAtCenter: [self center]
        withAttributes: [NSDictionary dictionary]];
}

- (id) dataSource
{
    return dataSource;
}

- (void) awakeFromNib
{
    painter = [[FLRadialPainter alloc] initWithView: self];
    [painter setColorer: self];
}

- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    if ([item isKindOfClass: [FLDirectory class]]) {
        return [painter colorForItem: item
                           angleFrac: angle
                           levelFrac: level];
    } else {
        return [NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0];
    }
}

@end
