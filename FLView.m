/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLView.h"

#import "FLRadialPainter.h"
#import "FLFile.h"
#import "FLController.h"
#import "FLDirectoryDataSource.h"

@interface FLView ()

@property (assign) IBOutlet id locationDisplay;
@property (assign) IBOutlet id sizeDisplay;
@property (assign) IBOutlet id dataSource;
@property (assign) IBOutlet id controller;
@property (assign) IBOutlet id contextMenu;

@property (assign) BOOL               wasAcceptingMouseEvents;
@property (assign) NSTrackingRectTag  trackingRect;
@property (retain) FLFile            *context_target;
@property (retain) FLRadialPainter   *painter;

@end

@implementation FLView

-(void)dealloc
{
    self.context_target = nil;
    self.painter = nil;
    
    [super dealloc];
}

#pragma mark Tracking

- (void) setTrackingRect
{    
    NSPoint mouse = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint where = [self convertPoint: mouse fromView: nil];
    BOOL inside = ([self hitTest: where] == self);
    
    self.trackingRect = [self addTrackingRect: [self visibleRect]
                                        owner: self
                                     userData: NULL
                                 assumeInside: inside];
    if (inside) {
        [self mouseEntered: nil];
    }
}

- (void) clearTrackingRect
{
	[self removeTrackingRect: self.trackingRect];
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

- (void) mouseEntered: (NSEvent * __attribute__ ((unused))) event
{
    self.wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [[self window] makeFirstResponder: self];
}

- (FLFile *) itemForEvent: (NSEvent *) event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    return [self.painter itemAt: where];
}

- (void) mouseExited: (NSEvent * __attribute__ ((unused))) event
{
    [[self window] setAcceptsMouseMovedEvents: self.wasAcceptingMouseEvents];
    [self.locationDisplay setStringValue: @""];
    [self.sizeDisplay setStringValue: @""];
}

- (void) mouseMoved: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item) {
        [self.locationDisplay setStringValue: [item path]];
        [self.sizeDisplay setStringValue: [item displaySize]];
        if ([item isKindOfClass: [FLDirectory class]]) {
            [[NSCursor pointingHandCursor] set];
        } else {
            [[NSCursor arrowCursor] set];
        }
    } else {
        [self.locationDisplay setStringValue: @""];
        [self.sizeDisplay setStringValue: @""];
        [[NSCursor arrowCursor] set];
    }
}

- (void) mouseUp: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item && [item isKindOfClass: [FLDirectory class]]) {
        [self.controller setRootDir: item];
    }
}

- (NSMenu *) menuForEvent: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item) {
        self.context_target = item;
        return (NSMenu *)self.contextMenu;
    } else {
        return nil;
    }
}

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    if ([item action] == @selector(zoom:)) {
        return [self.context_target isKindOfClass: [FLDirectory class]];
    }
    return YES;
}

#pragma mark - IBActions

- (IBAction) zoom: (id __attribute__ ((unused))) sender
{
    [self.controller setRootDir: (FLDirectory *)self.context_target];
}

- (IBAction) open: (id __attribute__ ((unused))) sender
{
    [[NSWorkspace sharedWorkspace] openFile: [self.context_target path]];
}

- (IBAction) reveal: (id __attribute__ ((unused))) sender
{
    [[NSWorkspace sharedWorkspace] selectFile: [self.context_target path]
                     inFileViewerRootedAtPath: @""];
}

- (IBAction) trash: (id __attribute__ ((unused))) sender
{
    NSInteger tag;
    BOOL success;
    
    NSString *path = [self.context_target path];
    NSString *basename = [path lastPathComponent];
    
    success = [[NSWorkspace sharedWorkspace]
        performFileOperation: NSWorkspaceRecycleOperation
                      source: [path stringByDeletingLastPathComponent]
                 destination: @""
                       files: @[basename]
                         tag: &tag];
    
    if (success) {
        [self.controller refresh];
    } else {
        NSString *msg = [NSString stringWithFormat:
            @"The path %@ could not be deleted.", path];
        NSRunAlertPanel(@"Deletion failed", msg, nil, nil, nil);
    }
}

- (IBAction) copyPath: (id __attribute__ ((unused))) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes: @[NSStringPboardType]
               owner: self];
    [pb setString: [[[self.context_target path] copy] autorelease]
          forType: NSStringPboardType];
}

#pragma mark - Drawing

- (void) drawSize: (NSString * __attribute__ ((unused))) str
{
    double rfrac, wantr, haver;
    float pts;
    NSFont *font;
    NSSize size;
    NSDictionary *attrs;
    NSPoint p, center;
    
    rfrac = [self.painter minRadiusFraction] - 0.02;
    wantr = [self maxRadius] * rfrac;
    
    font = [NSFont systemFontOfSize: 0];
    attrs = [NSMutableDictionary dictionary];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    haver = hypot(size.width, size.height) / 2;
    
    pts = [font pointSize] * wantr / haver;
    font = [NSFont systemFontOfSize: pts];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    center = [self center];
    p = NSMakePoint(center.x - size.width / 2,
                    center.y - size.height / 2);
    [str drawAtPoint: p withAttributes: attrs];
}

- (void) drawRect: (NSRect)rect
{
    NSString *size;
    [self.painter drawRect: rect];
    
    size = [[[self dataSource] rootDir] displaySize];
    [self drawSize: size];
}

- (void) awakeFromNib
{
    self.painter = [[[FLRadialPainter alloc] initWithView: self] autorelease];
    [self.painter setColorer: self];
}

- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    if ([item isKindOfClass: [FLDirectory class]]) {
        return [self.painter colorForItem: item
                                angleFrac: angle
                                levelFrac: level];
    } else {
        return [NSColor colorWithCalibratedWhite: 0.85 alpha: 1.0];
    }
}

@end
