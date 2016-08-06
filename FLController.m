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
static NSString *ToolbarItemCountID = @"Count ToolbarItem";

@interface FLController () <NSToolbarDelegate>

@property (strong) FLScanner   *scanner;
@property (strong) FLDirectory *scanDir;

@property (weak) IBOutlet FLView * sizer;
@property (unsafe_unretained) IBOutlet id tabView;
@property (unsafe_unretained) IBOutlet id progress;
@property (unsafe_unretained) IBOutlet id scanDisplay;
@property (unsafe_unretained) IBOutlet id window;

@end

@implementation FLController

#pragma mark Toolbar

+ (void)initialize
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"shouldCount": @"file size"}];
}

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
    } else if ([itemID isEqual: ToolbarItemCountID]) {
        NSPopUpButton *popup = [[NSPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 100, 26) pullsDown:NO];
        [popup addItemsWithTitles:@[@"file count", @"file size"]];
        [popup selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"shouldCount"]];
        
        [item setToolTip: @"Select what to count"];
        [item setView:popup];
        [item setAction: @selector(toolbarItemCountClicked:)];
    } else {
        return nil;
    }
    
    if (![item paletteLabel]) {
        [item setPaletteLabel: [item label]];
    }
    if (![item target]) {
        [item setTarget: self];
    }
    return item;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar * __attribute__ ((unused))) toolbar
{
    return @[ToolbarItemUpID, ToolbarItemRefreshID, NSToolbarFlexibleSpaceItemIdentifier, ToolbarItemCountID];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar * __attribute__ ((unused))) toolbar
{
    return @[ToolbarItemUpID,
             ToolbarItemRefreshID,
             ToolbarItemCountID,
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
    
    self.scanner = [[FLScanner alloc] initWithPath: path
                                           progress: self.progress
                                            display: self.scanDisplay];
    [self.scanner scanThenPerform: @selector(finishScan:)
                               on: self];
    return YES;
}

- (void) finishScan: (id __attribute__ ((unused))) data
{
    if ([self.scanner scanError]) {
        if (![self.scanner isCancelled]) {
            NSError *error = [NSError errorWithDomain:@"FilelightErrorDomain"
                                                 code:1
                                             userInfo:@{ NSLocalizedDescriptionKey: [self.scanner scanError] }];
            [[NSAlert alertWithError:error] beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse __unused returnCode) {
                [self.window orderOut: self];
            }];
        }
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
    NSInteger result = [openPanel runModal];
    if (result == NSModalResponseOK) {
        NSString *path = [(NSURL *)[openPanel URLs][0] path];
        [self startScan: path];
    }
}

- (IBAction) refresh: (id __attribute__ ((unused))) sender
{
    [self startScan: [[self rootDir] path]];
}

- (IBAction) toolbarItemCountClicked:(id)sender
{
    if ([sender isKindOfClass:[NSPopUpButton class]])
    {
        [[NSUserDefaults standardUserDefaults] setObject:[(NSPopUpButton*)sender titleOfSelectedItem] forKey:@"shouldCount"];
        [self.sizer setNeedsDisplay:YES];
    }
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
    FLView *sizer = self.sizer;
    
    [[sizer dataSource] setRootDir: dir];
    [sizer setNeedsDisplay: YES];
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
