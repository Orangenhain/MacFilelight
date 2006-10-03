/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"

#import "FLDirectoryDataSource.h"

@implementation FLController

- (void) awakeFromNib
{
    m_scanner = nil;
}

- (BOOL) application: (NSApplication *)app openFile: (NSString *)filename
{
    if (m_scanner) {
        return NO;
    }
    
    [tabView selectTabViewItemWithIdentifier: @"Progress"];
    [progress setDoubleValue: [progress minValue]];
    [scanDisplay setStringValue: @""];
    [window makeKeyAndOrderFront: self];
    
    m_scanner = [[FLScanner alloc] initWithPath: filename
                                       progress: progress
                                        display: scanDisplay];
    [m_scanner scanThenPerform: @selector(finishScan:)
                            on: self];
    return YES;
}

- (void) setRootDir: (FLDirectory *) dir
{
    [[sizer dataSource] setRootDir: dir];
    [sizer setNeedsDisplay: YES];
    [window setTitle: [dir path]];
}

- (void) finishScan: (id) data
{
    if ([m_scanner scanError]) {
        if (![m_scanner isCancelled]) {
            NSRunAlertPanel(@"Directory scan could not complete",
                            [m_scanner scanError], nil, nil, nil);
        }
        [window orderOut: self];
    } else {
        [self setRootDir: [m_scanner scanResult]];
        [tabView selectTabViewItemWithIdentifier: @"Filelight"];
    }
    
    [m_scanner release];
    m_scanner = nil;
}

- (IBAction) open: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    int result = [openPanel runModalForTypes: nil];
    if (result == NSOKButton) {
        NSString *path = [[openPanel filenames] objectAtIndex: 0];
        [self application: [NSApplication sharedApplication] openFile: path];
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    if (![window isVisible]) {
        [self open: self];
    }
}

- (IBAction) cancelScan: (id) sender
{
    if (m_scanner) {
        [m_scanner cancel];
    }
}

@end
