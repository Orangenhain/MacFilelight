/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"

#import "FLDirectoryDataSource.h"
#import "FLView.h"
#import "FLScanner.h"
#import "FLFile.h"

static NSString *ToolbarID = @"Filelight Toolbar";
static NSString *ToolbarItemUpID = @"Up ToolbarItem";
static NSString *ToolbarItemRefreshID = @"Refresh ToolbarItem";

@interface FLController () <NSToolbarDelegate>

@property (retain) FLScanner   *scanner;
@property (retain) FLDirectory *scanDir;

@property (assign) IBOutlet FLView * sizer;
@property (assign) IBOutlet id tabView;
@property (assign) IBOutlet id progress;
@property (assign) IBOutlet id scanDisplay;
@property (assign) IBOutlet id window;

@end

@implementation FLController

#pragma mark Toolbar

- (void) setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: ToolbarID];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [self.window setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar * __attribute__ ((unused))) toolbar
      itemForItemIdentifier: (NSString *) itemID
  willBeInsertedIntoToolbar: (BOOL __attribute__ ((unused))) willInsert
{
    NSToolbarItem *item = [[NSToolbarItem alloc]
        initWithItemIdentifier: itemID];
    
    if ([itemID isEqual: ToolbarItemUpID]) {
        [item setLabel: @"Up"];
        [item setToolTip: @"Go to the parent directory"];
        [item setImage: [NSImage imageNamed: @"arrowUp"]];
        [item setAction: @selector(parentDir:)];
    } else if ([itemID isEqual: ToolbarItemRefreshID]) {
        [item setLabel: @"Refresh"];
        [item setToolTip: @"Rescan the current directory"];
        [item setImage: [NSImage imageNamed: @"reload"]];
        [item setAction: @selector(refresh:)];
    } else {
        [item release];
        return nil;
    }
    
    if (![item paletteLabel]) {
        [item setPaletteLabel: [item label]];
    }
    if (![item target]) {
        [item setTarget: self];
    }
    return [item autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar * __attribute__ ((unused))) toolbar
{
    return @[ToolbarItemUpID, ToolbarItemRefreshID];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar * __attribute__ ((unused))) toolbar
{
    return @[ToolbarItemUpID,
             ToolbarItemRefreshID,
             NSToolbarCustomizeToolbarItemIdentifier,
             NSToolbarFlexibleSpaceItemIdentifier,
             NSToolbarSpaceItemIdentifier,
             NSToolbarSeparatorItemIdentifier];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) item
{
    if ([[item itemIdentifier] isEqual: ToolbarItemUpID]) {
        return ![FLScanner isMountPoint: [[self rootDir] path]];
    }
    return YES;
}

#pragma mark Scanning

- (BOOL) startScan: (NSString *) path
{
    if (self.scanner) {
        return NO;
    }
    
    [self.tabView selectTabViewItemWithIdentifier: @"Progress"];
    [self.progress setDoubleValue: [self.progress minValue]];
    [self.scanDisplay setStringValue: @""];
    [self.window makeKeyAndOrderFront: self];
    
    self.scanner = [[[FLScanner alloc] initWithPath: path
                                           progress: self.progress
                                            display: self.scanDisplay] autorelease];
    [self.scanner scanThenPerform: @selector(finishScan:)
                               on: self];
    return YES;
}

- (void) finishScan: (id __attribute__ ((unused))) data
{
    if ([self.scanner scanError]) {
        if (![self.scanner isCancelled]) {
            NSRunAlertPanel(@"Directory scan could not complete",
                            [self.scanner scanError], nil, nil, nil);
        }
        [self.window orderOut: self];
    } else {
        [self setScanDir: [self.scanner scanResult]];
        [self setRootDir: [self scanDir]];
        [self.tabView selectTabViewItemWithIdentifier: @"Filelight"];
    }
    
    self.scanner = nil;
}

#pragma mark - IBActions

- (IBAction) cancelScan: (id __attribute__ ((unused))) sender
{
    [self.scanner cancel];
}

- (IBAction) open: (id __attribute__ ((unused))) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    [openPanel setAllowedFileTypes:nil];
    int result = [openPanel runModal];
    if (result == NSOKButton) {
        NSString *path = [(NSURL *)[openPanel URLs][0] path];
        [self startScan: path];
    }
}

- (IBAction) refresh: (id __attribute__ ((unused))) sender
{
    [self startScan: [[self rootDir] path]];
}

#pragma mark Misc

- (BOOL) application: (NSApplication * __attribute__ ((unused))) app openFile: (NSString *) filename
{
    return [self startScan: filename];
}

- (void) awakeFromNib
{
    [self setupToolbar];
}

- (void) applicationDidFinishLaunching: (NSNotification* __attribute__ ((unused))) notification
{
    if (![self.window isVisible]) {
        [self open: self];
    }
}

- (void) setRootDir: (FLDirectory *) dir
{
    [[self.sizer dataSource] setRootDir: dir];
    [self.sizer setNeedsDisplay: YES];
    [self.window setTitle: [dir path]];
}

- (FLDirectory *) rootDir
{
    return [[self.sizer dataSource] rootDir];
}

- (void) parentDir: (id __attribute__ ((unused))) sender
{
    FLDirectory *parent = [[self rootDir] parent];
    if (parent) {
        [self setRootDir: parent];
    } else {
        NSString *path = [[self rootDir] path];
        path = [path stringByDeletingLastPathComponent];
        [self startScan: path];
    }
}

- (void) refresh
{
    [self refresh:nil];
}

@end
